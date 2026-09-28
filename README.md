# Claude Code config

This is my global [Claude Code](https://code.claude.com/docs) setup: `settings.json`, a few slash commands, and the skills that run my development workflow. I work AI-first. Agents write the code, and my part is what surrounds it: I frame the goal precisely enough to check it, I set up how the result gets verified, and I review what ships.

The repo is my `~/.claude` directory. Its `.gitignore` ignores everything, then whitelists the paths that are safe to share.

## The workflow

One rule holds throughout: **an agent never verifies its own work.** Each check is done by a separate agent with fresh context, and it looks at the running result, not at the code that produced it.

### 1. Frame: [`deliverable`](skills/deliverable/SKILL.md)

This skill turns a rough goal into a brief. It questions the goal until someone with no context could tell a finished result from an unfinished one. Then it writes a handful of definitions of done. Each one is an observable outcome, not an implementation, and comes with a check an agent can run alone:

- a test suite written from scenarios, a `curl`, an SQL query, or a CLI call
- a browser check (URL, viewport, what to read)
- for design and copy, a blind A/B: a judge scores the build against a reference without knowing which is which, against a bar set in the brief

Every check runs once against the current repo before the brief is accepted, so a broken check shows up now and not in round one of an unattended run. An optional out-of-scope list marks what must not be touched.

Next, a fresh read-only agent attacks the brief. It looks for false claims about the repo, sentences two builders would read differently, checks that would pass on a wrong build, and anything that decides the *how*. After I confirm, the brief is committed and pushed on a feature branch. That commit is the hand-off.

### 2. Build unattended: [`implement-loop`](skills/implement-loop/SKILL.md)

This skill runs the brief with nobody watching, round by round:

- **Build.** Builder agents work on the failing definitions. They may not weaken a test or edit the brief. A definition rewritten mid-run counts as deleted, not met.
- **Capture.** A cheap agent runs each check and brings back the artifact: a screenshot, an HTTP response, test output.
- **Judge.** A separate agent gets only the definition, its check and that artifact, and tries to refute it. It never sees the diff.
- The repo's own tests, typecheck, lint and build run every round, and each round is logged and committed.

A run succeeds only through the gate: one fresh agent judges every definition at once, on fresh artifacts. Otherwise the loop stops at one of these points and hands the decision back to me:

- a plateau: the same gap logged three rounds running on a definition that has already had the strongest builder settings
- eight rounds
- a check setup that keeps failing
- a definition that turns out to be contradictory

The orchestrating agent never edits code or reads diffs. It reads verdicts and a log. The output is one commit on the starting branch, plus a pushed tag that holds every round, the brief and the log. The [hand-off scripts](skills/implement-loop/scripts/) have a [test suite](skills/implement-loop/tests/test-scripts.sh) that runs them against a throwaway git remote.

Two supporting skills:

- [`ventilate`](skills/ventilate/SKILL.md) gives every subagent an explicit model and reasoning effort. By default a subagent with no model set inherits the session's model and effort, and nothing warns you. Here, a small wrapper refuses to dispatch an agent that doesn't name them. The choices come from a table of current prices and published cost-per-solved-task figures. Builders start at low effort and move up one level after each failed attempt. Afterwards, [a script](skills/ventilate/scripts/ventilation.py) reads the session's transcripts and adds to the run log what each agent actually ran on, naming any that fell back to the default.
- `cloud` pushes the current branch and runs a prompt against it on a self-hosted remote agent host. I use it for long loop runs. It lives in a private repo, so the `skills/cloud` entry here is a symlink that does not resolve on GitHub.

### 3. Review

- [`/pr`](commands/pr.md) makes me state the PR's scope in my own words before the agent shows me anything about the diff. The agent then compares my statement to the actual diff:
  - Anything I didn't mention, or claimed but isn't there, blocks the PR until I either keep it or remove it.
  - Vague answers get narrowed down with concrete options.
  - Mechanical fallout, like lockfiles, is listed but doesn't block.

  Only in-scope changes are committed, and the PR description is written from my statement, never from the diff alone. The command exists to catch agent changes that go further than what I think I shipped.
- [`stack-this`](skills/stack-this/SKILL.md) splits a large diff, usually the loop's single commit, into a stack of dependent PRs. It cuts by dependency layer, bottom-up: schema, then API, then UI. Each layer must pass the repo's checks on its own base. I approve the split before anything is pushed. The branch and PR mechanics use GitHub's [`gh-stack`](https://github.com/github/gh-stack) extension.
- [`/pr-comments`](commands/pr-comments.md) treats review comments as claims to verify, not instructions. The agent reads the code at each `file:line` and takes a position: agree, disagree, or needs my decision. It argues when it disagrees, and implements only what we agreed on.

### 4. Retro: [`retro`](skills/retro/SKILL.md)

After a session, [a script](skills/retro/digest.sh) turns the transcript into numbers:

- total span against active time
- every gap over five minutes, with its cause
- each prompt and how long it waited
- tool errors and files read three times or more
- one line per subagent: model, minutes, tokens

Then a fresh agent that played no part in the session reads those numbers and the raw transcript. It looks at four things:

- how I phrased my prompts, including a rewrite of the opening prompt that would have avoided the detours
- where time went inside each skill that ran
- instructions that were given but not followed
- facts about the repo that several agents each had to rediscover, which belong in the project's `CLAUDE.md`

Each finding is ranked, quotes the exact sentence at fault, and proposes a replacement or a deletion. The retro changes nothing on its own. Edits happen one sentence at a time, after we discuss them, when I ask.

## Principles

- **No self-verification.** A fresh agent tries to break the work at three points: the brief (before any code), each definition (during the loop), and the session (after it).
- **Check the output, not the diff.** Pages, responses, query results and test output are the evidence. A diff that looks right proves nothing.
- **Explicit model and effort for every agent**, with what actually ran recorded in the run log.
- **Repo knowledge lives in the repo.** Each project keeps its own `CLAUDE.md`, versioned with its code. The global [`CLAUDE.md`](CLAUDE.md) here is empty.
- **Reviewable PRs.** Large agent output goes out as stacked PRs, and each PR's description comes from what I say it does, checked against what it does.

## Guardrails

These live in [`settings.json`](settings.json):

- **Sandbox.** Commands Claude runs are sandboxed. Network access is limited to an allow-list: GitHub, npm, PyPI, Homebrew and a few others. Claude can't retry a command outside the sandbox (`allowUnsandboxedCommands: false`). Only `git`, `gh`, `docker` and `uv` are excluded from it.
- **Deny rules.** The Read tool is denied `.env`, `.env.local` and `.env.*.local` in any directory, and everything under `~/.aws/`.
- **Notifications.** Hooks call [`notify.sh`](notify.sh), which uses macOS `terminal-notifier`, when Claude is waiting for input, asks for a permission, asks a question, or finishes a task.
- **Unattended runs.** `implement-loop` is meant to run unattended only on hosts whose permissions already deny force-push, destructive shell commands and writes outside the repo.

## Repository layout

| Path | Contents |
|---|---|
| [`settings.json`](settings.json) | Permissions, sandbox, hooks, model defaults, plugins |
| [`skills/`](skills/) | The workflow skills above, plus third-party skills (see below) |
| [`commands/`](commands/) | Slash commands, including `/pr` and `/pr-comments` |
| [`rules/`](rules/) | Rules loaded into every session (currently: fetch library docs through Context7) |
| [`agents/`](agents/), [`agent-memory/`](agent-memory/) | A subagent definition, switched off (`.off`), and its notes |
| [`notify.sh`](notify.sh) | Desktop notification used by the hooks |

**Third-party skills.** `skills/` also holds skills I use but didn't write. They include Cloudflare's skill pack ([cloudflare/skills](https://github.com/cloudflare/skills)), which covers Workers, Wrangler, Durable Objects, Turnstile and more, and [`gh-stack`](skills/gh-stack/SKILL.md) from [github/gh-stack](https://github.com/github/gh-stack). Credit belongs to their authors. A few skills in the folder are switched off in `settings.json` (`skillOverrides`).

## Using it

This is a personal config to read and borrow from, not a packaged product. There is no installer, and paths assume `~/.claude`. To use a skill, copy its folder (for example `skills/deliverable/`) into your own `~/.claude/skills/`.

The workflow skills depend on each other and on a few tools:

- `deliverable`, `implement-loop` and `retro` expect one another, and `implement-loop` expects `ventilate`.
- `implement-loop` dispatches agents through Claude Code workflow scripts.
- `retro` needs `jq`, and `ventilate` needs `python3`.
- `/pr` and `/pr-comments` use the GitHub MCP server.
- `stack-this` uses the `gh-stack` extension.
- The reviewers in `deliverable` and `retro` are set to the `fable` model.

---

Author: Adrien Lupo — https://www.linkedin.com/in/adrienlupo/
