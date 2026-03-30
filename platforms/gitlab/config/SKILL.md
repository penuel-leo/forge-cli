---
name: glab-config
description: Configure glab CLI defaults and preferences — set editor, default remote, pager, and per-host settings. Triggers on config, configuration, defaults, preferences, settings, glab config.
---

# glab config

Set CLI defaults and preferences for the glab tool.

## Quick Start

```bash
glab config get editor                # View current editor
glab config set editor vim            # Set preferred editor
glab config list                      # List all settings
```

## Common Settings

```bash
# Set default editor
glab config set editor "code --wait"

# Set default remote
glab config set remote_alias origin

# Set preferred pager
glab config set pager "less -R"

# Set default protocol (ssh or https)
glab config set git_protocol ssh

# Disable prompts (for CI/scripts)
glab config set prompt disabled

# Per-host settings
glab config set token <pat> --host gitlab.company.com
glab config set git_protocol ssh --host gitlab.company.com
```

## Viewing Config

```bash
# List all settings
glab config list

# Get specific value
glab config get editor
glab config get git_protocol

# Per-host
glab config get token --host gitlab.company.com
```

## Config File Location

Default: `~/.config/glab-cli/config.yml`

Override with `GLAB_CONFIG_DIR` environment variable.

## Reference

| Command | Description |
|---------|-------------|
| `glab config list` | Show all configuration values |
| `glab config get <key>` | Get a config value |
| `glab config set <key> <value>` | Set a config value |
| `glab config set <key> <value> --host <host>` | Set per-host config |
