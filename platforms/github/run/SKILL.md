---
name: gh-run
description: View, rerun, cancel, and inspect individual GitHub Actions workflow runs. Get run logs, artifacts, and status. Triggers on run, workflow run, rerun, cancel run, run log, run status.
---

# gh run

Work with individual GitHub Actions workflow runs.

## Quick Start

```bash
gh run view <run-id>                     # View run details
gh run view <run-id> --log               # View full logs
gh run view <run-id> --log-failed        # View failed job logs only
gh run rerun <run-id>                    # Rerun entire workflow
gh run rerun <run-id> --failed           # Rerun only failed jobs
```

## Workflows

### Inspecting Runs

```bash
# View run summary
gh run view <run-id>

# View with job details
gh run view <run-id> --json jobs

# View specific job log
gh run view <run-id> --job <job-id> --log

# Live-stream run progress
gh run watch <run-id>
```

### Rerun and Cancel

```bash
# Rerun failed jobs only
gh run rerun <run-id> --failed

# Rerun entire workflow
gh run rerun <run-id>

# Cancel a running workflow
gh run cancel <run-id>
```

### Downloading Artifacts

```bash
# Download all artifacts
gh run download <run-id>

# Download specific artifact by name
gh run download <run-id> -n build-output

# Download to specific directory
gh run download <run-id> -D ./artifacts/
```

### Finding Run IDs

```bash
# List recent runs
gh run list --limit 10

# Filter by workflow
gh run list --workflow ci.yml

# Filter by status
gh run list --status failure

# JSON output
gh run list --json databaseId,status,conclusion --limit 5
```

## gh-actions vs gh-run

| Need | Use |
|------|-----|
| Trigger workflow, list runs | `gh-actions` |
| Individual run logs, rerun, cancel | `gh-run` |
| Download artifacts | `gh run download` |
| Stream run progress | `gh run watch` |

## Reference

| Command | Description |
|---------|-------------|
| `gh run view <id> [--log] [--log-failed]` | View run details/logs |
| `gh run watch <id>` | Live-stream run status |
| `gh run rerun <id> [--failed]` | Rerun workflow/failed jobs |
| `gh run cancel <id>` | Cancel running workflow |
| `gh run download <id> [-n name]` | Download artifacts |
| `gh run list [--workflow] [--status]` | List runs |
