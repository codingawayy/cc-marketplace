#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Agent Loop Orchestrator
#
# Runs Claude Code sessions in a loop, passing state between iterations
# via directive.md and learnings.md files on disk. Each iteration gets a
# fresh context window, so the loop can run indefinitely.
#
# Usage:
#   agent-loop "Your goal here" [options]
#
# Options:
#   --max-iterations N       Maximum number of iterations (default: 50)
#   --budget-per-iteration N Max USD per iteration (default: 5)
#   --model MODEL            Claude model to use (default: sonnet)
#   --working-dir DIR        Working directory for Claude (default: current directory)
#   --branch BRANCH          Create a git worktree on this branch for isolated work
#   --run-id ID              Resume a previous run by its ID
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Allow running from inside a Claude Code session
unset CLAUDECODE 2>/dev/null || true

# Defaults
MAX_ITERATIONS=50
BUDGET_PER_ITERATION=5
MODEL="sonnet"
WORKING_DIR=""
BRANCH=""
RUN_ID=""
GOAL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)       MAX_ITERATIONS="$2"; shift 2 ;;
    --budget-per-iteration) BUDGET_PER_ITERATION="$2"; shift 2 ;;
    --model)                MODEL="$2"; shift 2 ;;
    --working-dir)          WORKING_DIR="$2"; shift 2 ;;
    --branch)               BRANCH="$2"; shift 2 ;;
    --run-id)               RUN_ID="$2"; shift 2 ;;
    --*)                    echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$GOAL" ]]; then
        GOAL="$1"
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

