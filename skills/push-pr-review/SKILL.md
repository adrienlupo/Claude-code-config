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

**PR Description Format (Critical for Review Context):**

```markdown
## Context
[WHY this PR exists - the problem, bug, or feature request that triggered this work]

## Solution
[WHAT approach was taken to solve it - high-level explanation]

## Changes
[HOW it was implemented - bullet list of specific changes]
```

The Context section is crucial - it provides the reviewer with full understanding after `/clear` removes conversation history.

7. **Output the PR URL** and instruct user:

```
PR created: <URL>

For unbiased review, run:
/clear

Then:
/review <URL>
```

## Phase 2: Review (User-triggered)

After `/clear`, user runs `/review <PR-URL>`. The PR description provides all necessary context for objective code review.
