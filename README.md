# CC Marketplace

Personal Claude Code plugin marketplace.

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add codingawayy/cc-marketplace
```

## Available Plugins

| Plugin | Description | Install |
|--------|-------------|---------|
| [specs](./plugins/specs/) | Generate and browse system specification documents from codebase analysis | `/plugin install specs@cc-marketplace` |

## Repository Structure

```
cc-marketplace/
├── .claude-plugin/
│   └── marketplace.json    # Plugin registry
├── plugins/
│   └── specs/              # Specs plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── commands/       # Slash commands
│       ├── hooks/          # Event hooks
│       ├── schemas/        # YAML schemas
│       ├── scripts/        # PowerShell scripts
│       ├── site/           # Hugo site for browsing specs
│       └── README.md
├── LICENSE
└── README.md
```

## Adding New Plugins

1. Create a new directory under `plugins/`:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── commands/
   │   └── my-command.md
   └── README.md
   ```

2. Add an entry to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "my-plugin",
     "description": "What it does",
     "version": "1.0.0",
     "source": "./plugins/my-plugin",
     "category": "general",
     "tags": ["tag1", "tag2"]
   }
   ```

## License

MIT License - see [LICENSE](LICENSE)
