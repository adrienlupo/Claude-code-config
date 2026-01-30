---
name: push-pr-review
description: PR submission workflow that creates a pull request with clear context, then performs an unbiased code review. Use when: (1) user says "push PR", "submit PR", "create PR and review", (2) user wants to finalize changes and get them reviewed, (3) after completing a feature or fix and ready to submit. Chains PR creation, context clearing, and code review for objective feedback.
---

# Push PR Review

Submit a PR and get an unbiased code review in one workflow.

## Workflow

Execute these steps in order:

### 1. Create PR

Create the pull request using `gh pr create`:

**PR Description Format:**
```markdown
## Summary
[Problem being solved OR feature being added - 1-2 sentences]

## Changes
[Bullet list of what was implemented]
```

- Derive summary from conversation context (the problem/feature discussed)
- List actual changes from git diff
- Use concise, clear language

### 2. Clear Context

Run `/clear` to reset the conversation. This ensures the review is objective and not biased by implementation discussion.

### 3. Review PR

Run `/review` on the newly created PR. The fresh context provides unbiased analysis.

## Example Invocation

User: "push pr and review"

1. Create PR with summary + changes
2. `/clear`
3. `/review`
