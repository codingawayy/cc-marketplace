---
description: Start Hugo dev server to browse specs as website
allowed-tools: Bash, Read
---

# Serve Specifications

Start a local Hugo server to browse the generated specifications as a website.

## Instructions

1. Read `~/.claude/plugins/cache/settings.json` and get the `pluginPath` from the `cc-specs-plugin` entry.

2. If the file or entry is missing, tell the user: "Plugin not initialized. Please restart Claude Code to trigger plugin initialization."

3. Run the serve script using PowerShell with the full path:
   ```
   powershell.exe -NoProfile -File "<pluginPath>/scripts/serve.ps1"
   ```

4. Run the command in the background so the user can continue working while the server runs.

The script will:
- Check if Hugo is installed (provide install instructions if not)
- Convert YAML specs from `docs.specs/` to Hugo content
- Start a dev server at http://localhost:1313

The server runs until stopped.

## Requirements

- Hugo must be installed (script will guide installation if missing)
- Specs must be generated first using `/specs:generate`
