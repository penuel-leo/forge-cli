---
name: forge-cli
description: Multi-platform Git forge CLI toolkit supporting GitLab and GitHub. Auto-detects platform from git remote, auto-installs CLI dependencies, and routes to platform-specific sub-skills. Use when working with merge requests, pull requests, CI/CD pipelines, issues, repositories, or API access on any supported git hosting platform.
---

# Forge CLI — Multi-Platform Git Forge Toolkit

A plugin-based toolkit for Git hosting platforms. Supports **GitLab** and **GitHub** with automatic platform detection and automatic dependency installation.

## Auto-Setup (run before first use)

Before executing any platform commands, check and install CLI dependencies:

```bash
# Detect OS and install GitLab CLI (glab) if missing
#!/bin/bash

# Detect OS and install GitLab CLI (glab) if missing
if ! command -v glab >/dev/null 2>&1; then
  case "$(uname -s)" in
    Darwin)  
      brew install glab 
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        # Use official GitLab CLI apt repository
        curl -sL https://packages.gitlab.com/install/repositories/gitlab/gitlab-cli/script.deb.sh | sudo bash
        sudo apt-get install -y glab
      elif command -v dnf >/dev/null 2>&1; then
        # Use official GitLab CLI rpm repository
        curl -sL https://packages.gitlab.com/install/repositories/gitlab/gitlab-cli/script.rpm.sh | sudo bash
        sudo dnf install -y glab
      else
        # Fallback: dynamically fetch latest version from API to avoid 404
        GLAB_VER=$(curl -s "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" | grep -o '"tag_name":"[^"]*"' | head -n 1 | cut -d'"' -f4 | sed 's/^v//')
        curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VER}/downloads/glab_${GLAB_VER}_Linux_x86_64.tar.gz" -o /tmp/glab.tar.gz
        tar -xzf /tmp/glab.tar.gz -C /tmp bin/glab
        sudo mv /tmp/bin/glab /usr/local/bin/glab
        rm -rf /tmp/glab.tar.gz /tmp/bin
      fi 
      ;;
    MINGW*|MSYS*|CYGWIN*) 
      winget install --id GitLab.glab -e || scoop install glab 
      ;;
  esac
fi

# Detect OS and install GitHub CLI (gh) if missing
if ! command -v gh >/dev/null 2>&1; then
  case "$(uname -s)" in
    Darwin)  
      brew install gh 
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        # GitHub's official apt repository setup
        (type -p wget >/dev/null || sudo apt-get install wget -y) \
          && sudo mkdir -p -m 755 /etc/apt/keyrings \
          && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
          && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
          && sudo apt-get update && sudo apt-get install gh -y
      elif command -v dnf >/dev/null 2>&1; then
        # Use official GitHub CLI rpm repository
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh
      else
        # Fallback: dynamically fetch latest version from API to avoid 404
        GH_VER=$(curl -s "https://api.github.com/repos/cli/cli/releases/latest" | grep -o '"tag_name": "[^"]*"' | head -n 1 | cut -d'"' -f4 | sed 's/^v//')
        curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_${GH_VER}_linux_amd64.tar.gz" -o /tmp/gh.tar.gz
        tar -xzf /tmp/gh.tar.gz -C /tmp
        sudo mv /tmp/gh_${GH_VER}_linux_amd64/bin/gh /usr/local/bin/gh
        rm -rf /tmp/gh.tar.gz /tmp/gh_${GH_VER}_linux_amd64
      fi 
      ;;
    MINGW*|MSYS*|CYGWIN*) 
      winget install --id GitHub.cli -e || scoop install gh 
      ;;
  esac
fi

# Authenticate (if not already done)
glab auth status 2>/dev/null || glab auth login
gh auth status 2>/dev/null || gh auth login
```

Only the CLIs for the detected platform need to be installed. If only using GitLab, `gh` is optional and vice versa.

## Platform Detection

The toolkit auto-detects the platform from `git remote get-url origin`:

| Remote URL Pattern | Platform | Sub-skills Location |
|-------------------|----------|---------------------|
| `*github.com*` | GitHub | `platforms/github/` |
| `*gitlab.com*` or `*gitlab.*` | GitLab | `platforms/gitlab/` |
| Custom host with `GITLAB_HOST` set | GitLab | `platforms/gitlab/` |
| Custom host with `GITHUB_HOST` set | GitHub | `platforms/github/` |

