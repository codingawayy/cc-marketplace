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

### Step 1: Read Schemas and Documentation

Read the plugin folder (from `pluginPath`), specifically these files:
- `README.md` - Documentation, examples, and conventions
- `schemas/*` - Schema definitions for each spec type

## Generation

### Step 2: Extract Specs

Read `.specs/overview.md` to guide extraction. Use TodoWrite to track discovered items by category.

For each concept type:
1. Go to the locations specified in the overview
2. Read the relevant files
3. Extract detailed information for specs:
   - Entities (domain objects with fields, types, enums)
   - Actions (operations on entities with authorization)
   - Tasks (scheduled/background jobs)
   - Services (external API integrations)
   - Apps (application modules)

### Step 3: Generate Spec Files

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

### Step 4: Summary

Run the summarize script to get statistics:

```bash
pwsh -File "[pluginPath]/scripts/summarize.ps1"
```

Report the results to the user.
