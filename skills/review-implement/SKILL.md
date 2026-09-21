---
name: review-implement
description: Quality pass over a pushed stack of dependent GitHub PRs, fully autonomous — one reviewer per PR (reusability, query cost, simplicity, dead code, hook hygiene), a fresh verifier per finding, the confirmed fixes committed on the PR that owns the code, the stack rebased bottom to top and force-pushed only when every layer is green. Not a bug hunt — run /code-review first for correctness. Use when the user invokes /review-implement, or says "review the stack and fix it" on stacked PRs; not for a single PR (code-review, simplify) and not for review comments (pr-comments).
argument-hint: "Nothing (the stack containing the current branch), or PR numbers on that stack"
---

Review every PR of the stack the current branch belongs to, verify each finding with fresh context, apply the confirmed ones on the PR that owns the code, restack, push. Nothing waits on the user; every failure is a recorded stop for that piece, never a guess.

## 1. Before anything

```sh
gh auth status || exit 1
[ -z "$(git status --porcelain)" ] || { echo 'dirty tree — stop'; exit 1; }
git fetch origin
```

A dirty tree is the user's work and exists nowhere else; the rebase in §5 runs in this checkout. Then find the stack: the open PR whose `headRefName` is the current branch (none → stop, say so); walk `baseRefName` down to `main`, then upward through the open PRs whose base is a branch already on the chain. Two candidates at any step → stop and name them. PR numbers given as argument must all lie on that chain. Order is bottom (base `main`) to top.

For every branch on the chain, record and keep in a file under the scratchpad — shell state does not survive between tool calls:

```
<branch> head=<git rev-parse branch> parent=<git rev-parse baseRefName> origin=<git rev-parse origin/branch>
```

