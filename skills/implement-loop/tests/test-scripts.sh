#!/usr/bin/env bash
# Sandbox tests for the deliverable and implement-loop scripts. Usage: test-scripts.sh [skills-dir]
set -u
D=${1:-$HOME/.claude/skills}; T=$(mktemp -d); cd $T; export CLAUDE_CODE_SUBAGENT_MODEL=sonnet
pass=0; fail=0; ok(){ if eval "$2" >/dev/null 2>&1; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
git init -q --bare -b main remote.git; git init -q -b main w; cd w; git config user.email t@t; git config user.name t
echo v1 > app.txt; printf '*.sql\n' > .gitignore; git add -A; git commit -qm init; git remote add origin ../remote.git; git push -q -u origin main; git remote set-head origin main
G=$(git rev-parse --absolute-git-dir); DH=$D/deliverable/scripts/handoff.sh; ST=$D/implement-loop/scripts/start.sh; HO=$D/implement-loop/scripts/handoff.sh
brief(){ mkdir -p .deliverable/assets; printf "2026-09-24 · $1\n## Goal\ng\n" > .deliverable/brief.md; }
brief feat/x; ok "deliverable refuses default branch" "! $DH g"
git switch -q -c feat/x; echo s > .deliverable/assets/seed.sql; ok "deliverable refuses ignored seed" "! $DH g"
printf '!.deliverable/**\n' >> .gitignore; git add .gitignore; git commit -qm neg; ok "deliverable accepts a !-re-included seed" "$DH g"
ok "seed reached the remote" "git ls-tree -r --name-only origin/feat/x | grep -q seed.sql"
echo i > ".deliverable/assets/Capture d’écran 2026-09-24 à 10.00.00.png"; ok "deliverable pushes an accented file name" "$DH g"
ok "accented file on the remote" "[ \$(git ls-tree -r --name-only origin/feat/x .deliverable/assets | wc -l) -eq 2 ]"
echo u > other.txt; git add other.txt; echo b >> .deliverable/brief.md; $DH g >/dev/null
ok "staged user file kept out of the brief commit" "! git show --name-only --format= HEAD | grep -q other.txt"
git reset -q other.txt; rm other.txt
ok "loop refuses a dirty tree" "echo x > d.txt; ! $ST; rm d.txt"
ok "loop fresh start" "$ST | grep -q 'mode: fresh'"
echo v2 > app.txt; mkdir -p .implement-loop/replay; echo drive > .implement-loop/replay/D1; git add -A; git commit -qm r1
git switch -q main; ok "loop refuses resume from another branch (local wip exists)" "! $ST"
git switch -q feat/x; ok "loop resumes from its own branch" "$ST | grep -q 'mode: resume'"
ok "hand-off refuses without a message" "! $HO"
printf 'G\n\nD1 met\n' > $G/implement-loop.log.msg; TAG=$(sed -n 's/^tag: //p' $G/implement-loop.log)
ok "hand-off happy path" "$HO"
ok "one commit on feat/x, pushed" "[ \$(git rev-parse HEAD) = \$(git rev-parse origin/feat/x) ] && git log -1 --format=%s | grep -qx G"
ok "brief removed from the branch" "! git ls-tree -r --name-only HEAD | grep -q deliverable"
ok "tag on remote has brief and log, not the round artifacts" "git ls-remote --tags origin | grep -q '$TAG' && git ls-tree -r --name-only $TAG | grep -q .deliverable/brief.md && git ls-tree -r --name-only $TAG | grep -q .implement-loop/log && ! git ls-tree -r --name-only $TAG | grep -q replay/"
ok "cleanup: log renamed, wip gone, excludes removed" "ls $G | grep -q 'implement-loop.log.*.done' && ! git show-ref -q refs/heads/implement-loop-wip && ! grep -q implement-loop $G/info/exclude && ! grep -q worktrees $G/info/exclude"
brief feat/x; git add .deliverable; git commit -qm b2; git push -q; sleep 1
$ST >/dev/null; printf 'G\n' > $G/implement-loop.log.msg; ok "nothing built leaves the branch and brief alone" "$HO | grep -q 'nothing built' && [ -f .deliverable/brief.md ]"
sleep 1; $ST >/dev/null; echo v3 > app.txt; git add -A; git commit -qm r1; git switch -q feat/x; echo t > t.txt; git add t.txt; git commit -qm mate; git switch -q implement-loop-wip; printf 'G\n' > $G/implement-loop.log.msg
ok "hand-off refuses a moved start branch" "! $HO && git switch -q implement-loop-wip"
git branch -f feat/x origin/feat/x; git push -q -f origin implement-loop-wip; git switch -q feat/x; git branch -q -D implement-loop-wip
ok "cloud resume recreates wip from origin" "$ST | grep -q 'mode: resume' && git log -1 --format=%s | grep -q 'final state'"
( cd ..; git clone -q -b feat/x remote.git o; cd o; git config user.email t@t; git config user.name t; echo r > r.txt; git add r.txt; git commit -qm remote; git push -q )
ok "rejected push stops with a recovery" "$HO 2>/dev/null | grep -q 'push rejected'"
ok "recovery then --cleanup" "git pull -q --rebase origin feat/x && git push -q -u origin feat/x && $HO --cleanup && ! git ls-tree -r --name-only HEAD | grep -q deliverable"
brief feat/x; git add .deliverable; git commit -qm b3; git push -q; sleep 1
$ST >/dev/null; echo v9 > app.txt; git add -A; git commit -qm r1; git switch -q feat/x; git reset -q --hard implement-loop-wip; git push -q; git branch -q -D implement-loop-wip
ok "re-pin detected on resume" "$ST | grep -q repinned"
printf 'G\n' > $G/implement-loop.log.msg; ok "re-pin hand-off removes brief and names the range" "$HO | grep -q 're-pinned run' && ! git ls-tree -r --name-only HEAD | grep -q deliverable"
git worktree add -q ../wt -b feat/w; cd ../wt; brief feat/w; git add .deliverable; git commit -qm b; git push -q -u origin feat/w 2>/dev/null; sleep 1
ok "worktree run end to end" "$ST >/dev/null && echo w > w.txt && git add -A && git commit -qm r && printf 'W\n' > \$(git rev-parse --absolute-git-dir)/implement-loop.log.msg && $HO"
echo "--- $pass passed, $fail failed"; rm -rf $T
