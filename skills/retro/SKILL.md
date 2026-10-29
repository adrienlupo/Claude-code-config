---
name: retro
description: Look back at a session with a fresh Fable agent and say how the user's way of working with Claude should change — the prompts and the discussion, the skills that ran (implement-loop, deliverable, any other), and what the project's CLAUDE.md fails to tell every agent about the repo. Takes no argument — it picks the current session when there has been a conversation before the call, the previous one otherwise. Read-only; proposes edits, never makes them. Use when the user says "retro", "what could I have done better", "why was that so long", or after a skill run or a discussion ends.
argument-hint: "Nothing"
---

Find the session, reduce it to numbers, hand the numbers and the raw transcript to a fresh Fable agent that owes nothing to what happened, then talk the findings through with the user. The subject is not the code produced — it is how the user and Claude worked together: what the user said and when, and what the user's skills made Claude do. You spent this session, or the last one, doing the thing under review; you are the least placed to judge it, so the judgment is not yours.

## 1. Pick the session

No argument. The session is the newest transcript in this project's directory that holds a real conversation before this call — the current one when the user has been talking or running a skill, the previous one when `/retro` is the first thing said in a fresh session. The rule is one line so the user never has to know which case they are in:

```sh
ENC() { sed 's|[^a-zA-Z0-9]|-|g'; }
DIR=~/.claude/projects/$(pwd | ENC)   # cwd, then the repo root, same as `deliverable` does for images
[ -d "$DIR" ] || DIR=~/.claude/projects/$(git rev-parse --show-toplevel 2>/dev/null | ENC)
REAL() { jq -r 'select(.type=="user") | .message.content | if type=="string" then . elif (.[0].type? // "")=="text" then .[0].text else empty end | gsub("\n";" ")' "$1" | grep -v -e '^<local-command' -e '<command-name>/clear' -e '<command-name>/retro' -e '^Base directory for this skill' -e '<task-notification>' -e '^\[Request interrupted' | wc -l | tr -d ' '; }
for S in $(ls -t "$DIR"/*.jsonl); do [ "$(REAL "$S")" -ge 1 ] && break; done
CUT=$(jq -r 'select(.type=="user") | select((.message.content|tostring)|test("<command-name>/retro")) | .timestamp' "$S" | tail -1)   # set only when the session under review is this one
```

`$CUT` is the moment `/retro` was typed: everything after it is this skill working and not evidence. Say in one line which session was picked — its id, its first prompt's first words, and whether it is the current one. If the user meant a different one, they say so here; do not ask.

## 2. Gather

Everything the reviewer will read, as paths, in a scratch directory — the reviewer runs with fresh context and sees nothing of this conversation:

