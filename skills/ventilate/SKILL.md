---
name: ventilate
description: Choose the model and effort of every subagent a run dispatches — from current prices and Anthropic's measured cost per solved task — so no agent silently runs on the session's model and effort, and show afterwards what each one ran on. Use when a skill says to load ventilate, when writing a workflow script that dispatches agents, or when the user asks how a run was or should be ventilated.
argument-hint: "Nothing"
---

You pick every agent's model and effort, per call, from the task in front of you. This skill holds only what you can't derive: the silent default, the numbers, and a script that shows what actually ran.

## The silent default

An agent given no model runs on the session's model: Claude Code tries the per-call `model`, then the agent definition's, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the session's — for Agent-tool subagents and workflow agents alike. An agent given no effort runs at the session's effort. Nothing warns, and the Workflow tool's own guidance says to omit `model`. Here, never omit it.

Only a workflow's `agent()` takes `effort`; the Agent tool has none, so its subagents run at the session effort unless their definition sets one. So dispatch through workflows, via `run()` — pasted at the top of every script, since scripts can't import:

```js
const run = (role, prompt, { model, effort, ...opts } = {}) => {
  if (!['haiku', 'sonnet', 'opus'].includes(model)) throw new Error(`${role}: model must be haiku|sonnet|opus, got ${model}`)
  if (model !== 'haiku' && !effort) throw new Error(`${role}: name an effort for ${model}`)
  return agent(prompt, { model, ...(effort && { effort }), label: `${role} ${model}/${effort ?? '-'}`, ...opts })
}
```

`run('build', prompt, { model: 'opus', effort: 'low', phase: 'R2' })` — other options pass through; the label shows model and effort on every `/workflows` row.

## The numbers

Verified 2026-09-24 (platform.claude.com/docs: `models/overview`, `optimizing-for-cost-and-intelligence`; code.claude.com/docs: `sub-agents`, `model-config`, `workflows`). Re-check when a model ships.

| alias → model | $/MTok in / out | SWE-bench Pro subset: solved, $ per solved task |
|---|---|---|
| `fable` → Fable 5.1 | 10 / 50 | `low` 88.6 % $0.54 · default `high` 92.3 % $1.19 |
| `opus` → Opus 5.5 | 4 / 20 | `low` 87.4 % $0.12 · default `medium` 92.8 % $0.22 · **`low`, failures re-run at `high`: ~97 % $0.17** (all `high`: 95.3 % $0.29) |
| `sonnet` → Sonnet 5 | 2 / 10 | default `high` 77.4 % $0.84 |
| `haiku` → Haiku 4.5 | 1 / 5 | no effort, 200K context; GPQA at ~⅕ of Opus 5.5's cost per question, 63 % vs 92 % — "high-volume work with checkable outputs, not long agentic loops" |

Opus 5.5 at `xhigh` scores ~1.4 points above `high` for 2.5× the cost. Effort is calibrated per model: `low` on one is not `low` on another.

## Choosing

- **Builders climb `opus/low` → `opus/high` → `opus/xhigh`**, one rung per failed attempt; failing at the top is the plateau. Start higher only when the task says why. It is the cheapest measured policy on checkable work, and it needs a check that fails bad work.
- **Judges are `opus`** — the docs' default for agent work is Opus 5.5 at `medium`. A false pass is a loop's costliest error, so the gate gets the top rung.
- **Captures are `haiku`**: run a command, the suite or a replay (browser included), hand back the artifact. A drive that must find its own way, or a capture that failed twice, goes to `opus/low`. Keep Haiku's input small.
- **Sonnet has no default role**: `opus/low` beats it on score at a seventh of the cost per solved task.
- **Fable is not a worker, and `run()` refuses it**: Opus 5.5 matched it at a fifth of the cost. The docs' one case for Fable — Opus 5.5 at higher effort still falls short — is a plateau, and plateaus go back to the user.
- **`max` is not a rung**: it "may show diminishing returns and is prone to overthinking".

## Proof

Before an implement-loop log is frozen, append what actually ran:

```sh
python3 ~/.claude/skills/ventilate/scripts/ventilation.py >> "$(git rev-parse --absolute-git-dir)/implement-loop.log"
```

It finds the session by `$CLAUDE_CODE_SESSION_ID`, not the cwd; counts every subagent transcript of the session, workflow agents included, by the model and effort it recorded; and names each agent given no model that ran on the session's model — a dispatch that bypassed `run()`, which the hand-off reports by id. Agents from outside the run, like `deliverable`'s Fable reviewer, stay in the count: say what they were, never filter them out. A run resumed in a new session takes one `--session <id>` per session.
