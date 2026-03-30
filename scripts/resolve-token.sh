#!/usr/bin/env bash
# resolve-token.sh — Resolve the correct token for the detected Git hosting platform.
#
# Outputs the token to stdout. Exits with code 1 if no token can be resolved.
#
# Supports both GitLab and GitHub with platform-specific env var prefixes.
# Detection is automatic from git remote URL.
#
# GitLab resolution: GITLAB_TOKEN_<PROJECT> → GITLAB_TOKEN_<WORKSPACE> → GITLAB_TOKEN_<HOST> → GITLAB_TOKEN → glab config
# GitHub resolution: GITHUB_TOKEN_<PROJECT> → GITHUB_TOKEN_<WORKSPACE> → GITHUB_TOKEN → gh auth token

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

normalize_name() {
    echo "$1" | tr '[:lower:]' '[:upper:]' | sed 's/[-.]/_/g; s/[^A-Z0-9_]//g'
}

extract_from_remote() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null) || return 1

    local host="" namespace="" project=""

    if [[ "$remote_url" =~ ^https?://([^/]+)/(.+)/([^/]+)(\.git)?$ ]]; then
        host="${BASH_REMATCH[1]}"
        namespace="${BASH_REMATCH[2]}"
        project="${BASH_REMATCH[3]%.git}"
    elif [[ "$remote_url" =~ ^git@([^:]+):(.+)/([^/]+)(\.git)?$ ]]; then
        host="${BASH_REMATCH[1]}"
        namespace="${BASH_REMATCH[2]}"
        project="${BASH_REMATCH[3]%.git}"
    else
        return 1
    fi

    echo "$host" "$namespace" "$project"
}

detect_platform() {
    local host="${1:-}"
    if [[ -n "${GITLAB_HOST:-}" ]]; then
        local gl_host="${GITLAB_HOST#https://}"
        gl_host="${gl_host#http://}"
        [[ "$host" == "$gl_host" ]] && echo "gitlab" && return
    fi
    if [[ -n "${GITHUB_HOST:-}" ]]; then
        local gh_host="${GITHUB_HOST#https://}"
        gh_host="${gh_host#http://}"
        [[ "$host" == "$gh_host" ]] && echo "github" && return
    fi
    case "$host" in
        github.com|*.github.com) echo "github" ;;
        gitlab.com|*.gitlab.com|*gitlab*) echo "gitlab" ;;
        *) echo "unknown" ;;
    esac
}

resolve_by_hierarchy() {
    local prefix="$1" host="$2" namespace="$3" project="$4" platform="$5"

    if [[ -n "$project" ]]; then
        local var_name="${prefix}_$(normalize_name "$project")"
        local val="${!var_name:-}"
        [[ -n "$val" ]] && echo "$val" && return 0
    fi

    if [[ -n "$namespace" ]]; then
        local ns_top="${namespace%%/*}"
        local var_name="${prefix}_$(normalize_name "$ns_top")"
        local val="${!var_name:-}"
        [[ -n "$val" ]] && echo "$val" && return 0
    fi

    if [[ "$platform" == "gitlab" && -n "$host" ]]; then
        local effective_host="${GITLAB_HOST:-$host}"
        effective_host="${effective_host#https://}"
        effective_host="${effective_host#http://}"
        local var_name="${prefix}_$(normalize_name "$effective_host")"
        local val="${!var_name:-}"
        [[ -n "$val" ]] && echo "$val" && return 0
    fi

    local global="${!prefix:-}"
    [[ -n "$global" ]] && echo "$global" && return 0

    return 1
}

cli_fallback() {
    local platform="$1"
    local token=""
    case "$platform" in
        gitlab)
            token=$(glab config get token 2>/dev/null) || true
            ;;
        github)
            token=$(gh auth token 2>/dev/null) || true
            ;;
    esac
    [[ -n "$token" ]] && echo "$token" && return 0
    return 1
}

resolve() {
    local parts host="" namespace="" project=""
    if parts=$(extract_from_remote); then
        read -r host namespace project <<< "$parts"
    fi

    local platform
    platform=$(detect_platform "$host")

    local prefix=""
    case "$platform" in
        gitlab) prefix="GITLAB_TOKEN" ;;
        github) prefix="GITHUB_TOKEN" ;;
        *)
            echo "ERROR: Cannot detect platform. Set GITLAB_HOST or GITHUB_HOST." >&2
            return 1
            ;;
    esac

    if resolve_by_hierarchy "$prefix" "$host" "$namespace" "$project" "$platform"; then
        return 0
    fi

    if cli_fallback "$platform"; then
        return 0
    fi

    echo "ERROR: No ${platform} token found. Set ${prefix} or run: $([ "$platform" = "gitlab" ] && echo "glab" || echo "gh") auth login" >&2
    return 1
}

resolve
