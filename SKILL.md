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
if ! command -v glab >/dev/null 2>&1; then
  case "$(uname -s)" in
    Darwin)  brew install glab ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        curl -fsSL https://gitlab.com/gitlab-org/cli/-/releases/latest/downloads/glab_linux_amd64.deb -o /tmp/glab.deb && sudo dpkg -i /tmp/glab.deb && rm /tmp/glab.deb
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y 'https://gitlab.com/gitlab-org/cli/-/releases/latest/downloads/glab_linux_amd64.rpm'
      else
        curl -fsSL https://gitlab.com/gitlab-org/cli/-/releases/latest/downloads/glab_linux_amd64.tar.gz | tar xz -C /usr/local/bin glab
      fi ;;
    MINGW*|MSYS*|CYGWIN*) winget install --id GitLab.glab -e || scoop install glab ;;
  esac
fi

# Detect OS and install GitHub CLI (gh) if missing
if ! command -v gh >/dev/null 2>&1; then
  case "$(uname -s)" in
    Darwin)  brew install gh ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        (type -p wget >/dev/null || sudo apt-get install wget -y) \
          && sudo mkdir -p -m 755 /etc/apt/keyrings \
          && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
          && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
          && sudo apt-get update && sudo apt-get install gh -y
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y 'https://github.com/cli/cli/releases/latest/download/gh_linux_amd64.rpm'
      else
        curl -fsSL https://github.com/cli/cli/releases/latest/download/gh_linux_amd64.tar.gz | tar xz -C /usr/local/bin --strip-components=2 '*/bin/gh'
      fi ;;
    MINGW*|MSYS*|CYGWIN*) winget install --id GitHub.cli -e || scoop install gh ;;
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

Tokens are resolved hierarchically per platform. See [config/token-resolver.md](config/token-resolver.md).

**GitLab:** `GITLAB_TOKEN_<PROJECT>` → `GITLAB_TOKEN_<WORKSPACE>` → `GITLAB_TOKEN_<HOST>` → `GITLAB_TOKEN` → `glab config`

**GitHub:** `GITHUB_TOKEN_<PROJECT>` → `GITHUB_TOKEN_<WORKSPACE>` → `GITHUB_TOKEN` → `gh auth token`

Supports multiple instances simultaneously — the correct token is selected based on the current repo's remote URL.

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
# Detect platform
scripts/detect-platform.sh

# GitLab workflow
glab mr create --fill --draft
glab ci status
glab mr merge 123 --when-pipeline-succeeds

# GitHub workflow
gh pr create --fill --draft
gh run list
gh pr merge 123 --auto --squash
```
