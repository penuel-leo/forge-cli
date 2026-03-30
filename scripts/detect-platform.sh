#!/usr/bin/env bash
# detect-platform.sh — Detect the Git hosting platform from the current repo's remote URL.
#
# Outputs: "gitlab", "github", or "unknown"
# Exit code: 0 if detected, 1 if unknown
#
# Detection logic:
#   1. Extract host from git remote "origin"
#   2. Match against known patterns
#   3. Check GITLAB_HOST / GITHUB_HOST env vars for custom domains

set -euo pipefail

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

detect() {
    local host=""
    host=$(extract_host) || true

    if [[ -n "${GITLAB_HOST:-}" ]]; then
        local gl_host="${GITLAB_HOST#https://}"
        gl_host="${gl_host#http://}"
        if [[ "$host" == "$gl_host" || -z "$host" ]]; then
            echo "gitlab"
            return 0
        fi
    fi

    if [[ -n "${GITHUB_HOST:-}" ]]; then
        local gh_host="${GITHUB_HOST#https://}"
        gh_host="${gh_host#http://}"
        if [[ "$host" == "$gh_host" || -z "$host" ]]; then
            echo "github"
            return 0
        fi
    fi

    if [[ -z "$host" ]]; then
        echo "unknown"
        return 1
    fi

    case "$host" in
        github.com|*.github.com)
            echo "github"
            return 0
            ;;
        gitlab.com|*.gitlab.com|*gitlab*)
            echo "gitlab"
            return 0
            ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

PLATFORM=$(detect)
echo "$PLATFORM"
