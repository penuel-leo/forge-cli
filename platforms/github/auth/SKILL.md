---
name: gh-auth
description: Manage GitHub CLI authentication — login, logout, check status, switch between accounts, and configure tokens. Triggers on auth, login, logout, authentication, credentials, token, GitHub auth.
---

# gh auth

Manage GitHub CLI authentication.

## Quick Start

```bash
gh auth login                            # Interactive login
gh auth login --hostname github.company.com  # GitHub Enterprise
gh auth status                           # Check auth status
gh auth logout                           # Log out
```

## Workflows

### First-time Setup

```bash
# Interactive — choose browser or token auth
gh auth login

# Token-based (non-interactive)
echo "ghp_token" | gh auth login --with-token

# Verify
gh auth status
```

### GitHub Enterprise

```bash
gh auth login --hostname github.company.com

# Or set environment variable
export GH_HOST="github.company.com"
```

### Multiple Accounts

```bash
# Login to github.com
gh auth login

# Login to enterprise
gh auth login --hostname github.company.com

# Check all
gh auth status

# Switch active account
gh auth switch
```

For project-level token overrides, see [token-resolver.md](../../../config/token-resolver.md).

### Token Management

```bash
# View current token
gh auth token

# Refresh token with new scopes
gh auth refresh --scopes repo,read:org

# Set up token from env var
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
gh auth status
```

## Troubleshooting

**401 Unauthorized:**
- Verify: `gh auth status`
- Re-authenticate: `gh auth login`
- Check token scopes: Settings → Developer settings → Personal access tokens

**Wrong account:**
- Switch: `gh auth switch`
- Check: `gh auth status`

## Reference

| Command | Description |
|---------|-------------|
| `gh auth login` | Authenticate with GitHub (interactive) |
| `gh auth login --hostname <host>` | Authenticate with Enterprise instance |
| `gh auth login --with-token` | Authenticate with token from stdin |
| `gh auth logout` | Log out |
| `gh auth status` | Show auth status for all accounts |
| `gh auth token` | Print current auth token |
| `gh auth refresh [--scopes]` | Refresh token with new scopes |
| `gh auth switch` | Switch between authenticated accounts |
| `gh auth setup-git` | Configure git to use gh as credential helper |
