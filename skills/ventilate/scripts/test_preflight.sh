#!/bin/sh
# Tests for preflight.py, against run() exactly as SKILL.md prints it.
set -u
D="$(cd "$(dirname "$0")" && pwd)"; F="$D/preflight.py"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fails=0
ok()  { case "$2" in *"$3"*) echo "ok   $1";; *) echo "FAIL $1: wanted '$3' in: $2"; fails=$((fails+1));; esac; }
not() { case "$2" in *"$3"*) echo "FAIL $1: did not want '$3' in: $2"; fails=$((fails+1));; *) echo "ok   $1";; esac; }
BLOCK=$(awk '/^```js$/{f=1;next} /^```$/{if(f)exit} f' "$D/../SKILL.md")
script() { { printf "export const meta = { name: 't', description: 'every agent goes through run()' }\n"; printf '%s\n' "$BLOCK"; printf '%s\n' "$@"; } > "$T/s.js"; }
check() { out=$(python3 "$F" "$T/s.js" 2>&1); rc=$?; }

# prompt text, comments and schemas that name agents and models are text, not dispatch
script "// every agent() call goes through run()" \
       "const B = (b) => \`Build it. \${b && b.gap ? \`Close this gap from the agent(s) before you:\\n\${b.gap}\` : ''} Never agent(x).\`" \
       "await run('build', B(args.b), { model: 'opus', effort: 'low' })" \
       "await run('judge', 'List the agent(s) that touched D3; grep -rn \"fable\" skills/; keep model: \\'gpt-4o\\'', { model: 'opus', effort: 'medium', schema: { enum: ['opus', 'fable'] } })" \
       "await run('capture', 'p', { model: args.write ? 'sonnet' : 'haiku', ...(args.write && { effort: 'medium' }) })"
check
ok  "run() as printed passes, prompt text and comments aside" "rc=$rc $out" "rc=0 preflight:"

printf '%s' "$(cat "$T/s.js")" | sed 's/$/   \r/' > "$T/crlf.js"; mv "$T/crlf.js" "$T/s.js"
check
ok  "CRLF and trailing spaces pass"            "rc=$rc" "rc=0"

# the 2026-10-12 cloud run: the guard loosened for the brief's Fable judges
script "const judge = (r, p) => run(r, p, { model: 'fable', effort: 'high' })"
sed "s/if (!\['haiku', 'sonnet', 'opus'\].includes(model))/if (!(['haiku', 'sonnet', 'opus'].includes(model) || model === 'fable'))/" "$T/s.js" > "$T/s2.js"; mv "$T/s2.js" "$T/s.js"
check
ok  "a loosened run() is refused"              "rc=$rc" "rc=2"
ok  "  ...named as a changed run()"            "$out" "differs from ventilate's"
script "const run2 = run"; sed 's/Do only the task below/Do the task below/' "$T/s.js" > "$T/s2.js"; mv "$T/s2.js" "$T/s.js"
check
ok  "an edited GUARD is refused"               "$out" "differs from ventilate's"

for bypass in "await agent('p', { model: 'opus', effort: 'low' })" "await agent ('p', {})" "await agent?.('p', {})" \
              "const spawn = agent; await spawn('p', {})" "const go = (p, o) => globalThis['agent'](p, o); const agent2 = agent"; do
  script "$bypass"; check
  ok  "refused: $bypass"                       "rc=$rc $out" "rc=2"
done
ok  "  ...named"                               "$out" "agent named outside run()"

script "await workflow({ scriptPath: '/tmp/judges.js' })"
check
ok  "a nested workflow() is refused"           "rc=$rc $out" "rc=2"
ok  "  ...named"                               "$out" "nested workflow()"

out=$(python3 "$F" "$T/nope.js" 2>&1); rc=$?
ok  "unreadable script exits 1"                "rc=$rc" "rc=1"

[ $fails = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
