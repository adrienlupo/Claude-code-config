---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Optionally pass a spec file (e.g. /grill-me spec.md) to ground the interview and update it in place. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
argument-hint: "[path-to-spec.md]"
---

If a file path is given here, read it and treat it as the basis of the implementation: $ARGUMENTS

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

When we're done, if a spec file was provided, update it in place to reflect what we settled. Don't invent decisions we didn't make.
