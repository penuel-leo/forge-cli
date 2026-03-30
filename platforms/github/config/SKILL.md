---
name: gh-config
description: Configure gh CLI defaults and preferences — set editor, browser, pager, and per-host settings. Triggers on config, configuration, defaults, preferences, settings, gh config.
---

# gh config

Set CLI defaults and preferences for the gh tool.

## Quick Start

```bash
gh config get editor                     # View current editor
gh config set editor vim                 # Set preferred editor
gh config list                           # List all settings
```

## Common Settings

```bash
# Set default editor
gh config set editor "code --wait"

# Set preferred browser
gh config set browser "firefox"

# Set preferred pager
gh config set pager "less -R"

# Set default protocol (ssh or https)
gh config set git_protocol ssh

# Disable interactive prompts
gh config set prompt disabled

# Per-host settings
gh config set git_protocol ssh --host github.company.com
```

## Viewing Config

```bash
gh config list
gh config get editor
gh config get git_protocol
```

## Config File Location

Default: `~/.config/gh/config.yml`

Override with `GH_CONFIG_DIR` environment variable.

## Reference

| Command | Description |
|---------|-------------|
| `gh config list` | Show all configuration values |
| `gh config get <key>` | Get a config value |
| `gh config set <key> <value>` | Set a config value |
| `gh config set <key> <value> --host <host>` | Set per-host config |
