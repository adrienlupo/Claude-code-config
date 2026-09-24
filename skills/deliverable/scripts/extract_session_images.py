#!/usr/bin/env python3
"""Extract images pasted into a Claude Code session back out to real files.

A pasted image is stored in the session transcript as a base64 block, so it can be
recovered verbatim - no transcription, no lossy description.

Usage:
    python3 extract_session_images.py <output-dir>                     # this session
    python3 extract_session_images.py <transcript.jsonl> <output-dir>

With no transcript given, it takes the newest transcript of the project directory
for the cwd, then for the repo root. The directory name replaces every
non-alphanumeric character of the path with a dash, not only slashes.
"""
from __future__ import annotations

import base64
import json
import os
import pathlib
import re
import subprocess
import sys

EXT = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif"}


def find_transcript() -> pathlib.Path | None:
    projects = pathlib.Path(os.environ.get("CLAUDE_CONFIG_DIR", pathlib.Path.home() / ".claude")) / "projects"
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
    for path in (os.getcwd(), root):
        if not path:
            continue
        found = sorted((projects / re.sub(r"[^a-zA-Z0-9]", "-", path)).glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
        if found:
            return found[-1]
    return None  # never fall back to the newest transcript of another project


def main() -> int:
    if len(sys.argv) == 2:
        src, out = find_transcript(), pathlib.Path(sys.argv[1])
        if src is None:
            print(f"no transcript found for {os.getcwd()}", file=sys.stderr)
            return 1
    elif len(sys.argv) == 3:
        src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    else:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    print(f"transcript: {src}", file=sys.stderr)
    out.mkdir(parents=True, exist_ok=True)

    n = 0
    # streamed, not slurped - transcripts carrying images run to tens of MB
    for i, line in enumerate(src.open(errors="replace")):
        # cheap prefilter - transcripts get large
        if '"type":"image"' not in line and '"type": "image"' not in line:
            continue
        try:
            rec = json.loads(line)
        except Exception:
            continue
        msg = rec.get("message") or {}
        # user messages only: skip images returned by Read or a screenshot tool
        if rec.get("type") != "user" or not isinstance(msg.get("content"), list):
            continue
        for blk in msg["content"]:
            if not (isinstance(blk, dict) and blk.get("type") == "image"):
                continue
            source = blk.get("source") or {}
            if source.get("type") != "base64":
                continue
            n += 1
            path = out / f"pasted-{n:02d}.{EXT.get(source.get('media_type'), 'bin')}"
            path.write_bytes(base64.b64decode(source["data"]))
            print(f"{path}  ({path.stat().st_size} bytes, transcript line {i + 1})")

    print(f"--- {n} image(s) extracted ---")
    if not n:
        # usually the transcript has not flushed yet, not that nothing was shared
        print("no images found - retry before concluding none was shared", file=sys.stderr)
    return 0 if n else 1


if __name__ == "__main__":
    raise SystemExit(main())
