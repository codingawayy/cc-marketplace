# Tips for Writing Goals

## Goal writing

Good goals are **specific**, **scoped**, and **measurable**.

| Quality    | Bad                    | Good                                                       |
| ---------- | ---------------------- | ---------------------------------------------------------- |
| Specific   | "fix stuff"            | "Fix all CS0618 build warnings in UNWB.Business"           |
| Scoped     | "refactor everything"  | "Convert string concatenation to interpolation in Domain/" |
| Measurable | "improve code quality" | "Add null checks to all public methods in Services/"       |

## Constraining iteration scope

For large tasks, include constraints in the goal to prevent any single iteration from trying
to do everything at once and running out of context:

```
"Fix all build warnings in UNWB.Business. Process ONE folder per iteration."
```

```
"Add XML documentation to all public methods in Domain/Entities/. Do at most 5 files per iteration."
```

## When to suggest each model

| Model    | Use when...                                                    |
| -------- | -------------------------------------------------------------- |
| `sonnet` | Default. Good balance of speed, cost, and capability           |
| `opus`   | Complex reasoning, architectural decisions, tricky refactoring |
| `haiku`  | Simple repetitive tasks (renaming, formatting, search-replace) |

## When to suggest `--branch`

Always suggest `--branch` when the task modifies code. This creates a git worktree so:

- The user's main working directory stays untouched
- Changes can be reviewed on a PR before merging
- Multiple agent loops can run on different branches in parallel

Branch naming convention: `agent/{short-description}` (e.g., `agent/fix-warnings`).

## When to suggest `--pause-every`

- `--pause-every 1` -- for first-time use or when the user wants to watch closely
- `--pause-every 3` to `5` -- for trusted tasks where periodic review is sufficient
- `--pause-every 0` (default) -- fully autonomous, only stops when done or stuck
