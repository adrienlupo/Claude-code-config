---
name: implement-loop
description: Run a deliverable brief unattended until every definition of done passes its check and a fresh agent confirms it on the real output, then push the branch with the brief removed. Use when the user asks to run the implement loop, has a brief from the deliverable skill, or says "implement the brief".
argument-hint: "Nothing, or a path to a brief"
---

The brief says what done is and how to check it; everything in between is yours. The user settled it and left: nothing waits on approval.

## 1. The brief

`.deliverable/brief.md` unless a path was given. Say in one line which goal it holds. Missing, or not the goal the user asked for: run `deliverable` first.

`brief.md` and `assets/` are read-only: a definition rewritten mid-run has been deleted, not met. `## Out of scope` is a wall.

Work on the brief's branch, from a clean tree — uncommitted changes are the user's: stop and say so. Commits from an earlier run on this branch are your starting point; the checks tell you where it got to.

Set the session goal — propose it, or ask the user to run `/goal` with it:

> Every definition in .deliverable/brief.md passes its check on the current tree, shown by the command and its output, and a fresh verifier agent has confirmed each one.

## 2. Checks first

Turn every check into something that runs without a human: a test in the repo's own suite where it has one, otherwise a script under `.deliverable/checks/` — Playwright for a browser check, headless, at the brief's viewport. Reach the state under test in one step: a seed, a fixture, a deep link. Run each on the current tree: it fails where the work isn't built, for the reason its definition gives. Commit them.

## 3. Build

Build until every check passes, with the repo's own tests, typecheck and lint green. Commit each time a definition goes green, naming it (`D2: …`). A check stays as strict as its definition: when one fails, fix the code. Hand a subagent only a substantial, standalone part.

When several definitions are independent — separate parts of the code — and each is a substantial job, build them in parallel in a workflow, one builder per definition, through `ventilate`'s `run()` and both its checks; a check that stops the run sends you straight to §5. A builder gets its definition and check verbatim, the out-of-scope wall and, on a retry, the verifier's words, and leaves committing to you: once the workflow returns, commit each definition that went green.

## 4. Verify

Spawn one fresh agent (`model: "opus"`) that has seen none of the work. Give it the brief, `assets/` and how to reach the running output, and ask it to refute each definition against the real output — the page, the endpoint, the command's result — never the diff. It may run your checks, but it judges by the brief's words. Design, copy and feel it judges blind: the build's output and the reference, unlabelled, against the bar. It returns, per definition, pass or fail with its evidence: the command and its output, or a screenshot path.

A fail goes back to §3 with the verifier's words, then to a new verifier. All pass: hand off.

Hand off early, as it stands, when a definition fails the same way three attempts running, or proves impossible or contradictory as written — that one is the user's call.

## 5. Hand off

Stop any server you started. Run `git rm -rq --ignore-unmatch .deliverable && rm -rf .deliverable` (an empty `assets/` stays behind otherwise), commit with the goal as subject and one line per definition — met, or its gap — and `git push -u origin HEAD`. A rejected push means the branch moved: tell the user, whose commits those are.

Report for someone who never saw the run: each definition met or not, with the verifier's evidence; the branch and commit; after a workflow, `ventilate`'s `ventilation:` line; and when unfinished, their calls — adjust a definition, widen the scope, run longer, or take it as it stands. Open no PR: that's `stack-this` or `pr`.
