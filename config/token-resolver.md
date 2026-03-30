# Token Resolution

This skill resolves authentication tokens from environment variables in a hierarchical order, supporting multiple Git hosting platforms. Each platform uses its own env var prefix.

## Platform Detection

The resolver first detects the platform from `git remote get-url origin`:

| URL Pattern | Platform | Token Prefix |
|-------------|----------|-------------|
| `*github.com*` | GitHub | `GITHUB_TOKEN` |
| `*gitlab.com*` or `*gitlab.*` | GitLab | `GITLAB_TOKEN` |
| Custom (`GITLAB_HOST`) | GitLab | `GITLAB_TOKEN` |
| Custom (`GITHUB_HOST`) | GitHub | `GITHUB_TOKEN` |

## Resolution Order

### GitLab

```
GITLAB_TOKEN_<PROJECT>      →  project-specific (highest priority)
GITLAB_TOKEN_<WORKSPACE>    →  workspace/group level
GITLAB_TOKEN_<HOST>         →  per-instance (self-hosted)
GITLAB_TOKEN                →  global default
glab config get token       →  glab CLI stored credential (lowest priority)
```

### GitHub

```
GITHUB_TOKEN_<PROJECT>      →  project-specific (highest priority)
GITHUB_TOKEN_<WORKSPACE>    →  organization level
GITHUB_TOKEN                →  global default
gh auth token               →  gh CLI stored credential (lowest priority)
```

## Naming Convention

Environment variable suffixes are derived from the project/workspace/host name:

1. Convert to uppercase
2. Replace hyphens (`-`) and dots (`.`) with underscores (`_`)
3. Remove any non-alphanumeric characters (except `_`)

### Examples

| Context | GitLab Env Var | GitHub Env Var |
|---------|---------------|---------------|
| Project `my-app` | `GITLAB_TOKEN_MY_APP` | `GITHUB_TOKEN_MY_APP` |
| Project `ragflow` | `GITLAB_TOKEN_RAGFLOW` | `GITHUB_TOKEN_RAGFLOW` |
| Workspace `infiniflow` | `GITLAB_TOKEN_INFINIFLOW` | `GITHUB_TOKEN_INFINIFLOW` |
| Host `gitlab.company.com` | `GITLAB_TOKEN_GITLAB_COMPANY_COM` | N/A |

## Configuration

```bash
# GitLab — global default
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"

# GitLab — project-specific
export GITLAB_TOKEN_RAGFLOW="glpat-yyyyyyyyyyyyyyyyyyyy"

# GitLab — self-hosted instance
export GITLAB_HOST="https://gitlab.company.com"
export GITLAB_TOKEN_GITLAB_COMPANY_COM="glpat-zzzzzzzzzzzzzzzzzzzz"

# GitHub — global default
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# GitHub — org-specific
export GITHUB_TOKEN_MY_ORG="ghp_yyyyyyyyyyyyyyyyyyyy"
```

## How It Works

When a command runs, `scripts/resolve-token.sh`:

1. Extracts the **host**, **namespace**, and **project** from `git remote get-url origin`
2. Detects the platform from the host (or `GITLAB_HOST`/`GITHUB_HOST`)
3. Checks `<PREFIX>_TOKEN_<PROJECT>`
4. If not found, checks `<PREFIX>_TOKEN_<WORKSPACE>` (top-level namespace)
5. For GitLab: checks `<PREFIX>_TOKEN_<HOST>` (derived from host)
6. Falls back to `<PREFIX>_TOKEN` (global)
7. Last resort: queries the platform CLI for stored credentials

## Security Notes

- Tokens are never printed or logged by the resolver
- The resolver validates that tokens are non-empty and have a minimum length
- Only HTTPS hosts are accepted — HTTP is rejected to prevent token leakage over plaintext
