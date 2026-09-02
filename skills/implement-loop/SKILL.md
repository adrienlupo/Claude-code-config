---
name: implement-loop
description: Iterate on a settled brief until every definition of done is verifiably met — build, verify with fresh context, repeat. Depth is sized by an entry scan, not chosen; every agent's model and effort come from the ventilate skill. The deliverable is one big uncommitted, unpushed diff. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
argument-hint: "Nothing, or a path to a brief"
---

Read the brief, size the run, loop until every definition of done is verifiably met. Nothing is handed back, nothing waits on approval.

## 1. The brief

`.claude/deliverable.md` unless a path was given. Sections: `## Goal`, `## Definitions of done`, `## Verification`, optionally `## Out of scope`. Take it as settled; never guess a goal — every round after this verifies against it, so one you filled in yourself gets the full rigor of the loop aimed at the wrong target. If none exists, or its goal is too vague to judge output against, run the `deliverable` skill first and come back with one.

- Say in one line which goal it holds and when it was stamped — visibility, not approval. A stamp weeks old, from another branch, or naming a different goal than the user's ask means stale: run `deliverable` again rather than build at the wrong target.
- The brief and its assets are **read-only input**. Do not edit them, do not let a builder clean them away. A definition rewritten mid-run has not been met, it has been deleted. `## Out of scope` is a wall, not a preference: outside the builder's closed prompt (§4 step 1) and the wip branch (§3), it is the only thing bounding the run's blast radius.
- Each definition carries its verification means — the URL and viewport, the booted Simulator, the endpoint and the calls, the reference to compare against. They were settled with the user in the room. Carry them **verbatim** to every agent that checks one; never re-pick, never soften — a means the loop picks for itself proves the loop's own definition, not the user's. No verifiable definitions at all → stop and ask the user for them: a loop with nothing to verify burns rounds and converges on nothing.

## 2. Ventilation and limits

**Call the Skill tool with `ventilate`.** It is where every agent's model and effort are decided — by you, per call, from the scan's report and the log's gap lines, against the prices and the measured numbers it carries — and it hands back the `run()` dispatcher: the only `agent(` in the script, refusing any call that names no model, names the session model, or spends Opus without a reason the record can check. Copy its literal into the workflow script and dispatch everything through it; an agent launched outside `run()` is a bug, not a choice. The role names used below (`scan`, `build`, `capture`, `captureUI`, `select`, `probe`, `sweep`, `merge`, `gate`) are its vocabulary, and its ladders — `opus/low → high → xhigh` for a builder, `haiku → sonnet/low` for a capture — are what "escalate" means everywhere in this file. `LIMITS` is the same move for the run's numbers: every ceiling and threshold is declared here once, with the reason it holds that value, and named — never restated — everywhere below, so changing one is an edit to one line. Author the script, dispatch through `run()`, spend what the goal is worth at that size: the user settled the brief and left.

```js
const LIMITS = {   // which of these actually bind: the counts, because the loop holds them; not `budget`/`reserve` — nothing meters tokens mid-run — and not a per-call timeout, which the runtime does not have
  budget:        null,  // the run's token total: fix it at kickoff from the runtime's `budget` reading or a number you choose, and write it to the log's `limits:` field — a total nobody wrote down is not a ceiling
  reserve:       0.20,  // of `budget`, never spent on building: it is what pays for the final gate, the hand-off and the report — never plan for it to be what saves the gate, end on `rounds` with the gate still unspent
  rounds:        8,     // hard round ceiling — plateau fires only on a *repeating* gap, and a run where fix A breaks B and fix B breaks A alternates forever without ever repeating one
  attempts:      2,     // per non-builder call: one retry, then §7 — failing twice is a condition, not noise. A `capture` that fails twice moves one model up its ladder (`ventilate`) instead and never gets a third try on the same model: a transcript it never executed reads exactly like one it did, so the same model failing the same way is invisible rather than loud
  setupAttempts: 2,     // standing-setup bring-up or refresh, same reasoning: two failures are the environment, not luck
  builders:      4,     // most builders in flight in the 7+ tier, whatever the failing count: past that, collisions and the reconciling cost more than the parallelism buys
  retier:        2,     // rounds the failing count must sit in another tier before the run moves there — one miscount must not lock a large job into the small lane
  staleProbe:    3,     // rounds a definition may go unprobed before the radius takes it back regardless of what changed
  plateau:       3,     // rounds naming the same definition with substantially the same gap, after the top rung of the build ladder has had it (§7)
  sweepFloor:    50,    // changed lines, or a single changed file, under which the sweep is skipped: nothing has duplicated or drifted yet
}
```

