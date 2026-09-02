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
- `.claude/deliverable.md` if `implement-loop` ran — the brief the loop was aimed at. Read it now: the next `deliverable` run offers to discard it. Find the session that wrote it too, when there is one: the brief's stamp line has a date, and the transcript in `$DIR` from that day containing `deliverable.md` writes is the deliverable session. That is where "was the skill followed" gets answered — without it the reviewer can judge the brief but not the skill that produced it.
- The loop's run log: `/tmp/implement-loop-<hash>.log.<stamp>.done` (hash: `git rev-parse --show-toplevel | shasum | cut -c1-12`) — §8 renames it rather than deleting it, so a finished run's round lines are there, one per definition per round, with the gap in the verifier's words. A bare `.log` at that path is a run in flight or one that died; say which.

## 3. Digest

```sh
D=<scratch dir>; ~/.claude/skills/retro/digest.sh "$S" ${CUT:+"$CUT"} > "$D/digest.md"
```

Deterministic, free, and the reason the reviewer can read a 3 MB transcript: it turns the file into a table — span versus active time, gaps over five minutes labelled by what ended them (`user` is the user away or thinking, `tool-wait` is the session sleeping on a poll, `assistant` is a long call), every user prompt with the minutes it waited, tool counts and errors, files read three times or more, and one line per subagent with model, minutes, tool calls, output tokens, errors and the start of its prompt. Read it yourself before spawning anything: if it shows a session of two prompts and one answer, say so and stop — a retro of nothing is a bill.

Where the digest shows a workflow, add a round table by hand from the subagent lines — the loop's own log is gone, and the journal keys are hashes, so the role of each agent is read from its prompt's first words (`You are the entry scan`, `You are implementing ONE definition`, `You judge ONE definition`, `You are THE GATE`, `Capture the evidence`). One row per workflow call: builders, captures, judges, gate, agent-minutes, wall-minutes, and which definitions failed and passed if the prompts name them. This table is what turns "the loop was long" into which lever was long.

## 4. Review

Spawn a **fresh Fable agent** — `Agent` with `model: "fable"` — read-only: it writes no code and changes no file, and it writes its report to `$D/review.md`. Give it the digest, the round table, the raw paths from §2, and these instructions, verbatim:

> You are reviewing how a user and Claude worked together in one session, to make the next one shorter and better. Read the digest first, then the transcript where the digest points. Do not take the transcript's word for anything the digest can contradict. Three lenses, each producing findings:
>
> **The discussion.** Read every user prompt in order, with its wait time. Where did the user say something at prompt 6 that prompt 1 should have carried? Which questions Claude asked could the user have pre-empted — and which should Claude not have asked? Where did the user redirect, and what earlier wording caused the detour? Where did the user accept a stated assumption they should have refused — a wrong premise, a narrowed scope? Where did the user decide something Claude should have decided, or the reverse? End this lens with a rewrite of the opening prompt that would have skipped the detours you found — concrete, in the user's voice, no longer than it needs to be.
>
> **The skills.** For each skill that ran, read its SKILL.md and match the digest's time and tokens to its sections. Where did the time go — name the top three sinks with their minutes and tokens. For each sink, find the sentence in the SKILL.md that produced it, or the sentence that is missing. If `implement-loop` ran, use the round table: rounds that moved no definition, definitions that flipped pass→fail→pass with no relevant diff, gate refusals citing something no definition names, builders editing far outside the entry scan's paths, captures with tool counts or errors far above the others, a setup that failed to stand. Each of those is a fingerprint: the flip-flops and gate-invented criteria point at the brief, the counts and escalations point at the loop.
>
> **The model.** Where an instruction existed, in a prompt or a SKILL.md, and was not followed. This is not fixed by adding words; say so, and say whether a shorter or a harder wording would have held.
>
> **The project.** Where more than one agent — in the session or among its subagents — met the same fact about this repo and each paid to learn it: a path the tools refuse, a port that must not be touched, a server that serves a stale bundle until refreshed, a form that resets when a selector changes, a command that has to run first, a toast that vanishes in seconds, a hang. The fingerprint is repetition: the same error or the same workaround in several transcripts, or a prompt carrying lore ("measured last round", "the only path that works"). Each one is a `project` finding whose fix is one line in the project's `CLAUDE.md` — the fact and what to do about it, never the story of how it was found. Read the `CLAUDE.md` first: a fact already written there and still tripped over is a `model` finding, and the fix is its wording, not a second copy.
>
> Every finding: **BLOCKER** (cost over a fifth of the session, or a pattern that will repeat), **SHOULD-FIX**, or **NIT**. Each carries one `cause:` — `discussion`, the skill's name, `brief` (this brief, not the skill that wrote it), `project` (a line for the project's `CLAUDE.md`), or `model` — quotes the exact sentence at fault (transcript line, SKILL.md line, or brief line) and names the replacement, or names the deletion when the fix is fewer words. A skill grows by one sentence per finding if you are not allowed to delete; you are. Findings with `cause: brief` also say whether `deliverable`'s steps ran as written — dry-run, adversarial review, the definition count — because a brief defect that the skill's rules would have caught is a `model` finding, and one they let through is a `deliverable` finding. Rank by cost. Say what you could not determine and why.

The reviewer is fresh for the same reason the `deliverable` reviewer is: it did not spend the session, so it can see what the session spent.

## 5. Report and discuss

Save the review as `~/.claude/skills/retro/findings/<YYYY-MM-DD>-<project>-<sid first 8>.md`, with the digest's time line at the top. Before showing it, grep the earlier files in that directory for each finding's quoted sentence and cause: a finding seen before is marked **recurs (n)** and outranks a new one of the same severity — one session is one sample, and the skill edit worth making is the one two retros asked for.

Then talk. Print the time line, the top three findings with their cause and the sentence to change, and the rewritten opening prompt if the discussion lens produced one. Take the user's pushback on each: they know what they meant, the reviewer knows what was written, and the finding is right only where the two differ. Nothing is edited during this — not a skill, not the brief, not the findings file. When the user names a change they want, it is one sentence in one file — a skill, the brief, the project's `CLAUDE.md` — made on their word after the discussion and read back to them, never a batch applied because the report said so. A retro that rewrites the skills it reviewed has become one of them.
