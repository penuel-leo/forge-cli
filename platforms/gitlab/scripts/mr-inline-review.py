#!/usr/bin/env python3
"""
mr-inline-review.py — Post inline diff comments on GitLab merge requests.

Uses JSON body for the REST API to ensure inline positioning works correctly,
avoiding the silent fallback to general comments that occurs with form-encoded
position fields.

Usage:
  python3 mr-inline-review.py \\
    --project "group/project" --mr 42 \\
    --file "src/main.py" --line 15 --body "Add error handling here."

  python3 mr-inline-review.py \\
    --project "group/project" --mr 42 --batch comments.json

Batch file format:
  [{"file": "path/to/file.py", "line": 10, "body": "Comment text"}]

Environment:
  GITLAB_TOKEN   Personal access token with api scope (or via glab auth)
  GITLAB_HOST    GitLab host URL (default: https://gitlab.com)
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
PROJECT_RE = re.compile(r'^[\w.\-]+(/[\w.\-]+)+$')
FILE_RE = re.compile(r'^[^\x00\n\r]+$')


def _ssl_ctx():
    return ssl.create_default_context()


def _get_token(host):
    token = os.environ.get("GITLAB_TOKEN", "").strip()
    if token:
        _check_token(token)
        return token

    hostname = urllib.parse.urlparse(host).hostname or "gitlab.com"
    try:
        r = subprocess.run(
            ["glab", "config", "get", "token", "--host", hostname],
            capture_output=True, text=True, timeout=10,
        )
        if r.returncode == 0 and r.stdout.strip():
            token = r.stdout.strip()
            _check_token(token)
            return token
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    print("ERROR: No token found. Set GITLAB_TOKEN or run: glab auth login", file=sys.stderr)
    sys.exit(1)


def _check_token(t):
    if not t or len(t) < 10 or re.search(r'\s', t):
        print("ERROR: Token looks invalid (too short or has whitespace).", file=sys.stderr)
        sys.exit(1)


def _require_https(host):
    scheme = urllib.parse.urlparse(host).scheme
    if scheme != "https":
        print(f"ERROR: Host must use HTTPS (got {scheme}://). Tokens must not travel over HTTP.", file=sys.stderr)
        sys.exit(1)
    return host.rstrip("/")


def _check_project(p):
    if not PROJECT_RE.match(p):
        print(f"ERROR: Invalid project path: '{p}'. Expected: group/project", file=sys.stderr)
        sys.exit(1)
    return p


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


def _api_json(token, url):
    req = urllib.request.Request(url, headers={"PRIVATE-TOKEN": token})
    with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
        return json.loads(resp.read())


def _get_shas(token, host, project_enc, mr_iid):
    url = f"{host}/api/v4/projects/{project_enc}/merge_requests/{mr_iid}/versions"
    versions = _api_json(token, url)
    if not versions:
        raise ValueError(f"No diff versions found for MR !{mr_iid}")
    v = versions[0]
    return {
        "head_sha": v["head_commit_sha"],
        "start_sha": v["start_commit_sha"],
        "base_sha": v["base_commit_sha"],
    }


def _post_comment(token, host, project_enc, mr_iid, shas, filepath, line, body):
    url = f"{host}/api/v4/projects/{project_enc}/merge_requests/{mr_iid}/discussions"
    payload = {
        "body": body,
        "position": {
            "base_sha": shas["base_sha"],
            "start_sha": shas["start_sha"],
            "head_sha": shas["head_sha"],
            "position_type": "text",
            "new_path": filepath,
            "old_path": filepath,
            "new_line": line,
            "old_line": None,
        },
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, method="POST",
        headers={"PRIVATE-TOKEN": token, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
            result = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {err[:500]}")

    note = result.get("notes", [{}])[0]
    return result.get("id"), note.get("position") is not None


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
    ap = argparse.ArgumentParser(description="Post inline diff comments on GitLab MRs.")
    ap.add_argument("--project", required=True, help="Project path (group/project)")
    ap.add_argument("--mr", required=True, type=int, help="MR IID")
    ap.add_argument("--host", default=os.environ.get("GITLAB_HOST", "https://gitlab.com"),
                     help="GitLab host (default: GITLAB_HOST or https://gitlab.com)")
    ap.add_argument("--file", help="File path in repo")
    ap.add_argument("--line", type=int, help="Line number in new file")
    ap.add_argument("--body", help="Comment text")
    ap.add_argument("--batch", help="Path to JSON batch file")
    args = ap.parse_args()

    if not args.batch and not (args.file and args.line and args.body):
        ap.error("Provide --batch or all of --file, --line, --body")

    host = _require_https(args.host)
    project = _check_project(args.project)
    project_enc = urllib.parse.quote(project, safe="")

    if args.batch:
        comments = _load_batch(args.batch)
    else:
        comments = [{
            "file": _check_file(args.file),
            "line": _check_line(args.line),
            "body": _check_body(args.body),
        }]

    token = _get_token(host)

    print(f"Fetching diff versions for MR !{args.mr}...")
    try:
        shas = _get_shas(token, host, project_enc, args.mr)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print(f"  head: {shas['head_sha'][:12]}...")

    ok_inline = 0
    ok_general = 0
    errors = 0

    for c in comments:
        print(f"\n  {c['file']}:{c['line']} — {c['body'][:60]}{'...' if len(c['body']) > 60 else ''}")
        try:
            disc_id, is_inline = _post_comment(
                token, host, project_enc, args.mr, shas,
                c["file"], c["line"], c["body"],
            )
            if is_inline:
                print(f"    INLINE | discussion={disc_id}")
                ok_inline += 1
            else:
                print(f"    GENERAL (position rejected) | discussion={disc_id}")
                ok_general += 1
        except Exception as e:
            print(f"    FAILED: {e}", file=sys.stderr)
            errors += 1

    print(f"\nDone: {ok_inline} inline, {ok_general} general, {errors} failed")
    if ok_general:
        print(
            "\nNote: Some comments posted as general (non-inline) because the line number\n"
            "does not correspond to an added (+) line in the diff."
        )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
