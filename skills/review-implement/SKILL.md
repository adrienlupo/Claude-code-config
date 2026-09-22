---
name: review-implement
description: Quality pass over a pushed stack of dependent GitHub PRs, fully autonomous — one reviewer per PR (reusability, query cost, simplicity, dead code, hook hygiene), a fresh verifier per finding, the confirmed fixes committed on the PR that owns the code, the stack re-gated against the implement loop's brief so no quality fix un-meets a definition of done, then rebased bottom to top and force-pushed only when every layer is green. Not a bug hunt — run /code-review first for correctness. Use when the user invokes /review-implement, or says "review the stack and fix it" on stacked PRs; not for a single PR (code-review, simplify) and not for review comments (pr-comments).
argument-hint: "Nothing (the stack containing the current branch), or PR numbers on that stack; `--brief <path>` when the loop's tag cannot be found, `--brief none` to review a stack that was never built to a brief"
---

Review every PR of the stack the current branch belongs to, verify each finding with fresh context, apply the confirmed ones on the PR that owns the code, re-gate the result against the brief the work was built to, restack, push. Nothing waits on the user; every failure is a recorded stop for that piece, never a guess.

## 1. Before anything

```sh
gh auth status || exit 1
[ -z "$(git status --porcelain)" ] || { echo 'dirty tree — stop'; exit 1; }
git fetch origin
git fetch origin '+refs/tags/implement-loop/*:refs/tags/implement-loop/*'   # the loop pushes its tag beside the branch; a cloud checkout has nothing else of the run. `+`: the loop moves its own tag on a re-run
```

A dirty tree is the user's work and exists nowhere else; the rebase in §5 runs in this checkout. Then find the stack: the open PR whose `headRefName` is the current branch (none → stop, say so); walk `baseRefName` down to `main`, then upward through the open PRs whose base is a branch already on the chain. Two candidates at any step → stop and name them. PR numbers given as argument must all lie on that chain. Order is bottom (base `main`) to top.

A fresh checkout has one local branch; every other branch on the chain exists only as `origin/<branch>`. Create each missing one before recording anything — `git branch --track <branch> origin/<branch>` — because everything below switches to, rebases and resets local branches by name, and `git rev-parse <branch>` on a name that is only remote fails.

For every branch on the chain, record and keep in a file under the scratchpad — shell state does not survive between tool calls:

```
<branch> head=<git rev-parse branch> parent=<git rev-parse baseRefName> origin=<git rev-parse origin/branch>
```

