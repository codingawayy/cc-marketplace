# Agent Loop Rules

You are one iteration of an agent loop. Multiple Claude Code sessions run sequentially,
each picking up where the last one left off. Follow these rules exactly.

## On Start

1. Read the `directive.md` file to understand your goal, current progress, and what to do next.
2. Read the `learnings.md` file to benefit from discoveries made by previous iterations.

## While Working

3. Do the work described in the "Current Task" section of `directive.md`.
4. After each meaningful batch of changes, build/test to verify no regressions, then commit with a descriptive message.
5. If you discover something useful for future iterations (a gotcha, a pattern, a failed approach, an environment detail), note it so you can add it to learnings later.

## Before Exiting

6. **If every task in the Goal has been completed and verified**, update `run.json` to set status to `"done"`:
   ```json
   {"status":"done"}
   ```
   Do not invent follow-up tasks, improvements, or nice-to-haves beyond the original goal.
7. **Rewrite `directive.md`** (do not append — replace the entire file) with:
    - The same Goal section (unchanged)
    - Updated Status: `IN_PROGRESS` or `DONE`
    - Updated Progress checklist using `- [x]` for completed items and `- [ ]` for remaining items
    - Current Task:
      - If done: write "All tasks complete — no further action needed."
      - Otherwise: describe what the next iteration should do.
    - Updated Iteration History table with a row for what you accomplished
8. **Append to `learnings.md`** any new discoveries under a heading `## Iteration N` (use the iteration number from your prompt). Only add genuinely useful information — not trivial observations.
9. If `learnings.md` exceeds approximately 100 lines, consolidate older iteration entries into a `## Summary` section at the top, keeping only the most important points. Remove redundant or superseded details from older entries.

## Important

- Do NOT create or switch branches — work on whatever branch is already checked out.
- Do NOT push to remote — only commit locally.
- Keep your commits small and focused. Commit after each logical unit of work.
- If a previous iteration's approach failed (noted in learnings), try a different approach.
- When all Progress items are checked (`[x]`), you MUST update `run.json` to `"done"`. Do not add new unchecked items to justify continuing.
