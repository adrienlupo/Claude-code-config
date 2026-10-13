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
unasked=${out#*unasked on the session model}; unasked=${unasked%% — outside*}
not "named fable is not flagged unasked"         "$unasked" "eeeeeeee"
not "unnamed agent on its definition's model not flagged" "$unasked" "cccccccc"
ok  "named fable outside run() still listed"     "$out" "eeeeeeee fable-5-1/high"

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

# --- run() dispatch: a session on opus/high whose first agents bypassed run() or ran off their label
S2=22222222-3333-4444-5555-666666666666; A2="$P/$S2/subagents"
mkdir -p "$A2/workflows/wf_run-0" "$A2/workflows/wf_run-1"
turn 2026-09-24T08:59:00.000Z '"high"' claude-opus-5-5 > "$P/$S2.jsonl"
wf() { printf '{"agentType":"workflow-subagent","description":"%s","spawnDepth":1,"model":"%s"}' "$1" "$2"; }
agent "$A2/agent-44444444dddd" 2026-09-24T09:00:00.000Z '"high"' claude-fable-5-1 '{"agentType":"Plan","toolUseId":"toolu_x","description":"Review the build","spawnDepth":1,"model":"fable"}'
agent "$A2/workflows/wf_run-0/agent-55555555eeee" 2026-09-24T09:01:00.000Z '"high"' claude-opus-5-5 "$(wf 'gate opus/xhigh' opus)"
agent "$A2/workflows/wf_run-0/agent-66666666ffff" 2026-09-24T09:02:00.000Z '"high"' claude-opus-5-5 "$(wf 'judge D2' opus)"
agent "$A2/workflows/wf_run-0/agent-77777777aaaa" 2026-09-24T09:03:00.000Z '"low"' claude-sonnet-5-5 "$(wf 'build opus/low' opus)"
agent "$A2/workflows/wf_run-0/agent-88888888bbbb" 2026-09-24T09:04:00.000Z '"high"' claude-fable-5-1 "$(wf 'J1-p1-1 fable/high' fable)"
agent "$A2/workflows/wf_run-1/agent-11111111aaaa" 2026-09-24T09:10:00.000Z '"low"' claude-opus-5-5 "$(wf 'build:D1 opus/low' opus)"
agent "$A2/workflows/wf_run-1/agent-22222222bbbb" 2026-09-24T09:11:00.000Z '"medium"' claude-haiku-5-5 "$(wf 'capture D1 haiku/-' haiku)"
agent "$A2/agent-33333333cccc" 2026-09-24T09:12:00.000Z '"high"' claude-opus-5-5 '{"agentType":"general-purpose","description":"Simplification review","spawnDepth":2}'

out=$(python3 "$V" --projects "$T/projects" --session $S2); rc=$?
ok  "without --check a violation still exits 0"  "rc=$rc" "rc=0"
out=$(python3 "$V" --projects "$T/projects" --session $S2 --check); rc=$?
ok  "--check exits 2 on a violation"             "rc=$rc" "rc=2"
ok  "Agent-tool Fable is outside run()"          "$out" "44444444 fable-5-1/high"
ok  "agent() without run()'s label is outside"   "$out" "wf_run-0/66666666 opus-5-5/high"
ok  "a loosened run()'s fable label is outside"  "$out" "wf_run-0/88888888 fable-5-1/high"
ok  "outside run() counted"                      "$out" "outside run(): 3 ("
ok  "effort ignored is label≠ran"                "$out" "wf_run-0/55555555 opus/xhigh→opus-5-5/high"
ok  "model swapped is label≠ran"                 "$out" "wf_run-0/77777777 opus/low→sonnet-5-5/low"
not "an agent's own agent is out of run()'s reach" "${out#*outside run()}" "33333333"
not "haiku/- matches any effort"                 "${out#*outside run()}" "22222222"
out=$(python3 "$V" --projects "$T/projects" --session $S2 --since 2026-09-24T09:05:00Z --check); rc=$?
ok  "--check passes a run() run"                 "rc=$rc" "rc=0"
ok  "clean run reads none, none, none"           "$out" "outside run(): none — label≠ran: none — fable: none"

# --- each finding alone fails --check; a run() agent under another agentType doesn't
S3=33333333-4444-5555-6666-777777777777; A3="$P/$S3/subagents"; mkdir -p "$A3/workflows/wf_d"
turn 2026-09-24T09:59:00.000Z '"medium"' claude-opus-5-5 > "$P/$S3.jsonl"
agent "$A3/workflows/wf_d/agent-d1d1d1d1" 2026-09-24T10:00:00.000Z '"xhigh"' claude-opus-5-5 "$(wf 'build opus/low' opus)"
out=$(python3 "$V" --projects "$T/projects" --session $S3 --check); rc=$?
ok  "label≠ran alone exits 2"                    "rc=$rc $out" "rc=2"
rm "$A3/workflows/wf_d/agent-d1d1d1d1".*
agent "$A3/workflows/wf_d/agent-e1e1e1e1" 2026-09-24T10:01:00.000Z '"low"' claude-opus-5-5 '{"agentType":"Explore","description":"judge D1 opus/low","spawnDepth":1,"model":"opus"}'
agent "$A3/agent-f1f1f1f1" 2026-09-24T10:02:00.000Z '"high"' claude-fable-5-1 '{"agentType":"general-purpose","description":"Sub-judge","spawnDepth":2,"model":"fable"}'
out=$(python3 "$V" --projects "$T/projects" --session $S3 --check); rc=$?
not "run() agent of another agentType is inside" "${out#*outside run()}" "e1e1e1e1"
ok  "nested Fable is caught"                     "$out" "fable: 1 (f1f1f1f1 fable-5-1/high)"
ok  "nested Fable alone exits 2"                 "rc=$rc" "rc=2"
rm "$A3/agent-f1f1f1f1".*
agent "$A3/agent-a2a2a2a2" 2026-09-24T10:03:00.000Z '"high"' claude-opus-5-5 '{"agentType":"general-purpose","toolUseId":"toolu_y","description":"Review opus/high","spawnDepth":1,"model":"opus"}'
out=$(python3 "$V" --projects "$T/projects" --session $S3 --check); rc=$?
ok  "Agent-tool agent with a run()-like label is outside" "rc=$rc $out" "rc=2"
ok  "  ...named"                                 "$out" "a2a2a2a2 opus-5-5/high"

# --- dispatches with no agent transcript: nothing to check is no pass
S4=44444444-5555-6666-7777-888888888888
{ turn 2026-09-24T10:59:00.000Z '"medium"' claude-opus-5-5
  printf '{"type":"assistant","timestamp":"2026-09-24T11:00:00.000Z","message":{"model":"claude-opus-5-5","content":[{"type":"tool_use","id":"toolu_wf1","name":"Workflow","input":{}}]}}\n'
} > "$P/$S4.jsonl"
out=$(python3 "$V" --projects "$T/projects" --session $S4); rc=$?
ok  "without --check, still a line"             "rc=$rc $out" "rc=0 ventilation: 0 agents"
out=$(python3 "$V" --projects "$T/projects" --session $S4 --check 2>&1); rc=$?
ok  "dispatched, no transcripts: --check exits 1" "rc=$rc $out" "rc=1"
ok  "  ...saying why"                            "$out" "1 dispatches and no agent transcript"
out=$(python3 "$V" --projects "$T/projects" --session $S4 --check --since 2026-09-24T11:30:00Z 2>&1); rc=$?
ok  "a dispatch before --since doesn't count"    "rc=$rc" "rc=0"
printf '{"type":"user","timestamp":"2026-09-24T11:00:01.000Z","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_wf1","is_error":true,"content":"bad script"}]}}\n' >> "$P/$S4.jsonl"
out=$(python3 "$V" --projects "$T/projects" --session $S4 --check 2>&1); rc=$?
ok  "a launch that errored doesn't count"        "rc=$rc" "rc=0"

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
