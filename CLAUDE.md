# Code Style

- Always use absolute paths for imports - never relative paths
- No emojis in code, comments, or documentation
- Maximum 3 function parameters (use objects/configs for more)
- Early returns over nested conditionals

# Tool Usage

## GitHub MCP

Always prefer GitHub MCP tools over `gh` CLI for GitHub operations (PRs, issues, repos, code search).
Use `mcp__github__create_branch` + `mcp__github__push_files` instead of `git push` — the sandbox blocks writing to `.git/config`, which breaks push when Git LFS is enabled.

## Context7 MCP

Always query Context7 before implementing with external libraries/frameworks:
resolve-library-id -> query-docs -> Implement

# Memory Rules (when using `#` to save learnings)

- Generic preferences (style, tools, workflow) -> save here (`~/.claude/CLAUDE.md`)
- Project-specific rules (build, test, lint, architecture) -> save in the project's `./CLAUDE.md`

# Workflow

- **Cleanup after PR merged:**

```bash
git worktree remove ../project-feature-name
```
