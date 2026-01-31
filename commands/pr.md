---
allowed-tools: Bash(git:*), Bash(gh:*), AskUserQuestion
description: Create branch, commit, push and open a PR with clear context
---

Current branch: !`git branch --show-current`
Changes: !`git status --short`
Diff: !`git diff HEAD`

# PR Workflow

Create a pull request with a meaningful description that explains the WHY.

## Steps

1. **Check base branch**: If user didn't specify, ask which branch to target (default: main/master)

2. **Create feature branch** (if on main/master):
   - Name format: `feat/description` or `fix/description`
   - Ask user for branch name if unclear from changes

3. **Stage and commit**:
   - Stage relevant changes
   - Create commit following conventional commits

4. **Push** with upstream tracking

5. **Create PR** with `gh pr create`:

**PR Description Format:**

```markdown
## Why

[The reason this PR exists - what problem, bug, or need triggered this work]

## What

[The approach taken - explain the solution at a high level]

## Changes

[Bullet list of specific modifications]
```

The "Why" section is critical - reviewers need to understand the motivation, not just the code.

## Important

- NEVER create a PR without understanding WHY these changes are needed
- If the purpose is unclear from the diff, ASK the user to explain the context
- Keep the description concise but complete
