---
name: ventilate
description: Decide which model and effort every subagent of a run gets — from the prices, the task's own evidence and Anthropic's measured cost per solved task — and make that decision enforceable and provable, so a run can show afterwards that no worker ran on the session model. Use when a skill says "call the Skill tool with ventilate", when authoring a workflow script that dispatches agents, or when the user asks how a run was or should be ventilated.
argument-hint: "Nothing"
---

You are the orchestrator, and you choose. Every agent a run dispatches gets a model and an effort that you picked for that call, from the evidence in front of you and the prices below — not a table decided before the task was known, and not the session default. Two things bound the choice so it cannot drift: a dispatcher that refuses an unventilated call (§4), and a record that can contradict you afterwards (§5). The orchestrator is Fable; **Fable is never a worker**. Not because a rule says so — because at twice the Opus price it loses to the Opus ladder on Anthropic's own per-task numbers (§2), and a session model inherited by omission is the single most expensive mistake a run can make silently.

## 1. What is decided, and when

Each call names a **role** (what the agent is for: `scan`, `build`, `capture`, `captureUI`, `select`, `probe`, `sweep`, `merge`, `gate`), a **model** (`haiku`, `sonnet`, `opus`), an **effort** (`low` … `max`; Haiku takes none), and a **why** — one line the record keeps. The decision is made when the script is authored, per round, with the entry scan's report and the log's gap lines as the evidence; a workflow script is the natural place because the runtime's `agent()` takes `model` and `effort` directly, where the plain Agent tool takes only `model` and inherits the session effort. Roles are vocabulary for the log and the label, not a lookup: the same role may run on a different rung next round because the record says so.

## 2. The facts the choice rests on

Verified 2026-09-02 against platform.claude.com/docs (`about-claude/models/optimizing-for-cost-and-intelligence`, `build-with-claude/effort`) and code.claude.com/docs (`model-config`, `sub-agents`). Re-check them when a model ships; the numbers move, the method does not.

| model | in / out $ per MTok | SWE-bench Pro, cost per **solved** task |
|---|---|---|
| Fable 5.1 | 10 / 50 | `low`: 88.6 % at $0.54 · default: $1.19 |
| Opus 5 | 5 / 25 | `low`: 84.0 % at $0.25 · default: 91.7 % at $0.93–1.01 · **`low`, failures re-run at default: 93 % at $0.45** · `medium` first: 94 % at $0.61 |
| Sonnet 5 | 2 / 10 | default: 77.4 % at $0.84 |
| Haiku 4.5 | 1 / 5 | not a coding-loop model: knowledge Q&A at a tenth of Opus's cost per question at 63 % vs 92 % accuracy; 200K window; no `effort` |

- **The cheapest policy on a checkable task is not a setting, it is a ladder**: run low, re-run only the failures one rung up. Same model, rising effort — Anthropic's measured pattern is not a cheap model handing off to a dear one. The build–probe loop *is* that checker.
- **Effort is thinking depth, not output length.** `high` is the API default and the Claude Code default on every current model; `xhigh` is for demanding coding and agentic work; `max` "may show diminishing returns and is prone to overthinking — test before adopting". On Opus 5 changing effort does not reliably shorten responses, so never lower it to get a shorter report.
- **`low` is named for subagents** in the effort guide, and lower effort means fewer, more consolidated tool calls — the right shape for a capture or a merge, the wrong one for a judge who must look at everything.
- **Judging needs separation and skepticism, not rank.** Nothing published says a judge must outrank a builder; the documented failure is leniency — an evaluator that finds the issue and talks itself out of it. Prompt against that. Opus 5 and Sonnet 5 both follow "be conservative" review prompts faithfully and drop findings they deem minor, so every judge is told to report every issue and let a downstream step filter.
- **Haiku 4.5 is not a supported model for either computer-use toolset**; Sonnet 5 is, and carries the browser-use tool. A drive of a browser or a Simulator cannot fall to Haiku — the replay script is the only way Haiku takes a later round.
- **Fable orchestrating cheaper workers is the documented shape**: measured on bulk work, Fable 5.1 over Sonnet 5 workers cost about half of Fable alone and capped the cost tail; the orchestrator earns its plan, hand-off and merge only when there is bulk to hand off, which a build–verify loop over several definitions is.
- **Model resolution for a subagent**: per-call `model` → agent-file frontmatter → `CLAUDE_CODE_SUBAGENT_MODEL` → the session model. Anything with no model named anywhere runs on Fable.

## 3. How to choose

State the reason in `why`; these are the reasons that hold today.

