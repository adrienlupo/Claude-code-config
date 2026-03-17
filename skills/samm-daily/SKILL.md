---
name: samm-daily
description: >-
  Trigger on "daily", "standup", "daily meeting", "point du jour",
  "qu'est-ce que j'ai fait"
allowed-tools:
  - mcp__github__get_me
  - mcp__github__search_pull_requests
  - mcp__github__search_issues
---

# Daily Standup Prep

Generate a Slack-ready summary of your GitHub activity on `samm-care/samm` since the last working day.

## Your Task

### 1. Determine the reference date

Calculate the last working day from today's date:
- Monday → use Friday
- Tuesday–Friday → use yesterday
- Saturday/Sunday → use Friday

Format as `YYYY-MM-DD` for GitHub search qualifiers.

### 2. Get GitHub identity

Call `mcp__github__get_me` to retrieve the authenticated user's `login`.

### 3. Fetch activity

Run these searches on `repo:samm-care/samm`:

| What | Query |
|------|-------|
| PRs created since last working day | `author:{login} created:>={date}` |
| PRs currently open | `author:{login} is:open` |
| Issues created since last working day | `author:{login} created:>={date}` |
| Issues closed & assigned to user | `assignee:{login} closed:>={date}` |

### 4. Deduplicate

If a PR closes an issue (look for "closes #N" / "fixes #N" in the PR body), show the issue reference in parentheses after the PR line. Do NOT repeat that issue in the Issues sections.

### 5. Format output

Print a Slack-compatible plain-text block using these rules:

- `*bold*` for section headers (Slack mrkdwn)
- Each item: `- #number — title — *status*` with optional `(closes #N)`
- URL on its own line (Slack auto-links it)
- 1-sentence description in French below each item
- Omit sections that have no items
- If there is no activity at all, print: `RAS (rien a signaler)`

### Output template

```
*PR ouvertes*
- #649 — Unify cancellations into intervention exceptions — *open*, en review (closes #642)
  https://github.com/samm-care/samm/pull/649
  Refacto majeure qui fusionne les annulations et les exceptions en un seul modele.

*PR mergees*
- #647 — fix: clean up orphaned exceptions — *merged* (closes #645)
  https://github.com/samm-care/samm/pull/647
  Corrige un bug ou les exceptions devenaient orphelines lors d'un changement de recurrence.

*Issues creees*
- #648 — Move RRule expansion from frontend to backend — *open*
  https://github.com/samm-care/samm/issues/648
  Nouveau endpoint pour remplacer les 3 appels en cascade de l'agenda par un seul.

*Issues fermees*
- #518 — Application non visible sur les stores — *resolved*
  https://github.com/samm-care/samm/issues/518
  L'application est de nouveau visible sur l'App Store et le Google Play Store.
```

## Rules

- Always write descriptions in French with proper accents
- Omit empty sections entirely
- If no activity at all, say `RAS (rien a signaler)`
- Do not add any commentary outside the formatted block — the output is meant to be copy-pasted into Slack
