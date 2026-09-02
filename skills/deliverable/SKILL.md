---
name: deliverable
description: Settle a goal with the user — what gets built, the definitions of done that prove it, and how each one gets verified — capture any image shared in the session as a file, write it all to a brief, have a fresh Fable agent review it adversarially, then hand it to the implement-loop skill. Use before an implement loop, or when a goal is too fuzzy to judge output against.
argument-hint: "A rough goal, or nothing at all"
---

Settle what gets built and how "done" is recognised, then hand it to `implement-loop`. You do not run the loop, and you write no code that builds the goal — no tests, no scaffolding, nothing. A brief that contains code for the goal has already started deciding the implementation, which is exactly what this skill exists to avoid. The one exception is verification tooling: a seed, a fixture script, a data import that stands the state under test up in one step lives in `.claude/deliverable-assets/` and is named by the means that uses it. It decides nothing about the implementation — and without it the means decides that the fixture is entered by hand, through the app's own screens, by a fresh agent on every round.

Three things must leave this session extremely clear:

1. **A goal** — one objective: a feature, a site, a redesign.
2. **Definitions of done** — the concrete things that define when the goal is reached.
3. **A verification means for each one** — how an agent, later, puts reality next to the definition and reads the answer.

Six steps, in order: check for a leftover brief; capture every image shared in the session as a file; draft the goal, the definitions of done and what is out of scope; grill the user on them; derive and dry-run the verification means and write back what worked; have a fresh agent review the whole brief adversarially, apply what it finds, and confirm.

## Check for a leftover brief

Before drafting anything, look for `.claude/deliverable.md` and for `.claude/deliverable-assets/`, each on its own — this skill is the only thing that writes either path, so whatever is there is left over from an earlier session, and one can outlive the other: a brief whose images are gone, or images whose brief was deleted or never finished.

If the brief exists, show the user its stamp line (date and branch) and a one-line summary of its `## Goal`. If the assets folder exists, say what is in it — the file count, or the definitions the images were captured for when the brief is also there. Ask whether to discard or resume what you found; never overwrite either silently, and never assume it belongs to the current goal. An assets folder with no brief, or one the brief no longer references, gets its own question. If neither path exists, say nothing and move on to capturing images.

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

Several, not fifteen. Each definition is written once and re-verified on every round of the loop, so its cost is paid again on each pass — six that fence the goal tightly beat fifteen that fence it fifteen times over, and the longer list buys nothing but rounds. Add a definition only when its absence lets a wrong build pass; if the goal is already unmistakable without it, it is weight.

What a definition of done is **not**: unit tests, integration tests, or any code. Tests pin internals — function names, module boundaries, fixtures — and every pin is an implementation decision smuggled into the brief before the implementer has seen the problem. Scenarios say what must be true; the loop decides how to build it and how to prove it.

The definitions of done are the one thing that is irreducibly the user's. Spend the grilling there. Propose the sharpest set you can — the one that settles "done?" fastest — with one alternative beside it, a line each.

### Verification

For each definition of done, the means by which an agent later checks it — because a definition nobody can put next to reality is decoration, and the loop will substitute its own taste for it, silently. Typical means:

- A web UI → Chrome DevTools: the URL, the viewport, what to screenshot.
- A mobile app → a booted Simulator, logged in, on the right screen — and what stands it up.
- A backend scenario → how to exercise the real system: the endpoint and the calls, the CLI invocation, or a test suite the loop will write and run from the scenarios. The scenarios stay the authority; any suite is just the instrument.
- A live example or document → the URL, and what to compare.

Work the means out yourself, from the repo — ask only what the repo cannot tell you: credentials, which route, which device. **When in doubt about how a definition will be verified, ask the user** — a wrong verification means fails unattended, against a definition nobody can see. Note what is one-time setup (install, boot, log in, seed) versus what repeats at every check (reload, navigate, screenshot, run), because the loop pays them at different rates. Both have a ceiling. Setup reaches the state under test in **one step** — a seed file, a fixture script, a deep link, a data import — never by walking the app's own screens: a fixture entered by hand is re-entered every round, by a fresh agent that has to rediscover every click. Each per-check pass reads its answer in a handful of calls, on the one screen the definition is about, with the one emulation it actually needs. Ten bullets under one definition is a QA protocol, and the loop will execute it with full rigor every round, whatever it costs.

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

## Dry-run

