---
description: Validate specification files against schemas
allowed-tools: Bash, Read, TodoWrite
---

# Validate Specifications

Validate YAML spec files in `docs.specs/` against their JSON schemas.

## Step 0: Get Plugin Path

Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

## Step 1: Check Dependencies

Check if `node_modules` exists in the plugin's `validator/` directory. If not, run:

```
npm install --prefix "<pluginPath>/validator"
```

## Step 2: Run Validation Script

Run the Node.js validation script:

```
node "<pluginPath>/validator/validate.js" --specs "docs.specs" --schemas "<pluginPath>/schemas"
```

The script outputs JSON with validation results in this format:

```json
{
  "summary": { "total": 10, "valid": 8, "invalid": 2 },
  "results": [
    { "file": "domain/event/event.yaml", "schema": "entity", "valid": true },
    { "file": "system.yaml", "schema": "system", "valid": false,
      "errors": [{ "path": "/users/0", "message": "must have required property 'name'" }] }
  ]
}
```

## Step 3: Report Results

Parse the JSON output and report results in a user-friendly format:

### If all specs are valid:

Report the total count and list each file with a checkmark.

### If there are errors:

For each invalid spec:
1. Show the file path
2. List each error with its path and message
3. Suggest how to fix common errors

Group errors by file for readability.

### Summary

End with a summary line: "X of Y specs passed validation"
