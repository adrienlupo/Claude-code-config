---
name: figma-expo-verify
description: Visual QA verification between Figma designs and a running Expo native app. Use this skill whenever the user wants to compare their mobile app screens against Figma mockups, verify a UI implementation matches the design, do visual regression testing, check pixel-perfect accuracy, or says things like "compare with Figma", "verify against design", "check the screens", "does it match the mockup", "visual QA", "Figma vs app", "design review", "check my implementation", "does this look right", or "screenshot comparison". Also trigger when the user provides a Figma URL and mentions Expo, React Native, mobile screens, or simulator. This skill handles the full loop - fetching Figma screenshots, navigating the running app via Expo MCP, taking native screenshots, and reporting per-screen comparison results.
allowed-tools: mcp__figma__get_screenshot, mcp__figma__get_design_context, mcp__expo-mcp__automation_take_screenshot, mcp__expo-mcp__automation_tap, mcp__expo-mcp__automation_find_view, mcp__expo-mcp__expo_router_sitemap, Read, Glob, Grep, Bash
---

# Figma-Expo Visual Verification

You are a visual QA engineer. Your job is to systematically compare a running Expo native app against Figma design references, screen by screen, and report what matches and what differs.

## Before You Start: Gather Inputs

You need three things before running verification. If any are missing, ask the user.

### 1. Figma References

You need a `fileKey` and one or more `nodeId` values to fetch design screenshots.

**If the user provides a Figma URL**, extract from it:
- `figma.com/design/:fileKey/:fileName?node-id=:nodeId` -> fileKey and nodeId (convert `-` to `:` in nodeId)
- `figma.com/design/:fileKey/branch/:branchKey/:fileName` -> use branchKey as fileKey

**If the user provides nodeIds directly** (e.g., `1:2721`, `1:2564`), ask for the fileKey if not already known.

**If neither is provided**, ask:
> "I need the Figma reference to compare against. Can you share either:
> - A Figma URL (e.g., `figma.com/design/abc123/...?node-id=1-2`)
> - Or the fileKey and nodeIds for the frames you want to verify?"

### 2. Expo Project

- `projectRoot`: path to the Expo project (default: look for a `mobile/` subfolder in the current working directory, or use cwd if it has an `app.json`/`app.config.js`)
- `platform`: `ios` (iPhone 17 Pro simulator)

### 3. Screen Map

Ask the user which screens to verify and how they map to Figma frames. Example:
```
Screen: Menu -> Figma node 1:2721
Screen: Doctors list -> Figma node 1:2564
Screen: Doctor detail -> Figma node 1:2767
```

If the user has a plan document or implementation notes, read those to extract the mapping.

### 4. Planned Deviations

Before starting verification, collect ALL planned deviations -- places where the implementation intentionally differs from Figma. Sources to check:

1. **Ask the user directly**: "Are there any intentional differences from the Figma design?"
2. **Plan documents**: If the user references a plan doc, read it and extract any scope limitations, deferred features, or design changes.
3. **PR description / commit messages**: If relevant, check recent commits for notes about intentional departures.

Record each planned deviation in a structured list before starting Phase 1:
```
Planned Deviations:
- [Screen Name] / [Element]: [What differs] -- [Reason]
- Doctor detail / Specialty badge: Not shown -- deferred to v2
- Settings / Delete button: Missing -- out of scope
```

This list is your reference during comparison. Anything on it goes under "Planned Deviations" in the report, never under "Differences".

## Verification Workflow

### Phase 1: Fetch All Figma References (Parallel)

Fetch ALL Figma screenshots at once using `mcp__figma__get_screenshot`. Do them in parallel -- this is faster and gives you all references before you start navigating.

```
For each screen in the screen map:
  mcp__figma__get_screenshot(fileKey, nodeId, clientFrameworks="react-native,expo", clientLanguages="typescript")
```

Study each screenshot carefully. Note the key UI elements: layout structure, colors, typography, icons, spacing, card sizes, badges, buttons.

### Phase 2: Verify App is Running

Take an initial screenshot to confirm the app is running and determine the current screen:

```
mcp__expo-mcp__automation_take_screenshot(projectRoot, platform)
```

Also fetch the route sitemap to confirm all expected routes exist:

```
mcp__expo-mcp__expo_router_sitemap()
```

If the app isn't running or shows an error, tell the user to start the dev server first.

**Calibration step**: Use this initial screenshot to determine the actual image dimensions. Divide the image pixel width by the device point width (407pt for iPhone 17 Pro) to compute the exact scale factor for this session (see the Device Scale Factor Reference below).

### Phase 3: Navigate and Compare Each Screen

For each screen in the verification map, navigate to it, take a screenshot, and compare against the Figma reference.

#### Navigation via Tapping

Use `mcp__expo-mcp__automation_tap(projectRoot, platform, x, y)` to navigate by coordinates, or use `mcp__expo-mcp__automation_tap(projectRoot, platform, testID="my-button")` to tap by testID.

**Critical: Coordinate System**

The Expo MCP automation uses **screen point coordinates**, but the screenshots returned are at retina scale. You must convert:

```
tap_x = image_pixel_x / scale_factor
tap_y = image_pixel_y / scale_factor
```

#### Device: iPhone 17 Pro

| Property | Value |
|----------|-------|
| Screen size (pt) | 407 x 904 |
| Native pixel ratio | 3x |
| Simulator scale factor | ~1.92 |
| Expected image width (px) | ~781 |
| Top safe area | 62pt |
| Bottom safe area | 34pt |

Compute the exact scale factor from the first screenshot: `scale = image_width_px / 407`. The simulator scale (~1.92) differs from the native 3x because the simulator renders at its own window resolution.

