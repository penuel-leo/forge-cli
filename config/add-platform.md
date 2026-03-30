# Adding a New Platform

This guide explains how to add support for a new Git hosting platform (e.g., Gitea, Bitbucket, Codeberg).

## Steps

### 1. Create the platform directory

```bash
mkdir -p platforms/<platform-name>/{mr,ci,issue,repo,auth,api,label,job,config,scripts}
```

### 2. Fill in PLATFORM.md

Edit `platforms/<platform-name>/PLATFORM.md` with:

| Field | Description | Example |
|-------|-------------|---------|
| **Platform** | Display name | Gitea |
| **CLI Tool** | CLI binary name | `tea` |
| **CLI Version** | Minimum version | >= 0.9.0 |
| **Install** | Install command | `brew install tea` |
| **Auth** | Auth command | `tea login add` |
| **Host Detection Patterns** | URL patterns to match | `gitea.*`, `codeberg.org` |
| **Token Env Prefix** | Env var prefix | `GITEA_TOKEN` |
| **Terminology Mapping** | Platform-specific terms | Pull Request, Actions, etc. |

### 3. Write sub-skill SKILL.md files

For each domain (mr, ci, issue, repo, auth, api, label, job, config), write a SKILL.md with:

- `---` frontmatter block with `name` and `description`
- Quick start examples
- Workflow sections with CLI commands
- Reference table of all commands

Use the template files as starting points. Not all domains need to be implemented — only create skills for CLI features that exist on the platform.

### 4. Create platform-specific scripts (optional)

Add utility scripts to `platforms/<platform-name>/scripts/`:

- Inline review script (if the platform supports diff comments via API)
- CI failure report script
- Automated review script
- Issue-to-MR/PR script

### 5. Update token resolution (if needed)

If the platform uses a non-standard token env var prefix, the `scripts/resolve-token.sh` script auto-discovers platforms from the `PLATFORM.md` metadata. For most platforms, just setting the correct `token_env_prefix` in PLATFORM.md is sufficient.

For platforms with unique host detection patterns, add a case to `scripts/detect-platform.sh`:

```bash
case "$host" in
    *gitea*|codeberg.org) echo "gitea" ;;
esac
```

### 6. Verify

```bash
# Test platform detection
cd /path/to/repo-on-new-platform
scripts/detect-platform.sh
# Expected: <platform-name>

# Test token resolution
export <PREFIX>_TOKEN="test-token"
scripts/resolve-token.sh
# Expected: test-token
```

## What You Do NOT Need to Change

- Top-level `SKILL.md` (router auto-discovers platforms from `platforms/` directory)
- Existing platform directories (`platforms/gitlab/`, `platforms/github/`)
- `README.md` (update only to list the new platform in the supported table)
- `scripts/resolve-token.sh` (auto-discovers token prefix from platform detection)
