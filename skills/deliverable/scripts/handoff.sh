#!/usr/bin/env bash
# Commit and push .deliverable/ on the current, non-default branch — so a loop running
# anywhere (a cloud agent included) can check the brief out.
# Usage: handoff.sh "<the goal, one line>"
set -euo pipefail
GOAL=${1:?usage: handoff.sh "<the goal, one line>"}
cd "$(git rev-parse --show-toplevel)"
[ -f .deliverable/brief.md ] || { echo "STOP: no .deliverable/brief.md"; exit 1; }

BRANCH=$(git branch --show-current)
DEFAULT=$(git symbolic-ref --short -q refs/remotes/origin/HEAD | sed 's|^origin/||' || true)
[ -n "$DEFAULT" ] || DEFAULT=$(git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2 }' || true)
[ -n "$BRANCH" ] || { echo "STOP: detached HEAD"; exit 1; }
[ -n "$DEFAULT" ] || { echo "STOP: cannot tell the default branch — run: git remote set-head origin --auto"; exit 1; }
# the loop removes the brief in its hand-off commit; on the default branch that removal would show up in every PR
[ "$BRANCH" != "$DEFAULT" ] || { echo "STOP: on the default branch ($DEFAULT) — create the brief's branch first"; exit 1; }
# the loop reads a brief stamped with another branch as stale
grep -m1 . .deliverable/brief.md | grep -qF -- "$BRANCH" || { echo "STOP: the stamp line does not name $BRANCH"; exit 1; }

FILES=$(find .deliverable -type f ! -name .DS_Store | sort)
# `git add .deliverable` silently skips any file a rule like `*.sql` covers, and the loop runs without its fixture
IGNORED=$(printf '%s\n' "$FILES" | git check-ignore --stdin || true)   # no -v here: it also lists files a `!` rule re-includes
[ -z "$IGNORED" ] || { printf 'STOP: ignored by the repo — tell the user which rule; the fix is theirs, never add -f:\n'; printf '%s\n' "$IGNORED" | git check-ignore --stdin -v; exit 1; }

git add -- .deliverable
git diff --cached --quiet -- .deliverable || git commit -q -m "deliverable: $GOAL" -- .deliverable   # the path limits the commit to the brief, whatever else is staged

MISSING=$(git ls-files --others -- .deliverable ':!*.DS_Store')   # anything still untracked never reached the commit
[ -z "$MISSING" ] || { printf 'STOP: not in the commit, nothing pushed:\n%s\n' "$MISSING"; exit 1; }
[ -z "$(git status --porcelain -- .deliverable)" ] || { echo "STOP: .deliverable has uncommitted changes, nothing pushed"; exit 1; }

git push -q -u origin HEAD
echo "pushed: $BRANCH @ $(git rev-parse --short HEAD) — $(printf '%s\n' "$FILES" | wc -l | tr -d ' ') file(s) in .deliverable/"
