#!/usr/bin/env bash
# mr-auto-review.sh — Automated MR review: checkout → test → approve or reject.
#
# Usage:
#   ./mr-auto-review.sh <MR_IID> [test_command]
#   ./mr-auto-review.sh 123
#   ./mr-auto-review.sh 123 "pytest"

set -euo pipefail

MR_ID="${1:-}"
TEST_CMD="${2:-npm test}"

if [[ -z "$MR_ID" ]]; then
    echo "Usage: $0 <MR_IID> [test_command]"
    echo "  Default test command: npm test"
    echo "  Example: $0 123 'pytest -x'"
    exit 1
fi

if ! [[ "$MR_ID" =~ ^[0-9]+$ ]]; then
    echo "ERROR: MR_IID must be numeric (got: $MR_ID)" >&2
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

echo ">> Checking out MR !$MR_ID..."
glab mr checkout "$MR_ID"

echo ">> Running: $TEST_CMD"
if $TEST_CMD; then
    echo ">> Tests passed."
    glab mr note "$MR_ID" -m "Tests passed locally — approving."
    glab mr approve "$MR_ID"
    echo ">> MR !$MR_ID approved."
else
    echo ">> Tests failed." >&2
    glab mr note "$MR_ID" -m "Tests failed locally.

Command: \`$TEST_CMD\`

See CI logs or local output for details."
    echo ">> MR !$MR_ID not approved (test failure)." >&2
    exit 1
fi
