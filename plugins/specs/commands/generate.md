---
description: Generate system specification documents from codebase analysis
allowed-tools: Read, Write, Glob, Grep, TodoWrite, Bash
---

# Generate Specifications

Generate system specification YAML files by analyzing the codebase.

## Step 0: Get Plugin Path

1. Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

2. If the file or entry is missing, tell the user: "Plugin not initialized. Please restart Claude Code to trigger plugin initialization."

## Step 1: Read Schemas and Documentation

Read the plugin folder (from `pluginPath`) to understand:
- `README.md` - Documentation, examples, and conventions
- `schemas/` - Schema definitions for each spec type

## Step 2: Discovery Phase

Explore the codebase to discover what exists. Use TodoWrite to track discovered items by category.

### Exclusions

DO NOT analyze:
- `docs.specs/`
- `.claude/`, `.git/`, `.github/`, `.rider/`, `.idea/`, `.vscode/`
- `node_modules/`, `dist/`, `build/`, `.svelte-kit/`
- Paths matching patterns in `.gitignore`

## Step 3: Generate Documentation

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

## Step 4: Summary

Report items documented by category and any items needing manual review.