- `agent()` is the workflow-orchestration runtime's; without it this skill cannot run — say so and stop rather than improvising a dispatcher. `phase`, `meta`, `schema`, `isolation` and the `budget` reading are its bookkeeping: if the host omits one, drop that `opts` key and carry the fact yourself — your own count for the budget, prose for a missing `schema`, the 3–6 tier for a missing `isolation`. `meta` stays a pure literal and phase entries are written by hand — `run('build', prompt, { model: 'opus', effort: 'low', why: 'first attempt on D2', phase: 'round-3-build', meta: { defId: 'D2' } })` — never derived from a role, or a role rename quietly rewrites the run's own history and the audit can no longer tell what a call did.
- Model, effort, the reasons Opus may be spent, the `agent(`-appears-once audit and the proof at hand-off are `ventilate`'s (§2) — this file never restates them. Two of its facts bind here: an agent named nowhere inherits the session model, and the plain Agent tool takes no `effort`, so a worker is dispatched through the workflow runtime's `run()` even in the solo lane.
- `agent()` takes no `timeout` and the runtime enforces none: a wedged browser or server stalls its round until you stop the workflow, so read `/workflows` between rounds rather than trusting a limit to fire. Any call that errors or returns nothing is a failed attempt, never a pass — it verified nothing, and reading it as a pass banks a definition nobody checked. Exhausting `LIMITS.attempts` is the next rung of the build ladder (§4 step 1), the next model up for a `capture` (`ventilate`), and a stop (§7) for anything else.

## 3. Before the first agent

```sh
set -euo pipefail
LOG="$(git rev-parse --git-dir)/implement-loop.log"   # outside the index, so `git add -A` can never sweep it in, and any fresh session recomputes it from the repo alone — in `.git/` rather than /tmp because /tmp does not survive a restart, and a run whose log is gone restarts at round 0 over work that is already done
SHOTS="$(git rev-parse --show-toplevel)/.implement-loop"; mkdir -p "$SHOTS"; grep -qx '.implement-loop' .git/info/exclude 2>/dev/null || echo '.implement-loop' >> .git/info/exclude   # the run's only artifact root — every capture writes here and nowhere else, and §8 deletes it whole. Inside the repo because the capture tools refuse any path outside a workspace root (a /tmp root cost every capture a detour through dist/ and a copy); excluded through .git/info/exclude rather than .gitignore so the exclusion itself never appears in the hand-off diff
if [ -s "$LOG" ]; then
  git switch implement-loop-wip   # log present = a prior run died mid-flight: resume it, never restart at round 0 — and uncommitted work here is that run's own, not the user's
else
  [ -z "$(git status --porcelain)" ] || { echo 'dirty tree — stop and ask the user'; exit 1; }
  START=$(git rev-parse --abbrev-ref HEAD); SHA=$(git rev-parse HEAD); RUN=implement-loop/$(date +%Y%m%d-%H%M%S)
  git switch -c implement-loop-wip
  printf 'start: %s\nsha: %s\nwip: implement-loop-wip\ntag: %s\nsetup:\nlimits:\nround: 0\n' "$START" "$SHA" "$RUN" > "$LOG"   # first write: everything a fresh session needs to re-enter, `limits:` holding the two LIMITS values fixed at kickoff
fi
START=$(sed -n 's/^start: //p' "$LOG"); SHA=$(sed -n 's/^sha: //p' "$LOG"); RUN=$(sed -n 's/^tag: //p' "$LOG")
ROUND=$(sed -n 's/^round: //p' "$LOG"); SETUP=$(sed -n 's/^setup: //p' "$LOG"); LIMS=$(sed -n 's/^limits: //p' "$LOG")   # only a resume uses these three
[ -n "$START" ] && [ -n "$SHA" ] && [ -n "$RUN" ] || { echo 'log unreadable — stop'; exit 1; }
[ -n "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ] || echo 'WARN: no subagent default model — an agent that escapes run() inherits the session model (ventilate §5)' >> "$LOG"
```

