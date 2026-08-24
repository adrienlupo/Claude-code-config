---
description: Read the review comments on a PR, assess each one, argue when I'm wrong, then implement only what we agreed on
argument-hint: "[PR number]"
---

PR: $ARGUMENTS
Current branch: !`git branch --show-current`

# PR Comment Review

I reviewed my own PR and dropped comments. Your job is to assess them — not to obey them. Comments are my hypotheses, and some of them are wrong.

## Step 0 — Branch check (before anything else)

If no PR number was given above, ask me for it and wait. Don't guess it from the current branch.

Then read the PR's head branch (`gh pr view <PR> --json number,title,headRefName,state`) and compare it to the current branch:

- **Match** — say which PR and branch you're on, and continue.
- **Mismatch** — stop. Report both branches and the checkout command (`git checkout <headRefName>`). Do not fetch comments, do not read the diff, do not offer to switch branches yourself.

## Step 1 — Collect

Fetch the PR diff, its review comments and its issue comments (`mcp__github__pull_request_read`). Skip resolved threads and anything already answered.

For each comment, read the actual code at the referenced `file:line` before forming an opinion. Never assess a comment from its text alone.

## Step 2 — Assess

Classify each comment:

- **Question** — I asked something. Answer it, from the code, with a `file:line`.
- **Change request** — I want something different. State whether you agree, then say why.
- **Wrong premise** — the comment misreads the code, or the thing it asks for breaks something elsewhere. Say so plainly and show the evidence.

Then present a single ordered list: comment → your position (agree / disagree / needs a decision from me) → one-line rationale. No code changes yet.

## Step 3 — Discuss

Work through the list one comment at a time. Don't batch.

- Where you disagree, argue for it. Don't fold because I pushed back once — fold when I give you a reason.
- Where a comment opens a real design branch (several defensible answers, consequences beyond the diff), invoke `/grill-me` on that branch instead of guessing.
- Where the answer is in the codebase, go read it rather than asking me.

Exit condition: every comment is marked **fix**, **won't fix** (with the reason), or **deferred** (with where it goes — issue, follow-up PR).

## Step 4 — Implement

Only the comments marked **fix**, and nothing else. No opportunistic cleanup, no adjacent refactor.

Follow the repo's own gates (`CLAUDE.md` in the touched workspace: tests, coverage, OpenAPI, whatever it demands). Commit with conventional commits, one commit per coherent fix, and push.

## Step 5 — Close the loop

Reply on GitHub to each thread (`mcp__github__add_reply_to_pull_request_comment`): what was done and the commit, or why it won't be done. Then give me a short recap: fixed / won't fix / deferred.

## Important

- Never implement before Step 3 closes.
- Never agree with a comment you can't justify from the code.
- A comment I wrote is not an instruction — it's a claim to verify.
