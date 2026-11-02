---
name: implement-loop
description: Run a deliverable brief unattended until every definition of done passes its check and a fresh agent confirms it on the real output, then push the branch with the brief removed. Use when the user asks to run the implement loop or implement a brief, or has one from the deliverable skill.
argument-hint: "Nothing, or a path to a brief"
---

The brief says what done is and how to check it; everything in between is yours. The user settled it and left: nothing waits on approval.

## You orchestrate

Your context is the run's scarcest resource: it has to last every round, and each file, log or screenshot that lands in it stays there. So the work happens in workflow agents, and you hold the brief's path, each round's results and git. Your own calls are git, the run directory, launching workflows with `ventilate`'s two checks around each, and `lsof` on the brief's port. Writing code or checks, running a test, starting a server, opening a browser, reading a source file, a log, a journal or a transcript: each is an agent's task. When a result puzzles you, send the question and the paths to an agent. On 2026-10-26 a loop launched 22 workflows and still peaked at 548K tokens of context: it ran the suite, drove Chrome and debugged in its own session — 258 shell calls.

Every agent answers through a `schema` that bounds it: a status, the command it ran, a `tail` of at most 15 lines of 300 characters, and paths — screenshots and full logs saved in the run directory, files it changed. Pass a path on to the next agent; leave the file unopened.

The run directory is `implement-loop/<stamp>/` in the session's scratchpad, else under an absolute `$TMPDIR` — outside the repo and `.git`, where every write prompts. Load `ventilate`: every agent goes through its `run()`. Write one script per kind — checks, build, verify — and launch it by `scriptPath` with the round's `args`, saved as `state.json` in the run directory: after a compaction, read it back.

Wrap each `run()` so an agent that stalls, errors or returns `null` comes back as `{status: 'error', reason}`: that is a failed attempt, one rung up. A launch error is a bug in your script: fix it and relaunch.

## 1. The brief

`.deliverable/brief.md` unless a path was given. Say in one line which goal it holds. Missing, or not the goal the user asked for: run `deliverable` first.

`brief.md` and `assets/` are read-only: a definition rewritten mid-run has been deleted, not met. `## Out of scope` is a wall.

Work on the brief's branch, from a clean tree — uncommitted changes are the user's: stop and say so. The run is unattended only in auto mode, or with `Workflow` and the repo's commands allow-listed: otherwise say what will prompt, before the user leaves.

Propose the session goal, for the user to set with `/goal` before leaving:

> The last round's results show every definition in the brief green and confirmed by a fresh verifier, and the hand-off commit is pushed.

The goal's evaluator reads only this conversation, so the round results you print are its evidence: run nothing to show it. At a check-in while a workflow runs, wait unless its task has ended.

## 2. Checks first

The checks workflow turns every check into something that runs without a human: a test in the repo's own suite, in a file of its own, where it has one, otherwise a script under `.deliverable/checks/` — Playwright for a browser check, headless, at the brief's viewport — reaching the state under test in one step: a seed, a fixture, a deep link. Writers whose checks start a server or a browser run one after another, since they share its port; the others run in parallel. A writer reads its definition in the brief, runs its check on the current tree, adds the tool output it leaves in the tree to `.gitignore`, and returns the check's path and command, whether it fails and why in one line, and the files the check reads — fixtures, seeds, baselines, runner config. Those files and the check are the definition's protected set.

A check fails where the work isn't built, for the reason its definition gives. One that fails for another reason goes back to a writer, twice at most; then the definition is the user's call. One that passes is met at start: it gets no builder, and the verifier still confirms it.

Design, copy and feel stay a judgement: their check is a capture — the output at the brief's viewport, saved in the run directory — decided by a blind judge: a fresh `opus` agent shown the capture and the reference as A and B, in an order you draw with `$((RANDOM % 2))` and pass in `args` (a script can't call `Math.random()`), asked whether each meets the bar.

The workflow ends on one capture of the repo's full tests, typecheck and lint: the baseline, saved in the run directory. Commit the checks with one body line per definition, `D2: <path> — <command>`. A later run on this branch reads that map from `git log` and starts with a round that has no builder.

## 3. Rounds

A round is two workflows with a commit between them.

**Build** — a red definition whose check passed when the verifier refuted it goes first to a writer, with the verifier's words: the rewritten check must fail on the current tree for that reason. Then one builder per red definition, in sequence, each on the tree the last one left. A builder gets the brief's path and its definition's id, the check's path and command and, on a retry, the words that failed it; it reads its definition and the out-of-scope wall in the brief. It builds until its check passes with no suite failure beyond the baseline, and commits nothing. A check stays as strict as its definition: a failing check is fixed in the code, and the protected set is read-only to builders. Then one capture runs every check and the full suite against the baseline, and each judged definition goes to a blind judge. The workflow returns, per definition, the builder's status and files and the check's result, plus the suite's new failures with their tails.

Between the two:

1. `git status --porcelain -- <protected sets>` shows only sets a writer rewrote this round. A builder that touched its set failed its definition, whatever the check says: `git restore` the set.
2. Commit the whole tree, the subject naming each definition that went green (`D2, D3: …`), the body each red one as `WIP Dn: <its failure>`.

**Verify** — when nothing is red and the suite holds its baseline: one fresh verifier, the run's gate in `ventilate`'s terms, on the committed HEAD, that has seen none of the work. It gets the brief, `assets/` and how to start and reach the output; it frees the brief's port first, and refutes each definition against the real output — the page, the endpoint, the command's result — never the diff. It may run the checks, but it judges by the brief's words. For a judged definition it saves a fresh capture, and a new blind judge decides it. It stops what it started, and returns per definition pass or fail with its evidence: the command and its tail, or a screenshot path.

The next round takes each red or refuted definition one rung up `ventilate`'s builder ladder, with the words that failed it. A new suite failure goes to the builder whose files it touches, else to a `suite` builder on the same ladder.

Hand off early, as it stands, when a definition fails the same way three rounds running, fails at the top rung, or proves impossible or contradictory as written, or when the suite shows the same new failures two rounds running with nothing red — each is the user's call — and at once when a `ventilate` check stops the run.

## 4. Hand off

Agents stop the servers they start; if one still listens on the brief's port, stop it. Run `git rm -rq --ignore-unmatch .deliverable && rm -rf .deliverable` (an empty `assets/` stays behind otherwise), commit with the goal as subject and one line per definition — met, or its gap — and `git push -u origin HEAD`. A rejected push means the branch moved: tell the user, whose commits those are.

Report for someone who never saw the run: each definition met or not, with the verifier's evidence; the branch and commit; `ventilate`'s `ventilation:` line; and when unfinished, their calls — adjust a definition, widen the scope, run longer, or take it as it stands. Open no PR: that's `stack-this` or `pr`.
