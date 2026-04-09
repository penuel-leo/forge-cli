#!/usr/bin/env bash
# resolve-token.sh — Resolve the correct token for the detected Git hosting platform.
#
# Outputs the token to stdout. Exits with code 1 if no token can be resolved.
#
# Supports both GitLab and GitHub with platform-specific env var prefixes.
# Detection is automatic from git remote URL, or explicit via --platform / --host.
#
# Resolution order (highest → lowest priority):
#   --token <pat>
#   FORGE_TOKEN env var
#   GITLAB_TOKEN_<PROJECT> / GITHUB_TOKEN_<PROJECT>
#   GITLAB_TOKEN_<WORKSPACE> / GITHUB_TOKEN_<WORKSPACE>
#   GITLAB_TOKEN_<HOST>  (GitLab only)
#   GITLAB_TOKEN / GITHUB_TOKEN
#   glab config / gh auth token
#
# Usage:
#   ./resolve-token.sh [--token <pat>] [--platform gitlab|github] [--host <hostname>]
#
# Examples:
#   ./resolve-token.sh --token glpat-xxx --platform gitlab
#   ./resolve-token.sh --platform github --host github.company.com
#   FORGE_TOKEN=glpat-xxx ./resolve-token.sh --platform gitlab
#   ./resolve-token.sh                    # auto-detect from git remote

set -euo pipefail

# ─── Argument parsing ─────────────────────────────────

ARG_TOKEN=""
ARG_PLATFORM=""
ARG_HOST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token)
            ARG_TOKEN="${2:-}"
            [[ -z "$ARG_TOKEN" ]] && { echo "ERROR: --token requires a value" >&2; exit 1; }
            shift 2
            ;;
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
            echo "ERROR: Unknown argument: $1" >&2
            echo "Usage: $0 [--token <pat>] [--platform gitlab|github] [--host <hostname>]" >&2
            exit 1
            ;;
    esac
done

# ─── Helpers ──────────────────────────────────────────

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

detect_platform_from_host() {
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

# ─── Main resolve logic ──────────────────────────────

resolve() {
    # Priority 1: --token argument
    if [[ -n "$ARG_TOKEN" ]]; then
        echo "$ARG_TOKEN"
        return 0
    fi

    # Priority 2: FORGE_TOKEN env var
    if [[ -n "${FORGE_TOKEN:-}" ]]; then
        echo "$FORGE_TOKEN"
        return 0
    fi

    # Determine platform and host context
    local platform="" host="" namespace="" project=""

    if [[ -n "$ARG_PLATFORM" ]]; then
        platform="$ARG_PLATFORM"
        if [[ -n "$ARG_HOST" ]]; then
            host="$ARG_HOST"
        else
            [[ "$platform" == "gitlab" ]] && host="gitlab.com"
            [[ "$platform" == "github" ]] && host="github.com"
        fi
    elif [[ -n "$ARG_HOST" ]]; then
        host="$ARG_HOST"
        platform=$(detect_platform_from_host "$host")
    else
        local parts
        if parts=$(extract_from_remote); then
            read -r host namespace project <<< "$parts"
        fi
        if [[ -n "$host" ]]; then
            platform=$(detect_platform_from_host "$host")
        fi
    fi

    if [[ -z "$platform" || "$platform" == "unknown" ]]; then
        echo "ERROR: Cannot detect platform. Use --platform gitlab|github, or set GITLAB_HOST / GITHUB_HOST, or run inside a git repo." >&2
        return 1
    fi

    local prefix=""
    case "$platform" in
        gitlab) prefix="GITLAB_TOKEN" ;;
        github) prefix="GITHUB_TOKEN" ;;
    esac

    # Priority 3-6: Hierarchical env var resolution
    if resolve_by_hierarchy "$prefix" "$host" "$namespace" "$project" "$platform"; then
        return 0
    fi

    # Priority 7: CLI credential fallback
    if cli_fallback "$platform"; then
        return 0
    fi

    echo "ERROR: No ${platform} token found. Provide --token <pat>, set FORGE_TOKEN or ${prefix}, or run: $([ "$platform" = "gitlab" ] && echo "glab" || echo "gh") auth login" >&2
    return 1
}

resolve
