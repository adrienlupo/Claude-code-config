---
name: implement-loop
description: Run a settled brief unattended until every definition of done passes its check — build, check with fresh context against the real output, repeat, and end on one fresh gate over the whole set. Hands off one pushed commit on the starting branch with the brief removed, plus a pushed run tag holding the brief and the run log for retro. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
argument-hint: "Nothing, or a path to a brief"
---

The brief says what done is and how to check it. Everything in between is yours — how to split the work, how many builders, sequential or parallel, how each round is shaped. The user settled the brief and left: nothing waits on approval. What follows is only what must hold however you run it.

## 1. The brief

`.deliverable/brief.md` unless a path was given. Say in one line which goal it holds and when it was stamped. If it's stale — another branch, weeks old, not the goal the user asked for — or holds nothing checkable, run `deliverable` first. Never fill in a goal yourself.

The brief is read-only: a definition rewritten mid-run has been deleted, not met. `## Out of scope` is a wall. Every agent that builds or checks a definition gets it, and its check, **verbatim**.

## 2. Start

```sh
~/.claude/skills/implement-loop/scripts/start.sh
```

It starts the run — branch `implement-loop-wip`, log at `$(git rev-parse --git-dir)/implement-loop.log`, git-excluded artifacts under `.implement-loop/` — or resumes one that died, and prints its state. If it stops (a dirty tree, a log from another branch), tell the user: those changes are theirs.

Run unattended only where the host's permissions already deny force-push, destructive shell and writes outside the repo; nothing else enforces them on a subagent. Rounds commit with `git add -A`, so build output must already be gitignored.

## 3. The loop

Load `ventilate` and run the rounds as Workflow scripts through its `run()`: every agent gets a chosen model, never the session model by omission.

No two agents drive a browser at once, builders included, and each closes the pages it opened — several Chromiums at once have killed a cloud host.

Stand the check environment up once — local, disposable — and write its address to the log's `setup:` line. Refresh it in place after every change to the tree, before anything reads it.

Start with one fresh agent checking every definition against the repo as it is; that sizes the run. Then, each round:

- **Build** what fails. A builder gets its definitions, the out-of-scope wall, the setup's address and — on a retry — last round's gap for that definition. It doesn't push, run destructive commands, install beyond need, write outside the repo, weaken a test, or touch `.deliverable/`. A retry climbs `ventilate`'s ladder *and* carries the gap.
- **Check**, once every builder has returned, whatever the change could affect — decided by a fresh agent from `git status --porcelain`, never by the builder; unsure means include. The repo's own tests, typecheck, lint and build run every round.
- **Log** one line per definition checked — `R<n> <defId> pass|fail | gap in the checker's words, ≤15 words | paths` — update `round:`, and commit the round on the wip branch.

How a definition is checked is what makes the loop worth running:

- **Fresh context** — never the builder, never one carrying last round's argument.
- **The real output** — the page, the app, the endpoint, the query result — never the diff.
- **Capture apart from judgment** — a cheap agent runs the check and hands back the artifact itself (screenshot, response, suite output) under `.implement-loop/r<n>/`; the judge gets the definition, its check and the artifact, nothing else, and tries to **refute**.
- **Qualitative definitions are judged blind** — the build's output and the reference, unlabelled, scored against the bar the brief sets.
- A browser drive that works is saved as `.implement-loop/replay/<defId>` and replayed in later rounds.

**Gate** — the only successful end: one fresh agent judges the **whole set at once** on fresh artifacts, with the repo's own checks green. Passes banked across rounds don't count, and you never stand in for the gate.

## 4. Stopping

Stop when the gate passes. Stop short on a **plateau** — the same gap logged three rounds running for a definition the top of the ladder has had; compare the logged strings, not your impression — after **eight rounds**, when the setup or any non-builder agent **fails twice** (an empty return is a failure, never a pass), or as soon as a definition proves **impossible or contradictory** as written: that one is the user's call. Stopping short isn't failure — gate what you have and hand off the same way.

## 5. You orchestrate

You never touch the code, and you never pull source, diffs or transcripts into your context — agents return verdicts and log lines. The log, not your memory, decides stops and resumes. Keep `$LOG.progress` as a one-screen status.

## 6. Hand-off

Append `ventilate`'s `ventilation:` line to the log and write the commit message to `$LOG.msg` — the goal as subject; one line per definition, met or its gap; the log's `tag:`. Then:

```sh
~/.claude/skills/implement-loop/scripts/handoff.sh
```

It pushes the run tag (every round, the brief, the log), lays the run down as **one commit on the starting branch** with `.deliverable/` removed, pushes it, and cleans up. If it stops, follow only the recovery it prints — the work is safe in the tag. Then tear the setup down.

Report for someone who never saw the run: each definition met or not, gaps in plain words; the commit and branch; the tag, theirs to delete once merged; and if unfinished, their calls — widen the scope, adjust a definition, run longer, or take it as it stands. Open no PR; that's `stack-this`.
