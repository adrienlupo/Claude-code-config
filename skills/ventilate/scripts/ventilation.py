#!/usr/bin/env python3
"""Print the `ventilation:` line: what every subagent of a session actually ran on.

Usage:
    ventilation.py [--session ID]... [--since TIME] [--projects DIR] [--check]

--session  defaults to $CLAUDE_CODE_SESSION_ID. Repeat it for a run that spans
           a /clear or a resume.
--since    counts only agents started at or after TIME: ISO 8601 UTC
           (2026-09-24T08:06:00Z) or a local stamp like
           20260924-100600.
--projects defaults to ~/.claude/projects.
--check    exit 2 when "outside run()", "label≠ran" or "fable" is not none;
           exit 1 when the session dispatched agents but none of their
           transcripts is here - a teleported session keeps only its own.

The session is found by id, never by encoding the cwd, and every agent-*.jsonl
under <session>/subagents counts, workflow agents (workflows/wf_*/) included -
one entry each, keyed by the model and effort its transcript records.

Of the agents the session dispatched itself (spawnDepth <= 1), "outside run()"
lists each not under workflows/wf_*/ with run()'s label "<role> <model>/<effort|->":
an Agent-tool subagent or a bare agent() call, on the session's effort and free
to be Fable. "label≠ran" lists each whose label names a model or effort its
transcript did not run on. "fable" lists every agent that ran on Fable, at any
depth - an agent's own agents are out of run()'s reach.

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


LABEL = re.compile(r"\b(haiku|sonnet|opus)/(\S+)$")
DISPATCH = {"Workflow", "Agent", "Task"}


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


def dispatches(path, since):
    """Workflow and Agent tool calls the session made since `since`, launches that errored left out."""
    calls, errored = set(), set()
    for r in records(path):
        m = r.get("message")
        if not isinstance(m, dict) or not isinstance(m.get("content"), list):
            continue
        for b in m["content"]:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "tool_use" and b.get("name") in DISPATCH:
                if not since or not r.get("timestamp") or parse_time(r["timestamp"]) >= since:
                    calls.add(b.get("id"))
            elif b.get("type") == "tool_result" and b.get("is_error"):
                errored.add(b.get("tool_use_id"))
    return len(calls - errored)


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
    ap.add_argument("--check", action="store_true")
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

    agents, launched = [], 0
    for sid in sessions:
        dirs = [d for d in projects.glob(f"*/{sid}") if d.is_dir()]
        mains = list(projects.glob(f"*/{sid}.jsonl"))
        if not dirs and not mains:
            print(f"ventilation.py: session {sid} not found under {projects}", file=sys.stderr)
            return 1
        for m in mains:
            launched += dispatches(m, since)
        for d in dirs:
            agents += sorted((d / "subagents").rglob("agent-*.jsonl"))

    tally, outside, drift, fable, total = collections.Counter(), [], [], [], 0
    for path in agents:
        if since and (first_time(path) or since) < since:
            continue
        total += 1
        turns = collections.Counter(assistant_turns(path))
        if not turns:
            tally["no-reply"] += 1
            continue
        (model, effort), _ = turns.most_common(1)[0]
        ran = f"{model}/{effort}" if effort else model
        tally[ran] += 1
        meta_path = path.with_name(path.name[: -len(".jsonl")] + ".meta.json")
        meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
        where = path.parent.name if path.parent.name.startswith("wf_") else ""
        name = f"{where + '/' if where else ''}{path.stem[6:14]}"
        if model.startswith("fable"):
            fable.append(f"{name} {ran}")
        if (meta.get("spawnDepth") or 1) > 1:
            continue
        label = LABEL.search(meta.get("description") or "")
        if not where or not label:
            outside.append(f"{name} {ran}")
        elif not model.startswith(label[1]) or (effort and label[2] not in ("-", effort)):
            drift.append(f"{name} {label[1]}/{label[2]}→{ran}")

    def listed(xs):
        return f"{len(xs)} ({', '.join(xs)})" if xs else "none"

    counts = " · ".join(f"{k} {n}" for k, n in tally.most_common()) or "none"
    print(f"ventilation: {total} agents — {counts} — outside run(): {listed(outside)}"
          f" — label≠ran: {listed(drift)} — fable: {listed(fable)}")
    if a.check and launched and not total:
        print(f"ventilation.py: {launched} dispatches and no agent transcript - nothing to check, so no pass", file=sys.stderr)
        return 1
    return 2 if a.check and (outside or drift or fable) else 0


if __name__ == "__main__":
    sys.exit(main())
