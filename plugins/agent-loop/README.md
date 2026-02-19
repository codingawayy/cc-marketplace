# Agent Loop Plugin

A Claude Code plugin that helps you set up long-running autonomous tasks using a bash orchestrator. The orchestrator runs Claude Code sessions in a loop, passing state between iterations via files on disk. Each iteration gets a fresh context window, so the loop can run for hours without context exhaustion.

## Setup

The orchestrator script needs to be on your PATH. After installing the plugin, create a symlink or alias:

```bash
# Option 1: Symlink (Linux/macOS)
ln -s "$(claude plugin path agent-loop)/scripts/orchestrator.sh" ~/.local/bin/agent-loop

# Option 2: Alias in your shell profile
alias agent-loop='/path/to/plugins/agent-loop/scripts/orchestrator.sh'
```

## Commands

### `/agent-loop:run`

Generates a ready-to-copy `agent-loop` command to run in a separate terminal.
