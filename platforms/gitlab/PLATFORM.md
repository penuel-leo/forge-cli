# GitLab Platform

## Metadata

| Field | Value |
|-------|-------|
| **Platform** | GitLab |
| **CLI Tool** | `glab` (official GitLab CLI) |
| **CLI Version** | >= 1.36.0 |
| **Install** | `brew install glab` or [gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli) |
| **Auth** | `glab auth login` or `GITLAB_TOKEN` env var |
| **Self-hosted** | Supported via `GITLAB_HOST` env var or `--hostname` flag |

## Host Detection Patterns

This platform is selected when the git remote URL matches:

```
github.com     → NOT this platform
gitlab.com     → ✓ GitLab SaaS
gitlab.*       → ✓ Self-hosted GitLab (any domain containing "gitlab")
```

For self-hosted instances with non-standard domains, set `GITLAB_HOST`:

```bash
export GITLAB_HOST="https://code.company.com"
```

## Token Resolution

Environment variable prefix: `GITLAB_TOKEN`

| Priority | Variable | Scope |
|----------|----------|-------|
| 1 (highest) | `GITLAB_TOKEN_<PROJECT>` | Single project |
| 2 | `GITLAB_TOKEN_<WORKSPACE>` | Group/namespace |
| 3 | `GITLAB_TOKEN_<HOST>` | Per GitLab instance |
| 4 | `GITLAB_TOKEN` | Global default |
| 5 (lowest) | `glab config get token` | glab stored credentials |

## Terminology Mapping

| Forge Concept | GitLab Term | CLI Command |
|---------------|-------------|-------------|
| Code Review | Merge Request (MR) | `glab mr` |
| CI/CD | Pipeline | `glab ci` |
| CI Unit | Job | `glab ci trace <job-id>` |
| Issue | Issue | `glab issue` |
| Repository | Project | `glab repo` |
| Label | Label | `glab label` |
| Direct API | REST / GraphQL | `glab api` |

## Sub-skills

| Skill | Path | Description |
|-------|------|-------------|
| mr | `platforms/gitlab/mr/SKILL.md` | Merge requests: create, review, approve, merge |
| ci | `platforms/gitlab/ci/SKILL.md` | CI/CD pipelines: trigger, status, debug |
| issue | `platforms/gitlab/issue/SKILL.md` | Issues: create, list, update, close |
| repo | `platforms/gitlab/repo/SKILL.md` | Repositories: clone, fork, create |
| auth | `platforms/gitlab/auth/SKILL.md` | Authentication and instance management |
| api | `platforms/gitlab/api/SKILL.md` | Direct REST and GraphQL API access |
| label | `platforms/gitlab/label/SKILL.md` | Project and group label management |
| job | `platforms/gitlab/job/SKILL.md` | Individual CI/CD job operations |
| config | `platforms/gitlab/config/SKILL.md` | CLI configuration and defaults |

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `platforms/gitlab/scripts/mr-inline-review.py` | Post inline diff comments on MRs |
| `platforms/gitlab/scripts/mr-auto-review.sh` | Automated checkout → test → approve/reject |
| `platforms/gitlab/scripts/ci-failure-report.sh` | Diagnose failed pipeline jobs |
| `platforms/gitlab/scripts/issue-to-mr.sh` | Create branch and MR from issue |
