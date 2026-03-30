#!/usr/bin/env bash
# issue-to-mr.sh — Create a branch and MR from a GitLab issue.
#
# Usage:
#   ./issue-to-mr.sh <ISSUE_IID>
#   ./issue-to-mr.sh 456
#
# Creates a branch named <issue-id>-<slugified-title> and opens a draft MR.

set -euo pipefail

ISSUE_ID="${1:-}"

if [[ -z "$ISSUE_ID" ]]; then
    echo "Usage: $0 <ISSUE_IID>"
    echo "  Creates a branch and draft MR linked to the issue."
    exit 1
fi

if ! [[ "$ISSUE_ID" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Issue IID must be numeric (got: $ISSUE_ID)" >&2
    exit 1
fi

echo ">> Fetching issue #${ISSUE_ID}..."
ISSUE_TITLE=$(glab issue view "$ISSUE_ID" 2>/dev/null | head -1 | sed 's/^#[0-9]* //' || true)

if [[ -z "$ISSUE_TITLE" ]]; then
    echo "WARNING: Could not fetch issue title. Using generic branch name." >&2
    ISSUE_TITLE="issue-${ISSUE_ID}"
fi

SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | head -c 50)
BRANCH="${ISSUE_ID}-${SLUG}"

echo ">> Creating branch: $BRANCH"
git checkout -b "$BRANCH" 2>/dev/null || git switch -c "$BRANCH"

echo ">> Creating draft MR linked to issue #${ISSUE_ID}..."
glab mr create \
    --fill \
    --draft \
    --title "Draft: ${ISSUE_TITLE}" \
    --related-issue "$ISSUE_ID" \
    --push

echo ""
echo "Done. Branch: $BRANCH"
echo "MR created as draft — push commits and mark ready when done."
