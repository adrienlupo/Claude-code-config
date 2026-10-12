#!/bin/bash
# The probe's commands, in a cloud session. Names only: nothing here reads the environment's
# variables or network settings, and every value of them is redacted before posting.
#   report.sh smoke -- COMMAND...            run the project's smoke command, keep its result
#   report.sh post OWNER/REPO PR [--comment] the session-start output, the smoke result and this
#                                            session's inventory into the PR's description, or a comment
# Each finishes within the 10-minute Bash limit.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
project=$(git rev-parse --show-toplevel)
dir=/tmp/cloud-wizard
mkdir -p "$dir"

# The hook may still be setting the project up when the probe's first turn starts.
for _ in $(seq 24); do [ -f "$dir/hook.done" ] && break; sleep 5; done

case "${1:-}" in
smoke)
  shift
  [ "${1:-}" = -- ] && shift
  {
    echo "### Smoke: \`$*\`"
    echo '```'
    if (cd "$project" && timeout 450 "$@") >"$dir/smoke.log" 2>&1; then echo "ok    $*"; else echo "FAIL  $*"; fi
    tail -n 12 "$dir/smoke.log"
    echo '```'
  } >"$dir/smoke.md"
  head -3 "$dir/smoke.md" | tail -1
  ;;
post)
  repo=$2 pr=$3 mode=${4:-}
  {
    echo "<!-- cloud-wizard:report $(date -u +%FT%TZ) -->"
    echo "## Cloud probe"
    echo "Session \`${CLAUDE_CODE_REMOTE_SESSION_ID:-unknown}\` · Claude Code $(claude --version 2>/dev/null | cut -d' ' -f1)"
    echo
    echo "### Session start"
    echo '```'
    cat "$dir/hook.out" 2>/dev/null || echo "FAIL  no session-start output: the project's SessionStart hook didn't run"
    [ -f "$dir/hook.done" ] || echo "FAIL  the session-start hook hadn't finished when the probe ran"
    echo '```'
    cat "$dir/smoke.md" 2>/dev/null
    echo "### Inventory"
    echo '```'
    python3 "$here/cloudlib.py" actual "$project"
    echo '```'
    echo "<!-- cloud-wizard:report:end -->"
  } >"$dir/report.md"
  python3 "$here/cloudlib.py" redact "$dir/report.md" "$project"
  if [ "$mode" = --comment ]; then
    gh api "repos/$repo/issues/$pr/comments" -F body=@"$dir/report.md" --jq .html_url
  else
    gh api "repos/$repo/pulls/$pr" --jq '.body // ""' >"$dir/body.md"
    python3 "$here/cloudlib.py" splice "$dir/body.md" "$dir/report.md" >"$dir/new-body.md"
    gh api -X PATCH "repos/$repo/pulls/$pr" -F body=@"$dir/new-body.md" --jq .html_url
  fi
  ;;
*)
  sed -n '2,7p' "$0"
  exit 2
  ;;
esac