Shell state does not survive between tool calls, so every later command touching `$START`, `$SHA` or `$RUN` re-reads them from `$LOG` with those read-and-check lines and stops on empty — unset, they expand §4's and §8's git commands into something destructive instead of erroring. The log is read before the tree is judged, or the resume path is unreachable. A resumed run re-enters from those fields and nothing else: it counts from `$ROUND` against the ceilings in `$LIMS` rather than from zero, re-stands the standing setup at `$SETUP` (§4) before any probe reads it, and does **not** re-run the entry scan — the tiering it produced is in the log's round lines already, and a second scan would re-size the run from the tree the run itself changed. On a fresh start a dirty tree is a **stop**: those uncommitted changes are the user's, they exist nowhere else, and §8 would lay the run's tree over them. `$SHA` pins the commit `$START` was on, because the branch can move under a run that lasts all night — a commit from another window, a teammate's push merged in — and the run's hours-old tree laid over it reverts that work where no diff would ever show it. Past that, every round commits on `implement-loop-wip` (§4 step 6) — a dead run's last state lives on the branch and in `$LOG`, never in a shell variable, and §8 unwinds all three.

**Preconditions this file cannot enforce.** Its two hardest constraints are prompt text: the builder's sandbox (§4 step 1) and a judge's no-repo rule (invariant 3). Nothing here catches a subagent that ignores either — a markdown skill holds no permission over what an agent does. So running this unattended is safe only where the host's own permission configuration already denies what the sandbox forbids: push and force-push, destructive shell, installs and network, writes outside the repo root. Where it cannot, that is a reason not to start, not something to prompt harder about. Concurrency is the same shape: branch and log are shared state, and the resume path above cannot tell a crashed run from a live one, so one loop per repo is a precondition to confirm before taking either — not a check this loop can perform. The repo's `.gitignore` is the third: every round commits with `git add -A` (§4 step 6), and the standing setup is exactly what produces build output, caches and local env files — anything it writes into the tree that the ignore file does not already cover is committed and lands in the hand-off diff, so ignore those paths and keep credentials outside the repo root before starting.

## 4. The loop

**Entry scan.** One `scan` agent, fresh context, before any building: run the full definition set against the repo as it stands. It returns which already hold, which fail, how far each is, and the paths each gap must touch — that count and that path list size the run, and nothing else does. They size it, they do not settle it — `LIMITS.retier` moves the run between tiers when the log's failing count says so.

| failing | shape |
|---|---|
| 0 | already done: run the gate once to confirm, then go straight to hand-off (§8) |
| 1–2, no gap touching a shared surface (step 2) | solo lane: the same rounds, one builder and one probe wide — a shorter script, not a different set of rules, so a failed probe re-enters step 1 up the same ladder and the gate still ends it |
| 1–2 touching one, or 3–6 | workflow; builders run **sequentially in the one tree**; capture and probes in parallel |
| 7+ | workflow; builders run **in parallel, each in its own worktree**; capture and probes in parallel |

**Worktrees, in the 7+ tier only** (`isolation: 'worktree'`, ~200–500ms and disk per agent): the isolation only buys something when parallelism does. Integrating them is agent work too, never yours (§6): dispatch one `merge` agent per worktree to merge its changed paths into the main tree, and read its verdict rather than the diff. Two builders returning the same path is a **collision**: dispatch a fresh `merge` agent both diffs to reconcile before the merge continues — never a last-write-wins. Cap it at `LIMITS.builders` in flight. The round does not close until `git worktree remove` and `git worktree prune` have run.

