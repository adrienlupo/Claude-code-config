---
name: implement-loop
description: Iterate on a settled brief until every definition of done is verifiably met — build, verify with fresh context, repeat. Depth is sized by an entry scan, not chosen. The deliverable is one big uncommitted, unpushed diff. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
argument-hint: "Nothing, or a path to a brief"
---

Read the brief, size the run, loop until every definition of done is verifiably met. Nothing is handed back, nothing waits on approval.

## 1. The brief

`.claude/deliverable.md` unless a path was given. Sections: `## Goal`, `## Definitions of done`, `## Verification`, optionally `## Out of scope`. Take it as settled; never guess a goal. If none exists, or its goal is too vague to judge output against, run the `deliverable` skill first and come back with one.

- Say in one line which goal it holds and when it was stamped — visibility, not approval. A stamp weeks old, from another branch, or naming a different goal than the user's ask means stale: run `deliverable` again rather than build at the wrong target.
- The brief and its assets are **read-only input**. Do not edit them, do not let a builder clean them away. A definition rewritten mid-run has not been met, it has been deleted.
- Each definition carries its verification means — the URL and viewport, the booted Simulator, the endpoint and the calls, the reference to compare against. They were settled with the user in the room. Carry them **verbatim** to every agent that checks one; never re-pick, never soften.
- No verifiable definitions → stop and ask the user for them. A loop with nothing to verify burns rounds and converges on nothing.
- `## Out of scope` is a wall, not a preference. Nobody is watching; it is the only thing bounding the run's blast radius.

## 2. Roles

Every agent is dispatched through this table. **This is not a per-call judgment** — the assignments were decided in advance, for these roles specifically. Copy it into the workflow script; an agent launched without a role from it is a bug, not a choice.

```js
const ROLES = {
  capture:   { model: 'haiku'  },                    // files, endpoints, logs, suite output
  captureUI: { model: 'sonnet', effort: 'low'    },  // drive a browser or Simulator
  retrieve:  { model: 'haiku'  },                    // locate, list, read out
  select:    { model: 'haiku'  },                    // changed paths -> DoD ids in radius
  scan:      { model: 'sonnet', effort: 'medium' },  // entry scan
  build:     { model: 'sonnet', effort: 'high'   },
  buildHard: { model: 'opus',   effort: 'xhigh'  },  // escalation
  probe:     { model: 'sonnet', effort: 'high'   },  // judge a subset
  sweep:     { model: 'sonnet', effort: 'high'   },
  gate:      { model: 'opus',   effort: 'max'    },  // the only max in the run
}

const run = (role, prompt, opts = {}) => {
  const r = ROLES[role]
  if (!r) throw new Error(`unassigned role: ${role}`)
  return agent(prompt, { ...r, ...opts })
}
```

- Agents **inherit the session model unless the script sets one** — omitting `model` silently runs Opus. Audit before launching: `agent(` must appear exactly once in the script, inside `run()`.
- Haiku takes no `effort`; it is off that axis. Fable is never used — 2x Opus, no gain for these roles.
- `meta` must stay a pure literal, so phase entries are written by hand, not derived from `ROLES`.
- Runs with 3+ failing definitions are workflow-orchestrated: author the script, dispatch through `run()`, spend what the goal is worth at that size. The user settled the brief and left.

## 3. Before the first agent

```sh
git status --porcelain     # MUST be empty — otherwise stop and ask
git rev-parse --abbrev-ref HEAD   # remember: $START
git switch -c implement-loop-wip  # the run happens here
```

A dirty starting tree is a **stop**. Those are the user's uncommitted changes, they exist nowhere else, and the hand-off in §7 would lay the run's tree over them. The loop does not get to decide that.

The run works on `implement-loop-wip` with disposable commits — a long unwatched loop sometimes dies mid-flight and its last state must be recoverable by a fresh session. §7 unwinds this.

**Ceilings**, set now and enforced every round: **8 rounds**, and a token budget keeping a **20% reserve**. They exist because plateau only fires on a *repeating* gap — a run where fix A breaks B and fix B breaks A alternates forever and plateau never triggers. Hitting a ceiling is not a crash; it routes to §6 like any other stop, with the reserve paying for the final gate, the tag and the report.

## 4. The loop

**Entry scan.** One `scan` agent, fresh context, before any building: run the full definition set against the repo as it stands. It returns which already hold, which fail, how far each is — and it sizes the run.

| failing | shape |
|---|---|
| 1–2, locally scoped | solo lane: one builder, one probe, one gate. No workflow. |
| 3–6 | workflow; builders run **sequentially in the one tree**; capture and probes in parallel |
| 7+, or cross-cutting | workflow; builders run **in parallel, each in its own worktree**; capture and probes in parallel |

