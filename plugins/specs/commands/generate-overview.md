---
description: Generate system overview from codebase analysis
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Generate System Overview

Analyze the codebase and generate `.specs/overview.md` - a semantic map of the system architecture.

## Setup

### Step 0: Get Plugin Path

Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

## Discovery

### Step 1: Check Current State

Run the stats script to determine the current state:

```bash
pwsh -File "[pluginPath]/scripts/get-changes.ps1" -For overview
```

The script returns a JSON object with a `type` field. Based on `type`:
- `first-run` → Proceed to Step 2A
- `no-changes` → Report that overview is up to date and exit
- `incremental` → Proceed to Step 2B

For incremental updates, the script also saves the result to `.specs/temp/<prev>-to-<curr>.json`.

### Step 2A: Full Codebase Analysis (First Run)

Explore the entire codebase to understand its architecture. Use your own judgment to identify important files and patterns.

1. Explore the codebase structure
2. Identify key components, patterns, and conventions
3. Create `.specs/overview.md` with the structure below

Proceed to Step 3.

### Step 2B: Incremental Update

Update the existing overview based on changes since the last run.

1. Read `.specs/overview.md` to understand the current system
2. Read the stats file from `.specs/temp/<prev>-to-<curr>.json` to see:
   - List of commits since last overview
   - List of all changed files
3. To understand what changed, use these git commands:
   - View a specific commit: `git show <hash>`
   - View accumulated diff for a file: `git diff <previousCommit>..<currentCommit> -- <file>`
   - View full accumulated diff: `git diff <previousCommit>..<currentCommit>`
4. Update `.specs/overview.md` to reflect the changes

Proceed to Step 3.

## Overview Structure

The overview should contain:

- **System Overview** - Brief description of what the system does
- **Architecture** - High-level architecture (monolith, microservices, SvelteKit, Express, etc.)
- **Apps** - List of application modules with descriptions and paths
- **Folder Structure** - Key folders and what they contain
- **Where to Find Things** - Location patterns and file paths for each concept type:
  - Domain Entities
  - Actions
  - External Services
  - Tasks
- **Key Patterns** - Naming conventions, frameworks, and patterns observed in the codebase

## Finalize

### Step 3: Record Commit and Report

Update `.specs/config.json` with the current commit hash as `overviewCommit`.

**For first run:**
- Get the commit hash using `git rev-parse HEAD`
- Report that the overview was created from scratch

**For incremental updates:**
- Use the `currentCommit` from the JSON file saved in Step 1 (`.specs/temp/<prev>-to-<curr>.json`)
- Report the number of commits and files that were analyzed