**Standing setup.** Stand the verification environment up **once** — booted Simulator, running server, seeded DB, all local and disposable, never a shared or production target — and record its address in the run log's `setup:` field. It must serve the tree as it now stands: one `capture` agent refreshes it in place — rebuild, reload, reseed — after every change to the tree (build, sweep, revert) and before any probe or the gate reads it, and reports what it now serves. Refresh, never relaunch: nobody boots a second instance, and a probe reading a process still serving last round's bundle passes stale code. If it fails to come up or to refresh, retry to `LIMITS.setupAttempts`, then §7 — a run that built nothing yet still takes that exit, so the branch and log do not outlive it. Report what was tried, not just that it failed. It is the run's own, so §8 tears it down — processes, ports and seeded data go with the branch.

**Each round**

1. `build` the failing definitions; every attempt after the first climbs one rung of the build ladder (`ventilate`), and a gap surviving the top rung is a real plateau where one surviving only the cheap rungs is not a finding. Require back the paths it changed and the definition each serves — a report never asked for is never written. **The builder's prompt is the closed list below and nothing else — no brief, no round log, no verdict history beyond the one line in the first item — so every constraint on a builder lives here:**
   - the failing definitions **verbatim**, and `## Out of scope` **verbatim** (§1) — the wall it is bounded by; on any attempt after the first, add that definition's gap line from last round **verbatim** (step 5) and nothing else from it: the ladder changes the rung, this changes the input, and an identical prompt at a higher rung mostly buys back the same wrong reading;
   - the standing setup's address, the only target it may touch outside the repo tree;
   - the sandbox: no push or force-push, no destructive or irreversible shell, no installs or network calls beyond a definition's own need, no writes outside the repo root;
   - it may write tests, never weaken them: relaxing an assertion, deleting a failing case, or editing the brief or a named suite's scenarios (invariant 8) is the loop's cheapest path to green, and it is the deletion §1 forbids aimed at the instrument instead of the definition.
2. `git diff --name-only`, then one fresh `select` agent maps changed paths → the definitions in radius. **The builder never chooses what gets checked** — its own scope report is a cross-check, not a source: it knows its intent, not its effect. Shared surfaces (config, types, lockfile, build config, env, design tokens, CI) widen the radius to everything. Unsure → include. Any definition unprobed for `LIMITS.staleProbe` rounds comes back in.
3. The repo's own checks — test, typecheck, lint, build — run every round, whatever the radius. They are the cheap net under a narrow probe. A repo that has none is not a failure; note it in the log and lean harder on probes.
4. `probe` the selected definitions, fresh context, capture split off (`captureUI` where the means drives a browser or Simulator, `capture` otherwise). Capture hands back **the artifact itself** — the screenshot, the response body, the suite output at a path — never its own account of what it saw, here or at the gate. Every capture writes under `$SHOTS/r<n>/` (§3) and creates no directory of its own naming: that root is inside the repo because the capture tools write nowhere else, and excluded from git so nothing a capture writes can reach the hand-off diff. A capture left to choose its own gets a fresh sibling of the repo per run, and those outlive the run — nobody deletes what the loop never named. A judge given a description instead of an artifact records the check as not run: capture is the cheapest model in the run, and a paraphrase from it would become the expensive judge's ground truth (invariant 4). **Capture once, replay after.** The first time `captureUI` drives a means it also writes the drive itself — the navigations, the evaluate calls, the reads, in order, taking the round's directory as its one argument — to `$SHOTS/replay/<defId>`. From the next round that definition is captured by `capture` running the script; `captureUI` is dispatched again only when the script fails, and it rewrites the script when it does. A fresh Sonnet rediscovering the same seventy clicks every round is the largest token line in a browser-verified run, and the script is the only thing that carries what one round learned into the next.
5. Append one line per definition to `$LOG`: `R<n> <defId> pass|fail | gap in the verifier's own words, ≤15 words | paths touched`, then one line for what the radius excluded and why, the round's ventilation tally as `run()` returned it (`ventilate` §4), and the round and budget counters; overwrite `round:` in the log's header fields (§3). Give every judge a `schema` returning exactly those fields, so calling plateau (§7) is a comparison of two rounds' gap strings and not an impression of them.
6. `git add -A && git commit -m "implement-loop: round N"` on `implement-loop-wip` — the disposable commit that makes a dead run recoverable (§3).
7. Check the ceilings, every round: rounds spent against `LIMITS.rounds`, and — only where the host gives a reading to re-read — spend against `LIMITS.budget` minus `LIMITS.reserve`. Either reached → stop building, go straight to the gate on the current state, then §7. A ceiling is not a crash; it takes the same exit as every other stop.

