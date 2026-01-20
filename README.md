# CC Marketplace

This repository is a Claude Code **plugin marketplace**. These plugins are part of my own dev workflow that I use across different projects.

## Available Plugins

| Plugin                                    | Description                                        | Scope           |
| ----------------------------------------- | -------------------------------------------------- | --------------- |
| [git](./plugins/git/)                     | Streamlined git workflows                          | User or Project |
| [specs](./plugins/specs/)                 | Generate and browse system specification documents | Project only    |
| [code-patterns](./plugins/code-patterns/) | Code refactoring and manipulation skills           | User or Project |

Plugins with hooks can only be installed at the project level for security reasons, as hooks run automatically without user invocation.

## Usage

Add this marketplace to Claude Code:
```
/plugin marketplace add codingawayy/cc-marketplace
```

Install a plugin:
```
/plugin install <plugin-name>@cc-marketplace
```

After installing, plugin commands become available. Use `/help` to see all available commands.

Uninstall a plugin:
```
/plugin uninstall <plugin-name>
```

Remove this marketplace:
```
/plugin marketplace remove cc-marketplace
```

## License

MIT License - see [LICENSE](LICENSE)