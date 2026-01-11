---
description: Generate system specification documents from codebase analysis
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Generate Specifications

Generate system specification YAML files by analyzing the codebase.

## Setup

### Step 0: Get Plugin Path

Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

## Discovery Phase

### Step 1: Build File Index

Run the build-index script to create the file index:

```bash
pwsh -File "[pluginPath]/scripts/build-index.ps1"
```

This creates `.specs/index.csv` containing all repository files (excluding patterns from `.specs/config.json` and `.gitignore`).

### Step 2: Analyze Codebase

Read `.specs/index.csv` to get the list of files to analyze. Use TodoWrite to track discovered items by category.

For each file in the index, analyze the code to discover:
- Entities (domain objects)
- Actions (operations on entities)
- Tasks (scheduled/background jobs)
- Services (external API integrations)
- Apps (application modules)

## Generation Phase

### Step 3: Read Schemas and Documentation

Read the plugin folder (from `pluginPath`), specifically these files:
- `README.md` - Documentation, examples, and conventions
- `schemas/*` - Schema definitions for each spec type

### Step 4: Generate Spec Files

For each discovered item, generate a YAML spec file following the schemas. Write all output to `docs.specs/` with `.yaml` extension.

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

### Step 5: Summary

Run the summarize script to get statistics:

```bash
pwsh -File "[pluginPath]/scripts/summarize.ps1"
```

Report the results to the user.
