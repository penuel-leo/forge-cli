#!/usr/bin/env bash
# issue-to-pr.sh — Create a branch and PR from a GitHub issue.
#
# Usage:
#   ./issue-to-pr.sh <ISSUE_NUMBER>
#   ./issue-to-pr.sh 456
#
# Creates a branch named <issue-number>-<slugified-title> and opens a draft PR.

set -euo pipefail

ISSUE_NUM="${1:-}"

if [[ -z "$ISSUE_NUM" ]]; then
    echo "Usage: $0 <ISSUE_NUMBER>"
    echo "  Creates a branch and draft PR linked to the issue."
    exit 1
fi

if ! [[ "$ISSUE_NUM" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Issue number must be numeric (got: $ISSUE_NUM)" >&2
    exit 1
fi

echo ">> Fetching issue #${ISSUE_NUM}..."
ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --json title --jq .title 2>/dev/null || true)

if [[ -z "$ISSUE_TITLE" ]]; then
    echo "WARNING: Could not fetch issue title. Using generic branch name." >&2
    ISSUE_TITLE="issue-${ISSUE_NUM}"
fi

SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | head -c 50)
BRANCH="${ISSUE_NUM}-${SLUG}"

echo ">> Creating branch: $BRANCH"
git checkout -b "$BRANCH" 2>/dev/null || git switch -c "$BRANCH"

echo ">> Creating draft PR linked to issue #${ISSUE_NUM}..."
gh pr create \
    --fill \
    --draft \
    --title "Draft: ${ISSUE_TITLE}" \
    --body "Closes #${ISSUE_NUM}"

echo ""
echo "Done. Branch: $BRANCH"
echo "PR created as draft — push commits and mark ready when done."
