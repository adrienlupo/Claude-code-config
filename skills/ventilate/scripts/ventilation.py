#!/usr/bin/env python3
"""Print the `ventilation:` line: what every subagent of a session actually ran on.

Usage:
    ventilation.py [--session ID]... [--since TIME] [--projects DIR]

--session  defaults to $CLAUDE_CODE_SESSION_ID. Repeat it for a run that spans
           a /clear or a resume.
--since    counts only agents started at or after TIME: ISO 8601 UTC
           (2026-09-24T08:06:00Z) or a local stamp like implement-loop's tag,
           20260924-100600.
--projects defaults to ~/.claude/projects.

The session is found by id, never by encoding the cwd, and every agent-*.jsonl
under <session>/subagents counts, workflow agents included
(subagents/workflows/wf_*/). One agent is one entry, keyed by the model and
effort its transcript records. "unasked" lists the agents that were given no
model (their .meta.json has none) and ran on a model the session itself used:
the silent inheritance this line exists to catch.

Exit 1 when a session can't be found - never an empty line that reads as clean.
"""
import argparse
import collections
import datetime
import json
import os
import pathlib
import re
import sys


def short(model):
    return re.sub(r"-\d{8}$", "", model.removeprefix("claude-"))


def parse_time(s):
    if re.fullmatch(r"\d{8}-\d{6}", s):
        local = datetime.datetime.strptime(s, "%Y%m%d-%H%M%S").astimezone()
        return local.astimezone(datetime.timezone.utc)
    t = datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
    return (t if t.tzinfo else t.astimezone()).astimezone(datetime.timezone.utc)


def records(path):
    with open(path, errors="replace") as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def assistant_turns(path):
    """(model, effort) of every real assistant turn; harness-made <synthetic> ones skipped."""
    for r in records(path):
        m = r.get("message") if r.get("type") == "assistant" else None
        if isinstance(m, dict) and m.get("model") and m["model"] != "<synthetic>":
            yield short(m["model"]), r.get("effort")


def first_time(path):
    for r in records(path):
        if r.get("timestamp"):
            return parse_time(r["timestamp"])
    return None


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--session", action="append")
    ap.add_argument("--since")
    ap.add_argument("--projects", default=os.path.expanduser("~/.claude/projects"))
    ap.add_argument("-h", "--help", action="store_true")
    a = ap.parse_args()
    if a.help:
        print(__doc__.strip())
        return 0
    sessions = a.session or [os.environ.get("CLAUDE_CODE_SESSION_ID", "")]
    if not all(sessions):
        print("ventilation.py: no session id - pass --session or run from a Claude Code Bash tool", file=sys.stderr)
        return 1
    try:
        since = parse_time(a.since) if a.since else None
    except ValueError:
        print(f"ventilation.py: --since {a.since!r} is neither ISO 8601 nor YYYYmmdd-HHMMSS", file=sys.stderr)
        return 1
    projects = pathlib.Path(a.projects)

    session_models, agents = set(), []
    for sid in sessions:
        dirs = [d for d in projects.glob(f"*/{sid}") if d.is_dir()]
        mains = list(projects.glob(f"*/{sid}.jsonl"))
        if not dirs and not mains:
            print(f"ventilation.py: session {sid} not found under {projects}", file=sys.stderr)
            return 1
        for m in mains:
            session_models |= {model for model, _ in assistant_turns(m)}
        for d in dirs:
            agents += sorted((d / "subagents").rglob("agent-*.jsonl"))

    tally, unasked, total = collections.Counter(), [], 0
    for path in agents:
        if since and (first_time(path) or since) < since:
            continue
        total += 1
        turns = collections.Counter(assistant_turns(path))
        if not turns:
            tally["no-reply"] += 1
            continue
        (model, effort), _ = turns.most_common(1)[0]
        tally[f"{model}/{effort}" if effort else model] += 1
        meta = path.with_name(path.name[: -len(".jsonl")] + ".meta.json")
        asked = json.loads(meta.read_text()).get("model") if meta.exists() else None
        if not asked and model in session_models:
            where = path.parent.name if path.parent.name.startswith("wf_") else ""
            unasked.append(f"{where + '/' if where else ''}{path.stem[6:14]}")

    counts = " · ".join(f"{k} {n}" for k, n in tally.most_common()) or "none"
    on = ", ".join(sorted(session_models)) or "?"
    flag = f"{len(unasked)} ({' '.join(unasked)})" if unasked else "none"
    print(f"ventilation: {total} agents — {counts} — unasked on the session model ({on}): {flag}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
