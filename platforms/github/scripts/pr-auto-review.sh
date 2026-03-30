#!/usr/bin/env bash
# pr-auto-review.sh — Automated PR review: checkout → test → approve or request changes.
#
# Usage:
#   ./pr-auto-review.sh <PR_NUMBER> [test_command]
#   ./pr-auto-review.sh 123
#   ./pr-auto-review.sh 123 "pytest"

set -euo pipefail

PR_NUM="${1:-}"
TEST_CMD="${2:-npm test}"

if [[ -z "$PR_NUM" ]]; then
    echo "Usage: $0 <PR_NUMBER> [test_command]"
    echo "  Default test command: npm test"
    echo "  Example: $0 123 'pytest -x'"
    exit 1
fi

if ! [[ "$PR_NUM" =~ ^[0-9]+$ ]]; then
    echo "ERROR: PR number must be numeric (got: $PR_NUM)" >&2
    exit 1
fi

ALLOWED=(
    "npm test"
    "npm run test"
    "pnpm test"
    "yarn test"
    "make test"
    "cargo test"
    "go test ./..."
    "pytest"
    "pytest -x"
    "python -m pytest"
    "bundle exec rspec"
    "mvn test"
    "gradle test"
    "dotnet test"
)

CMD_OK=false
for allowed in "${ALLOWED[@]}"; do
    if [[ "$TEST_CMD" == "$allowed" ]]; then
        CMD_OK=true
        break
    fi
done

if [[ "$CMD_OK" == "false" ]]; then
    echo "ERROR: Test command not in allowlist: '$TEST_CMD'" >&2
    echo "" >&2
    echo "Allowed:" >&2
    for c in "${ALLOWED[@]}"; do
        echo "  - $c" >&2
    done
    echo "" >&2
    echo "Edit ALLOWED array in this script to add new commands." >&2
    exit 1
fi

echo ">> Checking out PR #$PR_NUM..."
gh pr checkout "$PR_NUM"

echo ">> Running: $TEST_CMD"
if $TEST_CMD; then
    echo ">> Tests passed."
    gh pr review "$PR_NUM" --approve --body "Tests passed locally — approving."
    echo ">> PR #$PR_NUM approved."
else
    echo ">> Tests failed." >&2
    gh pr review "$PR_NUM" --request-changes --body "Tests failed locally.

Command: \`$TEST_CMD\`

See CI logs or local output for details."
    echo ">> PR #$PR_NUM changes requested (test failure)." >&2
    exit 1
fi
