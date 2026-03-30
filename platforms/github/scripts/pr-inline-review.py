#!/usr/bin/env python3
"""
pr-inline-review.py — Post inline review comments on GitHub pull requests.

Uses the GitHub REST API to create a pull request review with inline comments,
ensuring comments are placed at the correct diff positions.

Usage:
  python3 pr-inline-review.py \\
    --repo "owner/repo" --pr 42 \\
    --file "src/main.py" --line 15 --body "Add error handling here."

  python3 pr-inline-review.py \\
    --repo "owner/repo" --pr 42 --batch comments.json

Batch file format:
  [{"file": "path/to/file.py", "line": 10, "body": "Comment text"}]

Environment:
  GITHUB_TOKEN   Personal access token with repo scope (or via gh auth)
  GITHUB_HOST    GitHub host URL (default: https://api.github.com)
"""

import argparse
import json
import os
import re
import ssl
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

BODY_MAX_LEN = 10_000
BATCH_MAX_COUNT = 100
BATCH_MAX_BYTES = 1_048_576
REPO_RE = re.compile(r'^[\w.\-]+/[\w.\-]+$')
FILE_RE = re.compile(r'^[^\x00\n\r]+$')


def _ssl_ctx():
    return ssl.create_default_context()


def _get_token():
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        _check_token(token)
        return token

    try:
        r = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True, text=True, timeout=10,
        )
        if r.returncode == 0 and r.stdout.strip():
            token = r.stdout.strip()
            _check_token(token)
            return token
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    print("ERROR: No token found. Set GITHUB_TOKEN or run: gh auth login", file=sys.stderr)
    sys.exit(1)


def _check_token(t):
    if not t or len(t) < 10 or re.search(r'\s', t):
        print("ERROR: Token looks invalid (too short or has whitespace).", file=sys.stderr)
        sys.exit(1)


def _api_url(host):
    if host and host != "https://api.github.com":
        return f"{host.rstrip('/')}/api/v3"
    return "https://api.github.com"


def _check_repo(r):
    if not REPO_RE.match(r):
        print(f"ERROR: Invalid repo path: '{r}'. Expected: owner/repo", file=sys.stderr)
        sys.exit(1)
    return r


def _check_file(f):
    if not f or not FILE_RE.match(f):
        print(f"ERROR: Invalid file path: {repr(f)}", file=sys.stderr)
        sys.exit(1)
    return f


def _check_line(n):
    if not isinstance(n, int) or n < 1:
        print(f"ERROR: Line must be a positive integer (got {n!r}).", file=sys.stderr)
        sys.exit(1)
    return n


def _check_body(b):
    b = b.strip()
    if not b:
        print("ERROR: Comment body is empty.", file=sys.stderr)
        sys.exit(1)
    if len(b) > BODY_MAX_LEN:
        print(f"WARNING: Body truncated from {len(b)} to {BODY_MAX_LEN} chars.", file=sys.stderr)
        b = b[:BODY_MAX_LEN]
    return b


def _get_head_sha(token, api_base, repo, pr_num):
    url = f"{api_base}/repos/{repo}/pulls/{pr_num}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
    })
    with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
        data = json.loads(resp.read())
    return data["head"]["sha"]


def _post_review(token, api_base, repo, pr_num, head_sha, comments):
    url = f"{api_base}/repos/{repo}/pulls/{pr_num}/reviews"
    payload = {
        "commit_id": head_sha,
        "body": f"Inline review ({len(comments)} comment{'s' if len(comments) != 1 else ''})",
        "event": "COMMENT",
        "comments": [
            {
                "path": c["file"],
                "line": c["line"],
                "body": c["body"],
            }
            for c in comments
        ],
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
            result = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {err[:500]}")

    return result.get("id"), len(result.get("comments", []))


def _load_batch(path):
    sz = os.path.getsize(path)
    if sz > BATCH_MAX_BYTES:
        print(f"ERROR: Batch file too large ({sz} bytes, max {BATCH_MAX_BYTES}).", file=sys.stderr)
        sys.exit(1)
    with open(path) as f:
        items = json.load(f)
    if not isinstance(items, list):
        print("ERROR: Batch file must be a JSON array.", file=sys.stderr)
        sys.exit(1)
    if len(items) > BATCH_MAX_COUNT:
        print(f"ERROR: Too many comments ({len(items)}, max {BATCH_MAX_COUNT}).", file=sys.stderr)
        sys.exit(1)
    out = []
    for i, c in enumerate(items):
        if not isinstance(c, dict) or not all(k in c for k in ("file", "line", "body")):
            print(f"ERROR: Batch entry {i} missing file/line/body.", file=sys.stderr)
            sys.exit(1)
        out.append({
            "file": _check_file(c["file"]),
            "line": _check_line(int(c["line"])),
            "body": _check_body(c["body"]),
        })
    return out


def main():
    ap = argparse.ArgumentParser(description="Post inline review comments on GitHub PRs.")
    ap.add_argument("--repo", required=True, help="Repository (owner/repo)")
    ap.add_argument("--pr", required=True, type=int, help="PR number")
    ap.add_argument("--host", default=os.environ.get("GITHUB_HOST", "https://api.github.com"),
                     help="GitHub API host (default: GITHUB_HOST or https://api.github.com)")
    ap.add_argument("--file", help="File path in repo")
    ap.add_argument("--line", type=int, help="Line number in new file")
    ap.add_argument("--body", help="Comment text")
    ap.add_argument("--batch", help="Path to JSON batch file")
    args = ap.parse_args()

    if not args.batch and not (args.file and args.line and args.body):
        ap.error("Provide --batch or all of --file, --line, --body")

    api_base = _api_url(args.host)
    repo = _check_repo(args.repo)

    if args.batch:
        comments = _load_batch(args.batch)
    else:
        comments = [{
            "file": _check_file(args.file),
            "line": _check_line(args.line),
            "body": _check_body(args.body),
        }]

    token = _get_token()

    print(f"Fetching PR #{args.pr} head SHA...")
    try:
        head_sha = _get_head_sha(token, api_base, repo, args.pr)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print(f"  head: {head_sha[:12]}...")

    print(f"\nPosting review with {len(comments)} comment(s)...")
    try:
        review_id, comment_count = _post_review(
            token, api_base, repo, args.pr, head_sha, comments
        )
        print(f"  Review #{review_id} created with {comment_count} inline comment(s).")
    except Exception as e:
        print(f"  FAILED: {e}", file=sys.stderr)
        return 1

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
