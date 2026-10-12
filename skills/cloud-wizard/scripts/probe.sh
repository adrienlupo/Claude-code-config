#!/bin/bash
# Launch the parity probe as a cloud session on the current branch, wait for its report on the
# PR, judge it against the local inventory and add the verdict to it. Takes minutes.
# Usage: probe.sh PR [--comment] [-- SMOKE COMMAND...]   (from the project, on the branch to probe)
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
pr=${1:?usage: probe.sh PR [--comment] [-- SMOKE COMMAND...]}
shift
mode=body flag=''
[ "${1:-}" = --comment ] && { mode=comment flag=' --comment'; shift; }
[ "${1:-}" = -- ] && shift
project=$(git rev-parse --show-toplevel) || exit 1
cd "$project" || exit 1
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner) || exit 1
branch=$(git branch --show-current)
git rev-parse -q --verify "@{u}" >/dev/null || { echo "FAIL  $branch isn't on GitHub: push it first, the cloud clones what's there"; exit 1; }
[ -z "$(git log --oneline "@{u}..")" ] || { echo "FAIL  $branch has unpushed commits: the cloud clones what's on GitHub"; exit 1; }

report=/opt/claude-config/skills/cloud-wizard/scripts/report.sh
if [ $# -gt 0 ]; then
  run="these two commands one after the other, each with a 600000 ms Bash timeout, then reply with the last line of the second: \`bash $report smoke -- $*\`, then \`bash $report post $repo $pr$flag\`"
else
  run="this command with a 600000 ms Bash timeout, then reply with its last line: \`bash $report post $repo $pr$flag\`"
fi
prompt="This cloud session is the cloud-wizard parity probe the owner of $repo asked for on PR #$pr. Run $run. Change no file and commit nothing."
since=$(python3 -c 'import datetime as d; print((d.datetime.now(d.timezone.utc) - d.timedelta(minutes=2)).strftime("%Y-%m-%dT%H:%M:%SZ"))')
dir=$(mktemp -d)

# claude --cloud refuses to start without a terminal: script(1) gives it one.
if script --version >/dev/null 2>&1; then
  script -qec "claude --cloud $(printf '%q' "$prompt")" "$dir/launch.log" </dev/null >/dev/null 2>&1
else
  script -q "$dir/launch.log" claude --cloud "$prompt" </dev/null >/dev/null 2>&1
fi
url=$(LC_ALL=C grep -ao 'https://claude.ai/code/session_[A-Za-z0-9]*' "$dir/launch.log" | head -1)
if [ -z "$url" ]; then
  echo "FAIL  claude --cloud didn't create a session. Launch it by hand from $project:"
  printf '  claude --cloud %q\n' "$prompt"
  exit 1
fi
echo "probe: $url"

fetch() {
  if [ "$mode" = comment ]; then
    gh api "repos/$repo/issues/$pr/comments?per_page=100" \
      --jq '[.[] | select(.body | startswith("<!-- cloud-wizard:report"))] | last | if . then "\(.id)\n\(.body)" else "" end'
  else
    gh api "repos/$repo/pulls/$pr" --jq '.body // ""'
  fi
}
end=$((SECONDS + 1800))
while :; do
  fetch 2>/dev/null | tr -d '\r' >"$dir/fetched"
  stamp=$(sed -n 's/.*<!-- cloud-wizard:report \([0-9TZ:-]*\) -->.*/\1/p' "$dir/fetched" | head -1)
  [ -n "$stamp" ] && [[ ! "$stamp" < "$since" ]] && break
  [ $SECONDS -lt $end ] || { echo "FAIL  no report on PR #$pr after 30 min: read the session at $url"; exit 1; }
  sleep 20
done

if [ "$mode" = comment ]; then
  comment=$(head -1 "$dir/fetched")
  tail -n +2 "$dir/fetched" >"$dir/report.md"
else
  sed -n '/<!-- cloud-wizard:report /,/<!-- cloud-wizard:report:end -->/p' "$dir/fetched" >"$dir/report.md"
fi
python3 "$here/cloudlib.py" verdict "$dir/report.md" "$HOME/.claude" "$project" "$dir/judged.md"
ok=$?
if [ "$mode" = comment ]; then
  gh api -X PATCH "repos/$repo/issues/comments/$comment" -F body=@"$dir/judged.md" --jq .html_url
else
  python3 "$here/cloudlib.py" splice "$dir/fetched" "$dir/judged.md" >"$dir/body.md"
  gh api -X PATCH "repos/$repo/pulls/$pr" -F body=@"$dir/body.md" --jq .html_url
fi
exit $ok
