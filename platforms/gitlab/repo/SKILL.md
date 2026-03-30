---
name: glab-repo
description: Clone, fork, create, and manage GitLab repositories. View repo info, open in browser, list repos, and manage archive/transfer. Triggers on repository, repo, clone, fork, create repo, remote, project.
---

# glab repo

Clone, fork, create, and manage GitLab repositories.

## Quick Start

```bash
glab repo clone group/project          # Clone by path
glab repo fork group/project           # Fork to your namespace
glab repo create my-new-project        # Create new repo
glab repo view --web                   # Open in browser
```

## Workflows

### Cloning

```bash
# By project path
glab repo clone group/project

# By full URL
glab repo clone https://gitlab.com/group/project

# Shallow clone
glab repo clone group/project -- --depth=1

# Self-hosted
glab repo clone group/project --hostname gitlab.company.com
```

### Forking

```bash
# Fork to your namespace
glab repo fork group/project

# Clone after fork
glab repo fork group/project --clone

# Fork to a specific group
glab repo fork group/project --name my-fork
```

### Creating Repos

```bash
# Private repo (default)
glab repo create my-project

# With description and visibility
glab repo create my-project --description "A cool tool" --public

# In a group/namespace
glab repo create group/my-project --internal
```

### Viewing Repo Info

```bash
# Current repo info
glab repo view

# Open in browser
glab repo view --web

# Another repo
glab repo view group/project
```

### Listing Repos

```bash
# Your repos
glab repo list

# Group repos
glab repo list --group my-group

# Filter
glab repo list --search "api" --per-page 50
```

## Reference

| Command | Description |
|---------|-------------|
| `glab repo clone <path>` | Clone repository |
| `glab repo fork <path> [--clone]` | Fork repository |
| `glab repo create <name> [--public\|--internal]` | Create new repository |
| `glab repo view [path] [--web]` | View repository details |
| `glab repo list [--group] [--search]` | List repositories |
| `glab repo archive <path>` | Archive repository |
| `glab repo delete <path>` | Delete repository |
