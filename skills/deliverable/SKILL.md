---
name: deliverable
description: Settle a goal with the user until it is unambiguous, turn it into definitions of done that each carry a way to check them, have a fresh agent attack the result, then commit and push it as the brief implement-loop runs on. Use before an implement loop, or when a goal is too fuzzy to judge output against.
argument-hint: "A rough goal, or nothing at all"
---

Settle **what** gets built and how anyone will know it's done, then hand over. The **how** belongs to the loop: write no code for the goal — no tests, no scaffolding. Only verification tooling (a seed, a fixture script) may go in `.deliverable/assets/`.

The output is `.deliverable/brief.md`, the only thing `implement-loop` reads:

```
<YYYY-MM-DD> · <branch>

## Goal
## Definitions of done
## Verification
## Out of scope        ← optional
```

If `.deliverable/` already exists, it's left over from an earlier session: show its stamp and goal, and ask whether to resume or discard. Never overwrite it silently. If it's tracked, discard it with `git rm -r .deliverable` and a commit.

## 1. The goal, unambiguous

Capture every image shared in the session, verbatim — the loop's agents never see this conversation:

```sh
python3 ~/.claude/skills/deliverable/scripts/extract_session_images.py .deliverable/assets/
```

Zero found usually means the transcript hasn't flushed: retry once, then ask the user to save it.

Draft the goal — one or two lines that let someone with no context tell finished from unfinished — write the brief, and invoke `grill-me` on it. Grill the *what*, never the *how*. If one pass would plainly do it, say the loop is overkill and offer to just build it.

## 2. Definitions of done, each with its check

A handful of definitions. Each costs a check, so add one only when its absence would let a wrong build pass. Each is an observable, never an implementation: an image to match, a live example, a scenario (given this state and this request, this happens), a document to conform to.

Each gets a check an agent can run without you:

- a test suite written from the scenarios, a `curl`, an SQL query, a CLI call;
- a browser check — DevTools or Playwright: the URL, the viewport, what to read;
- a Simulator on the right screen;
- **qualitative** (design, copy, feel): a blind A/B — a judge scores the build against the reference without knowing which is which, and the bar it must reach is set here.

Derive the checks from the repo; ask the user only what it can't tell you. Setup reaches the state under test in one step — a seed, a fixture, a deep link — never by clicking through the app. Every clause of a definition needs a step in its check and a state the setup produces — two items where it says every, an overflow where it says truncated. Add what's missing; a clause that can't have both goes to the user, never to a judge. Then run every check once, now, against the current repo, and write back what actually worked: a check that breaks at round one breaks unattended. The loop pays each check every round it's in question: rewrite one that takes a fresh agent more than a few minutes (count its steps if the feature doesn't exist yet), and script a long browser drive under `.deliverable/assets/` when the repo and the loop's host already have a driver for it. If a definition can't be checked, the loop is the wrong tool — say so.

Add `## Out of scope` only when something needs walling off; it is the unattended loop's only wall.

## 3. Adversarial pass

Spawn a fresh agent (`model: "fable"`), read-only, on the brief, the assets and the repo's `CLAUDE.md`, and ask it to break the brief: claims about the repo that aren't true, sentences two competent builders would read differently, checks that would **pass on a wrong build**, a clause no check step or fixture reaches, anything in the images the brief neither asks for nor excludes, an out-of-scope wall a definition needs to cross, anything that decides the *how*. Tell it a shorter brief that still blocks every wrong build beats a longer one, and that "no change" is a valid answer.

Fix what would let a wrong build through; leave the rest. What only the user can settle goes to the user.

## 4. Hand over

The brief travels by git — the loop may run on a cloud agent with nothing but the checkout — on a branch that is not the default, because the loop's hand-off commit deletes it and that must never show in a PR. On the default branch, create one named after the goal and update the stamp. Leave any other uncommitted changes exactly where they are — no stash, no commit; they're the user's. Confirm the brief, the branch and the push with the user — the last gate. Then:

```sh
~/.claude/skills/deliverable/scripts/handoff.sh "<the goal, one line>"
```

It commits only `.deliverable/` and pushes. When it stops — an ignore rule covering a file, the default branch — tell the user what it printed and let them choose the fix; never `git add -f`, never edit their ignore rules yourself. Report the branch and the commit.
