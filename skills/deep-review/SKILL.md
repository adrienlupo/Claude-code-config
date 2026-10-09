---
name: deep-review
description: Get a committed diff — a branch, or a whole stack of PRs — as clean as it can be before the user's own review, design first. Use when the user says "deep review", has a diff from implement-loop or stack-this, or wants a branch clean before a human reads it.
argument-hint: "Nothing, or a ref as the fixed point; --design-twice, --publish"
---

**Code quality matters, not only behaviour.** Working code that is badly written fails this review. The job is to leave the diff as clean as it can be before the user reads it; it does not replace that reading. Design first, so nothing gets polished that will be redesigned; quality before bugs, so the bug hunt reads the final code, a bug a quality fix introduced included.

Only the user starts this skill, and the user is in the room: a design finding is theirs to decide; everything after a passing gate runs through to the push without a question.

## 1. The diff

Committed changes only — `git diff <fixed point>...HEAD`, three-dot. The fixed point is the merge-base with the default branch; a ref argument overrides it. Load `gh-stack`: a stack (`gh stack view --json`) is reviewed from its top branch with the stack's trunk as the fixed point. Fail before any agent runs: a ref that doesn't resolve, an empty diff. Uncommitted changes: tell the user to commit first, and stop.

## 2. The intent

The gate judges the code against what it was meant to do. Take the first found: a `deliverable` brief (`.deliverable/brief.md`, or once the loop has removed it, on the `implement-loop/*` record branch whose log `sha:` is an ancestor of HEAD); a linked issue; the PR description(s); the commit messages; failing all, one question to the user — "what was this change meant to do?" Never guess it.

## 3. Agents

Load `ventilate` and dispatch every agent through Workflow scripts with its `run()`; this skill's instruction to call Workflow is the user's opt-in. Its review table names each role's model and effort. Each prompt names its skill as the agent's own task — the GUARD stops agents running skills on the session's word. Agents return verdicts, findings and commit shas, never the diff into your context; you write the pages. `simplify` and `code-review` spawn their own sub-agents outside `run()`, so `ventilate`'s Proof names them: expected.

Workflow agents cannot ask the user anything, so the design gate is one workflow, you handle its stop, and the fix stages are a second.

## 4. Design gate — the whole diff, or the whole stack

Load `mattpocock-skills:codebase-design` and give its vocabulary — module, interface, seam, depth, leverage, locality — to every agent here and to the baseline agent. The question, given the intent: is this the most maintainable, most straightforward implementation? With it: what the intent asks for and the diff misses, and work nobody asked for.

A triage judge first decides whether the change carries a real design decision — a new module, interface, data model or dependency. If it does, or `--design-twice` was passed, it names the candidate module and returns the designers' technical brief, and Design It Twice runs from `codebase-design`'s `DESIGN-IT-TWICE.md`: exactly three designers draft the alternatives, the gate compares them and rules, and the framing and the comparison come back for the design page — nothing is shown to the user from inside the workflow. Otherwise the gate is a single challenger. The gate also returns what the user must read themselves: interface, schema and dependency changes, and one-way doors — data loss, migrations, mass emails.

**Pass**: continue to the end, push included, asking nothing more. **Finding**: stop, write the design page (§7), open it, and let the user decide — keep the design and continue, or redesign. A redesign ends the run: append the `ventilation:` line to the log and stop.

## 5. Fixes

One pass per stage, acting on the cited findings, then stop — a review is never looped until it comes back clean. Small, safe fixes (dead code, reusing an existing helper, a bug fix with its test) are applied; design and interface changes are reported only. On a stack each agent's target is its slice's own range — `simplify`'s is the whole stack (§6); otherwise `<fixed point>...HEAD`. Once its skill returns, the agent commits each finding on its own, so any one reverts alone, and returns the shas.

- **Quality** — one agent runs the `simplify` skill. Then a fresh one fixes against `BASELINE.md` plus the repo's own standards — `CLAUDE.md`, `AGENTS.md`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `.cursor/rules/`. The repo wins where they disagree; skip anything tooling already enforces. Every finding cites the rule and quotes the hunk.
- **Bugs** — one agent runs the built-in `code-review` skill at `high` with `--fix`.
- **Docs** — once, on the whole diff, alongside the first bug pass, only when a judge says the diff relies on a third-party library's API or a framework's conventions (Expo, NestJS…: config, decorators, file-based routing, lifecycle), or bumps a dependency — internal code alone never triggers it. The checker uses an installed doc-first skill for the framework first (`expo:*`, `cloudflare`, `wrangler`, `workers-best-practices`, `durable-objects`), the Context7 MCP for everything else, and checks against the version in the lockfile. It reports and changes nothing.
- **Verify** — after each stage that changed code, a capture runs the repo's own checks (`CLAUDE.md`, else `package.json` scripts). Red: revert that stage's commits and record it for the report.

## 6. Stacks

The gate reads the whole stack, and `simplify` runs once over it, before the slices — one agent, on the top branch, over `<trunk>...HEAD` — then carries each fix down to the lowest slice that introduced the code, bottom up, each slice it touches green on its own base and restacked; a fix that won't apply there is dropped and goes in the report. The baseline fixer and bugs then run slice by slice, bottom up: a slice's agents change only their slice but get the whole stack's diff read-only, so duplication across slices is still caught. A fix lands in the lowest slice that introduced the code — `stack-this`'s rule for hunks. After each slice: green on its own base, then restack the slices above it with `gh-stack`. A restack conflict (exit 3 restores every branch) reverts that fix, restacks again, and goes in the report; conflicts are never resolved here. Every layer green: resubmit the stack with `gh-stack` — the gate passed, so nothing waits on a confirmation. With no stack, the same pipeline runs on the whole diff, and the branch is pushed if it has an upstream.

## 7. Report

From the repo toplevel, log the run to `$(git rev-parse --git-common-dir)/deep-review.log` — one line per stage: what ran, what it changed, its commits — and append `ventilate`'s `ventilation:` line before writing the report.

The report is one self-contained HTML file, `$(git rev-parse --git-common-dir)/deep-review/<short sha of the reviewed tip>.html`, never in the working tree. Open it in the browser; with `--publish`, publish it as a private Artifact instead. Sections: design verdict · what was changed, each commit with its link · bugs · docs check · reverted stages · open questions · **read this yourself** — the gate's list.

The design page, only when the gate stops, is a separate file in the same place: the current design beside the alternative(s), diagrams, the trade-offs in depth, locality and seam placement, a recommendation, and the decision the user must make.

Both pages: short — dense pages don't get read — readable in light and dark, no external dependencies.
