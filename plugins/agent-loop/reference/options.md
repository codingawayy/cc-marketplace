# CLI Options

## Usage

```
agent-loop "GOAL" [OPTIONS]
```

## Options

| Flag                       | Default     | Description                                              |
| -------------------------- | ----------- | -------------------------------------------------------- |
| `--max-iterations N`       | 50          | Maximum number of iterations before stopping             |
| `--budget-per-iteration N` | 5           | Maximum USD to spend per iteration                       |
| `--model MODEL`            | sonnet      | Claude model (`sonnet`, `opus`, `haiku`)                 |
| `--pause-every N`          | 0           | Pause for human review every N iterations (0 = never)    |
| `--working-dir DIR`        | current dir | Directory where Claude runs (picks up CLAUDE.md, skills) |
| `--branch BRANCH`          | none        | Create a git worktree on this branch for isolated work   |
| `--run-id ID`              | none        | Resume a previous run                                    |

## Examples

### Basic autonomous run

```bash
agent-loop "Refactor all string concatenation to interpolation in src/"
```

### Step-by-step with human review

```bash
agent-loop "Add input validation to all API endpoints" --pause-every 1
```

### Working on a separate branch (recommended for code changes)

```bash
agent-loop "Fix all build warnings" --branch agent/fix-warnings
```

Creates a git worktree at `../{repo}--agent-fix-warnings/` so the main working directory stays untouched.

### Targeting a different project

```bash
agent-loop "Update all dependencies" --working-dir ~/Projects/other-repo
```

### Combining options

```bash
agent-loop "Add unit tests for all public methods" \
  --branch agent/add-tests \
  --model opus \
  --max-iterations 30 \
  --budget-per-iteration 10 \
  --pause-every 5
```

### Resuming a previous run

```bash
# List available runs (from the project's working directory)
ls .agent-loop/

# Resume by run ID
agent-loop --run-id "2026.02.19-fix-all-build-warnings"
```

When resuming, `--working-dir` and `--branch` are loaded from the saved config.
Other flags like `--max-iterations` or `--pause-every` can be overridden.

### Run data location

All run data is stored in the working directory under `.agent-loop/{run-id}/`:

```
.agent-loop/
└── 2026.02.19-fix-all-build-warnings/
    ├── config.json       # Run configuration
    ├── directive.md      # Current goal, status, and next task
    ├── learnings.md      # Accumulated discoveries across iterations
    └── iterations/       # JSON output from each Claude session
        ├── 1.json
        ├── 2.json
        └── ...
```
