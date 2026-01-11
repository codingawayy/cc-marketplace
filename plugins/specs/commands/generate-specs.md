---
description: Generate spec files from system overview
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Generate Spec Files

Generate YAML specification files using the system overview as a guide.

**Prerequisite:** Run `/specs:generate-overview` first to create `.specs/overview.md`.

## Setup

### Step 0: Get Plugin Path

Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

### Step 1: Check Current State

Run the stats script to determine the current state:

```bash
pwsh -File "[pluginPath]/scripts/get-changes.ps1" -For specs
```

The script returns a JSON object with a `type` field. Based on `type`:
- `first-run` → Proceed to Step 2 (full generation)
- `no-changes` → Report that specs are up to date and exit
- `incremental` → Proceed to Step 2 (incremental generation)

For incremental updates, the script saves the result to `.specs/temp/<prev>-to-<curr>.json`.

### Step 2: Read Overview

Read `.specs/overview.md` to understand the system architecture.

### Step 3: Read Schemas and Documentation

Read the plugin folder (from `pluginPath`), specifically these files:
- `README.md` - Documentation, examples, and conventions
- `schemas/*` - Schema definitions for each spec type

## Generation

### Step 4: Create or Resume Plan

Check if a plan already exists in `.specs/temp/plans/`:
- First run: `full-<commit>.md`
- Incremental: `<prev>-to-<curr>.md`

**If plan exists:** Read it and continue from where it left off (some items may already be checked).

**If plan does not exist:** Use the `plan-and-do` skill to create a new plan with:
- **Objective**: Generate/update YAML spec files from codebase
- **Approach**: List phases (e.g., System → Entities → Actions → Tasks → Services → Apps)
- **Detailed Plan**: Checkbox items for each spec to generate, organized by phase
- **Notes**: Any relevant context from the overview or changes file
- **Changelog**: Initial entry

For incremental updates, read `.specs/temp/<prev>-to-<curr>.json` to identify which specs need updating based on changed files.

### Step 5: Generate Spec Files

Execute the plan following the `plan-and-do` skill guidelines:
1. Re-read the plan before starting
2. For each item, read relevant source files and generate the YAML spec
3. Mark items complete (`[x]`) immediately after generating each spec
4. Update the plan if you discover additional specs needed or changes in scope

Write all output to `docs.specs/` with `.yaml` extension.

Rules:
- Only include fields defined in the schema
- Omit optional fields if not applicable

Output structure:
```
docs.specs/
├── system.yaml
├── domain/
│   └── [entity]/
│       ├── [entity].yaml
│       └── actions/
│           └── [action].yaml
├── tasks/
│   └── [task].yaml
├── external-services/
│   └── [service].yaml
└── apps/
    └── [app]/
        └── [app].yaml
```

### Step 6: Validate

Run the validation script to check the generated specs against schemas:

```bash
node "[pluginPath]/validator/validate.js"
```

If validation errors are found, fix them before proceeding.

### Step 7: Record Commit and Summary

Update `.specs/config.json` with the current commit hash as `specsCommit`.

**For first run:**
- Get the commit hash using `git rev-parse HEAD`

**For incremental updates:**
- Use the `currentCommit` from the JSON file saved in Step 1

Run the summarize script to get statistics:

```bash
pwsh -File "[pluginPath]/scripts/summarize.ps1"
```

Report the results to the user.
