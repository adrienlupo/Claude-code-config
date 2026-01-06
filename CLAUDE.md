# General Style

1. **Do not use emojis**

# Code Quality Standards

## Core Principles (Priority Order)

1. **Simplicity**: KISS over cleverness - simple beats complex
2. **Minimalism**: YAGNI - only build what's explicitly needed
3. **Clarity**: Self-documenting code - comments explain "why", not "what"
4. **Single Responsibility**: One function, one purpose

## Naming Conventions

- Descriptive and pronounceable names that reveal intent
- No abbreviations unless universally understood in the domain
- Follow language/framework conventions consistently

## Function Design

- Maximum 3 parameters (use objects/configs for more)
- No side effects unless function name indicates it
- Early returns over nested conditionals

## Code Organization

- DRY: Extract reusable logic immediately
- Remove dead code on sight
- Explicit error handling - no silent failures

---

# Tool Usage Guidelines

## Context7 MCP - When to Use

**Always query Context7 before implementing when:**

- Working with external libraries/frameworks
- Uncertain about API signatures or best practices
- Library documentation may have changed recently
- Implementing features with unfamiliar dependencies

**Workflow**: Resolve library ID → Query docs → Implement

---

# Implementation Constraints

- **No over-engineering**: Solve the current problem, not future hypotheticals
- **No extra features**: Stick strictly to requirements
- **No premature optimization**: Make it work, then make it fast (if needed)
- **Consistent style**: Match existing codebase formatting
