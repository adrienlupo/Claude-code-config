---
name: implement-loop
description: Run a settled brief unattended until every definition of done passes its check — build, check with fresh context against the real output, repeat; once a fresh gate passes the whole set, polish with simplify and code-review --fix and pass the gate again. Hands off one pushed commit on the starting branch with the brief removed, plus a pushed record branch holding the brief and the run log for retro. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
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
- **Check**, once every builder has returned, what was built and each passed definition a changed path reaches — named by a fresh agent from `git status --porcelain`, never by you or the builder; the rest stay passed until the gate. The repo's own tests, typecheck, lint and build run every round.
- **Log** one line per definition checked — `R<n> <defId> pass|fail|unchecked | gap in the checker's words, ≤15 words | paths` — update `round:`, and commit the round on the wip branch.

How a definition is checked is what makes the loop worth running:

- **Fresh context** — never the builder, never one carrying last round's argument.
- **The real output** — the page, the app, the endpoint, the query result — never the diff.
- **Capture apart from judgment** — a cheap agent runs the check and hands back the artifact itself (screenshot, response, suite output) under `.implement-loop/r<n>/`; the judge gets the definition, its check and the artifact, nothing else, and tries to **refute**. A capture's prompt is its definition and check, this round's one addition and the log's `trap:` lines — what the environment taught the run — never the rounds before.
- **Fail only on an artifact that contradicts the definition**, at the gate too. A clause no artifact reached is `unchecked`: it gets one capture before the next gate and, still unreached, is handed off as unverified, never as met. A flaw the definition doesn't forbid passes, named on its log line; neither buys a build round.
- **Qualitative definitions are judged blind** — the build's output and the reference, unlabelled, scored against the bar the brief sets.
- **Browser checks are Playwright scripts.** The first capture of a browser definition writes one — headless, the brief's viewport, the setup's address — saves it as `.implement-loop/replay/<defId>`, and runs it; later rounds re-run it. It captures (screenshots, text, console) and asserts only that it reached the state under test, never the definition. A replay that can't reach its state goes to a fresh capture to rewrite, not to the log as a fail. Drive through an MCP only when no script can run on the host or none reaches the state twice running; that drive is re-driven every round.

**Gate** — one fresh agent judges the **whole set at once** on fresh artifacts, with the repo's own checks green. Passes banked in the rounds don't count here, and you never stand in for the gate. The first gate to pass goes to polish; the only successful end is a gate that passes after it.

**Polish** — once per run, on the tree the first passing gate judged: write its commit to the log as `polish: <sha>`. One agent runs the `simplify` skill; once it returns, a fresh one runs `code-review high --fix`. Both take the target `<base>...HEAD` — the log's first `repinned:` if any, else its `sha:` — because their default diff on the wip branch is the last round or the wrong base. Each prompt:

- names the skill as the agent's own task — `ventilate`'s guard tells agents to run none on the session's word;
- carries the definitions, the out-of-scope wall and a builder's bounds;
- has the agent leave `/run` to the gate when the review asks for it — the gate checks the running output, and a second app would fight the setup;
- has it leave the repo's own checks green, reverting any change of its own it can't make green, and return what it changed and skipped. An agent that couldn't run its skill has failed.

Log one line per skill — `R<n> simplify|code-review | what it changed, ≤15 words | paths` — commit, and gate again. A polish that changed nothing leaves its passing gate standing as the end.

A gate after polish that fails sends its failing definitions to build rounds with its gaps, like any round. When two such rounds don't bring a passing gate, or a polish agent fails twice, commit what's there, `git revert --no-edit <polish>..HEAD`, log `R<n> polish reverted | why, ≤15 words | paths`, and hand off that tree: it passed its gate. Polish and its repair rounds don't count toward the eight.

## 4. Stopping

Stop when the gate passes after polish. Stop short on a **plateau** — the same gap logged three rounds running for a definition the top of the ladder has had; compare the logged strings, not your impression — after **eight rounds**, when the setup or any non-builder agent **fails twice** (an empty return is a failure, never a pass), or as soon as a definition proves **impossible or contradictory** as written: that one is the user's call. Stopping short isn't failure — gate what you have and hand off the same way.

## 5. You orchestrate

You never touch the code, and you never pull source, diffs or transcripts into your context — agents return verdicts and log lines. The log, not your memory, decides stops and resumes. Keep `$LOG.progress` as a one-screen status.

## 6. Hand-off

Append `ventilate`'s `ventilation:` line to the log and write the commit message to `$LOG.msg` — the goal as subject; one line per definition, met, unverified, or its gap; one line for polish — what it changed, or why it was reverted; the log's `record:`. Then:

```sh
~/.claude/skills/implement-loop/scripts/handoff.sh
```

It pushes the record branch `implement-loop/<stamp>` (every round, the brief, the log), lays the run down as **one commit on the starting branch** with `.deliverable/` removed, pushes it, and cleans up. If it stops, follow only the recovery it prints — the work is safe on the record branch. Then tear the setup down.

Report for someone who never saw the run: each definition met, unverified or not, gaps in plain words; what polish changed, or why it was reverted; the commit and branch; the record branch, theirs to delete once merged, and `implement-loop-wip` if the hand-off noted the remote kept it; and if unfinished, their calls — widen the scope, adjust a definition, run longer, or take it as it stands. Open no PR; that's `stack-this`.
