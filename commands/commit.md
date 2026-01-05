---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a conventional commit
model: haiku
---

Current changes: !`git status`
Diff: !`git diff HEAD`

Create a single git commit following Conventional Commits specification.

Format: <type>[optional scope]: <description>

Choose the appropriate type:

- feat: new feature
- fix: bug fix
- docs: documentation only
- style: formatting, no code change
- refactor: code change, neither fix nor feature
- perf: performance improvement
- test: adding or updating tests
- build: build system or dependencies
- ci: CI configuration
- chore: other changes

Examples:

- "feat: add user authentication"
- "fix: prevent racing of requests"
- "docs: correct spelling of CHANGELOG"
- "feat(lang): add Polish language"
- "refactor(parser): simplify token handling"

Keep it simple and direct.
