---
name: glab-job
description: View, retry, cancel, and inspect individual CI/CD jobs. Get job logs, artifacts, and status. Use for job-level operations as opposed to pipeline-level commands in glab-ci. Triggers on job, retry job, cancel job, job log, job status, CI job.
---

# glab job

Work with individual CI/CD jobs (as opposed to pipeline-level operations in `glab-ci`).

## Quick Start

```bash
glab ci trace <job-id>                # View job logs (real-time)
glab ci retry <job-id>                # Retry a failed job
glab ci trigger <job-id>              # Trigger a manual job
```

## Workflows

### Inspecting Jobs

```bash
# Real-time log streaming
glab ci trace <job-id>

# View pipeline with all jobs
glab ci view

# View pipeline for a specific branch
glab ci view main
```

### Retry and Cancel

```bash
# Retry a failed job
glab ci retry <job-id>

# Cancel a running job
glab ci cancel <job-id>
```

### Manual Jobs

```bash
# Trigger a manual job (e.g., deploy-to-staging)
glab ci trigger <job-id>
```

### Finding Job IDs

```bash
# View pipeline to see job IDs
glab ci view

# List pipelines, then inspect
glab ci list --per-page 5
glab ci view <pipeline-id>
```

## glab-ci vs glab-job

| Need | Use |
|------|-----|
| Pipeline status, trigger, list | `glab-ci` |
| Individual job logs, retry, cancel | `glab-job` |
| Download artifacts by branch/job name | `glab ci artifact` |
| Stream specific job log | `glab ci trace <job-id>` |

## Reference

| Command | Description |
|---------|-------------|
| `glab ci trace <job-id>` | Stream job log output |
| `glab ci retry <job-id>` | Retry a failed/canceled job |
| `glab ci cancel <job-id>` | Cancel a running job |
| `glab ci trigger <job-id>` | Trigger a manual job |
| `glab ci view [branch]` | View pipeline with job list |
