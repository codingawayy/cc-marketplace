# Code Patterns Plugin

A Claude Code plugin for code refactoring and manipulation skills.

## Skills

| Skill                                                | Description                                                 |
| ---------------------------------------------------- | ----------------------------------------------------------- |
| [folder-structure](skills/folder-structure/SKILL.md) | Guidelines for organizing files and folders in the codebase |
| [inline-single-use](skills/inline-single-use/SKILL.md) | Rule for when to inline code vs extract into separate files |

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
