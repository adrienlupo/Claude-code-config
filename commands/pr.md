---
allowed-tools: Bash(git:*), mcp__github__create_pull_request, AskUserQuestion
description: Ask the user for the PR perimeter, verify it against the diff, then branch, commit, push and open the PR
---

Current branch: !`git branch --show-current`
Status: !`git status --short`
Has commits: !`git rev-parse --verify -q HEAD >/dev/null 2>&1 && echo yes || echo no`
Full PR diff (merge-base with main through working tree): !`git rev-parse --verify -q HEAD >/dev/null 2>&1 && git diff "$(git merge-base main HEAD 2>/dev/null || git rev-parse HEAD)" || echo "(no commits yet - repository is unborn)"`

# PR Workflow

This skill exists to counter agentic-coding drift: the PR description must come from the user's own understanding of what they shipped, verified against the code — never auto-written from the diff. The diff injected above is for YOUR comparison only; do not summarize or reveal it before the user has stated their perimeter.

## Step 0 — Unborn repository bootstrap (only if "Has commits: no" above)

A PR needs a base commit to diff against; with zero commits on the branch there is nothing to branch off or compare to. Handle this before anything else, and skip Steps 1-5 entirely once done:

1. Tell the user plainly there are no commits yet, so this will be an initial commit directly on the current branch rather than a PR.
2. Ask what should go into this first commit (or accept it if already stated in the /pr arguments).
3. Review `git status --short` against that description — flag anything untracked that looks unrelated (e.g. secrets, editor config, build output) before staging.
4. Stage the confirmed files, commit with a conventional commit message derived from the user's description, and push with upstream tracking if a remote is configured.
5. Stop here. Do not open a PR — there is no base branch state to PR against yet.

## Step 1 — Blind perimeter question (always first)

Before showing the user anything about the diff — no file list, no stats, no summary:

- If the /pr invocation already contains a description of the work (arguments), treat that as the user's perimeter statement and skip the question.
- Otherwise ask, as a plain open question in text: "What is the perimeter of this PR — what does it change, and why?" Do NOT use AskUserQuestion with options here: options derived from the diff would leak it and break the blind test.

## Step 2 — Alignment check

Compare the stated perimeter against the full PR diff: everything between the merge-base with the target branch and the working tree, plus untracked files from git status.

Classify every difference:

- **Substantive divergence** — a behavioral or structural change the user did not mention, or something the user claimed that is absent from the diff. Red flag: go to Step 3.
- **Imprecision (doubt, not divergence)** — the user's statement is compatible with the diff but too vague to confirm alignment (e.g. "improved the chat endpoint" while the diff touches streaming AND error handling). The user is right but imprecise: align with AskUserQuestion, offering concrete interpretations drawn from the diff (the blind answer is already given, so leaking is no longer a concern). Repeat until the perimeter is precise enough to classify every change; unresolved doubt escalates to Step 3.
- **Mechanical fallout** — lockfiles, formatting, import renames that follow directly from a change the user did mention. List these for transparency; they never block.

If aligned: say so in one short message, list any mechanical fallout, and proceed to Step 4.

## Step 3 — Red flag: joint review

Misalignment means either the user's mental model is wrong or the code is wrong. Do not branch, commit, or create anything until resolved:

1. Present the divergences one at a time, with the relevant hunks referenced as file:line.
2. For each, the user classifies it: "I forgot this — keep it" or "unintended — remove it".
3. Remove unintended changes from the PR scope (unstage, revert, or stash) before continuing.
4. Exit condition: every divergence is classified AND the user restates the corrected perimeter in their own words. That restated perimeter replaces the original one.

## Step 4 — Branch, commit, push

- If the user didn't specify a target branch, ask (default: main/master).
- If on main/master, create a feature branch (`feat/...` or `fix/...`) named from the perimeter.
- Stage ONLY changes within the confirmed perimeter; out-of-perimeter changes stay uncommitted.
- Commit following conventional commits, message derived from the user's perimeter statement.
- Push with upstream tracking.

## Step 5 — PR description

Free-form prose — no imposed Why/What/Changes template. Rules:

- Written from the user's perimeter statement, in their framing, lightly edited for clarity. Nothing invented.
- Completed with concrete details from the diff only where the user's statement was vague, and only with details the user already saw or confirmed during the alignment check.
- Every substantive claim in the description must trace back to something the user said or explicitly confirmed.

Create the PR with mcp__github__create_pull_request.

## Important

- NEVER write the description from the diff alone.
- NEVER skip the blind question, even for tiny changes.
- If the purpose is still unclear after the user answers, keep asking — do not fill gaps from the diff.
