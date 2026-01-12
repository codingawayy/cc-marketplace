---
description: Index system artifacts from codebase analysis
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Index System Artifacts

Analyze the codebase and generate `.specs/artifacts.csv` - an index of system artifacts.

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
- `first-run` → Proceed to Step 2A (full indexing)
- `no-changes` → Report that artifacts are up to date and exit
- `incremental` → Proceed to Step 2B (incremental update)

For incremental updates, the script saves the result to `.specs/temp/<prev>-to-<curr>.json`.

## Discovery

### Step 2A: Full Codebase Analysis (First Run)

1. Read `.specs/overview.md` to understand the system architecture
2. Read `[pluginPath]/README.md` for artifact type definitions
3. Analyze the codebase to identify all artifacts:
   - **system** - The system itself (always exactly one)
   - **entity** - Domain objects with fields and behavior
   - **action** - Operations on entities
   - **task** - Scheduled or background jobs
   - **service** - External API dependencies
   - **app** - Application modules (web, cli, mobile, etc.)
4. Create `.specs/artifacts.csv` with columns: Type, Name, Description

Proceed to Step 3.

### Step 2B: Incremental Update

Update the existing artifact index based on changes since the last run.

1. Read `.specs/overview.md` to understand the current system
2. Read `.specs/artifacts.csv` to see the current artifact index
3. Read the stats file from `.specs/temp/<prev>-to-<curr>.json` to see:
   - List of commits since last indexing
   - List of all changed files
4. To understand what changed, use these git commands:
   - View a specific commit: `git show <hash>`
   - View accumulated diff for a file: `git diff <previousCommit>..<currentCommit> -- <file>`
5. Update `.specs/artifacts.csv` to reflect any new, modified, or removed artifacts

Proceed to Step 3.

## Finalize

### Step 3: Report Results

Report the artifact counts by type:
- Number of entities
- Number of actions
- Number of tasks
- Number of services
- Number of apps

For incremental updates, also report what changed (added, removed, modified).