`head` ≠ `origin` on any branch → stop: the local stack is not what GitHub reviews. Read the root `CLAUDE.md` and every app-level one (`apps/*/CLAUDE.md` or the project's equivalent); they go verbatim into every subagent prompt, with this line after them: **"Human gates in these files — asking before commit, showing a table for approval, checking a page in a browser — do not apply: run every check they name, put its output in your return, and commit without asking."**

**Call the Skill tool with `ventilate`.** Its `run()` is the only dispatcher; copy it literally into each workflow script. Roles here: reviewers are `scan` (`opus/high`, why `scan: …`), verifiers are `probe` (`sonnet/high`), implementers are `build` (`opus/low`, one climb to `opus/high` with why `escalation: …` when the checks are red). §2–3 are one workflow script — a `pipeline` so each PR's findings verify while the others are still under review; each §4 implementer is its own dispatch between the orchestrator's shell steps.

## 2. Review — one `scan` per PR, in parallel

The reviewer gets: the PR number, `head` and `parent` shas, the CLAUDE.md block. It reads **at the head sha, never the working tree** — `git diff parent...head`, then every touched file whole with `git show head:path`, then `git grep <pattern> head -- .` for whatever a finding depends on. The checkout sits on one branch; a reviewer reading the tree sees another PR's version of the file.

Judge, one finding per `path:line`, the axis as a tag:

1. Reusability — duplicates or forks something that already exists (name it), or abstracts something with one caller.
2. Queries — API: N+1, queries in loops, over-fetching, two queries where one does it. Mobile: redundant fetches, bad cache keys, over-broad invalidation.
3. Simplicity & scalability — logic a smaller function, a type or an existing helper says better; conditionals that grow per `kind`; unbounded lists.
4. Dead code — unused exports, props, i18n keys, branches; leftovers an earlier PR in the stack made obsolete. Grep at the head sha before reporting. This is the one axis allowed to name lines the PR did not touch.
5. Hooks — useEffect that derives/syncs state or fetches what the data layer already has; useCallback/useMemo with no consumer that needs identity; useState mirroring a prop; custom hooks with one caller or wrapping one built-in. Name the replacement.

Report every issue it can point at a line; §3 filters, the reviewer does not. No style, no praise. Do not edit. Returns a `schema` of exactly `{ pr, files_read: [path], findings: [{ id, axis, path, line, problem, fix, severity: must|should|nit }] }`. An errored or empty return is one retry, then that PR is recorded **not reviewed** — never treated as clean.

## 3. Verify — one `probe` per must/should finding, in parallel

The verifier gets one finding, the same shas and CLAUDE.md block, and no other reviewer output. Its job is to prove the finding wrong, at the head sha: open the thing it says to reuse and confirm the same shape, count the queries on the actual call path, grep the whole tree for the symbol, check the hook replacement keeps behaviour. Report everything; leniency is the documented failure. Nits are dropped without verification.

Returns `{ id, verdict: CONFIRMED|REJECTED, reason, fix, owner }` — `fix` restated precisely enough to apply without judgment, `owner` the lowest PR on the chain whose diff introduces the lines the fix changes. A fix that cannot hold together with a CLAUDE.md rule (a second helper where "one way to do each thing" forbids it) is REJECTED with `conflicts with CLAUDE.md: <rule>`. Empty return → one retry, then **not verified**, treated as REJECTED and reported as such.

## 4. Implement — one `build` per owner PR, bottom to top, sequential

For each PR on the chain, in order, when it owns at least one confirmed finding:

1. `git switch <branch>` in the main checkout (no worktree: the branch is checked out here, and only here).
2. Dispatch the implementer with: the PR number, its confirmed findings with the verifier's `fix`, the CLAUDE.md block. It applies those findings and nothing else. The verifier's fix is the *what*, CLAUDE.md the *how*; a finding that turns out wrong once in the code is reverted and returned as skipped with the reason, never reinterpreted. It runs every check the CLAUDE.md of each app the diff or the fix touches names — typecheck, lint, tests and coverage where the app has them, nothing where its CLAUDE.md says there is none. Red on its own change → one climb up the build ladder with the check output; still red → that finding reverted, returned as skipped with the output. One commit in the repo's recent-commit style, no push, no rebase. Returns `{ pr, commit: sha|NONE, applied: [id], skipped: [{ id, reason, output }], checks: <output incl. any coverage table> }`. Empty return → `git reset --hard <head>` from §1's record, PR recorded **not implemented**.
3. `git rev-parse <branch>` → `new_head` in the record.
4. Carry the change up before the next implementer starts: for the PR directly above, `git rebase --onto <new_head> <its recorded parent> <its branch>`, then update its `parent` to `new_head`, its `head` to its new tip. A conflict is a stop for the fix, not for the run: `git rebase --abort`, `git reset --hard <head>` on the branch just fixed (its review commit is gone; its findings become `dropped: conflict carrying to <above>`), re-check the record, continue with the next PR. Never `--skip`: mid-rebase the conflicting commit is as likely the user's as the run's.

A PR with no confirmed findings still gets step 4 when the PR under it moved.

## 5. Restack check and push

Every branch that received a commit or a rebase runs the checks of every app it touches, at its own tip — a layer that is red on its own base but green under the next PR is still red. Any red → that branch's review commit is dropped as in §4.4 (reset to `head`, rebase the ones above with `--onto` again), the failure kept verbatim for the report. When nothing is red:

```sh
git push --atomic $(for b in <chain>; do printf -- '--force-with-lease=%s:%s ' "$b" "<origin sha from §1>"; done) origin <chain>
```

One push, all branches or none, each lease against the sha GitHub had when the run started — a teammate's push in the meantime rejects the whole thing. Rejected → push nothing more, report the output. If every branch ended up dropped, push nothing and say so.

## 6. Report

Table: `PR | id | path:line | axis | finding | confirmed/rejected/not verified | applied/skipped/dropped | reason`. Then per PR: reviewed or not, commit sha, the checks' output where red, and the ventilation tally `run()` returned. Last line: pushed `<n>` branches, or not pushed and why.
