---
name: spec
description: >-
  Interview the user in depth to refine a spec markdown file, then write the
  enriched spec back to disk, followed by a self-review pass that challenges
  and simplifies the draft. Use whenever the user asks to refine, flesh out,
  enrich, or deepen a spec file, or points at a .md file in a specs/ folder
  and wants it developed further before planning or implementation. Also
  trigger on phrases like "interview me on this spec", "turn this idea into
  a proper spec", or "grill me and write it up".
allowed-tools:
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Glob
  - Grep
---

# Spec refinement

Take a spec file from a one-line idea (or a detailed draft) to an exhaustive, self-contained document through deep user interview, then a critical self-review pass.

## Input

The target spec file path comes from the conversation context -- a user message, an opened file, or a referenced path. If the path is unclear, ask the user for it before doing anything else.

## Process

### 1. Read the file

Read the spec file first. If not found, try reading it once more (the path may have been misresolved). If still not found on the second attempt, abort immediately -- do not interview, do not write anything, just inform the user that the file could not be found and stop.

### 2. Interview

Interview the user in detail using the AskUserQuestion tool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. but make sure the questions are not obvious.

Whenever a question relates to something that already exists in the codebase (a component, a helper, a hook, a pattern, an endpoint, a file), include the concrete file path in the question. The goal is to send the user to look at the actual code before answering, so the decision is grounded in what's really there.

Be very in-depth and continue interviewing continually until it's complete. The input may range from a single sentence to an already detailed draft -- either way, the output must be an exhaustive, self-contained spec.

### 3. First write

Write the fully enriched spec back to the file, replacing the original content entirely. Every tradeoff, scope boundary, and design decision from the interview must be captured.

If the spec contains Figma URLs, keep them in the final spec.

### 4. Self-review

After the first write, re-read the draft with fresh eyes and critique the approach from a code perspective. The goal is to reduce comprehension debt and reach full alignment on the outcome -- not to polish prose. Challenge the plan:
- Am I using the libraries already in the project, or am I introducing a new one for no good reason?
- Am I respecting the project's conventions (structure, naming, patterns, state management, styling)?
- Is there a different way to think about this -- a simpler decomposition, an existing pattern we could reuse, a different layer to solve it in?

When any of these are unclear, ask the user via AskUserQuestion with concrete options and cite the relevant file paths so the user can verify against the real code. Don't assume, don't self-answer.

Then rewrite the file with the agreed changes, replacing the previous draft.

### 5. Offer a plan

Ask the user via AskUserQuestion whether they want to create a plan for this spec now. If yes, invoke the `plan-spec` skill with the same file path to generate the implementation plan.
