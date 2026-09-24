#!/usr/bin/env bash
# End an implement-loop run, finished or not:
#   1. freeze the run (rounds, brief, log) into its tag and push the tag
#   2-3. lay the run down on the starting branch as one commit, with .deliverable/ removed, and push it
#   4. clean up the wip branch, the log and the artifacts
# Needs the commit message at $LOG.msg. `handoff.sh --cleanup` runs step 4 alone,
# after a rejected push was rebased and pushed by hand.
# Exits non-zero, with a line starting STOP:, and the recovery to follow, when it refuses.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"   # every pathspec below is root-relative
LOG="$(git rev-parse --absolute-git-dir)/implement-loop.log"
EXCLUDE=$(git rev-parse --git-path info/exclude)
field() { sed -n "s/^$1: //p" "$LOG"; }
START=$(field start); SHA=$(field sha); RUN=$(field tag); REPIN=$(field repinned)
[ -n "$START" ] && [ -n "$SHA" ] && [ -n "$RUN" ] || { echo "STOP: log unreadable ($LOG) — the state is on implement-loop-wip"; exit 1; }

cleanup() {   # the sentinel dies with the branch it names; the log is renamed, not deleted — retro reads it
  git branch -q -D implement-loop-wip 2>/dev/null || true
  ! git ls-remote -q --exit-code --heads origin implement-loop-wip >/dev/null 2>&1 || git push -q origin --delete implement-loop-wip
  mv "$LOG" "$LOG.$(date +%Y%m%d-%H%M%S).done"; rm -f "$LOG.progress" "$LOG.msg"
  rm -rf .implement-loop
  git worktree prune
  { grep -vFx -e '.implement-loop' -e '.claude/worktrees' "$EXCLUDE" || true; } > "$EXCLUDE.tmp" && mv "$EXCLUDE.tmp" "$EXCLUDE"
}
if [ "${1:-}" = --cleanup ]; then cleanup; echo "cleaned up; $START @ $(git rev-parse --short HEAD)"; exit 0; fi

[ -s "$LOG.msg" ] || { echo "STOP: write the commit message to $LOG.msg first"; exit 1; }
[ "$(git branch --show-current)" = implement-loop-wip ] || { echo "STOP: not on implement-loop-wip — switch to it and re-run"; exit 1; }

# 1. the record rides in the tag's tree under the excluded root: force-added here, stripped before the
#    hand-off commit. Pushed at once — a cloud container dies with the session, and the tag is what
#    retro reads. -f: every re-run moves the run's own tag, nothing else lives there
mkdir -p .implement-loop && cp "$LOG" .implement-loop/log
git add -A
git add -f .implement-loop/log
git commit -q --allow-empty -m "implement-loop: final state"
git tag -f "$RUN" >/dev/null
git push -q -f origin "refs/tags/$RUN" || { echo "STOP: tag push failed — the record is in tag $RUN locally only; fix the remote, then re-run"; exit 1; }

# 2. lay it down on the starting branch — only if it is clean and still where the run started
git switch -q "$START"
[ "$(git rev-parse HEAD)" = "$SHA" ] || { echo "STOP: $START moved since the run started — nothing laid down; the state is in tag $RUN. Recover: git switch implement-loop-wip"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "STOP: $START is dirty — nothing laid down; the state is in tag $RUN. Recover: git switch implement-loop-wip"; exit 1; }
git read-tree -u --reset "$RUN"

# 3. verify while the index holds exactly the tag's tree
git diff --cached --stat --exit-code "$RUN" || { echo "STOP: tree does not match $RUN. Recover: git reset -q --hard $SHA && git switch implement-loop-wip"; exit 1; }
if [ -z "$(field repinned)" ] && git diff --cached --quiet "$SHA" -- ':/' ':!/.implement-loop'; then
  # nothing built: no commit and no push, so the branch keeps its brief for the next attempt.
  # Never after a re-pin — the rounds are in the base then, and the brief's removal is still owed
  git reset -q --hard "$SHA"
  cleanup
  echo "nothing built — $START untouched, brief still in place; the record is in tag $RUN on the remote"
  exit 0
fi
# the brief was input, never output: removed in the same commit that carries the work, so a PR from this
# branch never shows it. Only the default location — a brief read from a path the user gave stays
git rm -r -q -f --ignore-unmatch ':/.deliverable' ':/.implement-loop'; rm -rf .deliverable
[ -z "$(git ls-files --cached -- ':/.deliverable' ':/.implement-loop')" ] || { echo "STOP: the record is still in the index — nothing committed. Recover: git reset -q --hard $SHA && git switch implement-loop-wip"; exit 1; }
git commit -q --allow-empty -F "$LOG.msg" || { echo "STOP: commit failed — nothing pushed. Recover: git reset -q --hard $SHA && git switch implement-loop-wip"; exit 1; }
# a plain push: a rejection means the remote moved under the run, and a teammate's commits are not ours to overwrite
git push -q -u origin "$START" || { echo "STOP: push rejected — the commit is on $START locally, the record in tag $RUN on the remote. Recover: git pull --rebase origin $START && git push -u origin $START, then: $0 --cleanup"; exit 1; }

# 4.
cleanup
echo "handed off: $START @ $(git rev-parse --short HEAD), pushed; tag $RUN pushed"
[ -z "$REPIN" ] || echo "re-pinned run: the work is $(git rev-parse --short "$REPIN")..HEAD, not the last commit alone — say so in the hand-off"
