---
name: gh-repo
description: Clone, fork, create, and manage GitHub repositories. View repo info, open in browser, list repos, and manage settings. Triggers on repository, repo, clone, fork, create repo, GitHub repo.
---

# gh repo

Clone, fork, create, and manage GitHub repositories.

## Quick Start

```bash
gh repo clone owner/repo                 # Clone by path
gh repo fork owner/repo                  # Fork to your account
gh repo create my-new-repo               # Create new repo
gh repo view --web                       # Open in browser
```

## Workflows

### Cloning

```bash
gh repo clone owner/repo
gh repo clone owner/repo -- --depth=1    # Shallow clone
gh repo clone https://github.com/owner/repo
```

### Forking

```bash
gh repo fork owner/repo
gh repo fork owner/repo --clone          # Fork and clone
gh repo fork owner/repo --org my-org     # Fork to organization
```

### Creating Repos

```bash
gh repo create my-project --private
gh repo create my-project --public --description "A cool tool"
gh repo create my-org/my-project --internal
gh repo create my-project --template owner/template-repo
```

### Viewing Info

```bash
gh repo view                             # Current repo
gh repo view --web                       # Open in browser
gh repo view owner/repo --json description,stargazerCount
```

### Listing

```bash
gh repo list                             # Your repos
gh repo list my-org                      # Organization repos
gh repo list --language go --limit 50
```

## Reference

| Command | Description |
|---------|-------------|
| `gh repo clone <path>` | Clone repository |
| `gh repo fork <path> [--clone]` | Fork repository |
| `gh repo create <name> [--public\|--private]` | Create new repository |
| `gh repo view [path] [--web] [--json]` | View repository details |
| `gh repo list [org] [--language]` | List repositories |
| `gh repo archive <path>` | Archive repository |
| `gh repo delete <path> --yes` | Delete repository |
| `gh repo rename <new-name>` | Rename repository |
| `gh repo edit [--default-branch]` | Edit repository settings |
