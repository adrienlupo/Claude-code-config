---
name: review-implement
description: Review every PR in the current stack with one subagent per PR (reusability, query cost, simplicity, dead code, hook hygiene), verify each finding with a fresh agent, implement the confirmed ones on the PR that owns the code, restack and push. Fully autonomous — never stops for the user. Use when the user says "review and implement", "review the stack and fix it", or invokes /review-implement on a pushed stack of dependent PRs.
argument-hint: "Nothing (the open stack on this branch), or a list of PR numbers"
---

Review every PR in the stack on this branch, fix what the review finds, restack and push. Fully autonomous — never stop for the user's input.

## Stack

`gh pr list --state open --json number,headRefName,baseRefName,title`, ordered bottom (base = main) to top; only the PRs given as argument if any. Each PR is reviewed against its own parent (`git diff base...head`), never against main. Read the root and every `apps/*/CLAUDE.md` (or the project's equivalent) first and pass them verbatim to every subagent.

## Review — one subagent per PR, in parallel

Read the diff, then the touched files whole, then grep the repo for whatever a finding depends on. Judge:

1. Reusability — duplicates or forks something that already exists (name it), or abstracts something with one caller.
2. Queries — API: N+1, queries in loops, over-fetching, two queries where one does it. Mobile: redundant fetches, bad cache keys, over-broad invalidation.
3. Simplicity & scalability — logic a smaller function, a type or an existing helper says better; conditionals that grow per `kind`; unbounded lists.
4. Dead code — unused exports, props, i18n keys, branches; leftovers an earlier PR in the stack made obsolete. Grep before reporting.
5. Hooks — useEffect that derives/syncs state or fetches what the data layer already has; useCallback/useMemo with no consumer that needs identity; useState mirroring a prop; custom hooks with one caller or wrapping one built-in. Name the replacement.

Findings: `path:line`, problem, concrete fix, must-fix / should-fix / nit. Verified only — no style, no praise, no untouched code. Do not edit.

## Verify — one fresh subagent per must-fix and should-fix, in parallel

Given one finding, try to prove it wrong: open the thing it says to reuse, count the queries, grep for the symbol, check the hook replacement keeps behaviour. Return CONFIRMED with the fix restated precisely, or REJECTED with the reason. Nits are dropped without verification.

## Implement — one subagent per PR with confirmed findings, own worktree each

Apply only the confirmed findings, on that PR's branch. Follow CLAUDE.md. Run that app's typecheck, lint and tests; a finding you can't get green is reverted and reported. One commit, no push, no rebase.

## Restack

Rebase bottom to top (the gh-stack skill if it fits). Non-mechanical conflict → drop that commit and note it. Typecheck, lint and test the top of the stack. Green → force-with-lease push every branch. Red → push nothing, report the output verbatim.

## Report

Table: PR | file:line | finding | confirmed/rejected | applied/skipped/dropped | reason. Then pushed or not.
