---
allowed-tools: Read, Glob, Grep, Write, Bash
description: Write a detailed and comprehensive full plans based on given spec md file.
---

Read the spec file at $ARGUMENTS. Analyze every requirement, edge case, and dependency.

Write a comprehensive, actionable implementation plan as a markdown file in the project's `plans/` folder, using the same base filename as the spec (e.g., `specs/foo.md` -> `plans/foo.md`).

Be specific: include field names, types, method signatures. Order steps by dependency. Reference existing codebase patterns. A developer should follow the plan step by step without guessing.

Do NOT ask questions — just write the best plan from the spec as-is.

After the plan file is written, delete the original spec file from the `specs/` directory. Do not ask for confirmation.