**Sweep.** When probes come back clean, freeze the state before touching it: `git add -A && git commit -m "implement-loop: probes clean" && git tag -f "$RUN"` — the safety tag, taken the moment the state is first believed good; `-f` keeps it idempotent across repeated sweeps, same-day reruns and the final hand-off. Then one `sweep` pass, fresh context, scoped to the diff's footprint: dead code out, duplication merged where builders never saw each other, defensive complexity dropped, the repo's own idiom restored. Pre-existing dead code is not its business and neither is redesign — the definitions stop being the target here and become the invariant. `$SHOTS` is not its business either: the gate still reads this round's artifacts, and they are §8's to remove. Then run step 3's checks on what it changed: falling after the last round and before the gate, the sweep is the one edit those checks never see (invariant 6) and the likeliest to break a green build — red, `git reset --hard "$RUN"` and gate the frozen state instead. Skip it under `LIMITS.sweepFloor`.

**Gate.** The full set, at once, fresh context, `gate` role, batched by shared verification means — one screenshot serves every definition that reads it, and one judge reading them together catches contradictions per-definition judges cannot. Prompt the judge to **refute**, not to confirm. This is the only thing that ends the run successfully. If it fails on something inside the sweep's footprint, `git reset --hard "$RUN"` and re-gate once; otherwise the definition was never met — keep looping.

## 5. Invariants

1. **Whoever judges a definition has fresh context.** Never the agent that built the thing, never one carrying a previous round's argument. A builder believes its work is done; that belief is exactly what must not do the judging.
2. **Judge against the real output, never the diff** — the rendered page, the running app, the live endpoint.
3. **A judge gets its definition verbatim, its means verbatim, and the evidence. Nothing else.** No brief, no repo, no round log. A verifier that greps the codebase is judging the diff.
4. **Split every check in two:** capture reaches the real thing and produces the artifact; the judge reads the artifact against the definition. Only the judge is worth paying for.
5. **A definition met stays met.** The gate judges the whole set — nothing else will notice when a late round breaks an early pass.
6. **The repo's own checks stay green.** Not a brief field, just hygiene: a diff that meets every definition while breaking the build is not done.
7. **The run ends on one fresh-context pass where every definition is met at once.** Passes banked across rounds are not a finish, and you never stand in for that verifier.
8. **Where the brief names a test suite as the instrument, the scenarios stay the authority.** The loop writes and runs the suite; a probe reads suite against scenarios whenever either changes, because a passing suite that no longer matches them proves nothing.

## 6. Your own discipline

You orchestrate. You never build. Your context is the scarcest thing in the run — the only thing that persists across every round and the only place the whole picture lives. Spend it on judgment, never on material. When it runs out the loop does not fail loudly; it just stops being able to tell what is happening.

- **Never touch the codebase.** Not a one-line fix, not a typo, not "faster than dispatching an agent". Your own Write/Edit is for the run log and the progress page, nothing else.
- **Never pull material in.** No source files, no diffs, no agent transcripts or reasoning; agents hand back verdicts and the short structured facts of step 5. `git diff --name-only` is a fact; the diff itself is material. Expect the pull to just fix it — the fix looks small and the agent looks slow — and expect to pay two rounds later: a lead that has read half the codebase can no longer tell a plateau from a mess it made itself.
- **`$LOG` (§3) is the record** — that file, not your recollection, is what you read to call a stop or to resume a crashed run. Keep a progress page beside it (`$LOG.progress`): one screen, overwritten each round with phase, round number and per-definition status, for a human to glance at without reading the whole log.

## 7. Stopping without finishing

Once the branch exists, every stop lands here. The refusals in §1 (no verifiable definitions) and §3 (dirty tree) fire before it and end nothing.

