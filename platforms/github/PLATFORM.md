# GitHub Platform

## Metadata

| Field | Value |
|-------|-------|
| **Platform** | GitHub |
| **CLI Tool** | `gh` (official GitHub CLI) |
| **CLI Version** | >= 2.40.0 |
| **Install** | `brew install gh` or [cli.github.com](https://cli.github.com/) |
| **Auth** | `gh auth login` or `GITHUB_TOKEN` env var |
| **GitHub Enterprise** | Supported via `GH_HOST` env var or `--hostname` flag |

## Host Detection Patterns

This platform is selected when the git remote URL matches:

```
gitlab.com     → NOT this platform
github.com     → ✓ GitHub SaaS
*.github.com   → ✓ GitHub Enterprise Cloud
```

For GitHub Enterprise Server with custom domains, set `GITHUB_HOST`:

```bash
export GITHUB_HOST="https://github.company.com"
```

## Token Resolution

Environment variable prefix: `GITHUB_TOKEN`

| Priority | Variable | Scope |
|----------|----------|-------|
| 1 (highest) | `GITHUB_TOKEN_<PROJECT>` | Single repository |
| 2 | `GITHUB_TOKEN_<WORKSPACE>` | Organization |
| 3 | `GITHUB_TOKEN` | Global default |
| 4 (lowest) | `gh auth token` | gh stored credentials |

## Terminology Mapping

| Forge Concept | GitHub Term | CLI Command |
|---------------|-------------|-------------|
| Code Review | Pull Request (PR) | `gh pr` |
| CI/CD | GitHub Actions | `gh run`, `gh workflow` |
| CI Unit | Workflow Run | `gh run view <run-id>` |
| Issue | Issue | `gh issue` |
| Repository | Repository | `gh repo` |
| Label | Label | `gh label` |
| Direct API | REST / GraphQL | `gh api` |

## Sub-skills

| Skill | Path | Description |
|-------|------|-------------|
| pr | `platforms/github/pr/SKILL.md` | Pull requests: create, review, merge |
| actions | `platforms/github/actions/SKILL.md` | GitHub Actions: workflows, runs, logs |
| issue | `platforms/github/issue/SKILL.md` | Issues: create, list, update, close |
| repo | `platforms/github/repo/SKILL.md` | Repositories: clone, fork, create |
| auth | `platforms/github/auth/SKILL.md` | Authentication and token management |
| api | `platforms/github/api/SKILL.md` | Direct REST and GraphQL API access |
| label | `platforms/github/label/SKILL.md` | Label management |
| run | `platforms/github/run/SKILL.md` | Individual workflow run operations |
| config | `platforms/github/config/SKILL.md` | CLI configuration and defaults |

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `platforms/github/scripts/pr-inline-review.py` | Post inline review comments on PRs |
| `platforms/github/scripts/pr-auto-review.sh` | Automated checkout → test → approve/reject |
| `platforms/github/scripts/actions-failure-report.sh` | Diagnose failed workflow runs |
| `platforms/github/scripts/issue-to-pr.sh` | Create branch and PR from issue |
