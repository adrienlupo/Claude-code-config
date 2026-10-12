---
name: cloud-wizard
description: Set a project up so `claude --cloud` sessions on it work like local ones — the plugins enabled locally, Claude-code-config's skills, commands, rules and agents, the project's runtime, services, MCP servers and env — and stay so with no hands on claude.ai. Writes and pushes the repo side, gives the user the claude.ai environment field by field, proves parity with a probe cloud session reported on the PR. Use when the user says "cloud wizard", wants a project ready for cloud sessions, or a cloud session lacks something local has; rerun to audit.
argument-hint: "Nothing — runs on the project in the working directory"
---

A cloud session is a fresh VM: it clones the project from GitHub and nothing else of the user's machine. Two layers make it **like local**:

- **The environment** on claude.ai, one per project, named after the repository. Its setup script is `scripts/bootstrap.sh`, the same for every project; everything it runs lives in Claude-code-config, so it is pasted once and changes reach the cloud through git.
- **The project's `SessionStart` hook**, from `templates/cloud-session.sh`: at every session start it brings `~/.claude` in step with Claude-code-config as pushed, then runs the project's own setup, one `ok` / `FAIL` / `note` line per step.

`scripts/cloudlib.py` holds the one definition of the **inventory** and of what stays **local-only**. **Parity** is judged on the verbatim inventory a probe session posts on the PR, diffed locally — never on a session's account of itself.

Scripts below are in `${CLAUDE_SKILL_DIR}/scripts/`; run them from the project's root.

## What the platform does

Each line is an assumption the wizard is built on; step 1 checks it against the live docs.

1. A cloud session clones the GitHub remote at the current branch; the repo needs a pushed commit. (claude-code-on-the-web)
2. It reads the repo's `CLAUDE.md`, `.claude/settings.json` hooks and permissions, `.mcp.json`, `.claude/skills|commands|agents|rules`. It never reads `~/.claude` or `.claude/settings.local.json`, and installs no plugin a repo's `enabledPlugins` or `extraKnownMarketplaces` declare. (cloud-environments: What carries over from your setup)
3. Environments are created and edited only in claude.ai/code's environment selector. The setup script runs as root after the clone, before Claude Code; a setup under about five minutes is snapshotted for about seven days, rebuilt when the setup script or the allowed domains change. (cloud-environments: Setup scripts, Environment caching)
4. Network *Custom* with "Also include default list of common package managers" allows the defaults plus the listed domains; the defaults hold GitHub, npm, PyPI, nodejs.org and Docker Hub, not `cdn.playwright.dev` nor `playwright.download.prss.microsoft.com`. (cloud-environments: Default allowed domains)
5. Environment variables are per environment, `KEY=value` per line, readable by anyone using it; network secrets (Pro and Max) inject an API key as a request header without the session seeing it. (cloud-environments)
6. `remote.defaultEnvironmentId` picks the environment of `claude --cloud` and is read from project settings too. (settings)
7. `permissions.defaultMode: "auto"` has no effect from project settings; a cloud session's mode comes from the claude.ai mode dropdown. (permission-modes)
8. Plugins load at launch. A skill or command written into `~/.claude` mid-session is usable at once.
9. `claude --cloud` needs a terminal. Inside a session `gh pr` fails (GraphQL) while `gh api` REST works; auto mode's classifier blocks pushing environment diagnostics, so the probe posts names only.

## 1. Read the docs

Fetch https://code.claude.com/docs/en/cloud-environments and https://code.claude.com/docs/en/settings (section "Settings in cloud sessions"); add https://code.claude.com/docs/en/permission-modes when line 7 is in doubt. Mark each line above **holds** or **changed**. A changed line: tell the user what the doc now says and what it changes below, then follow the doc.

Done when every line is marked.

## 2. Preflight

- The project: a git repository with a commit, `origin` on GitHub, the current branch pushed. Otherwise name what's missing and stop.
- Claude-code-config is what the cloud pulls. `git -C ~/.claude status --porcelain -- settings.json CLAUDE.md skills commands rules agents` and `git -C ~/.claude log --oneline @{u}..`: anything listed is local but not in the cloud. Name the files and offer to commit and push them; push only on the user's yes.
- An **audit** when the project has `.claude/cloud-environment.md` and its hook runs `session.sh`: every later step compares with what's there and asks only about what differs. With nothing to change: no commit, no PR, and step 8 probes with `--comment` on the PR `gh pr list --head chore/cloud-setup --state all` finds.

Done when the project qualifies, Claude-code-config is pushed or the user chose to leave it, and you know whether this is an audit.

## 3. Inventory

`python3 cloudlib.py expected ~/.claude .` and `python3 cloudlib.py local-only ~/.claude`. Show the user the plugins by name, the counts of skills, commands, rules and agents, the MCP servers, and the local-only list with its reasons. A plugin enabled but not installed locally shows without its skills: say so — installed locally, they join the check.

Done when the user has seen both lists.

## 4. The project's own setup

