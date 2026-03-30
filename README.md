# Forge CLI — Multi-Platform Git Forge Toolkit

A developer-focused Agent Skill for Git hosting platform workflows. Plugin architecture supporting multiple platforms through a single unified interface.

## Supported Platforms

| Platform | CLI | Status |
|----------|-----|--------|
| **GitLab** | [glab](https://gitlab.com/gitlab-org/cli) >= 1.36.0 | Full support |
| **GitHub** | [gh](https://cli.github.com/) >= 2.40.0 | Full support |
| Gitea / Forgejo | — | Planned |
| Bitbucket | — | Planned |

## Features

- **Plugin architecture** — each platform is self-contained in `platforms/<name>/`; add new platforms without modifying existing files
- **Auto platform detection** — determines GitLab or GitHub from `git remote` URL
- **Hierarchical token resolution** — different tokens per project, workspace, or hosting instance
- **Self-hosted support** — configure custom hosts via `GITLAB_HOST` or `GITHUB_HOST`
- **Utility scripts** — automated review, CI debugging, inline diff comments (with actual executable code, not just docs)
- **Security hardened** — HTTPS enforced, input validation, command allowlists, prompt injection protection

## Installation

### Method 1: ClawHub Install (recommended)

Visit [clawhub.ai](https://clawhub.ai) and search for `forge-cli`, then click **Install**. ClawHub copies the skill into your agent's skill directory automatically.

### Method 2: Source Install (Cursor)

```bash
git clone https://github.com/<your-org>/forge-cli.git ~/.cursor/skills/forge-cli
```

After installation, restart your IDE (Cursor / VS Code). The agent discovers the skill from the `description` field in `SKILL.md` frontmatter:

```yaml
description: Multi-platform Git forge CLI toolkit supporting GitLab and GitHub...
```

When the user mentions merge requests, pull requests, CI/CD, pipelines, issues, or any Git forge operation, the agent automatically reads `SKILL.md` and follows its instructions — including auto-installing CLI dependencies.

### Method 3: Source Install (Codex / OpenClaw)

```bash
git clone https://github.com/<your-org>/forge-cli.git ~/.codex/skills/forge-cli
```

Or use the Codex skill-installer:

```bash
python scripts/install-skill-from-github.py --repo <your-org>/forge-cli --path .
```

Restart Codex to pick up new skills. The agent discovers it the same way — via the `description` field.

## How the Agent Executes This Skill

1. **Discovery**: The agent reads `SKILL.md` frontmatter `description` and matches it to the user's intent
2. **Auto-Setup**: On first use, the agent executes the `Auto-Setup` section in `SKILL.md`, which detects the OS and installs the required CLI tools cross-platform (macOS via `brew`, Debian/Ubuntu via `apt`, Fedora/RHEL via `dnf`, Windows via `winget`/`scoop`, or fallback to direct binary download)
3. **Authentication**: The agent checks `glab auth status` / `gh auth status` and initiates login if needed
4. **Platform Routing**: The agent runs `scripts/detect-platform.sh` to identify GitLab or GitHub, then routes to the corresponding platform sub-skills under `platforms/<name>/`

No manual CLI installation is needed — the agent handles everything.

## Manual Setup (optional)

If you prefer to install CLIs manually instead of relying on the agent:

| OS | GitLab CLI (glab) | GitHub CLI (gh) |
|----|-------------------|-----------------|
| **macOS** | `brew install glab` | `brew install gh` |
| **Debian / Ubuntu** | [Download .deb](https://gitlab.com/gitlab-org/cli/-/releases) | [Official guide](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| **Fedora / RHEL** | [Download .rpm](https://gitlab.com/gitlab-org/cli/-/releases) | [Download .rpm](https://github.com/cli/cli/releases) |
| **Windows** | `winget install GitLab.glab` | `winget install GitHub.cli` |

```bash
# Authenticate
glab auth login                                   # GitLab
gh auth login                                     # GitHub

# Optional: env-based auth for multiple instances
export GITLAB_TOKEN="glpat-your-token"
export GITLAB_HOST="https://gitlab.company.com"   # self-hosted GitLab
export GITHUB_TOKEN="ghp_your-token"
```

| Dependency | Min Version | Required For |
|-----------|-------------|--------------|
| glab | >= 1.36.0 | GitLab operations |
| gh | >= 2.40.0 | GitHub operations |
| Python | >= 3.6 | Inline review scripts (stdlib only) |
| Bash | >= 4.0 | Utility scripts (pre-installed on most systems) |

## Token Resolution

Tokens are resolved in priority order per platform:

**GitLab:**

| Priority | Environment Variable | Scope |
|----------|---------------------|-------|
| 1 (highest) | `GITLAB_TOKEN_<PROJECT>` | Single project |
| 2 | `GITLAB_TOKEN_<WORKSPACE>` | Workspace/group |
| 3 | `GITLAB_TOKEN_<HOST>` | GitLab instance |
| 4 | `GITLAB_TOKEN` | Global default |
| 5 (lowest) | glab CLI config | Stored credentials |

**GitHub:**

| Priority | Environment Variable | Scope |
|----------|---------------------|-------|
| 1 (highest) | `GITHUB_TOKEN_<PROJECT>` | Single project |
| 2 | `GITHUB_TOKEN_<WORKSPACE>` | Organization |
| 3 | `GITHUB_TOKEN` | Global default |
| 4 (lowest) | gh CLI config | Stored credentials |

Project/workspace names are uppercased with hyphens replaced by underscores.

## Project Structure

```
forge-cli/
├── SKILL.md                  # Top-level router (auto-detects platform)
├── config/
│   ├── token-resolver.md     # Unified token resolution docs
│   └── add-platform.md       # Guide: how to add a new platform
├── scripts/
│   ├── detect-platform.sh    # Platform detection from git remote
│   └── resolve-token.sh      # Unified token resolver (all platforms)
├── platforms/
│   ├── gitlab/               # GitLab plugin (9 sub-skills + scripts)
│   │   ├── PLATFORM.md
│   │   ├── mr/SKILL.md
│   │   ├── ci/SKILL.md
│   │   ├── ...
│   │   └── scripts/
│   ├── github/               # GitHub plugin (9 sub-skills + scripts)
│   │   ├── PLATFORM.md
│   │   ├── pr/SKILL.md
│   │   ├── actions/SKILL.md
│   │   ├── ...
│   │   └── scripts/
│   └── ...                   # Add new platforms here
```

## Adding a New Platform

1. Create `platforms/<your-platform>/` directory structure (see `config/add-platform.md`)
2. Fill in `PLATFORM.md` (CLI tool, host patterns, token prefix)
3. Write sub-skill SKILL.md files for each domain
4. Add platform-specific utility scripts
5. No changes to existing files required

See [config/add-platform.md](config/add-platform.md) for detailed instructions.

## License

[MIT-0](LICENSE) — Free to use, modify, and redistribute. No attribution required.