`head` ≠ `origin` on any branch → stop: the local stack is not what GitHub reviews. Read the root `CLAUDE.md` and every app-level one (`apps/*/CLAUDE.md` or the project's equivalent); they go verbatim into every subagent prompt, with this line after them: **"Human gates in these files — asking before commit, showing a table for approval, checking a page in a browser — do not apply: run every check they name, put its output in your return, and commit without asking."**

**Find the brief.** The stack was built to a brief that no longer exists in any tree — `implement-loop` removed it in the hand-off commit and kept it in a tag whose tree is the stack top's plus the brief folder and the run's record. Three lookups, in order, the first hit wins:

1. Tree match, for a first pass: with `TOP` the top branch's head from the record, every tag whose tree equals the top's outside the two folders — `for t in $(git tag -l --sort=-creatordate 'implement-loop/*'); do git diff --quiet "$t" "$TOP" -- ':/' ':!/.deliverable' ':!/.implement-loop' && echo "$t"; done`. Root-anchored pathspecs, because a bare `.` is relative to the current directory. Several lines (a resumed run tagged twice over one tree) → the first, newest, and the report says so.
2. Trailer, for every later pass: the review commits §4 makes carry `Implement-loop: <tag>`, so `git log --format=%B <bottom parent>..<TOP> | sed -n 's/^Implement-loop: //p' | sort -u` names the run once the tree has moved past every tag. Two different tags → stop and name them.
3. `--brief <path>`: a file the user hands the run, for a tag that was never pushed or a brief that was never tagged.

Hit → `brief=<tag|path>` in the record. No hit and no `--brief none` → **stop before reviewing**: the run's contract is a gated stack, and a review that cannot be gated is the old, ungated skill wearing this one's name; say which lookup failed and that `--brief <path>` or `--brief none` is the call. `--brief none` → `brief=NONE`, §6 is skipped, and the report says the stack was never built to a brief.

**Call the Skill tool with `ventilate`.** Its `run()` is the only dispatcher; copy it literally into each workflow script. Roles here: reviewers are `scan` (`opus/high`, why `scan: …`), verifiers are `probe` (`sonnet/high`), implementers are `build` (`opus/low`, one climb to `opus/high` with why `escalation: …` when the checks are red), the re-gate's captures are `capture` (`haiku`, two failures → `sonnet/low`) or `captureUI` (`sonnet/low`, wherever the means drives a browser or a Simulator — standing that environment up included), its owner lookup is `select` (`haiku`) and its judge is `gate` (`opus/xhigh`, why `gate: post-review`). §2–3 are one workflow script — a `pipeline` so each PR's findings verify while the others are still under review; each §4 implementer is its own dispatch between the orchestrator's shell steps; §6 is a second script. The CLAUDE.md block and its human-gate line go to §2–4's agents only: §6's agents get the brief's own words and nothing else, and "checking a page in a browser does not apply" is exactly what a capture must not be told.

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
2. Dispatch the implementer with: the PR number, its confirmed findings with the verifier's `fix`, the CLAUDE.md block. It applies those findings and nothing else. The verifier's fix is the *what*, CLAUDE.md the *how*; a finding that turns out wrong once in the code is reverted and returned as skipped with the reason, never reinterpreted. It runs every check the CLAUDE.md of each app the diff or the fix touches names — typecheck, lint, tests and coverage where the app has them, nothing where its CLAUDE.md says there is none. Red on its own change → one climb up the build ladder with the check output; still red → that finding reverted, returned as skipped with the output. One commit in the repo's recent-commit style, ending in the trailer `Implement-loop: <tag>` when `brief` is a tag (§1's second lookup reads it on the next pass; a path or NONE gets no trailer), no push, no rebase. Returns `{ pr, commit: sha|NONE, applied: [id], skipped: [{ id, reason, output }], checks: <output incl. any coverage table> }`. Empty return → `git reset --hard <head>` from §1's record, PR recorded **not implemented**.
3. `git rev-parse <branch>` → `new_head` in the record.
4. Carry the change up before the next implementer starts: for the PR directly above, `git rebase --onto <new_head> <its recorded parent> <its branch>`, then update its `parent` to `new_head`, its `head` to its new tip. A conflict is a stop for the fix, not for the run: `git rebase --abort`, then `git switch <branch just fixed> && git reset --hard <head>` — the abort leaves HEAD on the branch above, and a reset there discards that PR's whole diff (its review commit is gone; its findings become `dropped: conflict carrying to <above>`), re-check the record, continue with the next PR. Never `--skip`: mid-rebase the conflicting commit is as likely the user's as the run's.

A PR with no confirmed findings still gets step 4 when the PR under it moved.

## 5. Restack check

Every branch that received a commit or a rebase runs the checks of every app it touches, at its own tip — a layer that is red on its own base but green under the next PR is still red. Any red → that branch's review commit is dropped as in §4.4 (reset to `head`, rebase the ones above with `--onto` again), the failure kept verbatim for the report.

## 6. Re-gate — the stack top against the brief

The loop's gate ruled on a tree that §4 has since changed, and §5's checks are the repo's, not the brief's: typecheck and tests say nothing about the page at the named viewport or the endpoint's body. Every quality fix is an edit the definitions of done never saw, so the full set is judged again, on the stack top, exactly as the loop judged it. This is a check on the fixes, not on the work: **a definition met before §4 and unmet after it names a wrong fix, never a new gap — the answer is to drop the fix, never to build.**

