---
description: generate an agent-loop command to run a long-running autonomous task in a separate terminal
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# Agent Loop

Generate a ready-to-copy `agent-loop` command that the user can run in a separate terminal to start a long-running autonomous task.

---

## 1. Workflow

**Important:** Never invoke the orchestrator yourself — only output a command for the user to copy.

### Phase 1: Craft the prompt (stay here until the user approves)

1. **If no task was provided as an argument**, immediately ask the user:
   "What task would you like to run autonomously in a separate terminal?"
   Do NOT do anything else — just ask and wait for the response.

2. Once you have the user's initial task description, collaborate with them to craft a **specific, scoped, measurable** goal string using the best practices in section 3. This means:
   - Reading files and searching the codebase to better understand the user's task and its context
   - Asking clarifying questions about scope, constraints, and expected outcomes
   - Proposing a refined prompt and explaining why specific wording helps
   - Iterating on the prompt based on the user's feedback

3. When you have a draft prompt you're confident in, present it clearly and ask:
   "Are you happy with this prompt? If so, I'll generate the agent loop script for it."
   - **If the user says no** or wants changes — continue refining the prompt. Go back to step 2.
   - **If the user says yes** — proceed to Phase 2.

**During Phase 1, do NOT output any CLI flags, run data details, or the final command. Stay focused entirely on perfecting the prompt.**

### Phase 2: Generate the command (only after the user approves the prompt)

4. Select appropriate flags based on the task — use section 3's flag guidance and section 2's CLI reference.

5. Output the full command in a fenced code block so the user can copy it. Use the full path to the
   orchestrator script (provided in session context by the SessionStart hook) instead of just `agent-loop`:

   ```bash
   /full/path/to/scripts/orchestrator.sh "The specific goal here" --branch agent/short-name
   ```

6. Remind the user to run the command **in a separate terminal**, not in this Claude session.

7. After the command, print a summary for the user containing:
   - The full CLI flags table from section 2, so the user can see what else they can customize
   - The run data files table from section 2, so the user knows where logs and state live
   - A tip that they can monitor progress by checking `directive.md` while the loop runs

---

## 2. Reference

### CLI flags

```
agent-loop "GOAL" [OPTIONS]
```

| Flag                       | Default     | Description                                            |
| -------------------------- | ----------- | ------------------------------------------------------ |
| `--max-iterations N`       | 50          | Maximum number of iterations before stopping           |
| `--budget-per-iteration N` | 5           | Maximum USD to spend per iteration                     |
| `--model MODEL`            | sonnet      | Claude model (`sonnet`, `opus`, `haiku`)               |
| `--working-dir DIR`        | current dir | Directory where Claude runs                            |
| `--branch BRANCH`          | none        | Create a git worktree on this branch for isolated work |
| `--run-id ID`              | none        | Resume a previous run                                  |

### Run data

All run data is stored in `.agent-loop/{run-id}/` inside the working directory.

| File           | Purpose                                                        |
| -------------- | -------------------------------------------------------------- |
| `config.json`  | Run configuration (goal, flags, working dir)                   |
| `directive.md` | Current goal, status, progress, and next task                  |
| `learnings.md` | Accumulated discoveries across iterations                      |
| `iterations/`  | JSON output from each Claude session (`1.json`, `2.json`, ...) |

---

## 3. Best practices

### Goal writing

Good goals are **specific**, **scoped**, and **measurable**.

| Quality    | Bad                    | Good                                                       |
| ---------- | ---------------------- | ---------------------------------------------------------- |
| Specific   | "fix stuff"            | "Fix all CS0618 build warnings in UNWB.Business"           |
| Scoped     | "refactor everything"  | "Convert string concatenation to interpolation in Domain/" |
| Measurable | "improve code quality" | "Add null checks to all public methods in Services/"       |

For large tasks, include constraints in the goal to prevent any single iteration from doing too much:
- "Fix all build warnings in UNWB.Business. Process ONE folder per iteration."
- "Add XML documentation to all public methods in Domain/Entities/. Do at most 5 files per iteration."

### Flag selection

**Model:**
- `sonnet` (default) — good balance of speed, cost, and capability
- `opus` — complex reasoning, architectural decisions, tricky refactoring
- `haiku` — simple repetitive tasks (renaming, formatting, search-replace)

**Branch:** Always suggest `--branch agent/{short-description}` when the task modifies code. This creates a git worktree so the main working directory stays untouched.

**Pause:** The orchestrator asks how often to pause when it starts. Suggest `1` for first-time users or unfamiliar tasks. The interval can be changed at each pause.
