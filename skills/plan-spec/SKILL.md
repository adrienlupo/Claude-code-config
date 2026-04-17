---
name: plan-spec
description: >-
  Turn a spec markdown file into a detailed, agent-executable implementation
  plan -- either written locally to plans/ or posted as a GitHub issue. Pulls
  in Figma designs when referenced, grounds every step in real codebase paths
  via a mandatory pre-read pass, and structures steps with files-to-touch,
  acceptance criteria, and verification commands so a coding agent can run
  the plan end-to-end. Use whenever the user asks to plan, scaffold, or break
  down a spec, references a file in specs/ and wants next steps, or says
  things like "write a plan for this", "turn this spec into a plan", "faire
  le plan", or "plan-spec".
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
  - mcp__figma-desktop__get_metadata
  - mcp__figma-desktop__get_screenshot
  - mcp__figma__get_screenshot
  - mcp__github__issue_write
---

# Plan a spec

Read the spec file (path comes from the conversation context -- the user's message, an opened file, or a referenced path). If the path is unclear, ask for it before doing anything else. Then analyze every requirement, edge case, and dependency.

## Phase 1: Figma enrichment (if references found)

Scan the spec for Figma references:
- Figma URLs (e.g., `figma.com/design/...`)
- Figma node IDs (e.g., `1:2721`)
- Mentions of Figma frames, components, or screen names
- Any indication that a design exists (e.g., "see Figma", "maquette", "design", "ecran", "mockup")

**Skip this phase entirely if no Figma reference is found.**

Otherwise, this phase is CRITICAL. Every Figma frame referenced MUST be fetched, analyzed exhaustively, and transcribed into the plan. The goal: a developer following the plan alone, without Figma access, should know exactly what to build.

### Fetching Figma frames

1. **From URLs**: Extract `fileKey` and `nodeId` (convert `-` to `:` in nodeId), fetch with `mcp__figma__get_screenshot(fileKey, nodeId)`.

2. **From node IDs without URL**: Ask the user for the fileKey, then fetch.

3. **From vague references or user selection**: Call `mcp__figma-desktop__get_metadata()` to read the current Figma selection. If nothing selected, ask: "Please select the relevant frames in the Figma desktop app." Then fetch each node with `mcp__figma-desktop__get_screenshot(nodeId=...)`. Fetch multiple nodes in parallel.

4. **Multiple screens**: If the feature spans several screens, fetch ALL of them. Ask the user if there are additional frames to look at.

### Extracting design details

For EACH Figma frame, study the screenshot meticulously and extract every detail:

- **Layout**: full hierarchy -- screen > sections > cards > rows > cells. Scroll direction if content overflows.
- **Components**: every button, input, list, modal, bottom sheet, badge, FAB, icon, toggle, checkbox, radio, dropdown, date picker, avatar, divider. Note exact position.
- **Typography**: heading levels, label styles, body text, placeholder text. Note weight (bold, semibold, regular), relative size, and color.
- **Colors**: background, card fill, borders, accent/brand colors, status colors (success/warning/error), text colors.
- **Spacing & sizing**: relative padding, margins, gaps, corner radius, icon sizes.
- **States**: empty states, loading states, error states, selected/active states, disabled states. Fetch and document each if multiple states exist.
- **Interactive elements**: what is tappable, swipeable, long-pressable, expandable/collapsible. Where each interaction leads.
- **Data displayed**: exact field names, labels, placeholder text, units, formats (dates, phone numbers, currency).
- **Navigation**: header title, back button, tab bar state, where each tappable element leads.
- **Conditional UI**: elements that appear/disappear based on role, state, or data.

### Writing design references in the plan

For each screen, write a structured **"Design Reference"** section in the plan:
1. Nested bullet list of every visual element
2. Exact labels and placeholder text as they appear in the mockup
3. Interaction descriptions (tap -> navigate to X, swipe -> delete)
4. Notes on anything ambiguous

**Do NOT write "see Figma" or "matches the mockup" -- transcribe everything into the plan.**

## Phase 2: Codebase grounding (mandatory)

Before writing any step, ground the plan in real code. The plan will be executed by a coding agent, so every reference must point to a file that actually exists with the name you cite.

For each concept mentioned in the spec -- components, hooks, services, endpoints, utilities, types, config -- locate the real file:

1. **Glob the spec's vocabulary**: if the spec says "the user card", grep for `UserCard`, `user-card`, `UserRow`. Find the canonical name used in the codebase.
2. **Read neighbors**: once a relevant file is found, read the surrounding directory to understand folder conventions (tests, types, styles, stories).
3. **Identify the extension points**: where exactly will the new code attach? Which file imports this component? Which router config registers this route?
4. **Note existing libraries**: form library, state manager, HTTP client, styling system, icon set. The plan must reuse these, not introduce new ones.

Keep a running list of confirmed paths. Every step in the plan will cite at least one of them.

## Phase 3: Write the plan

Write a comprehensive, agent-executable implementation plan. Use this structure:

```markdown
# <Feature name>

## Context
<1-3 sentences: what this is, why, link back to spec file path>

## Files touched
- path/to/file/a (new)
- path/to/file/b (modified)
- ...

## Out of scope
- <explicit list of things NOT to do, to stop the agent from wandering>

## Acceptance criteria
- [ ] <user-visible outcome 1>
- [ ] <user-visible outcome 2>
- [ ] Tests pass: <exact command>
- [ ] Typecheck passes: <exact command>

## Dependency graph
Step 1 -> Step 3, Step 4
Step 2 (independent)
Step 3 -> Step 5
...

## Steps

### Step 1: <short imperative title>
**Files:** path/to/file (new|modified)
**What to do:** <concrete changes, field names, types, method signatures>
**Design reference:** <only when Figma was analyzed -- transcribed visual details>
**Verify:** <command to run, expected output, or test file to check>

### Step 2: ...
```

Rules:
- Every step names its files, its change, and its verification. No step should require the agent to guess.
- Include field names, types, method signatures verbatim when known.
- Cite the existing codebase patterns discovered in Phase 2 ("follow the pattern in `src/components/UserCard.tsx`").
- If Figma designs were analyzed in Phase 1, integrate the design references directly into the relevant step's "Design reference" field -- do NOT leave a separate Design Reference section at the end.
- Do NOT write "see Figma", "matches the mockup", or "use existing helpers". Every reference must be concrete.

### Strategy shift check

After drafting the plan, compare it to the spec. If the plan diverges from the approach the spec assumed -- different layer, different decomposition, different library, different data model -- this is a strategy shift and must not be silent.

Flag it explicitly:
1. Add a **"Strategy shift"** section at the top of the plan (right after Context) describing what changed from the spec and why (e.g., "spec assumed a new `useReservations` hook; plan reuses `useBookings` from `src/hooks/useBookings.ts` because it already handles the same lifecycle").
2. Prompt the user via AskUserQuestion with the options:
   - Accept the shift (keep plan as-is)
   - Revert to the spec's approach (rewrite affected steps)
   - Update the spec first (stop, edit the spec file to reflect the new strategy, then continue)

Do not proceed to Phase 4 until the user confirms.

## Phase 4: Choose output destination

Ask the user via AskUserQuestion whether to:
1. **Local file** — write to `plans/<name>.md` (same base filename as the spec).
2. **GitHub issue** — create an issue in a repo of the user's choice using `mcp__github__issue_write`.

### If local file
Write the plan to `plans/<name>.md` in the project.

### If GitHub issue
Derive the obvious fields yourself -- do not prompt for them:
- **Repo** (`owner/name`): read from the current git remote (`git remote get-url origin`).
- **Title**: use the spec's feature name (H1 or filename-derived).

Only ask the user via AskUserQuestion for fields that aren't obvious:
- **Labels**: offer the repo's existing labels (or common ones) and let the user pick.
- **Assignee**: offer the current GitHub user, no assignee, or free-text.

If deriving the repo fails (no git remote, ambiguous remote), ask for it. Otherwise proceed silently.

Then create the issue with `mcp__github__issue_write`, passing the plan as the issue body. Return the issue URL to the user.

## Phase 5: Handle the original spec

Ask the user via AskUserQuestion what to do with the original spec file:
- **Keep it** -- leave `specs/<name>.md` in place as a reference.
- **Delete it** -- remove it now that the plan exists.

Do not default to deletion -- this is now an explicit user decision.
