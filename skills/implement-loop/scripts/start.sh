#!/usr/bin/env bash
# Start an implement-loop run, or resume one that died. Prints the run's state.
# Exits non-zero, with a line starting STOP:, when the run must not start.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
LOG="$(git rev-parse --absolute-git-dir)/implement-loop.log"   # in .git: never swept by `git add -A`, and it survives a restart
EXCLUDE=$(git rev-parse --git-path info/exclude)
field() { sed -n "s/^$1: //p" "$LOG"; }

# the artifact root lives inside the repo because capture tools refuse paths outside a workspace root;
# excluded through info/exclude rather than .gitignore, so the exclusion never reaches the hand-off commit
mkdir -p .implement-loop "$(dirname "$EXCLUDE")"
for p in .implement-loop .claude/worktrees; do   # worktrees inside the repo would be committed as gitlinks by `git add -A`
  grep -qxF "$p" "$EXCLUDE" 2>/dev/null || echo "$p" >> "$EXCLUDE"
done

if [ -s "$LOG" ]; then
  MODE=resume   # a log means a run died mid-flight: its uncommitted work is its own, not the user's
  START=$(field start); SHA=$(field sha)
  case "$(git branch --show-current)" in implement-loop-wip|"$START") ;; *) echo "STOP: an unfinished run belongs to $START; this is $(git branch --show-current) — ask the user"; exit 1;; esac
  if ! git switch -q --no-guess implement-loop-wip 2>/dev/null; then
    # no local wip branch: a cloud checkout deleted it, and we are on the log's own branch (checked above)
    if git fetch -q origin implement-loop-wip 2>/dev/null && git merge-base --is-ancestor "$SHA" FETCH_HEAD; then
      git switch -q -c implement-loop-wip FETCH_HEAD   # the host pushed the killed run's rounds under the wip name
    else
      git switch -q -c implement-loop-wip              # or onto the starting branch: HEAD is that tip
    fi
  fi
  # the starting branch sits on the wip tip: a host pushed the rounds onto it, so they are the base now
  if [ "$(git rev-parse -q --verify "refs/heads/$START")" = "$(git rev-parse implement-loop-wip)" ] && [ "$SHA" != "$(git rev-parse HEAD)" ]; then
    printf 'repinned: %s\n' "$SHA" >> "$LOG"
    sed -i.bak "s/^sha: .*/sha: $(git rev-parse HEAD)/" "$LOG" && rm -f "$LOG.bak"
  fi
else
  MODE=fresh
  DIRTY=$(git status --porcelain -- ':/' ':!/.deliverable')   # an uncommitted brief is input, not the user's unsaved work
  [ -z "$DIRTY" ] || { printf 'STOP: dirty tree — these changes are the user'"'"'s and exist nowhere else:\n%s\n' "$DIRTY"; exit 1; }
  ! git show-ref -q --verify refs/heads/implement-loop-wip || { echo "STOP: implement-loop-wip exists with no log — an earlier run's leftover; ask the user"; exit 1; }
  START=$(git branch --show-current); [ -n "$START" ] || { echo "STOP: detached HEAD"; exit 1; }
  # sha pins where the starting branch was: hand-off refuses to lay the run over a branch that moved
  printf 'start: %s\nsha: %s\nwip: implement-loop-wip\ntag: implement-loop/%s\nsetup:\nround: 0\n' \
    "$START" "$(git rev-parse HEAD)" "$(date +%Y%m%d-%H%M%S)" > "$LOG"
  git switch -q -c implement-loop-wip
fi

[ -n "$(field start)" ] && [ -n "$(field sha)" ] && [ -n "$(field tag)" ] || { echo "STOP: log unreadable: $LOG"; exit 1; }
if [ -z "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ]; then
  echo 'WARN: CLAUDE_CODE_SUBAGENT_MODEL is unset — an agent dispatched without a model runs on the session model'
  echo 'warn: CLAUDE_CODE_SUBAGENT_MODEL unset' >> "$LOG"
fi
echo "mode: $MODE"
echo "log: $LOG"
grep -E '^(start|sha|tag|setup|round|repinned): ' "$LOG"
[ "$MODE" = fresh ] || { echo "last round lines:"; grep -E '^R[0-9]+ ' "$LOG" | tail -n 20 || true; }
