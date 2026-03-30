# Contributing to Forge CLI

Thank you for your interest in contributing to Forge CLI.

## How to Contribute

### Reporting Bugs

Open an issue with:
- Steps to reproduce
- Expected vs actual behavior
- OS, shell version, CLI versions (`glab --version`, `gh --version`)

### Suggesting Features

Open an issue describing the use case and expected behavior.

### Adding a New Platform

This is the most impactful way to contribute. Follow the guide in [config/add-platform.md](config/add-platform.md):

1. Create `platforms/<your-platform>/` with `PLATFORM.md`
2. Add sub-skill SKILL.md files for each domain (e.g., PR, CI, issues)
3. Add utility scripts under `platforms/<your-platform>/scripts/`
4. Update the top-level `SKILL.md` platform table
5. **Zero modification** to existing platform files is required

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Test locally by symlinking to your agent's skills directory
5. Submit a PR with a clear description

## Code Standards

### SKILL.md Files

- Keep under 500 lines
- Use YAML frontmatter with `name` and `description`
- `description` must be third-person and include trigger keywords
- Consistent terminology within each platform

### Scripts

- Use `#!/usr/bin/env bash` shebang
- Set `set -euo pipefail` at the top
- Support cross-platform where possible
- Python scripts: stdlib only (no external dependencies)

### Naming Conventions

- Platform directories: lowercase (`gitlab`, `github`, `gitea`)
- Sub-skill directories: lowercase, match the platform's domain term (`mr` for GitLab, `pr` for GitHub)
- Scripts: `kebab-case.sh` or `kebab-case.py`

## Testing

After making changes, install the skill locally and verify:

```bash
# Cursor
ln -sf "$(pwd)" ~/.cursor/skills/forge-cli

# Codex
ln -sf "$(pwd)" ~/.codex/skills/forge-cli
```

Restart the IDE, then test commands through the agent.

## License

By contributing, you agree that your contributions will be licensed under the [MIT-0 License](LICENSE).
