# Language

- When writing in French, always include proper accents (e.g., é, è, ê, à, ù, ç, etc.)

# Code Style

- Always use absolute paths for imports - never relative paths
- No emojis in code, comments, or documentation
- Maximum 3 function parameters (use objects/configs for more)
- Early returns over nested conditionals

# Tool Usage

## Context7 MCP

Always query Context7 before implementing with external libraries/frameworks:
resolve-library-id -> query-docs -> Implement

## GitHub

Always prefer GitHub MCP tools (`mcp__github__*`) over `gh` CLI. The sandbox blocks Go TLS certificate verification, making `gh` unreliable. MCP tools work directly via the API without TLS issues.

# Workflow

- **Cleanup after PR merged:**

```bash
git worktree remove ../project-feature-name
```
