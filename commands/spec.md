---
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Grep, mcp__figma-desktop__get_metadata, mcp__figma-desktop__get_screenshot, mcp__figma__get_screenshot
description: Read a spec file and interview the user in depth, then write the refined spec back to the file.
---

Read this $ARGUMENTS and follow the process below. The input may range from a single sentence to an already detailed draft -- either way, the output must be an exhaustive, self-contained spec.

## Phase 1: Read the Spec

Read the spec file. Scan for Figma references:
- Figma URLs (e.g., `figma.com/design/...`)
- Figma node IDs (e.g., `1:2721`)
- Mentions of Figma frames, components, or screen names
- Any indication that a design exists (e.g., "see Figma", "maquette", "design", "ecran", "mockup")

## Phase 2: Figma Enrichment (if references found)

**Skip this phase entirely if no Figma reference is found.**

Otherwise, this phase is CRITICAL. Every Figma frame referenced MUST be fetched, analyzed exhaustively, and transcribed into the spec. The goal: a developer reading the spec alone, without Figma access, should know exactly what to build.

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

### Writing the Design Reference

For each screen, write a structured **"Design Reference"** sub-section directly in the spec:
1. Nested bullet list of every visual element
2. Exact labels and placeholder text as they appear in the mockup
3. Interaction descriptions (tap -> navigate to X, swipe -> delete)
4. Notes on anything ambiguous that needs clarification during the interview

**Do NOT write "see Figma" or "matches the mockup" -- transcribe everything into the spec.**

## Phase 3: Interview (THIS IS THE CORE OF THE SKILL)

This is the most important phase. Everything else exists to feed this step.

Interview me in detail using the AskUserQuestion tool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. but make sure the questions are not obvious.

Be very in-depth and continue interviewing me continually until it's complete, then write the fully enriched spec back to the file -- replacing the original content entirely. Every tradeoff, scope boundary, and design decision from the interview must be captured.