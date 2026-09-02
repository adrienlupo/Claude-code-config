#!/usr/bin/env python3
"""Extract images pasted into a Claude Code session back out to real files.

A pasted image is stored in the session transcript as a base64 block, so it can be
recovered verbatim - no transcription, no lossy description.

Usage:
    python3 extract_session_images.py <transcript.jsonl> <output-dir>

Locate the transcript with the recipe in ../SKILL.md (section "Images"): the
project directory name replaces every non-alphanumeric character with a dash,
not only slashes, and falls back from the cwd to the repo root.
"""
import base64
import json
import pathlib
import sys

EXT = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif"}


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    src = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
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