- **Plateau** — `LIMITS.plateau` (§2). Call it by comparing the logged gap lines (§4 step 5), not your impression of them: you are the agent that wants to keep going, so the record has to be able to contradict you.
- **Ceiling** — `LIMITS.rounds` spent, or the budget down to `LIMITS.reserve`.
- **Environment** — the standing setup failed `LIMITS.setupAttempts` times.
- **Agent** — any non-builder call failing `LIMITS.attempts` times (§2); builders and captures escalate up the ladder instead.

The exit is the one a finished run takes: gate the current state if the reserve allows, then run **all of §8**, every step of it. An unfinished run leaves no more behind than a finished one. Then report the standing gap, the diff so far, and the calls that are the user's — widen the scope, adjust the definition, extend the budget, take it as it stands. None of these is a failure. A run that ends silently is indistinguishable from one that failed.

## 8. Hand-off

The single ending, finished or not (§7). One diff, **uncommitted and unpushed**, in the working tree of `$START`. Say which definitions are met, say where the diff is, and stop.

```sh
set -euo pipefail   # recompute $LOG with §3's LOG= line first; state is read back from it, never from shell memory
START=$(sed -n 's/^start: //p' "$LOG"); SHA=$(sed -n 's/^sha: //p' "$LOG"); RUN=$(sed -n 's/^tag: //p' "$LOG")
[ -n "$START" ] && [ -n "$SHA" ] && [ -n "$RUN" ] || { echo 'log unreadable — stop; the state is on implement-loop-wip'; exit 1; }
# 1. freeze the state on the wip branch, and tag it
git add -A && git commit --allow-empty -m "implement-loop: final state" && git tag -f "$RUN"   # --allow-empty: a stop before any build still ends here; -f: idempotent, never collides with itself
# 2. lay it down on the starting branch — refuse unless that branch is clean and still where the run started
git switch "$START" && [ "$(git rev-parse HEAD)" = "$SHA" ] && [ -z "$(git status --porcelain)" ] || { echo "$START moved or is dirty — stop, the state is in tag $RUN"; exit 1; }
git read-tree -u --reset "$RUN"
# 3. verify BEFORE destroying anything, while the index still holds the tag's tree — must print nothing
git diff --cached --stat --exit-code "$RUN" || { echo "tree does not match $RUN — stop"; exit 1; }
git reset --mixed "$START"   # unstage: the run's work becomes the uncommitted diff, files it added left untracked
# 3b. prove the ventilation (ventilate §5): its histogram over this session's subagent transcripts, appended to "$LOG" as `ventilation: …` — a fable count above zero is a defect the hand-off names, with the transcript ids
# 4. only now — the sentinel dies with the branch it names, the record does not
git branch -D implement-loop-wip && mv "$LOG" "$LOG.$(date +%Y%m%d-%H%M%S).done" && rm -f "$LOG.progress"
rm -rf "$SHOTS"; { grep -vx '.implement-loop' .git/info/exclude || true; } > .git/info/exclude.tmp && mv .git/info/exclude.tmp .git/info/exclude   # recompute $SHOTS with §3's line first — the artifacts were evidence for a gate that has now ruled; the verdicts live in the log, and the exclude line goes with the root
```

Step 2 refuses on a dirty tree, which `read-tree` would overwrite without a backup, and on a moved `$START` (§3). Step 3 must run before the `--mixed` reset: after that reset every file the run added is untracked, `git diff` cannot see one, and the check would fail on a correct hand-off and send the next session down the resume path for nothing. If it does print, stop and report — the work is safe in the tag, the branch and log still exist to re-enter on, and improvising a repair is how it gets lost. Step 4 clears the sentinel and the artifacts: a log left at `$LOG` sends the next run on this repo to a branch that no longer exists — renamed, not deleted, because the round history is what the human reads afterwards. Tear the standing setup (§4) down with it, and `$SHOTS` with both — screenshots and response bodies are a round's evidence, not its record, and a run that leaves a directory of them beside the repo has left the user something to identify and delete by hand months later. The tag is the point: an uncommitted diff is one stray `git checkout` or `git clean` from gone, and hours of work must not hang on nothing going wrong. It is the only thing the run leaves in the repo — no commits, no branches, no PRs. Name it in the hand-off, say it is the user's to delete once the diff is committed or discarded, and never delete it yourself. A review of that diff is the `stack-this` skill's job; never start it yourself.
