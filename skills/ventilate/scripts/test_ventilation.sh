#!/bin/sh
# Tests for ventilation.py: a synthetic session (always), then real transcripts when present.
set -u
V="$(cd "$(dirname "$0")" && pwd)/ventilation.py"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fails=0
ok()  { case "$2" in *"$3"*) echo "ok   $1";; *) echo "FAIL $1: wanted '$3' in: $2"; fails=$((fails+1));; esac; }
not() { case "$2" in *"$3"*) echo "FAIL $1: did not want '$3' in: $2"; fails=$((fails+1));; *) echo "ok   $1";; esac; }

# --- synthetic session: project dir encoded from a path with a dot, session on Fable
P="$T/projects/-Users-me--claude"; S=11111111-2222-3333-4444-555555555555; A="$P/$S/subagents"
mkdir -p "$A/workflows/wf_test-123"
turn() { printf '{"type":"assistant","timestamp":"%s","effort":%s,"message":{"model":"%s"}}\n' "$1" "$2" "$3"; }
turn 2026-09-24T07:00:00.000Z '"xhigh"' claude-fable-5-1 > "$P/$S.jsonl"
agent() { f="$1"; shift; : > "$f.jsonl"; while [ $# -gt 2 ]; do turn "$1" "$2" "$3" >> "$f.jsonl"; shift 3; done; printf '%s\n' "$1" > "$f.meta.json"; }
agent "$A/agent-aaaaaaaa1111" 2026-09-24T08:00:00.000Z '"low"' claude-opus-5-5 2026-09-24T08:01:00.000Z '"low"' claude-opus-5-5 '{"model":"opus"}'
agent "$A/workflows/wf_test-123/agent-bbbbbbbb2222" 2026-09-24T08:02:00.000Z '"xhigh"' claude-fable-5-1 '{"agentType":"workflow-subagent","model":null}'
agent "$A/agent-cccccccc3333" 2026-09-24T08:03:00.000Z null claude-haiku-4-5-20251001 '{"agentType":"claude-code-guide","model":null}'
agent "$A/agent-dddddddd4444" 2026-09-24T08:04:00.000Z null '<synthetic>' '{"model":"sonnet"}'
agent "$A/agent-eeeeeeee5555" 2026-09-24T08:05:00.000Z '"high"' claude-fable-5-1 '{"model":"fable"}'
agent "$A/agent-ffffffff6666" 2026-09-24T06:00:00.000Z '"low"' claude-sonnet-5 '{"model":"sonnet"}'

mkdir -p "$T/a_b.c d"; cd "$T/a_b.c d"   # a cwd the old sed encoding got wrong
out=$(python3 "$V" --projects "$T/projects" --session $S)
ok  "all agents counted, workflow ones included" "$out" "ventilation: 6 agents"
ok  "keyed by model and effort"                  "$out" "opus-5-5/low 1"
ok  "no effort recorded -> bare model"           "$out" "haiku-4-5 1"
ok  "synthetic-only agent is no-reply"           "$out" "no-reply 1"
not "synthetic never shows as a model"           "$out" "synthetic"
ok  "unnamed agent on the session model flagged" "$out" "(fable-5-1): 1 (wf_test-123/bbbbbbbb)"
not "named fable is not flagged"                 "$out" "eeeeeeee"
not "unnamed agent on its definition's model not flagged" "$out" "cccccccc"

out=$(python3 "$V" --projects "$T/projects" --session $S --since 2026-09-24T07:30:00Z)
ok  "--since drops earlier agents"               "$out" "ventilation: 5 agents"
not "--since drops earlier agents (model gone)"  "$out" "sonnet-5"
stamp=$(python3 -c 'import datetime as d; print(d.datetime(2026,9,24,7,30,tzinfo=d.timezone.utc).astimezone().strftime("%Y%m%d-%H%M%S"))')
out2=$(python3 "$V" --projects "$T/projects" --session $S --since "$stamp")
ok  "local tag stamp == ISO UTC"                 "$out2" "$out"

out=$(python3 "$V" --projects "$T/projects" --session $S --since "")
ok  "empty --since (no tag in the log) = whole session" "$out" "ventilation: 6 agents"
out=$(python3 "$V" --projects "$T/projects" --session $S --since yesterday 2>&1); rc=$?
ok  "bad --since fails loudly" "$out rc=$rc" "neither ISO"
ok  "bad --since exits 1"      "rc=$rc" "rc=1"

out=$(CLAUDE_CODE_SESSION_ID=$S python3 "$V" --projects "$T/projects")
ok  "session from CLAUDE_CODE_SESSION_ID"        "$out" "ventilation: 6 agents"

out=$(python3 "$V" --projects "$T/projects" --session nope 2>&1); rc=$?
ok  "unknown session fails loudly"               "$out rc=$rc" "not found"
ok  "unknown session exits 1"                    "rc=$rc" "rc=1"

# --- real transcripts, when this machine still has them
R=~/.claude/projects/-Users-qraft-code-empty4Claude/4b4640b3-4158-4cb8-9d74-a1e9b4755ae4
if [ -d "$R" ]; then   # Agent-tool subagents: Opus and Fable named, one claude-code-guide on its own Haiku
  out=$(python3 "$V" --session 4b4640b3-4158-4cb8-9d74-a1e9b4755ae4)
  ok  "real: Fable judges counted" "$out" "fable-5-1/xhigh "
  ok  "real: guide agent on Haiku" "$out" "haiku-4-5 "
  ok  "real: nothing unasked"      "$out" "(opus-5-5): none"
fi
W=~/.claude/projects/-Users-qraft-code-wisetax-app/c27659ae-d088-4ec2-a0de-930e2438739b
if [ -d "$W" ]; then   # a workflow-only session: every agent sits under subagents/workflows/wf_*/
  n=$(find "$W/subagents" -name 'agent-*.jsonl' | wc -l | tr -d ' ')
  out=$(python3 "$V" --session c27659ae-d088-4ec2-a0de-930e2438739b)
  ok  "real: every workflow agent counted" "$out" "ventilation: $n agents"
fi

[ $fails = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
