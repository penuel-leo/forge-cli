---
name: glab-auth
description: Manage GitLab CLI authentication — login, logout, check status, switch between accounts or self-hosted instances, and configure Docker registry access. Triggers on auth, login, logout, authentication, credentials, token, Docker registry, self-hosted.
---

# glab auth

Manage GitLab CLI authentication and instance configuration.

## Quick Start

```bash
glab auth login                              # Interactive login
glab auth login --hostname gitlab.company.com # Self-hosted instance
glab auth status                              # Check auth status
glab auth logout                              # Log out
```

## Workflows

### First-time Setup

```bash
# Interactive — choose token or browser auth
glab auth login

# Verify
glab auth status
```

### Self-hosted GitLab

```bash
# Login to company GitLab
glab auth login --hostname gitlab.company.com

# Or set environment variable (applies to all commands)
export GITLAB_HOST="https://gitlab.company.com"
```

### Multiple Accounts

Each GitLab instance stores credentials independently:

```bash
# Login to gitlab.com
glab auth login

# Login to company instance
glab auth login --hostname gitlab.company.com

# Check all authenticated instances
glab auth status
```

For project-level token overrides, see [token-resolver.md](../../../config/token-resolver.md).

### Docker Registry

```bash
# Configure Docker credential helper for GitLab registry
glab auth configure-docker

# Verify Docker auth
docker login registry.gitlab.com

# Pull private images
docker pull registry.gitlab.com/group/project/image:tag
```

## Troubleshooting

**401 Unauthorized:**
- Verify: `glab auth status`
- Token may have expired — re-authenticate: `glab auth login`
- Check token scopes in GitLab settings (needs `api` scope)

**Wrong instance:**
- Specify instance: `glab auth login --hostname correct-host.com`
- Check current: `glab auth status`

**Docker registry fails:**
- Re-run: `glab auth configure-docker`
- Inspect: `cat ~/.docker/config.json`

## Reference

| Command | Description |
|---------|-------------|
| `glab auth login` | Authenticate with GitLab (interactive) |
| `glab auth login --hostname <host>` | Authenticate with specific instance |
| `glab auth login --token <pat>` | Authenticate with a token directly |
| `glab auth logout` | Log out of current instance |
| `glab auth logout --hostname <host>` | Log out of specific instance |
| `glab auth status` | Show authentication status for all instances |
| `glab auth configure-docker` | Set up Docker credential helper |