**Common tap targets (in POINT coordinates for iPhone 17 Pro, 407 x 904 pt):**

| Element | Approximate Point Coordinates | Formula / Notes |
|---------|-------------------------------|-----------------|
| Tab bar icon (3 tabs: left) | x=68, y=870 | x = 407/6, y = 904 - 34 |
| Tab bar icon (3 tabs: center) | x=204, y=870 | x = 407/2 |
| Tab bar icon (3 tabs: right) | x=339, y=870 | x = 407*5/6 |
| Tab bar icon (5 tabs: 1st) | x=41, y=870 | x = 407/10 |
| Tab bar icon (5 tabs: 2nd) | x=122, y=870 | x = 407*3/10 |
| Tab bar icon (5 tabs: 3rd/center) | x=204, y=870 | x = 407/2 |
| Tab bar icon (5 tabs: 4th) | x=285, y=870 | x = 407*7/10 |
| Tab bar icon (5 tabs: 5th) | x=366, y=870 | x = 407*9/10 |
| Header back chevron | x=30, y=73 | y = 62 (safe area) + 11 |
| FAB (bottom right) | x=359, y=822 | x = 407 - 48, y = 904 - 34 - 48 |

**Tapping tips:**
- Taps can be unreliable. If a tap doesn't navigate, adjust coordinates by ~10-20pt and try again.
- Always take a screenshot after tapping to confirm navigation succeeded.
- ScrollViews can intercept taps meant for fixed header elements (like back buttons). If the back button tap scrolls the page instead, try tapping a neutral area first to deactivate any focused input, then retry the back button.
- When tapping list items, the items start below the header + search bar area. On iPhone 17 Pro (62pt top safe area + ~44pt nav header + ~36pt search bar = ~142pt), the first item is typically at y~180pt, second at y~235pt, third at y~290pt (varies by row height of ~55pt). If there is no search bar, items start ~15pt earlier.

#### Using testID (Preferred When Available)

The `mcp__expo-mcp__automation_tap` tool accepts a `testID` parameter directly -- you do not need to call `find_view` first to tap. Use testID-based tapping whenever the target element has a `testID` prop, as it is far more reliable than coordinate-based tapping.

```
mcp__expo-mcp__automation_tap(projectRoot, platform, testID="doctor-list-item-0")
```

Use `mcp__expo-mcp__automation_find_view(projectRoot, platform, testID="some-id")` when you need to **inspect** a view's properties (text content, visibility, dimensions), not just tap it.

To discover available testIDs, search the codebase:
```
Grep for testID= in the app source files
```

#### Handling Scrollable Content

Figma frames often show the full screen content (including below-fold items). The app screenshot only captures the visible viewport. To verify below-fold content:

1. Compare the visible portion first.
2. Swipe down by tapping and dragging (tap at y=450, then tap at y=200 to simulate scroll), or tap list items to navigate deeper.
3. Take additional screenshots after scrolling.
4. Note in the report which elements were verified "after scroll".

#### Comparison Checklist

For each screen, after taking the app screenshot, compare against the Figma reference on these dimensions:

1. **Layout structure**: Same hierarchy of sections, cards, rows?
2. **Typography**: Section titles bold/extrabold? Field labels regular? Correct sizes?
3. **Colors**: Header background, avatar colors, badge colors, card borders match?
4. **Icons**: Correct icons in correct positions? Right size?
5. **Spacing**: Gaps between sections, padding within cards, margins match?
6. **Content**: Correct labels, placeholder text, button text?
7. **Interactive elements**: FAB present? Search bar? Filter/sort icons? Back button?
8. **Safe areas**: Status bar spacing, bottom safe area (home indicator) handled correctly?
9. **Empty states**: If a list is empty, does the empty state match the Figma design?
10. **Planned deviations**: Cross-reference your pre-collected deviation list. Mark any intentional differences as "planned deviation", not bugs.

### Phase 4: Report Results

For each screen, output a structured comparison:

```
## Screen: [Screen Name] (Figma node [nodeId])

**Status**: MATCH | PARTIAL MATCH | MISMATCH

### Matches
- [element]: [description of what matches]

### Differences
- [element]: Expected [Figma description] but got [app description]

### Planned Deviations
- [element]: [what differs and why it's intentional]
```

Then output a final summary:

```
## Verification Summary

| Screen | Status | Issues |
|--------|--------|--------|
| Menu | MATCH | None |
| Doctors list | PARTIAL MATCH | Missing specialty badge (planned) |
| ... | ... | ... |

**Overall**: PASS | FAIL
- PASS: All screens match or only have planned deviations
- FAIL: One or more screens have unplanned differences (list them)
```

## Handling Common Issues

### App not responding to taps
Try slightly different coordinates. The retina scale factor varies by device model. If coordinates seem consistently off, recalibrate: tap a known element (like a tab bar icon), verify with a screenshot, and compute the actual scale factor from the screenshot dimensions.

### Keyboard blocking elements
If a keyboard is open (e.g., from tapping a text field), tap a neutral area outside text fields or use `mcp__expo-mcp__automation_tap` on a non-interactive region (e.g., x=204, y=400) to dismiss it. On iOS, swiping down on the keyboard area can also dismiss it. Wait for the keyboard dismiss animation (~300ms) before retrying your intended tap.

### Screen didn't navigate
Take a screenshot to see current state. The tap may have landed on the wrong element. Identify the correct element's position in the new screenshot and retry.

### Figma shows elements not in scope
The Figma design may contain features not yet implemented. Check with the user or the plan document for what's in scope. Only flag differences that are NOT planned deviations.

### Modal / overlay blocking interaction
If a modal, bottom sheet, or toast is covering the screen, dismiss it first (tap outside, tap the close button, or swipe down) before navigating further.