- The transcript `$S` itself, and its subagent files under `$DIR/<sid>/subagents/` — `agent-*.jsonl` and, for workflow runs, `workflows/wf_*/journal.jsonl`. These carry the timestamps that measure machine time; the main transcript measures the user's.
- The project's `CLAUDE.md` — the repo root's, and anything under `.claude/rules/` — what every agent in the session was told about this repo before it started. A fact about the repo is a finding only if it is not already written there.
- The `SKILL.md` of every skill invoked (the digest lists them). The reviewer's findings quote sentences from these files, so it needs the exact text that ran, not a summary.
- `.deliverable/` if `implement-loop` ran — the brief the loop was aimed at, and the check scripts it wrote. The loop's last commit removes it, so when it is gone read it from the commit before: `R=$(git log -1 --format=%H --diff-filter=D -- .deliverable/brief.md)`, then `git show "$R^:.deliverable/brief.md"` and `git ls-tree -r --name-only "$R^" -- .deliverable/checks`. Find the session that wrote it too: the transcript in `$DIR` from the day of `git log -1 --format=%cs --diff-filter=A -- .deliverable/brief.md` containing `brief.md` writes is the deliverable session. That is where "was the skill followed" gets answered — without it the reviewer can judge the brief but not the skill that produced it.
- The loop's commits: `git log --reverse --format='%h %ci %s%n%b' <the brief's commit>..<the hand-off commit>` — the checks commit, one per definition gone green, and the hand-off listing each definition met or its gap.

## 3. Digest

```sh
D=<scratch dir>; ~/.claude/skills/retro/digest.sh "$S" ${CUT:+"$CUT"} > "$D/digest.md"
```

Deterministic, free, and the reason the reviewer can read a 3 MB transcript: it turns the file into a table — span versus active time, gaps over five minutes labelled by what ended them (`user` is the user away or thinking, `tool-wait` is the session sleeping on a poll, `assistant` is a long call), every user prompt with the minutes it waited, tool counts and errors, files read three times or more, and one line per subagent with model, minutes, tool calls, output tokens, errors and the start of its prompt. Read it yourself before spawning anything: if it shows a session of two prompts and one answer, say so and stop — a retro of nothing is a bill.

Where `implement-loop` ran, add a timeline by hand from its commits and the digest's subagent lines: when the checks were committed, when each definition went green, each verifier dispatch with its minutes and verdicts. This timeline is what turns "the loop was long" into which stretch was long.

## 4. Review

Spawn a **fresh Fable agent** — `Agent` with `model: "fable"` — read-only: it writes no code and changes no file, and it writes its report to `$D/review.md`. Give it the digest, the round table, the raw paths from §2, and these instructions, verbatim:

> You are reviewing how a user and Claude worked together in one session, to make the next one shorter and better. Read the digest first, then the transcript where the digest points. Do not take the transcript's word for anything the digest can contradict. Three lenses, each producing findings:
>
> **The discussion.** Read every user prompt in order, with its wait time. Where did the user say something at prompt 6 that prompt 1 should have carried? Which questions Claude asked could the user have pre-empted — and which should Claude not have asked? Where did the user redirect, and what earlier wording caused the detour? Where did the user accept a stated assumption they should have refused — a wrong premise, a narrowed scope? Where did the user decide something Claude should have decided, or the reverse? End this lens with a rewrite of the opening prompt that would have skipped the detours you found — concrete, in the user's voice, no longer than it needs to be.
>
> **The skills.** For each skill that ran, read its SKILL.md and match the digest's time and tokens to its sections. Where did the time go — name the top three sinks with their minutes and tokens. For each sink, find the sentence in the SKILL.md that produced it, or the sentence that is missing. If `implement-loop` ran, use the timeline: long stretches with no definition going green, the time spent making checks runnable, a check script edited after its commit (a weakened check), verifier fails citing something no definition names, a definition verified pass then fail with no relevant diff. Each of those is a fingerprint: the flip-flops and verifier-invented criteria point at the brief, the stretches and weakened checks point at the loop.
>
> **The model.** Where an instruction existed, in a prompt or a SKILL.md, and was not followed. This is not fixed by adding words; say so, and say whether a shorter or a harder wording would have held.
>
> **The project.** Where more than one agent — in the session or among its subagents — met the same fact about this repo and each paid to learn it: a path the tools refuse, a port that must not be touched, a server that serves a stale bundle until refreshed, a form that resets when a selector changes, a command that has to run first, a toast that vanishes in seconds, a hang. The fingerprint is repetition: the same error or the same workaround in several transcripts, or a prompt carrying lore ("measured last round", "the only path that works"). Each one is a `project` finding whose fix is one line in the project's `CLAUDE.md` — the fact and what to do about it, never the story of how it was found. When the fact is mechanical — a path, port or command that must or must not be touched — the fix is a hook or a check, not a CLAUDE.md line; say which. Read the `CLAUDE.md` first: a fact already written there and still tripped over is a `model` finding, and the fix is its wording, not a second copy.
>
> Every finding: **BLOCKER** (cost over a fifth of the session, or a pattern that will repeat), **SHOULD-FIX**, or **NIT**. Each carries one `cause:` — `discussion`, the skill's name, `brief` (this brief, not the skill that wrote it), `project` (a line for the project's `CLAUDE.md`, or a hook or check when the fact is mechanical), or `model` — quotes the exact sentence at fault (transcript line, SKILL.md line, or brief line) and names the replacement, or names the deletion when the fix is fewer words. A skill grows by one sentence per finding if you are not allowed to delete; you are. Findings with `cause: brief` also say whether `deliverable`'s steps ran as written — the repo read before asking, a check per definition, the wrong-build read, the definition count — because a brief defect that the skill's rules would have caught is a `model` finding, and one they let through is a `deliverable` finding. Rank by cost. Say what you could not determine and why.

The reviewer is fresh for the same reason the loop's verifier is: it did not spend the session, so it can see what the session spent.

## 5. Report and discuss

The review stays in `$D`; nothing is kept between retros — the user is the memory, and a pattern is worth fixing when they recognise it, not when a grep does.

Then talk. Print the time line, the top three findings with their cause and the sentence to change, and the rewritten opening prompt if the discussion lens produced one. Take the user's pushback on each: they know what they meant, the reviewer knows what was written, and the finding is right only where the two differ. Nothing is edited during this — not a skill, not the brief, not the findings file. When the user names a change they want, it is one sentence in one file — a skill, the brief, the project's `CLAUDE.md` — made on their word after the discussion and read back to them, never a batch applied because the report said so. A retro that rewrites the skills it reviewed has become one of them.
