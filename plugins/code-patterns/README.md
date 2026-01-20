# Code Patterns Plugin

A Claude Code plugin for code refactoring and manipulation commands.

## Commands

| Command | Description |
|---------|-------------|
| `/code-patterns:folder-structure` | Guidelines for organizing files and folders in the codebase |
| `/code-patterns:inline-single-use` | Rule for when to inline code vs extract into separate files |

## Overview

This plugin provides various code refactoring and manipulation capabilities to help improve code quality, maintainability, and consistency.

## Installation

Add this plugin to your Claude Code configuration:

```json
{
  "plugins": [
    {
      "name": "code-patterns",
      "source": "https://github.com/codingawayy/cc-marketplace",
      "path": "plugins/code-patterns"
    }
  ]
}
```
