# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-03-30

### Added

- Multi-platform plugin architecture (`platforms/<name>/`)
- GitLab full support: MR, CI/CD, Issues, Repos, Auth, API, Labels, Jobs, Config (9 sub-skills)
- GitHub full support: PR, Actions, Issues, Repos, Auth, API, Labels, Runs, Config (9 sub-skills)
- Auto platform detection from `git remote` URL (`scripts/detect-platform.sh`)
- Hierarchical token resolution for both platforms (`scripts/resolve-token.sh`)
- Cross-platform CLI auto-installation (macOS, Linux, Windows)
- Self-hosted instance support via `GITLAB_HOST` / `GITHUB_HOST`
- Utility scripts: automated review, CI failure diagnosis, inline diff comments, issue-to-PR conversion
- Security hardening: HTTPS enforcement, input validation, command allowlists
- Platform extension guide (`config/add-platform.md`)

### Migration from gitlab-cli

- Renamed project from `gitlab-cli` to `forge-cli`
- Moved GitLab files from root to `platforms/gitlab/`
- All existing `glab-*` SKILL.md files preserved under new paths
- Added GitHub as second supported platform
