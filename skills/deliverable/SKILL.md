---
name: deliverable
description: Settle a goal with the user — what gets built, the definitions of done that prove it, and how each one gets verified — capture any image shared in the session as a file, write it all to a brief, then hand it to the implement-loop skill. Use before an implement loop, or when a goal is too fuzzy to judge output against.
argument-hint: "A rough goal, or nothing at all"
---

Settle what gets built and how "done" is recognised, then hand it to `implement-loop`. You do not run the loop, and you write no code — no tests, no scaffolding, nothing. A brief that contains code has already started deciding the implementation, which is exactly what this skill exists to avoid.

Three things must leave this session extremely clear:

1. **A goal** — one objective: a feature, a site, a redesign.
2. **Definitions of done** — the concrete things that define when the goal is reached.
3. **A verification means for each one** — how an agent, later, puts reality next to the definition and reads the answer.

Four steps, in order: capture every image shared in the session as a file; draft the goal, the definitions of done and what is out of scope; grill the user on them; derive and dry-run the verification means, write back what worked, confirm.

## The brief

`implement-loop` reads these sections and nothing else. Write them under these headings, verbatim, so an agent reading the brief cold never has to guess the format: `## Goal`, `## Definitions of done`, `## Verification`, `## Out of scope` (optional — omit it when nothing needs walling off). Above the sections, one stamp line — the date and the branch the brief was settled on — so a later session can tell a live brief from a stale one.

### Goal

One or two lines. What exists when this is done. It has to let someone with no context tell finished from unfinished; that is the test to grill it against.

### Definitions of done

The heart of the brief, and what the next skill's success hangs on. Each definition of done is a concrete thing the finished work can be held against:

- **An image** — a screenshot, a mockup, a design export. For a visual goal this is the densest definition you will get.
- **A live example** — a named product or page: "the onboarding flow of Strava", "the settings screen of Linear". It only counts if every fresh agent can reach it or recalls the same thing.
- **Scenarios** — for work with no screen, a backend feature, an API, a CLI. Written as behaviour: given this state, this request, this happens. Precise enough that done/not-done is a reading, not an opinion — but scenarios, not a spec of internals, and never a full test plan.
- **A document** — an online spec, an RFC, a doc page the work must conform to.

A goal usually needs several, and one definition can combine kinds: a screenshot plus the three scenarios the screen must survive. List each one explicitly; the loop will verify each one by name.

What a definition of done is **not**: unit tests, integration tests, or any code. Tests pin internals — function names, module boundaries, fixtures — and every pin is an implementation decision smuggled into the brief before the implementer has seen the problem. Scenarios say what must be true; the loop decides how to build it and how to prove it.

The definitions of done are the one thing that is irreducibly the user's. Spend the grilling there. Propose the sharpest set you can — the one that settles "done?" fastest — with one alternative beside it, a line each.

### Verification

For each definition of done, the means by which an agent later checks it — because a definition nobody can put next to reality is decoration, and the loop will substitute its own taste for it, silently. Typical means:

- A web UI → Chrome DevTools: the URL, the viewport, what to screenshot.
- A mobile app → a booted Simulator, logged in, on the right screen — and what stands it up.
- A backend scenario → how to exercise the real system: the endpoint and the calls, the CLI invocation, or a test suite the loop will write and run from the scenarios. The scenarios stay the authority; any suite is just the instrument.
- A live example or document → the URL, and what to compare.

Work the means out yourself, from the repo — ask only what the repo cannot tell you: credentials, which route, which device. **When in doubt about how a definition will be verified, ask the user** — a wrong verification means fails unattended, against a definition nobody can see. Note what is one-time setup (install, boot, log in, seed) versus what repeats at every check (reload, navigate, screenshot, run), because the loop pays them at different rates.

### Out of scope

Optional. What the loop must not touch, when something needs naming — a directory, a feature, a config. The loop runs unwatched; this is its only wall. Omit the section when there is nothing to wall off.

## Images

Keep every image shared, verbatim, at the resolution it arrived. Never replace one with a prose description: the loop's agents run with fresh context and never see this conversation.

Pasted images sit in the transcript as base64:

```sh
ENC() { sed 's|[^a-zA-Z0-9]|-|g'; }   # dir name: every non-alphanumeric becomes a dash
for P in "$(pwd)" "$(git rev-parse --show-toplevel 2>/dev/null)"; do   # cwd, then the repo root
  D=~/.claude/projects/$(printf %s "$P" | ENC)
  [ -n "$P" ] && ls "$D"/*.jsonl >/dev/null 2>&1 && DIR=$D && break
done
[ -n "$DIR" ] || { echo "no transcript for $(pwd)"; exit 1; }   # never fall back to the newest dir anywhere
python3 ~/.claude/skills/deliverable/scripts/extract_session_images.py \
  "$(ls -t $DIR/*.jsonl | head -1)" .claude/deliverable-assets/
```

Zero extracted means the transcript has not flushed yet, not that nothing was shared — retry once, then ask the user to save it themselves. If none was shared at all, ask once whether one exists.

An image already on disk goes to the same folder if it lives outside the repo. Say what each one is, and which definition of done it belongs to.

## Grill

Write what you have to `.claude/deliverable.md`, then invoke `grill-me` with that path. Its job is removing ambiguity — aim it at the *what*, and at the definitions of done above all.

Never settle the *how*: do not prescribe it, do not interview for it. It strips decisions from the loop before it starts. Verification means are the exception, and they are yours to derive, not the user's to supply — the user only confirms them when you are in doubt.

A goal whose definitions of done cannot be verified does not go to the loop. Build verifiable ones while the user is still here. If none can be built, say plainly that the loop is the wrong tool for this goal, and stop — handing the question downstream only asks it once the user has gone. The same honesty applies at the other end of the scale: a goal one builder would plainly settle in a single pass does not need the loop. Say it is overkill, offer to just build the thing, and stop.

## Hand off

Before you confirm, dry-run the verification means: stand up the one-time setup, take one pass through the per-check steps, and put each definition of done on screen or on record next to the current state of the repo. It costs one cycle, and it is the only moment a wrong step is cheap — a verification that fails at round one fails unattended, and the loop grinds on comparing nothing. Fix what breaks, write back what actually worked, then confirm.

Check whether the brief and its assets are tracked — `git ls-files --error-unmatch .claude/deliverable.md`, not `git check-ignore`, which answers a different question: a fresh file under an unignored `.claude/` is neither tracked nor ignored. Untracked, they survive branch switches but not `git clean -fdx`. Say which in the brief; either way the loop treats them as read-only input.

Confirm with the user. This is the last gate before anything runs: `implement-loop` then reads the brief from disk, takes the definitions of done as settled and starts straight away. Nothing comes back to approve.
