# Token Resolution

This skill resolves authentication tokens from multiple sources in a strict priority order, supporting both GitLab and GitHub platforms. Designed for BYOK (Bring Your Own Key) scenarios where tokens can be provided explicitly, or resolved automatically from environment and CLI credentials.

## Resolution Order (Highest → Lowest)

```
1. --token <pat>                    Explicit argument (highest priority)
2. FORGE_TOKEN                      Universal env var override
3. GITLAB_TOKEN_<PROJECT>           Project-specific (GitLab)
   GITHUB_TOKEN_<PROJECT>           Project-specific (GitHub)
4. GITLAB_TOKEN_<WORKSPACE>         Workspace/group-level (GitLab)
   GITHUB_TOKEN_<WORKSPACE>         Organization-level (GitHub)
5. GITLAB_TOKEN_<HOST>              Per-instance (GitLab self-hosted only)
6. GITLAB_TOKEN / GITHUB_TOKEN      Global default
7. glab config / gh auth token      CLI stored credential (lowest priority)
```

## Platform Detection

Platform is determined in this order:

| Priority | Source | Example |
|----------|--------|---------|
| 1 | `--platform` argument | `--platform gitlab` |
| 2 | `--host` argument (pattern match) | `--host gitlab.company.com` |
| 3 | `GITLAB_HOST` / `GITHUB_HOST` env var | `GITLAB_HOST=https://gitlab.company.com` |
| 4 | `git remote get-url origin` | Auto-detected from repo |

| Remote URL Pattern | Platform | Token Prefix |
|-------------|----------|-------------|
| `*github.com*` | GitHub | `GITHUB_TOKEN` |
| `*gitlab.com*` or `*gitlab.*` | GitLab | `GITLAB_TOKEN` |
| Custom (`GITLAB_HOST`) | GitLab | `GITLAB_TOKEN` |
| Custom (`GITHUB_HOST`) | GitHub | `GITHUB_TOKEN` |

## Host Resolution

| Arguments | Resolved Host |
|-----------|---------------|
| `--platform gitlab` | `gitlab.com` (default) |
| `--platform gitlab --host mygl.com` | `mygl.com` |
| `--platform github` | `github.com` (default) |
| `--platform github --host ghe.company.com` | `ghe.company.com` |
| *(none)* | Extracted from `git remote get-url origin` |

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

## Usage

```bash
# BYOK: Explicit PAT (e.g., from an external platform like OpenClaw)
./resolve-token.sh --token glpat-xxxxxxxxxxxxxxxxxxxx --platform gitlab

# BYOK: PAT for self-hosted instance
./resolve-token.sh --token ghp-xxxxxxxxxxxx --platform github --host github.company.com

# BYOK: Via environment variable
FORGE_TOKEN=glpat-xxx ./resolve-token.sh --platform gitlab

# Auto-detect: Inside a git repo, no arguments needed
./resolve-token.sh

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

When `resolve-token.sh` runs:

1. Checks for `--token` argument → immediate return if present
2. Checks `FORGE_TOKEN` env var → immediate return if present
3. Determines platform:
   - `--platform` argument, OR
   - `--host` pattern match, OR
   - `GITLAB_HOST` / `GITHUB_HOST` env var, OR
   - git remote URL auto-detection
4. Walks the hierarchical env var chain for that platform
5. Falls back to CLI stored credentials (`glab config get token` / `gh auth token`)
6. Returns error if no token found

## Security Notes

- Tokens are never printed or logged by the resolver (output goes to stdout only)
- The resolver validates that tokens are non-empty and have a minimum length
- Only HTTPS hosts are accepted — HTTP is rejected to prevent token leakage over plaintext
- When using `--token`, ensure the value is not exposed in shell history (prefer `FORGE_TOKEN` env var for automation)