# ─────────────────────────────────────────────────────────────────────────────
# Git worktree setup
# ─────────────────────────────────────────────────────────────────────────────
setup_worktree() {
  local branch="$1"
  local repo_root

  # Find the MAIN repo root (not a worktree root). --git-common-dir returns
  # the shared .git directory, which always belongs to the main repo — even
  # when WORKING_DIR is already a worktree (e.g. on resume).
  local search_dir="${WORKING_DIR:-$(pwd)}"
  local git_common_dir
  git_common_dir=$(git -C "$search_dir" rev-parse --git-common-dir 2>/dev/null)

  if [[ -z "$git_common_dir" ]]; then
    echo "Error: --branch requires a git repository" >&2
    exit 1
  fi

  # Resolve to absolute path — git-common-dir may be relative (".git") or
  # absolute ("C:/Users/.../repo/.git" on Windows). cd handles both.
  repo_root=$(dirname "$(cd "$search_dir" && cd "$git_common_dir" && pwd)")

  local repo_name
  repo_name=$(basename "$repo_root")

  # Worktree goes in a sibling directory: ../{repo}--{branch-slug}
  local branch_slug
  branch_slug=$(echo "$branch" | tr '/' '-')
  local worktree_dir
  worktree_dir="$(dirname "$repo_root")/${repo_name}--${branch_slug}"

  # Check if worktree already exists at this path
  if [[ -d "$worktree_dir" ]]; then
    echo "  Worktree already exists: $worktree_dir"
    # Verify it's actually a git worktree
    if ! git -C "$worktree_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Error: $worktree_dir exists but is not a git worktree" >&2
      exit 1
    fi
  else
    echo "  Creating worktree: $worktree_dir (branch: $branch)"

    # Create the branch if it doesn't exist
    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
      # Branch exists — create worktree using existing branch
      git -C "$repo_root" worktree add "$worktree_dir" "$branch"
    else
      # Branch doesn't exist — create it from current HEAD
      git -C "$repo_root" worktree add -b "$branch" "$worktree_dir"
    fi

    echo "  Worktree created."
  fi

  # Set working dir to the worktree
  WORKING_DIR="$worktree_dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# Resolve working directory and run directory
# ─────────────────────────────────────────────────────────────────────────────

if [[ -n "$RUN_ID" ]]; then
  # Resuming — we need to find the run directory. It could be in the working
  # dir (if provided) or the current dir. Try both.
  SEARCH_DIR="${WORKING_DIR:-$(pwd)}"
  RUN_DIR="$SEARCH_DIR/.agent-loop/$RUN_ID"
  if [[ ! -d "$RUN_DIR" ]]; then
    echo "Error: Run directory not found: $RUN_DIR" >&2
    exit 1
  fi
  echo "Resuming run: $RUN_ID"

  # Load saved values from config if not explicitly provided
  if [[ -f "$RUN_DIR/config.json" ]]; then
    if [[ -z "$WORKING_DIR" ]]; then
      SAVED_DIR=$(jq -r '.working_dir // empty' "$RUN_DIR/config.json" 2>/dev/null)
      [[ -n "$SAVED_DIR" ]] && WORKING_DIR="$SAVED_DIR"
    fi
    if [[ -z "$BRANCH" ]]; then
      SAVED_BRANCH=$(jq -r '.branch // empty' "$RUN_DIR/config.json" 2>/dev/null)
      [[ -n "$SAVED_BRANCH" ]] && BRANCH="$SAVED_BRANCH"
    fi
  fi
fi

# Set up worktree if --branch was specified (new run or resumed)
if [[ -n "$BRANCH" ]]; then
  setup_worktree "$BRANCH"
fi

# Final working dir resolution
if [[ -n "$WORKING_DIR" ]]; then
  WORKING_DIR="$(cd "$WORKING_DIR" && pwd)"
else
  WORKING_DIR="$(pwd)"
fi

# Runs live inside the working directory
RUNS_DIR="$WORKING_DIR/.agent-loop"

# ─────────────────────────────────────────────────────────────────────────────
# Set up new run (skipped when resuming)
# ─────────────────────────────────────────────────────────────────────────────
if [[ -z "$RUN_ID" ]]; then
  # New run
  if [[ -z "$GOAL" ]]; then
    echo "Usage: $0 \"Your goal here\" [options]" >&2
    exit 1
  fi

  # Create run directory with date + slug from goal
  SLUG=$(echo "$GOAL" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | head -c 40 | sed 's/-$//')
  RUN_ID="$(date +%Y.%m.%d)-${SLUG}"
  RUN_DIR="$RUNS_DIR/$RUN_ID"
  mkdir -p "$RUN_DIR/iterations"

  # Seed directive.md
  cat > "$RUN_DIR/directive.md" << DIRECTIVE_EOF
# Agent Directive

## Goal

$GOAL

## Status

IN_PROGRESS

## Progress

(No progress yet — this is the first iteration.)

## Current Task

Analyze the goal, break it into steps, and begin working on the first step.

## Iteration History

| # | What was done | Result |
|---|---------------|--------|
DIRECTIVE_EOF

  # Seed empty learnings.md
  cat > "$RUN_DIR/learnings.md" << 'LEARNINGS_EOF'
# Learnings

(No learnings yet — this is the first iteration.)
LEARNINGS_EOF

  # Save config
  GOAL_JSON=$(echo -n "$GOAL" | jq -Rs '.')
  BRANCH_JSON=$(echo -n "$BRANCH" | jq -Rs '.')
  cat > "$RUN_DIR/config.json" << CONFIG_EOF
{
  "goal": $GOAL_JSON,
  "max_iterations": $MAX_ITERATIONS,
  "budget_per_iteration_usd": $BUDGET_PER_ITERATION,
  "model": "$MODEL",
  "working_dir": "$WORKING_DIR",
  "branch": $BRANCH_JSON
}
CONFIG_EOF

  echo "Created run: $RUN_ID"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────────────────────────────────────
DIRECTIVE="$RUN_DIR/directive.md"
LEARNINGS="$RUN_DIR/learnings.md"
ITERATIONS_DIR="$RUN_DIR/iterations"
RULES_FILE="$SCRIPT_DIR/rules.md"

# Read rules for injection into system prompt
RULES_CONTENT=$(cat "$RULES_FILE")

# Convert a Git Bash path (/c/Users/...) to a Windows path (C:\Users\...)
_win_path() {
  echo "$1" | sed -E 's|^/([a-zA-Z])/|\U\1:\\|; s|/|\\|g'
}

# Print resume command on any exit (except when the run is DONE)
_on_exit() {
  if [[ -f "$DIRECTIVE" ]] && grep -q "DONE" "$DIRECTIVE" 2>/dev/null; then
    return
  fi
  local win_script
  win_script=$(_win_path "$SCRIPT_DIR/orchestrator.sh")
  echo ""
  echo "  To resume this run:"
  echo ""
  echo "    & \"C:\\Program Files\\Git\\bin\\bash.exe\" \"$win_script\" --run-id $RUN_ID --working-dir $WORKING_DIR"
  echo ""
}
trap _on_exit EXIT

# ─────────────────────────────────────────────────────────────────────────────
# Real-time progress: poll the NDJSON output file and print tool calls/tokens
#
# Uses file polling instead of `tail -f | pipe` because pipe buffering on
# Windows/Git Bash causes output to stall until the buffer fills (~64KB).
# ─────────────────────────────────────────────────────────────────────────────
_show_progress() {
  local file="$1"
  local pid="$2"
  local start_ts
  start_ts=$(date +%s)
  local total_in=0
  local total_out=0
  local tool_count=0
  local last_tool=""
  local seen=0

  while true; do
    # Count complete lines in the output file
    local total_lines
    total_lines=$(wc -l < "$file" 2>/dev/null) || total_lines=0
    total_lines=$((total_lines + 0))

    if [[ "$total_lines" -gt "$seen" ]]; then
      # Process new lines in a single jq call. grep filters out non-JSON lines
      # (stderr mixed in via 2>&1). The Claude Code CLI stream-json format uses
      # "assistant" events with tool_use content blocks and per-turn usage.
      local batch
      batch=$(tail -n +"$((seen + 1))" "$file" | head -n "$((total_lines - seen))" \
        | grep '^{' \
        | jq -r '
          if .type == "assistant" then
            (.message.content[]? | select(.type == "tool_use") | "tool:" + .name),
            (if (.message.usage.input_tokens // 0) > 0 then
              "in:" + ((.message.usage.input_tokens // 0) | tostring)
            else empty end),
            (if (.message.usage.output_tokens // 0) > 0 then
              "out:" + ((.message.usage.output_tokens // 0) | tostring)
            else empty end)
          else empty
          end
        ' 2>/dev/null | tr -d '\r') || true
      seen="$total_lines"

      if [[ -n "$batch" ]]; then
        local changed=false
        while IFS= read -r parsed; do
          case "$parsed" in
            tool:*)
              tool_count=$((tool_count + 1))
              last_tool="${parsed#tool:}"
              changed=true
              ;;
            in:*)
              total_in=$((total_in + ${parsed#in:}))
              changed=true
              ;;
            out:*)
              total_out=$((total_out + ${parsed#out:}))
              changed=true
              ;;
          esac
        done <<< "$batch"

        if [[ "$changed" == true ]]; then
          local now elapsed mins secs
          now=$(date +%s)
          elapsed=$((now - start_ts))
          mins=$((elapsed / 60))
          secs=$((elapsed % 60))

          local status
          status=$(printf '[%dm%02ds] Tokens: ↑%s ↓%s' "$mins" "$secs" "$total_out" "$total_in")
          if [[ -n "$last_tool" ]]; then
            status+=" | Tools: $tool_count (last: $last_tool)"
          fi
          # \r returns to start of line; %-80s pads to overwrite stale chars
          printf '\r  %-80s' "$status"
        fi
      fi
    fi

    # Exit once Claude has finished and all output has been processed
    if ! kill -0 "$pid" 2>/dev/null; then
      local final_lines
      final_lines=$(wc -l < "$file" 2>/dev/null) || final_lines=0
      final_lines=$((final_lines + 0))
      if [[ "$final_lines" -gt "$seen" ]]; then
        continue  # Process remaining lines before exiting
      fi
      break
    fi

    sleep 2
  done

  # End the in-place line so subsequent output starts on a fresh line
  echo ""
}

# Find the starting iteration number
START_ITERATION=1
if ls "$ITERATIONS_DIR"/*.json >/dev/null 2>&1; then
  LAST=$(ls "$ITERATIONS_DIR"/*.json | sort -V | tail -1 | xargs basename | sed 's/.json//')
  START_ITERATION=$((LAST + 1))
fi

PREV_DIRECTIVE_HASH=""
TOTAL_COST=0

echo ""
echo "════════════════════════════════════════════════════"
echo "  Agent Loop: $RUN_ID"
echo "  Max iterations: $MAX_ITERATIONS | Budget/iter: \$$BUDGET_PER_ITERATION | Model: $MODEL"
echo "  Working dir: $WORKING_DIR"
[[ -n "$BRANCH" ]] && echo "  Branch: $BRANCH"
echo "════════════════════════════════════════════════════"
echo ""

# Ask how often to pause for review
printf '  Pause for review every how many iterations? (1 = every iteration, 0 = never): '
read -r PAUSE_EVERY
if ! [[ "$PAUSE_EVERY" =~ ^[0-9]+$ ]]; then
  PAUSE_EVERY=1
  echo "  Invalid input, defaulting to 1."
fi
if [[ "$PAUSE_EVERY" -gt 0 ]]; then
  NEXT_PAUSE_AT=$((START_ITERATION + PAUSE_EVERY - 1))
  echo "  Will pause every $PAUSE_EVERY iteration(s)."
else
  NEXT_PAUSE_AT=0
  echo "  Running without pauses."
fi
echo ""

for i in $(seq "$START_ITERATION" "$MAX_ITERATIONS"); do
  echo "── Iteration $i ──────────────────────────────────"

  # Check if directive is stuck (same hash as previous iteration)
  CURRENT_HASH=$(md5sum "$DIRECTIVE" | cut -d' ' -f1)
  if [[ "$CURRENT_HASH" == "$PREV_DIRECTIVE_HASH" ]]; then
    echo ""
    echo "ABORT: Directive unchanged between iterations — agent may be stuck."
    echo "Check $DIRECTIVE for details."
    exit 1
  fi
  PREV_DIRECTIVE_HASH="$CURRENT_HASH"

  # Build the prompt
  PROMPT="You are iteration $i of an agent loop. Your working files are:
- Directive: $DIRECTIVE
- Learnings: $LEARNINGS

Read both files now, then do the work described in the directive's 'Current Task' section.
Before you finish, you MUST:
1. Rewrite $DIRECTIVE with updated progress and next steps
2. Append any new discoveries to $LEARNINGS under '## Iteration $i'"

  # Run Claude
  ITER_START=$(date +%s)
  echo "  Launching Claude ($MODEL)..."
  ITER_OUTPUT="$ITERATIONS_DIR/$i.json"
  : > "$ITER_OUTPUT"

  # Run Claude in background so Ctrl+C can stop just this iteration
  ITER_INTERRUPTED=false
  (cd "$WORKING_DIR" && claude -p "$PROMPT" \
    --model "$MODEL" \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep,Skill" \
    --max-budget-usd "$BUDGET_PER_ITERATION" \
    --append-system-prompt "$RULES_CONTENT" \
    --output-format stream-json \
    --verbose \
    >> "$ITER_OUTPUT" 2>&1) &
  CLAUDE_PID=$!

  # Monitor progress by polling the output file
  _show_progress "$ITER_OUTPUT" "$CLAUDE_PID" &
  PROGRESS_PID=$!

  # Ctrl+C kills the iteration, not the orchestrator
  trap 'kill $CLAUDE_PID 2>/dev/null; ITER_INTERRUPTED=true' INT
  wait $CLAUDE_PID 2>/dev/null
  CLAUDE_EXIT=$?
  trap - INT

  if [[ "$ITER_INTERRUPTED" == true ]]; then
    echo ""
    echo "  Iteration $i interrupted by user."
  elif [[ "$CLAUDE_EXIT" -eq 0 ]]; then
    echo "  Iteration $i completed."
  else
    echo "  Iteration $i exited with error (exit code $CLAUDE_EXIT)."
    echo "  Output saved to: $ITER_OUTPUT"
  fi

  # Stop progress monitor (|| true: may have already exited)
  kill $PROGRESS_PID 2>/dev/null || true
  wait $PROGRESS_PID 2>/dev/null || true

  # Compute iteration duration
  ITER_END=$(date +%s)
  ITER_ELAPSED=$((ITER_END - ITER_START))
  ITER_MINS=$((ITER_ELAPSED / 60))
  ITER_SECS=$((ITER_ELAPSED % 60))
  ITER_DURATION=$(printf '%dm%02ds' "$ITER_MINS" "$ITER_SECS")

  # Extract cost from the result event in the NDJSON stream
  ITER_COST=$(
    jq -r 'select(.type == "result") | .total_cost_usd // empty' "$ITER_OUTPUT" 2>/dev/null \
    | head -1
  )
  ITER_COST="${ITER_COST:-0}"
  TOTAL_COST=$(echo "$TOTAL_COST + $ITER_COST" | bc 2>/dev/null || echo "$TOTAL_COST")
  echo "  Duration: $ITER_DURATION | Cost: \$$ITER_COST (total: \$$TOTAL_COST)"

  # Check if done
  if grep -q "^DONE" "$DIRECTIVE" || grep -q "Status.*DONE" "$DIRECTIVE" || grep -q "## Status" "$DIRECTIVE" && grep -A1 "## Status" "$DIRECTIVE" | grep -q "DONE"; then
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "  DONE after $i iterations (total cost: \$$TOTAL_COST)"
    echo "════════════════════════════════════════════════════"
    exit 0
  fi

  # Check if blocked
  if grep -q "Status.*BLOCKED\|Status.*FAILED" "$DIRECTIVE"; then
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "  BLOCKED/FAILED after $i iterations"
    echo "  Check $DIRECTIVE for details."
    echo "════════════════════════════════════════════════════"
    exit 1
  fi

  # Pause checkpoint — also triggered when the user interrupts an iteration
  if [[ "$ITER_INTERRUPTED" == true ]] || { [[ "$NEXT_PAUSE_AT" -gt 0 ]] && [[ "$i" -ge "$NEXT_PAUSE_AT" ]]; }; then
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  Paused after iteration $i.                  "
    echo "  │  Review: $DIRECTIVE  "
    echo "  └─────────────────────────────────────────────┘"
    printf '  How many more iterations? (Enter = %d, 0 = run to completion, q = quit): ' "$PAUSE_EVERY"
    read -r USER_INPUT
    if [[ "$USER_INPUT" == "q" || "$USER_INPUT" == "quit" ]]; then
      exit 0
    fi
    if [[ -n "$USER_INPUT" ]]; then
      if [[ "$USER_INPUT" =~ ^[0-9]+$ ]]; then
        PAUSE_EVERY="$USER_INPUT"
      else
        echo "  Invalid input, keeping current interval ($PAUSE_EVERY)."
      fi
    fi
    if [[ "$PAUSE_EVERY" -gt 0 ]]; then
      NEXT_PAUSE_AT=$((i + PAUSE_EVERY))
    else
      NEXT_PAUSE_AT=0
      echo "  Pausing disabled — running to completion."
    fi
  fi

  echo ""
done

echo "════════════════════════════════════════════════════"
echo "  Reached max iterations ($MAX_ITERATIONS)."
echo "  Total cost: \$$TOTAL_COST"
echo "  Run: $RUN_DIR"
echo "════════════════════════════════════════════════════"
exit 0
