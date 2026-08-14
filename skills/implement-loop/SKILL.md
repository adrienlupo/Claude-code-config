---
name: implement-loop
description: Iterate on a settled brief until every definition of done is verifiably met — build, verify with fresh context, repeat. Runs at full depth (ultracode). The deliverable is one big uncommitted, unpushed diff. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
argument-hint: "Nothing, or a path to a brief"
---

Read the settled brief and start the loop. Nothing is handed back, and there is nothing for the user to approve mid-run. The loop has one job: make every definition of done in the brief verifiably true, and keep iterating until it is.

## 1. Find the brief

`.claude/deliverable.md`, unless a path was given. Its sections are `## Goal`, `## Definitions of done`, `## Verification`, and optionally `## Out of scope`. Read it and take it as settled. If no brief exists, or its goal is too vague to judge output against, run the `deliverable` skill first and come back with one. Never guess a goal.

Before anything runs, say in one line which goal the brief holds and when it was stamped — visibility, not approval; nothing waits on an answer. A stamp weeks old or from another branch is a flag, and if the user's ask plainly names a different goal than the brief holds, that is a stale brief: run `deliverable` again rather than launch full depth against the wrong one.

The brief and the assets it points at — images, documents — are read-only input. Do not edit them, and do not let a builder clean them away. A definition of done that gets rewritten mid-run has not been met; it has been deleted.

## 2. Take the definitions of done

The brief lists them, each with its verification means — the URL and viewport, the booted Simulator, the endpoint and the calls, the reference to compare against. They were settled with the user in the room: do not re-pick them, do not soften them, and carry the verification means through verbatim to every agent that checks one.

Stand the one-time setup up once and keep it standing; only the per-check steps repeat. Every check runs against the real thing — the rendered page, the running app, the live endpoint — never against the diff.

Where a definition is scenarios and the brief names a test suite as the instrument, the loop writes and runs that suite — but the scenarios stay the authority: a passing suite that no longer matches the scenarios proves nothing.

If the brief carries no verifiable definitions of done, stop and ask the user for them. A loop with nothing to verify burns rounds and converges on nothing.

If the brief has an out-of-scope section, it is a wall, not a preference. Nobody is watching the run; this is the only thing holding its blast radius.

## 3. Run the loop

Start now. You are the lead agent, and the specifics — decomposition, agent counts, round counts — are yours.

Run it at full depth. **This is an ultracode run every time**: orchestrate the fan-out with workflows and spend what the goal is worth. The user settled the brief and left, so depth is not theirs to re-authorise, and a loop run thin converges on nothing.

One rule is prescribed, because without it the loop grades its own homework: **whoever verifies a definition of done has fresh context** — never the agent that just built the thing, and never one carrying the argument from a previous round. A builder believes its work meets the definition; that belief is exactly what must not do the judging. Everything else — how you split the work, how many builders, worktrees or not, how rounds are shaped — is yours to decide.

What must be true of every round:

- Each check reaches the real output by the brief's verification means and reads the definition of done against it. An image or live-example definition is judged harshly: "close" is not met. A scenario definition either holds or it does not.
- A definition met stays met. Verifiers judge the whole set they can see, not only the gap they were handed — nothing else will notice when a late round breaks an early pass.
- The repo's existing checks — tests, typecheck, lint, build, whatever it already runs — stay green. Not a brief field, just hygiene: a diff that meets every definition of done while breaking the build is not done.
- The run ends on a single fresh-context verification pass in which **every** definition of done is met at once. Passes banked across rounds are not a finish: a late round may have broken what an early one met. You never stand in for that final verifier.

Keep looping until every definition holds, the run plateaus, or the user stops it. Keep a live progress page showing the work evolving — it is the only window into a run nobody is watching.

A plateau is a stop. Log every round's named gap verbatim, in the verifier's own words, and call the plateau by comparing those strings — not your impression of them. You are the agent that wants to keep going, so the record has to be able to contradict you. Three rounds naming substantially the same gap means a fourth will not change it. It is not a failure: stop, and report the standing gap, the diff so far, and the calls that are the user's — widen the scope, adjust the definition, or take it as it stands. A run that ends silently is indistinguishable from one that failed.

That is what must be true of the loop, not how to run it. The vagueness is deliberate: every line added here takes a decision away from you, so nothing gets added — no numbered phases, no agent counts, no checklists.

## 4. The deliverable

One big diff, **uncommitted and unpushed**, sitting in the working tree of the branch the run started on. That is the whole hand-off: say the definitions of done are met, say where the diff is, and stop. No commits, no branches, no PRs survive the run.

During the run, disposable commits are allowed — a long unwatched loop sometimes dies mid-flight, and its last state must be recoverable by a fresh session. Use a throwaway branch for them. At the end, restore everything to the starting branch as uncommitted changes and delete the throwaway branch: the recovery mechanism must leave no trace in the result.

If the user then wants the diff reviewed, that is the `stack-this` skill's job — never start it yourself.
