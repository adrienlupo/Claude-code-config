---
name: push-pr-review
description: PR submission workflow that creates a pull request with clear context, then performs an unbiased code review. Use when: (1) user says "push PR", "submit PR", "create PR and review", (2) user wants to finalize changes and get them reviewed, (3) after completing a feature or fix and ready to submit. Automates PR creation, then guides user through context clearing for objective review.
---

# Push PR Review

Automated PR workflow with unbiased review.

## Phase 1: Create PR (Automated)

Execute these steps automatically:

1. **Check git status** - Identify staged/unstaged changes
2. **Ask user** which changes to include if mixed/unclear
3. **Create feature branch** if on main/master
4. **Stage and commit** the selected changes
5. **Push to remote** with upstream tracking
6. **Create PR** using `gh pr create` with this format:

```markdown
## Summary
[Derive from conversation: problem solved OR feature added - 1-2 sentences]

## Changes
[List from git diff: bullet points of what was implemented]
```

7. **Output the PR URL** and instruct user:

```
PR created: <URL>

For unbiased review, run:
/clear

Then:
/review <URL>
```

## Phase 2: Review (User-triggered)

After `/clear`, user runs `/review <PR-URL>` for objective code review with fresh context.
