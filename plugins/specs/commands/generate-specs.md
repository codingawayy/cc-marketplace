---
description: Generate spec files from system overview
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Generate Spec Files

Generate YAML specification files using the system overview as a guide.

**Prerequisites:**
- Run `/specs:generate-overview` first to create `.specs/overview.md`
- Run `/specs:index-artifacts` to create `.specs/artifacts.csv`

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

### Step 2: Read Overview and Artifacts

Read `.specs/overview.md` to understand the system architecture.

Read `.specs/artifacts.csv` to get the list of artifacts to generate specs for.

### Step 3: Read Schemas and Documentation

Read the plugin folder (from `pluginPath`), specifically these files:
- `README.md` - Documentation, examples, and conventions
- `schemas/*` - Schema definitions for each spec type

## Generation

### Step 4: Create Plan

Check if a plan already exists in `.specs/temp/plans/`:
- First run: `full-<commit>.md`
- Incremental: `<prev>-to-<curr>.md`

**If plan exists:** Read it and continue from where it left off (some items may already be checked).

**If plan does not exist:** Read `[pluginPath]/templates/generate-specs-plan.md` and follow its instructions to create a new plan. Replace all `{{placeholder}}` values with actual paths and names.

### Step 5: Generate Spec Files

Execute the plan following the `plan-and-do` skill guidelines.

**Critical: Update the plan after EACH item.** For each item in the plan:

1. **Check if the spec already exists** - Read the file path to see if it's already been generated
2. **If it exists and is valid**, mark it complete with a note: `[x] Generate system.yaml (exists, valid)`
3. **If it doesn't exist**, generate it, then mark complete: `[x] Generate system.yaml (created)`
4. **If it exists but needs fixes**, update it, then mark complete: `[x] Generate system.yaml (updated)`

Update the plan file after completing each item or small batch of related items - do not wait until the end. This ensures progress is tracked even if the session is interrupted.

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
