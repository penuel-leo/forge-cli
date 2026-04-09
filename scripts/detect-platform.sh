#!/usr/bin/env bash
# detect-platform.sh — Detect the Git hosting platform.
#
# Outputs: "gitlab", "github", or "unknown"
# Exit code: 0 if detected, 1 if unknown
#
# Detection priority:
#   1. --platform argument (explicit override)
#   2. --host argument (pattern match)
#   3. GITLAB_HOST / GITHUB_HOST env vars
#   4. git remote "origin" URL pattern
#
# Usage:
#   ./detect-platform.sh [--platform gitlab|github] [--host <hostname>]

set -euo pipefail

ARG_PLATFORM=""
ARG_HOST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform)
            ARG_PLATFORM="${2:-}"
            if [[ "$ARG_PLATFORM" != "gitlab" && "$ARG_PLATFORM" != "github" ]]; then
                echo "ERROR: --platform must be 'gitlab' or 'github' (got: $ARG_PLATFORM)" >&2
                exit 1
            fi
            shift 2
            ;;
        --host)
            ARG_HOST="${2:-}"
            [[ -z "$ARG_HOST" ]] && { echo "ERROR: --host requires a value" >&2; exit 1; }
            ARG_HOST="${ARG_HOST#https://}"
            ARG_HOST="${ARG_HOST#http://}"
            ARG_HOST="${ARG_HOST%%/*}"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Priority 1: explicit --platform
if [[ -n "$ARG_PLATFORM" ]]; then
    echo "$ARG_PLATFORM"
    exit 0
fi

detect_from_host() {
    local host="$1"
    [[ -z "$host" ]] && return 1

    if [[ -n "${GITLAB_HOST:-}" ]]; then
        local gl_host="${GITLAB_HOST#https://}"
        gl_host="${gl_host#http://}"
        [[ "$host" == "$gl_host" ]] && echo "gitlab" && return 0
    fi
    if [[ -n "${GITHUB_HOST:-}" ]]; then
        local gh_host="${GITHUB_HOST#https://}"
        gh_host="${gh_host#http://}"
        [[ "$host" == "$gh_host" ]] && echo "github" && return 0
    fi

    case "$host" in
        github.com|*.github.com) echo "github"; return 0 ;;
        gitlab.com|*.gitlab.com|*gitlab*) echo "gitlab"; return 0 ;;
    esac
    return 1
}

# Priority 2: --host argument
if [[ -n "$ARG_HOST" ]]; then
    if detect_from_host "$ARG_HOST"; then
        exit 0
    fi
    echo "unknown"
    exit 1
fi

# Priority 3: GITLAB_HOST / GITHUB_HOST env vars (no git repo needed)
if [[ -n "${GITLAB_HOST:-}" ]]; then
    echo "gitlab"
    exit 0
fi
if [[ -n "${GITHUB_HOST:-}" ]]; then
    echo "github"
    exit 0
fi

# Priority 4: git remote URL
extract_host() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null) || return 1

    if [[ "$remote_url" =~ ^https?://([^/]+)/ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^git@([^:]+): ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        return 1
    fi
}

host=""
host=$(extract_host) || true

if [[ -n "$host" ]] && detect_from_host "$host"; then
    exit 0
fi

echo "unknown"
exit 1