- **Builders climb the Opus ladder: `opus/low` → `opus/high` → `opus/xhigh`.** Start every definition at the bottom unless the scan gives a reason to start higher — a gap touching a shared surface (config, types, lockfile, build config, tokens, CI) or many paths starts at `high`, and the `why` says which. Each failed attempt climbs one rung; the top rung failing is the plateau. Sonnet is not a rung: at 77 % for $0.84 it is dominated by `opus/low` on both axes, and a Sonnet failure still bills its probe, its capture and an orchestrator turn.
- **The entry scan runs `opus/high`.** Its spend is reading, which effort does not trim; its output sizes the whole run, and a two-point miss there mis-tiers every round after it.
- **Captures are `haiku`.** Run the script, run the suite, hit the endpoint, hand back the artifact's path — checkable output, tiny share of spend. Keep its input small: a chatty suite log fits a 200K window badly. Two failures move it to `sonnet/low` in the *same* role — never to a browser driver, which cannot run a suite either. **Driving a browser or a Simulator is `sonnet/low`**; the replay script it writes is what lets Haiku take the next round.
- **`select` is `haiku`.** Paths in, definition ids out.
- **Probes are `sonnet/high`** with the report-everything prompt — except a probe reading what an `opus/xhigh` build produced, which runs `opus/low`: a false pass there is caught only by the gate, and the gate bounces to another Opus round at full price.
- **The sweep is `sonnet/high`; a worktree merge or a collision reconcile is `opus/low`**, and both are followed by a probe on what they changed — the merge is the widest edit in the run and the sweep rewrites Opus code.
- **The gate is `opus/xhigh`.** `max` is allowed once per run, and only after an `xhigh` gate has been shown wrong on the record — the `why` cites the round.
- **Opus is spent for exactly three reasons**: a cheaper rung failed on the record, the entry scan, the final judge (merge and the post-xhigh probe are `low`, and cite their rule). An Opus call whose `why` names none of these is the drift this skill exists to catch.
- **Fable at `low`** is what the cost guide now names first for agent workloads in general; on the coding numbers it loses to the Opus ladder per solved task, and it answers from memory more readily at `low` — the wrong trait for a builder that must read the repo. The rule holds on evidence. Revisit it when the table changes, not before.

## 4. The dispatcher — copy it literally into every script

```js
const PRICE = { haiku: 1, sonnet: 2, opus: 5 }                          // $ in per MTok, for the tally's rough weight only
const EFFORT = ['low', 'medium', 'high', 'xhigh', 'max']
const tally = { haiku: 0, sonnet: 0, opus: 0, max: 0, calls: [] }

const run = (role, prompt, { model, effort, why, ...opts } = {}) => {   // the ONLY `agent(` in the script
  if (!(model in PRICE)) throw new Error(`${role}: unventilated call — model must be haiku|sonnet|opus, got ${model}`)   // fable, inherit and omission all land here
  if (model === 'haiku' ? effort !== undefined : !EFFORT.includes(effort)) throw new Error(`${role}: effort ${effort} is not valid on ${model}`)
  if (!why) throw new Error(`${role}: every dispatch carries a why`)
  if (model === 'opus' && !/^(escalation|scan|gate|merge|post-xhigh)\b/.test(why)) throw new Error(`${role}: opus needs a §3 reason — escalation|scan|gate|merge|post-xhigh — got "${why}"`)
  if (effort === 'max' && (role !== 'gate' || tally.max > 0 || !/R\d+/.test(why))) throw new Error(`${role}: max is once per run, gate only, citing the round an xhigh gate was wrong`)
  if (effort === 'max') tally.max++
  tally[model]++; tally.calls.push(`${role} ${model}/${effort ?? '-'} — ${why}`)
  log(`▸ ${role} → ${model}/${effort ?? '-'} — ${why}`)
  return agent(prompt, { model, ...(effort && { effort }), label: `${role} ${model}/${effort ?? '-'}`, ...opts })
}
// at the end of the script, return the tally beside the result: `return { result, ventilation: tally }`
```

- `agent(` must appear **exactly once**, inside `run()` — read the script to check; that single occurrence is the proof no call slipped past. `run('build', prompt, { model: 'opus', effort: 'low', why: 'first attempt on D2', phase: 'round-1-build' })` is the shape; `phase`, `schema`, `isolation` pass through untouched.
- The label puts the model on every row of `/workflows` while the run is live, and `log()` writes the same line above the tree — ventilation visible as it happens, not reconstructed after.
- The tally comes back with the workflow's result; the orchestrator copies it to the run log as one line per round: `R<n> ventilation: haiku 4 sonnet 3 opus 2 max 0`.

## 5. Enforcement outside the script

- **The net under everything: `CLAUDE_CODE_SUBAGENT_MODEL=sonnet`** in the settings' `env`. It sits between "named nowhere" and "the session model" in the resolution order, so an agent that escapes `run()` — a solo-lane Agent tool call, a forgotten key — costs Sonnet rates, not Fable's. Check it at kickoff: `[ -n "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ] || echo 'WARN: no subagent default model — an unventilated agent inherits the session model'` into the log. Not a stop — `run()` is the enforcement — but a run that starts with the warning is one omission from Fable rates, and the hand-off says so.
- **Proof, at hand-off.** Every subagent transcript records the model it ran on, per turn. Histogram the session's:

```sh
P=~/.claude/projects/$(pwd | sed 's#/#-#g'); SID=$(ls -t "$P"/*.jsonl | head -1 | xargs basename | sed 's/\.jsonl$//')
find "$P/$SID/subagents" -name 'agent-*.jsonl' -exec cat {} + | jq -r 'select(.type=="assistant")|.message.model' | sed 's/claude-//;s/-[0-9]\{8\}$//' | sort | uniq -c | awk '{printf "%s %s ", $2, $1}'; echo
```

  Write it to the run log as `ventilation: <histogram>` before the log is renamed. Any `fable` count above zero is a defect the hand-off reports by name, with the transcript ids — it means a call was dispatched outside `run()`. The `retro` skill reads the same field, so a run that hid its ventilation shows up there too.

## 6. What the record must let a reader judge

For every dispatch: role, model/effort, and the `why`. For every Opus call: the cheaper failure it follows (the gap line's round), or `scan`, or `gate`. For a `max`: the round the `xhigh` gate was wrong. For a builder started above `low`: what the scan said. A `why` that a reader cannot check against the log is not a reason, and a retro will say so.
