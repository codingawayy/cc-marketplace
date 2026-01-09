---
description: commits all staged and unstaged changes to the current git branch
allowed-tools: [Read, Bash, TodoWrite]
---

# Git Commit

Commit all staged and unstaged changes using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Instructions

1. Stage all changes (unless explicitly asked to do otherwise):
   ```bash
   git add -A
   ```

2. Check what will be committed:
   ```bash
   git status
   git diff --cached
   ```

3. Review recent commit messages to match the project's style:
   ```bash
   git log --oneline -5
   ```

4. Analyze the changes and create a commit message following the Conventional Commits specification:

   **Format:**
   ```
   <type>[optional scope]: <description>

   [optional body]

   [optional footer(s)]
   ```

   **Types:**
   - `feat` - New feature (MINOR version bump)
   - `fix` - Bug fix (PATCH version bump)
   - `docs` - Documentation only
   - `style` - Formatting, whitespace (no code change)
   - `refactor` - Code restructuring (no behavior change)
   - `perf` - Performance improvement
   - `test` - Adding/updating tests
   - `build` - Build system or dependencies
   - `ci` - CI configuration
   - `chore` - Maintenance tasks

   **Breaking Changes:**
   - Append exclamation mark after type/scope, e.g. `feat!: description` or `feat(api)!: description`
   - Or add footer with `BREAKING CHANGE: description`

5. Commit (do NOT include "Generated with Claude Code" or Co-Authored-By footers):
   ```bash
   git commit -m "type: short description"
   ```

6. Report the commit hash when done.

## Notes

- If there are no changes to commit, inform the user
- Do not push to remote unless explicitly asked
- Keep the description concise and in imperative mood ("add feature" not "added feature")
