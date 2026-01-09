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
| [specs](https://github.com/codingawayy/cc-specs-plugin) | Generate and browse system specification documents from codebase analysis | `/plugin install specs@cc-marketplace` |

## Adding New Plugins

Edit `.claude-plugin/marketplace.json` to add plugin entries:

**For external repos:**
```json
{
  "name": "my-plugin",
  "description": "What it does",
  "version": "1.0.0",
  "source": {
    "source": "url",
    "url": "https://github.com/user/my-plugin.git"
  },
  "category": "general",
  "tags": ["tag1", "tag2"]
}
```

**For local plugins:**
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
