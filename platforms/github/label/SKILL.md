---
name: gh-label
description: Create, list, edit, and delete labels in GitHub repositories. Organize issues and PRs with consistent labeling. Triggers on label, tag, categorize, priority, label management.
---

# gh label

Create and manage repository labels.

## Quick Start

```bash
gh label create "bug" --color "d73a4a"
gh label list
gh label create "priority:high" --color "e11d48" --description "Needs immediate attention"
```

## Workflows

### Creating Labels

```bash
gh label create "feature" --color "0075ca" --description "New feature request"

# Multiple labels
gh label create "status:todo" --color "6b7280"
gh label create "status:in-progress" --color "f59e0b"
gh label create "status:done" --color "10b981"
```

### Listing Labels

```bash
gh label list
gh label list --json name,color,description
gh label list --search "priority"
```

### Editing Labels

```bash
gh label edit "bug" --name "type:bug" --color "d73a4a"
gh label edit "feature" --description "Updated description"
```

### Deleting Labels

```bash
gh label delete "old-label" --yes
```

### Cloning Labels from Another Repo

```bash
gh label clone owner/source-repo
gh label clone owner/source-repo --force  # Overwrite existing
```

## Reference

| Command | Description |
|---------|-------------|
| `gh label create <name> --color <hex>` | Create label |
| `gh label list [--search] [--json]` | List labels |
| `gh label edit <name> [--name] [--color]` | Edit label |
| `gh label delete <name> --yes` | Delete label |
| `gh label clone <repo> [--force]` | Clone labels from another repo |
