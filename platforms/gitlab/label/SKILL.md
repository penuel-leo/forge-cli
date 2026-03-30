---
name: glab-label
description: Create, list, and manage project and group labels in GitLab. Organize issues and MRs with consistent labeling. Triggers on label, tag, categorize, priority, label management.
---

# glab label

Create and manage project and group labels.

## Quick Start

```bash
glab label create "bug" --color "#d73a4a"
glab label list
glab label create "priority::high" --color "#e11d48" --description "Needs immediate attention"
```

## Workflows

### Creating Labels

```bash
# Project-level label
glab label create "feature" --color "#0075ca" --description "New feature request"

# Multiple labels for workflow
glab label create "status::todo" --color "#6b7280"
glab label create "status::in-progress" --color "#f59e0b"
glab label create "status::done" --color "#10b981"
```

### Group-level Labels

Group labels are shared across all projects in the group:

```bash
# Create in a group (via API)
glab api groups/:id/labels -X POST \
  -f name="priority::high" \
  -f color="#e11d48" \
  -f description="Critical priority"
```

### Listing Labels

```bash
glab label list
glab label list --per-page 100
```

## Project vs Group Labels

| Scope | When to Use |
|-------|------------|
| **Project** | Project-specific workflows (e.g., `needs-review`, `deploy-staging`) |
| **Group** | Consistent labeling across projects (e.g., `priority::high`, `type::bug`) |

## Reference

| Command | Description |
|---------|-------------|
| `glab label create <name> --color <hex>` | Create label |
| `glab label list` | List project labels |
| `glab label delete <name>` | Delete label |