Dry-run the verification means: stand up the one-time setup, take one pass through the per-check steps, and put each definition of done on screen or on record next to the current state of the repo. It costs one cycle, and it is the only moment a wrong step is cheap — a verification that fails at round one fails unattended, and the loop grinds on comparing nothing. Fix what breaks, and write back what actually worked rather than what you planned. Record what each pass cost — tool calls and minutes, per definition — beside its means. A means that works but takes a fresh agent a quarter of an hour is not ready: rewrite it — a seed instead of a walk, one screen instead of five, a script instead of steps — and dry-run it again before the brief is stamped, because the loop pays that quarter of an hour per definition, per round, and it is the largest number in the run. Every trap met here — a toast that dismisses in seconds, a read that hangs, a selector that resets a form — goes into the means as written; a trap the loop meets instead costs it a round of false findings before it is written anywhere.

## Review

You have been staring at this brief since it was a sentence, and you can no longer see what it fails to say. Spawn a **fresh Fable agent** — `Agent` with `model: "fable"` — to read it cold and try to break it. Do this after the dry-run, never before: the reviewer must see the verification means as they actually ran, not as you first imagined them.

Give it the brief's path, the repo's conventions files, and the assets folder, and tell it to open the images. Tell it explicitly not to take the brief's word for any fact — a brief is dense with claims about routes, constraints, file paths and command output, and the stale ones are invisible from inside. Ask for findings ranked **BLOCKER / SHOULD-FIX / NIT**, each quoting the exact sentence at fault and naming the replacement — or naming the deletion, when the fix is fewer words. Read-only: it writes no code and changes no files.

Point it at the eight things that actually go wrong:

- **Factual accuracy** — every claim about the current state of the repo, re-checked against the repo.
- **Completeness against the images** — anything visible that the brief neither specifies nor lists as a deviation.
- **Ambiguity that forks the build** — could two competent implementers read this sentence and build different things?
- **Verifiability** — any definition whose means is absent, hand-wavy, or needs human judgment.
- **Traps for an unattended agent** — unrecoverable state, destructive reflexes, ordering dependencies left unstated.
- **Scope coherence** — does *Out of scope* actually wall off what the definitions imply?
- **Convention conflicts** — anything violating a `CLAUDE.md`, a glossary, or an ADR, beyond the conflicts the brief already names and resolves.
- **Over-specification** — any sentence that decides the *how*: a named function or file, a library, a data shape, a prescribed sequence of steps, a definition of done phrased as an implementation rather than as an observable. Plus every definition that restates another, and every one so fine-grained that no competent build would miss it. The brief must remove all ambiguity about *what* and leave the loop entirely free on *how* — a sentence that closes an ambiguity by dictating the implementation has not fixed the brief, it has made the decision on the implementer's behalf.

Tell it that bullet is not an afterthought but a counterweight, and say why: the seven above are all satisfied by adding words, so a reviewer hunting gaps grows the brief by default and nobody prices the growth. The price is real — every definition of done and every constraint is re-checked on each round of the loop, so a marginal SHOULD-FIX is paid on every pass, not once. Require it to rank by cost as well as by defect, and to drop or downgrade its own finding when the words it wants cost more than the ambiguity they close: a paragraph added to foreclose a misreading no competent implementer would reach is a NIT at best, and often nothing at all. A shorter brief that still forecloses every wrong build is the better brief, and "the reviewer proposed no additions" is a valid outcome.

The class of finding worth the whole exercise is the one where **verification passes while the build is wrong**: a definition two readings satisfy, where the obvious fixture happens to satisfy both. Those never surface in a dry-run, because the dry-run is run by the person who chose the fixture. When one turns up, the fix is usually not more words in the definition — it is a fixture that makes the readings disagree.

Apply what it finds — but not on sight. A finding is a claim that the brief lets a wrong build through; test it as one before you write the words, because the reviewer pays nothing for the length it proposes and you pay it on every round. Take every BLOCKER. Take a SHOULD-FIX when you can name the wrong build it prevents; drop it when you cannot. Where the fix as written pins the *how*, keep the finding and rewrite it as an observable — the ambiguity was real even when the proposed cure was not.

Then send it back over the revised brief for a confirmation pass, and aim that pass at your own edits: renumbered definitions whose cross-references you updated by hand, and fixes that contradict a section you did not reopen. Scope it to that, explicitly: a confirmation pass turned loose on the whole brief is a second hunt for gaps, and it will find them — the ratchet only ever turns one way unless you stop it. If it hands back a genuine blocker you cannot close from the repo, that is the user's to settle — ask, do not guess.

## Hand off

Check whether the brief and its assets are tracked — `git ls-files --error-unmatch .claude/deliverable.md`, not `git check-ignore`, which answers a different question: a fresh file under an unignored `.claude/` is neither tracked nor ignored. Untracked, they survive branch switches but not `git clean -fdx`. Say which in the brief; either way the loop treats them as read-only input.

Confirm with the user. This is the last gate before anything runs: `implement-loop` then reads the brief from disk, takes the definitions of done as settled and starts straight away. Nothing comes back to approve.