Find what a fresh clone needs before the app runs, and the command for each: the runtime version (`.nvmrc`, `.node-version`, `.python-version`, `.tool-versions`) — the VM has Node 22 by default (20 and 21 in `/opt`), Python 3, Docker and Compose, Postgres 16 and Redis 7 installed but stopped; the dependencies from the lockfile; services (`docker-compose*`: start `dockerd` when `docker info` fails, then `docker compose up -d --wait`); env files created from the committed `.env.example`; codegen and migrations; the project's run skill if it has one. MyKarate's hook is the worked example. List every domain a step fetches from beyond the defaults, and the two Playwright domains always. A step's command line is posted on the PR: it carries variable names, never values.

For each server in `.mcp.json`, decide whether it runs headless in the cloud. chrome-devtools does when it branches on `CLAUDE_CODE_REMOTE` to `--headless --isolated --executablePath /usr/local/bin/chromium`, as MyKarate's does.

Done when every step has its command and the reason a fresh clone needs it.

## 5. The repo side, on `chore/cloud-setup`

Branch `chore/cloud-setup` from the current branch, or check it out when it exists.

- `.claude/hooks/cloud-session.sh`: the template, with step 4's commands in place of `@PROJECT_STEPS@`, each through `run` so it prints `ok` or `FAIL`. A hook already there keeps its project steps; whatever it did for Claude-code-config (pulling it, copying skills) gives way to the template's block, and the whole takes the template's `tee` and `hook.done` ending. `chmod +x`.
- `.claude/settings.json`: a `SessionStart` hook, matcher `startup|resume`, `"timeout": 1200`, running `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/cloud-session.sh`, merged with every key already there. Remove `permissions.defaultMode` when it is `auto` (line 7: it does nothing in the cloud and overrides the user's own `auto` locally); the wizard writes `auto` into no project file.
- `.mcp.json`: step 4's changes.
- `.gitignore`: add `.claude/settings.local.json` unless `git check-ignore -q` already ignores it — step 6 pins the environment there.

Done when `bash -n` passes on the hook and both JSON files parse.

## 6. claude.ai, one field at a time

One message per field with its value in a code block, then wait for the user's "done". In an audit, or when the environment was made by hand (MyKarate's), edit it and ask only for the fields that change.

1. claude.ai/code → environment selector → add an environment named after the repository (the `CLOUD_ENV` value below).
2. Network access *Custom*, "Also include default list of common package managers" ticked, allowed domains: step 4's list.
3. Environment variables: `f=$(mktemp) && python3 cloudlib.py env-block . "$f" && pbcopy <"$f"; rm -f "$f"`. It prints key names only and puts the block — `CLOUD_ENV` and the non-secret values a committed `.env.example` doesn't give — on the clipboard; no value enters this conversation. Show the user the names and where each goes; they paste the block and can drop any line before saving. Then the secret keys it listed, one by one: each is theirs to add with its value, as a network secret when it's an API key sent as a request header, or to leave out — a pasted empty value would override the `.env` the hook writes.
4. Setup script: the content of `bootstrap.sh`, verbatim.
5. Ask the user to type `/remote-env` here and pick the environment. It writes `remote.defaultEnvironmentId` into `~/.claude/settings.json`: move the value into the project's `.claude/settings.local.json`, and put back the user's previous value (or remove the key) — the pin is this project's alone.
6. The session mode dropdown on claude.ai on Auto.

Then write `.claude/cloud-environment.md`: the environment's name, network level, allowed domains, each env key's name and where it went (block, environment variable, network secret, left out), and that the setup script is `bootstrap.sh` — names only, never a value. It is what an audit compares against.

Done when the user said "done" to every field and the record is written. Changing the setup script or the domains rebuilds the snapshot; variables reach new sessions.

## 7. Commit, guard, push, PR

Commit the files of steps 5 and 6 alone. `python3 cloudlib.py secrets . <default-branch>..HEAD`: a `LEAK` line names a key whose value is in the diff — take it out, amend, run it again. Push `chore/cloud-setup` and open a PR against the default branch with `gh pr create`; its body says what the setup does and that the probe's report follows. The PR is the user's to merge; nothing goes to the default branch.

Done when `secrets` prints `ok` and the PR exists.

## 8. Probe

From the `chore/cloud-setup` checkout, run `probe.sh <PR> [--comment] [-- <smoke command>]` in the background. The smoke command is the project's run script when it has one (MyKarate: `.claude/skills/run-mykarate/scripts/up.sh`). It launches a `claude --cloud` session, waits up to 30 minutes for the report on the PR, adds the verdict and exits 0 on parity. When it can't start the session it prints the command: give it to the user to run with `!` and wait.

Read the verdict with the user. A `FAIL` at session start points to its log; a missing plugin to its marketplace; a missing `chromium` to `/tmp/cloud-wizard/setup.log` and the Playwright domains; a stale `Claude-code-config@` to an environment that pulled before the last push. Fix the repo side and probe again; a claude.ai field goes back to step 6 for that field alone.

Done when the verdict says parity holds, or the user has every gap with its cause. Hand over the PR link, the verdict and the local-only list.
