#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Convert to Windows path if running on Windows (Git Bash returns /c/... style paths)
if command -v cygpath >/dev/null 2>&1; then
  SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi

echo "The agent-loop orchestrator script is at: $SCRIPT_DIR/orchestrator.sh"
