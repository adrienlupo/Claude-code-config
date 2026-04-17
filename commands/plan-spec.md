---
allowed-tools: Read, Glob, Grep, Write, Bash, mcp__figma-desktop__get_metadata, mcp__figma-desktop__get_screenshot, mcp__figma__get_screenshot
description: Write a detailed and comprehensive full plans based on given spec md file.
---

Read the spec file at $ARGUMENTS. Analyze every requirement, edge case, and dependency.

## Phase 1: Figma Enrichment (if references found)

Scan the spec for Figma references:
- Figma URLs (e.g., `figma.com/design/...`)
- Figma node IDs (e.g., `1:2721`)
- Mentions of Figma frames, components, or screen names
- Any indication that a design exists (e.g., "see Figma", "maquette", "design", "ecran", "mockup")

**Skip this phase entirely if no Figma reference is found.**

Otherwise, this phase is CRITICAL. Every Figma frame referenced MUST be fetched, analyzed exhaustively, and transcribed into the plan. The goal: a developer following the plan alone, without Figma access, should know exactly what to build.

### Fetching Figma Frames

1. **From URLs**: Extract `fileKey` and `nodeId` (convert `-` to `:` in nodeId), fetch with `mcp__figma__get_screenshot(fileKey, nodeId)`.

2. **From node IDs without URL**: Ask the user for the fileKey, then fetch.

3. **From vague references or user selection**: Call `mcp__figma-desktop__get_metadata()` to read the current Figma selection. If nothing selected, ask: "Please select the relevant frames in the Figma desktop app." Then fetch each node with `mcp__figma-desktop__get_screenshot(nodeId=...)`. Fetch multiple nodes in parallel.

4. **Multiple screens**: If the feature spans several screens, fetch ALL of them. Ask the user if there are additional frames to look at.

### Extracting Design Details

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

### Writing Design References in the Plan

For each screen, write a structured **"Design Reference"** section in the plan:
1. Nested bullet list of every visual element
2. Exact labels and placeholder text as they appear in the mockup
3. Interaction descriptions (tap -> navigate to X, swipe -> delete)
4. Notes on anything ambiguous

**Do NOT write "see Figma" or "matches the mockup" -- transcribe everything into the plan.**

## Phase 2: Write the Plan

Write a comprehensive, actionable implementation plan as a markdown file in the project's `plans/` folder, using the same base filename as the spec (e.g., `specs/foo.md` -> `plans/foo.md`).

Be specific: include field names, types, method signatures. Order steps by dependency. Reference existing codebase patterns. A developer should follow the plan step by step without guessing.

If Figma designs were analyzed in Phase 1, integrate the design references directly into the relevant implementation steps -- each step should specify what to build and exactly how it should look.

Do NOT ask questions -- just write the best plan from the spec as-is.

After the plan file is written, delete the original spec file from the `specs/` directory. Do not ask for confirmation.
