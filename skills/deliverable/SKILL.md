---
name: deliverable
description: Interview the user until a goal and how to check it are clear, write them as a short brief, and push it for implement-loop to run. Use before an implement loop, or when a goal is too fuzzy to judge output against.
argument-hint: "A rough goal, or nothing at all"
---

Settle **what** gets built and how anyone will know it's done — in minutes, with the user in the room. Everything else belongs to `implement-loop`: the code, and the scripts that run the checks. Here you write words, not tooling.

If `.deliverable/` already exists, show its goal and ask whether to resume or discard it; discard a tracked one with `git rm -r .deliverable` and a commit.

## 1. Interview

Read the repo first, then ask only what it can't answer, up to four questions at a time. Ask about the *what*, never the *how*. Stop when you could write the brief. If one pass would plainly do the job, say so and offer to just build it.

Save every image the user shared — the loop never sees this conversation:

```sh
python3 ~/.claude/skills/deliverable/scripts/extract_session_images.py .deliverable/assets/
```

Zero found usually means the transcript hasn't flushed: retry once.

## 2. The brief

`.deliverable/brief.md`:

```
# <the goal, one line>

## Goal
One or two lines that let someone with no context tell finished from unfinished.

## Done when
- **D1** <an observable outcome>. Check: <what is run or looked at, and what passes>.

## Out of scope        ← only when something needs walling off
```

A handful of definitions, each observable: a scenario (given this state and this request, this happens), a page at a URL and viewport, a command's output, an image in `assets/` to match. Add one only when its absence would let a wrong build pass. A check names what is run and what passes — pass/fail, or a number to beat — and the loop writes the script: name the repo's existing command when there is one. Design, copy and feel are judged blind against a reference, with the bar written down.

Read each check once as a wrong build would: if it could pass while the goal is unmet, tighten it. A definition no check can reach means the loop is the wrong tool — say so.

## 3. Hand over

The brief travels by git, so a cloud session can run it from a fresh checkout, on a branch that isn't the default: the loop's last commit deletes the brief, and that must never show in a PR. On the default branch, create one named after the goal. Leave other uncommitted changes where they are. Show the user the brief and the branch, then:

```sh
~/.claude/skills/deliverable/scripts/handoff.sh "<the goal, one line>"
```

It commits only `.deliverable/` and pushes. When it stops — an ignore rule covering a file, the default branch — tell the user what it printed and let them choose the fix. Report the branch and the commit.