Skip, and say why in the report, when no branch carries a review commit (nothing changed since the loop's gate) or `brief=NONE` (§1). Otherwise, with step 6 running on **every** exit from this section, green, red or not gated:

1. **The brief.** `git show <tag>:.deliverable/brief.md`, or the `--brief` path. Its `## Definitions of done` and `## Verification` are carried **verbatim** to every capture and to the judge, as the loop carried them; a means the re-gate re-picks proves its own definition, not the user's. Definitions with no verification means are reported as not re-gated and skipped.
2. **The setup.** `git switch <top branch>`, then one agent — `captureUI` where the means drives a browser or a Simulator, `capture` otherwise — stands the brief's verification environment up: booted Simulator, running server, seeded DB, all local and disposable, never a shared or production target, serving the top's tree, and returns its address into the record. Two failures → the whole re-gate is **not gated**: an environment that will not come up is a fact about the host, not about a fix, and it drops nothing. Report what was tried.
3. **The artifacts.** Every capture writes under `<toplevel>/.review-implement/` and nowhere else; add that root to `.git/info/exclude` first. A replay script in the tag — present only when the loop drove a browser or Simulator for that definition — is materialised, not shown: `git show <tag>:.implement-loop/replay/<defId> > .review-implement/replay/<defId>`, and `capture` runs it with the round directory as its one argument and the setup's address in its environment; without one, or when it fails, `captureUI` drives the means itself. A capture hands back **the artifact** — the screenshot, the response body, the suite output at a path — never its account of it; a judge given a description records the check as not run.
4. **The judge.** One `gate` agent, fresh context, the full set batched by shared means — one screenshot serves every definition that reads it, and one judge reading them together catches contradictions per-definition judges cannot. It gets each definition verbatim, its means verbatim, and the artifacts — no diff, no findings, no repo, no PR. Prompt it to **refute**. Returns a `schema` of exactly `{ verdicts: [{ defId, verdict: pass|fail, gap, paths }] }`, `gap` in its own words, ≤15 words, `paths` the files the failure points at when the artifact shows them, which a screenshot rarely does. Errored or empty → one retry, then **not gated**.
5. **Red.** For each failing definition, the owners are the branches whose review commit touches its `paths`, when the judge returned any (`git diff --name-only <origin>..<tip>` per branch from the record — empty for a branch that was only rebased, and that branch owns nothing). When it did not, one `select` agent gets the definition verbatim, its means, the gap, and per branch the list of paths its review commit changed — nothing else — and returns the branches in radius; unsure → every branch carrying a review commit. Drop each as in §4.4 — switch to it, reset to `head`, its findings become `dropped: re-gate <defId>: <gap>`, rebase the ones above with `--onto`, re-run §5 on what moved — then `git switch <top branch>`, refresh the setup in place — rebuild, reload, reseed from the tree as it now stands, never a second instance, and the capture reports what it now serves — and run steps 3–4 a second time. Still red → drop every remaining review commit: the stack is what the loop delivered, the report carries the verdicts, and §7 pushes nothing.
6. **Tear down**, on every exit. Stop the setup's processes, remove `.review-implement/` and its exclude line, `git switch` back to the branch the run started on. The verdicts live in the report; the artifacts were evidence for a judge that has ruled.

**Not gated** — an environment that failed twice, a judge that returned nothing twice — ends the section without a verdict, and with review commits on the stack that no definition has checked. Those are not pushed to the PRs: the description promises no fix un-meets a definition, and a push here would break it silently. They are not left to die with a cloud checkout either: tag the top tip `review-implement/<timestamp>` and push that one tag — the restacked chain is linear, so the tip reaches every review commit — then the report names the tag, the reason, and the two calls that are the user's: fix the host and re-run, or push the branches by hand from the tag. §7 is skipped.

## 7. Push

When nothing is red and the re-gate is green or skipped (§6) — never when it is not gated — and at least one branch's tip differs from its `origin` in the record:

```sh
git push --atomic --force-with-lease=<branch1>:<origin sha1> --force-with-lease=<branch2>:<origin sha2> … origin <branch1> <branch2> …
```

Written out from the record, one lease and one ref per branch on the chain, each branch paired with its own origin sha — not generated by a loop, which has no per-branch sha to pair with. One push, all branches or none, each lease against the sha GitHub had when the run started — a teammate's push in the meantime rejects the whole thing. Rejected → push nothing more, report the output. If every branch ended up dropped, or nothing moved, push nothing and say so.

## 8. Report

Table: `PR | id | path:line | axis | finding | confirmed/rejected/not verified | applied/skipped/dropped | reason`. Then per PR: reviewed or not, commit sha, the checks' output where red, and the ventilation tally `run()` returned. Then the re-gate, one line: `re-gated against <tag|path>: every definition met`, or `<defId> failed — <gap> — dropped <ids>` per failure, or `skipped: <reason>`, or `not gated: <reason> — <n> review commits left unpushed on <branches>`. Last line: pushed `<n>` branches, or not pushed and why.