**Worktrees, in the 7+ tier only** (`isolation: 'worktree'`, ~200–500ms and disk per agent). They are yours to manage: each builder returns its changed paths; the orchestrator merges them into the main tree and verifies the merge before the next round; two builders returning the same path is a **collision to surface, never a last-write-wins**; and the round does not close until `git worktree remove` and `git worktree prune` have run. Below 7, sequential builders in one tree — the isolation only buys something when parallelism does.

**Standing setup.** Stand the verification environment up **once** — booted Simulator, running server, seeded DB — and record its address in the run log. No agent boots it twice. If it fails, **retry once**, then stop and ask (§6): never came up → stop immediately, nothing was built; died mid-run → tag the current state first, then stop. Report what was tried, not just that it failed.

**Each round**

1. `build` the failing definitions. Third attempt on the same one escalates: `build` → `build` → `buildHard`. A gap surviving `buildHard` is a real plateau; one surviving only cheap builders is not a finding.
2. `git diff --name-only`, then one fresh `select` agent maps changed paths → the definitions in radius. **The builder never chooses what gets checked** — its own scope report is a cross-check, not a source: it knows its intent, not its effect. Shared surfaces (config, types, lockfile, build config, env, design tokens, CI) widen the radius to everything. Unsure → include. Any definition unprobed for 3 rounds is included regardless.
3. The repo's own checks — test, typecheck, lint, build — run every round, whatever the radius. They are the cheap net under a narrow probe. A repo that has none is not a failure; note it in the log and lean harder on probes.
4. `probe` the selected definitions, fresh context, capture split off (`captureUI` where the means drives a browser or Simulator, `capture` otherwise).
5. Append to the run log: verdicts, each gap in the verifier's own words, what was excluded and why, and the round and budget counters.
6. Check the ceilings. Reserve reached → stop building, go straight to the gate on the current state, then §6.

**Sweep.** When probes come back clean, commit and tag (§7 step 1) — the safety tag, taken the moment the state is first believed good. Then one `sweep` pass, fresh context, scoped to the diff's footprint: dead code out, duplication merged where builders never saw each other, defensive complexity dropped, the repo's own idiom restored. Pre-existing dead code is not its business and neither is redesign — the definitions stop being the target here and become the invariant. Skip the sweep on a small diff.

**Gate.** The full set, at once, fresh context, `gate` role, batched by shared verification means — one screenshot serves every definition that reads it, and one judge reading them together catches contradictions per-definition judges cannot. Prompt the judge to **refute**, not to confirm. This is the only thing that ends the run successfully. If it fails on something inside the sweep's footprint, restore the tag and re-gate once; otherwise the definition was never met — keep looping.

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
- **Never pull material in.** No source files, no diffs, no agent transcripts or reasoning. Agents hand back verdicts and short structured facts — give them a `schema` so the log holds comparable strings, not paraphrase. `git diff --name-only` is a fact; the diff itself is material.
- Expect the pull to just fix it: the fix looks small and the agent looks slow. The fix costs context you cannot get back, and you pay two rounds later — a lead that has read half the codebase can no longer tell a plateau from a mess it made itself.
- **The round log lives on disk, not in your head.** That file, not your recollection, is what you read to call a stop.
- Keep a live progress page — the only window into a run nobody is watching.

## 7. Stopping without finishing

Three triggers, one exit:

- **Plateau** — three rounds naming substantially the same gap, after `buildHard` has had it. Call it by comparing the logged strings, not your impression of them: you are the agent that wants to keep going, so the record has to be able to contradict you.
- **Ceiling** — 8 rounds, or the budget reserve reached.
- **Environment** — the standing setup failed twice.

All three take the same exit: run the gate on the current state if the reserve allows, complete §8 through the tag, then report the standing gap, the diff so far, and the calls that are the user's — widen the scope, adjust the definition, extend the budget, take it as it stands. None of these is a failure. A run that ends silently is indistinguishable from one that failed.

## 8. Hand-off

One diff, **uncommitted and unpushed**, in the working tree of `$START`. Say which definitions are met, say where the diff is, and stop.

```sh
# 1. freeze the state on the wip branch, and tag it
git add -A && git commit -m "implement-loop: final state"
git tag implement-loop/$(date +%Y-%m-%d)

# 2. lay it down on the starting branch as uncommitted changes
git switch $START
git read-tree -u --reset implement-loop/$(date +%Y-%m-%d)
git reset --mixed $START

# 3. verify BEFORE destroying anything — must print nothing
git diff --stat implement-loop/$(date +%Y-%m-%d)

# 4. only now
git branch -D implement-loop-wip
```

Step 3 is the gate on step 2. If it prints anything, stop and report — the work is safe in the tag and the branch still exists; do not improvise a repair.

The tag is the point: an uncommitted diff is one stray `git checkout` or `git clean` from gone, and hours of work must not hang on nothing going wrong. Name it in the hand-off, say it is the user's to delete once the diff is committed or discarded, and never delete it yourself.

No commits, no branches, no PRs survive the run — only the tag. If the user wants the diff reviewed, that is the `stack-this` skill's job; never start it yourself.