Run detection: `scripts/detect-platform.sh`

## Token Resolution

Tokens are resolved in strict priority order. See [config/token-resolver.md](config/token-resolver.md) for full details.

**Priority (highest → lowest):**

1. `--token <pat>` — explicit argument (BYOK / external platform integration)
2. `FORGE_TOKEN` — universal env var override
3. `GITLAB_TOKEN_<PROJECT>` / `GITHUB_TOKEN_<PROJECT>` — project-specific
4. `GITLAB_TOKEN_<WORKSPACE>` / `GITHUB_TOKEN_<WORKSPACE>` — workspace/org level
5. `GITLAB_TOKEN_<HOST>` — per-instance (GitLab only)
6. `GITLAB_TOKEN` / `GITHUB_TOKEN` — global default
7. `glab config` / `gh auth token` — CLI stored credential

**Platform detection:** `--platform gitlab|github` > `--host <hostname>` > `GITLAB_HOST`/`GITHUB_HOST` env var > git remote URL auto-detection.

Supports multiple instances simultaneously — the correct token is selected based on explicit arguments or the current repo's remote URL.

## Platform Sub-skills

### GitLab (`glab`)

See [platforms/gitlab/PLATFORM.md](platforms/gitlab/PLATFORM.md) for full details.

| Domain | Skill | Key Commands |
|--------|-------|--------------|
| Merge Requests | `platforms/gitlab/mr/` | `glab mr create`, `glab mr diff`, `glab mr merge` |
| CI/CD | `platforms/gitlab/ci/` | `glab ci status`, `glab ci run`, `glab ci trace` |
| Issues | `platforms/gitlab/issue/` | `glab issue create`, `glab issue list` |
| Repositories | `platforms/gitlab/repo/` | `glab repo clone`, `glab repo fork` |
| Authentication | `platforms/gitlab/auth/` | `glab auth login`, `glab auth status` |
| API | `platforms/gitlab/api/` | `glab api <endpoint>`, GraphQL |
| Labels | `platforms/gitlab/label/` | `glab label create`, `glab label list` |
| Jobs | `platforms/gitlab/job/` | `glab ci trace`, `glab ci retry` |
| Config | `platforms/gitlab/config/` | `glab config set`, `glab config list` |

### GitHub (`gh`)

See [platforms/github/PLATFORM.md](platforms/github/PLATFORM.md) for full details.

| Domain | Skill | Key Commands |
|--------|-------|--------------|
| Pull Requests | `platforms/github/pr/` | `gh pr create`, `gh pr diff`, `gh pr merge` |
| Actions | `platforms/github/actions/` | `gh run list`, `gh run view`, `gh run watch` |
| Issues | `platforms/github/issue/` | `gh issue create`, `gh issue list` |
| Repositories | `platforms/github/repo/` | `gh repo clone`, `gh repo fork` |
| Authentication | `platforms/github/auth/` | `gh auth login`, `gh auth status` |
| API | `platforms/github/api/` | `gh api <endpoint>`, GraphQL |
| Labels | `platforms/github/label/` | `gh label create`, `gh label list` |
| Workflow Runs | `platforms/github/run/` | `gh run view`, `gh run rerun` |
| Config | `platforms/github/config/` | `gh config set`, `gh config list` |

## Quick Start

```bash
# Auto-detect platform from git remote
scripts/detect-platform.sh

# Explicit platform (no git repo needed)
scripts/detect-platform.sh --platform gitlab
scripts/detect-platform.sh --host gitlab.company.com

# Resolve token — BYOK with explicit PAT
scripts/resolve-token.sh --token glpat-xxx --platform gitlab
scripts/resolve-token.sh --token ghp-xxx --platform github --host ghe.company.com

# Resolve token — env var
FORGE_TOKEN=glpat-xxx scripts/resolve-token.sh --platform gitlab

# Resolve token — auto-detect (inside a git repo)
scripts/resolve-token.sh

# GitLab workflow
glab mr create --fill --draft
glab ci status
glab mr merge 123 --when-pipeline-succeeds

# GitHub workflow
gh pr create --fill --draft
gh run list
gh pr merge 123 --auto --squash
```
