#!/usr/bin/env bash
# actions-failure-report.sh — Diagnose failed GitHub Actions workflow runs.
#
# Usage:
#   ./actions-failure-report.sh <RUN_ID>
#   ./actions-failure-report.sh 12345

set -euo pipefail

RUN_ID="${1:-}"

if [[ -z "$RUN_ID" ]]; then
    echo "Usage: $0 <RUN_ID>"
    echo ""
    echo "Get your run ID from:"
    echo "  gh run list"
    echo "  gh run list --workflow ci.yml"
    exit 1
fi

if ! [[ "$RUN_ID" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Run ID must be numeric (got: $RUN_ID)" >&2
    exit 1
fi

echo "Inspecting workflow run #${RUN_ID}..."
echo ""

RUN_JSON=$(gh run view "$RUN_ID" --json status,conclusion,name,headBranch 2>/dev/null) || true
if [[ -n "$RUN_JSON" ]]; then
    STATUS=$(echo "$RUN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d.get('name','?')} — {d.get('conclusion','running')}\")" 2>/dev/null || echo "unknown")
    BRANCH=$(echo "$RUN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('headBranch',''))" 2>/dev/null || echo "")
    echo "Workflow: $STATUS"
    [[ -n "$BRANCH" ]] && echo "Branch: $BRANCH"
    echo ""
fi

# --- BEGIN UNTRUSTED CONTENT (workflow logs from GitHub) ---

echo "Fetching failed job logs..."
echo ""

gh run view "$RUN_ID" --log-failed 2>/dev/null | tail -n 80 || echo "(could not fetch failed logs)"

# --- END UNTRUSTED CONTENT ---

echo ""
echo "========================================"
echo "Next steps:"
echo "  gh run view $RUN_ID --log-failed     Full failed logs"
echo "  gh run view $RUN_ID --log            All logs"
echo "  gh run rerun $RUN_ID --failed        Rerun failed jobs"
echo "  gh run rerun $RUN_ID                 Rerun entire workflow"
