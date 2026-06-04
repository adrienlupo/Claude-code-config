---
name: sysadmin
description: Bootstrap and operate small website deployments on Hetzner Cloud (Docker + Caddy Let's Encrypt + Tailscale SSH + GitHub Actions to GHCR). Detects the project stack first, then adapts: generates only the deploy/ files, GHA workflow, deploy spec, runbook and (when migrating an existing domain) SEO migration plan. Also handles day-2 ops (rollback, restore, troubleshoot, logs, DNS migration with SEO preservation) by emitting copy-paste commands - never executes SSH or Docker against production. Use when the user wants to deploy a new small site, set up a Hetzner VPS, write a deploy spec, plan an SEO-preserving DNS cutover, or operate an existing Hetzner deployment. Trigger only on explicit /sysadmin invocation.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git remote*)
  - Bash(git log*)
  - Bash(cat package.json*)
  - Bash(cat tsconfig.json*)
  - Bash(cat .gitignore*)
  - Bash(ls*)
  - Bash(test*)
  - Bash(basename*)
  - Bash(pwd)
  - AskUserQuestion
---

# sysadmin - Hetzner deploy stack

Reference architecture: Hetzner Cloud CX23 (Falkenstein) + Debian 12 + Docker + Caddy 2 with Let's Encrypt + Tailscale SSH (no public :22) + GitHub Actions building to GHCR. The original spec is `specs/deploy-hetzner.md` of the `sporting-karate-marseille` project - mirror its decisions, do not invent new ones.

The same stack runs unchanged on any Debian + Docker host (e.g. an OVH VPS). The only provider-specific piece is the public firewall: Hetzner offers a free upstream Cloud Firewall; providers without one (OVH, bare VPS) need a host firewall instead (nftables) - see "Security invariants" for the fallback and its gotchas. Debian 13 (Trixie) also works; note Docker there uses the nftables backend (no `DOCKER-USER` iptables chain).

This skill is opinionated. Stack locked: Next.js 16 (standalone) + Prisma + Postgres 17 + pnpm. The detection step (1) decides which pieces to drop when the project diverges (no DB, no auth). Projects on npm or yarn are out of scope - stop and tell the user to migrate to pnpm first or fork the templates.

## Conventions

- Templates live in `templates/` next to this file. Use `{{VAR}}` for substitutions and `{{#if FLAG}}...{{/if FLAG}}` (or `{{#if !FLAG}}...{{/if !FLAG}}` for negation) for conditional blocks. Two valid forms:
  - **Block form** (markers on their own line): drop the marker lines entirely when the flag is true (keep inner content), drop the whole block when false.
  - **Inline form** (markers inside a sentence): drop just the markers when true (keep the inline content), drop the markers + their content when false. Used for short conditional fragments inside prose, like `tous "running"{{#if HAS_DB}} + db "healthy"{{/if HAS_DB}}`.
- Never overwrite an existing project file silently. If a target path already exists, read it, diff against the rendered template, and ask the user before writing.
- Never execute SSH, `docker compose`, `dig`, or any command that touches the production VPS. Always emit copy-paste blocks. The `allowed-tools` Bash patterns are intentionally restricted to local read-only ops (git remote, package.json reads, file existence).
- French strings stay French (project is for a French clientele). Do not translate `lib/content.ts`-style copy.
- No emojis in any generated file. Absolute imports (`@/...`) in any TypeScript code emitted - but only after verifying the project's `tsconfig.json` has the matching `paths` config (see step 1).

## Security invariants

These hold on every flow and provider. Encode them in any emitted command or file; never weaken them for convenience.

- **Docker bypasses the host firewall.** Docker inserts its own DNAT/FORWARD rules that are evaluated *before* nftables' INPUT chain. A container port published on `0.0.0.0` stays reachable from the internet even with an nftables `policy drop`. So: publish on `0.0.0.0` ONLY `80`/`443` (Caddy). Every other service (Postgres, admin UIs, internal tools) must be bound to `127.0.0.1`, bound to the Tailscale IP `100.x:PORT:PORT`, or not published at all (internal Docker network). This is exactly why the compose file binds Postgres to `127.0.0.1:5432` and why a network firewall (Hetzner) or careful binding (everywhere else) is the real control - not a host firewall on its own.
- **GHCR images stay PRIVATE.** Never tell the user to flip the package to public to simplify pulls (image layers leak source and, frequently, baked-in secrets). The CI push uses the automatic `GITHUB_TOKEN` (`packages: write`). The VPS pull authenticates with a separate **read-only** token (fine-grained PAT, `read:packages` only - never a write token on the server) via `docker login ghcr.io`. Store it in the password manager; `chmod 600 ~/.docker/config.json`.
- **SSH hardening goes in a drop-in that sorts before cloud-init's.** Debian cloud images ship `/etc/ssh/sshd_config.d/50-cloud-init.conf` with `PasswordAuthentication yes`. sshd uses the FIRST value found and reads `sshd_config.d/*.conf` in lexical order, so editing the main `sshd_config` (or a `99-` drop-in) is silently overridden for `PasswordAuthentication`. Write `00-hardening.conf` (prefix < 50) and verify the EFFECTIVE config with `sudo sshd -T | grep -E 'passwordauth|permitroot|allowusers'` - never trust the file content alone.
- **Host nftables fallback (non-Hetzner): match Tailscale by name.** When using host nftables instead of a network firewall, the admin-access rule must be `iifname "tailscale0" accept`, NOT `iif "tailscale0"`. `iif` resolves the interface index at load time and fails at boot ("Interface does not exist") because nftables starts before tailscaled creates the interface; the firewall then fails to load and leaves the box open. `iifname` matches the name at runtime. Always validate boot-persistence with a real reboot, then `systemctl is-active nftables`.
- **Multi-line files: prefer `printf '...' | sudo tee file` over heredocs.** Heredocs (`<<'EOF'`) break on copy-paste when leading whitespace creeps in (the closing `EOF` is no longer at column 0, shell hangs on `>`). Keep emitted commands paste-proof.

## Process

### 1. Detect the stack

Run this before anything else, from the cwd:

| Signal | Reads | Sets |
|---|---|---|
| Framework | `package.json` deps + `next.config.{ts,js,mjs}` | `IS_NEXTJS`, `NEXT_STANDALONE` |
| Package manager | presence of `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` | `PKG_MANAGER` |
| ORM / DB | `prisma/schema.prisma` + its `datasource db { provider = ... }` | `HAS_PRISMA`, `DB_PROVIDER` |
| Auth bootstrap | grep for `bootstrapAdmin` / `ADMIN_PSEUDO` in `instrumentation.*` and `lib/` | `HAS_ADMIN_BOOTSTRAP` |
| TS path alias | `tsconfig.json` `compilerOptions.paths["@/*"]` | `HAS_AT_ALIAS` |
| Gitignore covers .env | `.gitignore` contains `.env` (or pattern matching it) | `GITIGNORES_ENV` |
| Already containerized | `Dockerfile` at root | `HAS_DOCKERFILE` |
| Already has infra | `deploy/docker-compose.yml`, `deploy/Caddyfile` | `HAS_DEPLOY_DIR` |
| Already has workflow | `.github/workflows/deploy.yml` | `HAS_DEPLOY_WORKFLOW` |
| SEO scaffolding | presence of `app/robots.ts`, `app/sitemap.ts`, `next.config.{ts,js}` redirects() block, `lib/seo.ts` (or grep for `NEXT_PUBLIC_SITE_URL`) | `HAS_SEO_SCAFFOLD` |
| Existing SEO migration spec | `specs/seo-migration.md` | `HAS_SEO_SPEC` |
| Repo identity | `git remote -v` (origin) | `GITHUB_OWNER`, `GITHUB_REPO` |

Then compute:
- `HAS_DB = HAS_PRISMA && DB_PROVIDER == "postgresql"` - the only DB shape supported.
- **Hard stop** if `IS_NEXTJS == false`: this skill only supports Next.js + Prisma + Postgres. Do not attempt a generic deployment.
- **Hard stop** if `PKG_MANAGER != "pnpm"`: the templates assume pnpm. Tell the user to migrate to pnpm or fork the templates - do not attempt mechanical substitution from this skill.

Then prepare the **prerequisite fixes** the bootstrap flow will apply (with diff+confirm before each write):

1. **`NEXT_STANDALONE == false`**: edit `next.config.{ts,js,mjs}` to add `output: "standalone"`. The `Dockerfile.tmpl` `COPY .next/standalone` step fails without it. If the user refuses the edit, abort the bootstrap.
2. **`HAS_AT_ALIAS == false`**: the `instrumentation.ts.tmpl` and `lib-bootstrap-admin.ts.tmpl` use `@/lib/...` imports. Edit `tsconfig.json` to add:
   ```json
   "compilerOptions": { "baseUrl": ".", "paths": { "@/*": ["./*"] } }
   ```
   If the user refuses, switch the rendered `instrumentation.ts` to `import { bootstrapAdmin } from "./lib/bootstrap-admin"` (relative). Note this is the only place in the skill where relative imports are acceptable - explicitly because `tsconfig` is not configured.
3. **`GITIGNORES_ENV == false`**: append `.env` and `/opt/*/` to `.gitignore`. The skill's templates write `env.tmpl` content the user copies onto the VPS - never to disk - but the `deploy/docker-compose.yml` references `.env`, and a future careless `cp` could land it in the repo.

Print one short summary block to the user (one line per detected feature, plus the list of prerequisite fixes the bootstrap will apply) and ask via `AskUserQuestion` whether the detection and fix list look right before continuing.

### 2. Ask what to do

Use `AskUserQuestion` with these options, in this order:

1. Bootstrap initial - generate the missing infra files for this project + print the VPS bootstrap checklist (recommended when `!HAS_DEPLOY_DIR`).
2. Generate spec only - write `specs/deploy-hetzner.md` adapted to this project, nothing else.
3. SEO migration plan - write `specs/seo-migration.md` for cutting over an existing domain to this VPS while preserving Google ranking. Recommended when an existing site already ranks on `DOMAIN_APEX` and you want to migrate it to the new Next.js site without losing traffic. Asks for `LEGACY_HOST_LABEL` (e.g. "WordPress OVH") and renders `seo-migration.md.tmpl`.
4. Day-2 op - rollback / restore / logs / troubleshoot / DNS migration on an already-deployed project.
5. Refresh files - re-render `deploy/` + workflow + runbook from current templates (use when templates evolved upstream).

Skip options that do not apply (e.g. hide "Bootstrap initial" if `HAS_DEPLOY_DIR && HAS_DEPLOY_WORKFLOW`, hide "SEO migration plan" if `HAS_SEO_SPEC` unless user explicitly asks to refresh).

### 3. Collect variables

Ask the user (only the variables you do not already have):

| Variable | Default / source | Notes |
|---|---|---|
| `PROJECT_SLUG` | basename of cwd, lowercased, hyphens-only | Used for `/opt/<slug>`, Postgres user/db, Tailscale hostname suffix |
| `PROJECT_NAME` | from `package.json` `name` or ask | Human-readable, for the spec title |
| `GITHUB_OWNER` / `GITHUB_REPO` | parsed from `git remote get-url origin` | Confirm with user |
| `IMAGE_REF` | `ghcr.io/<owner>/<repo>` lowercased | Derived |
| `DOMAIN_APEX` | ask | e.g. `example.fr` |
| `PREVIEW_HOST` | default `preview.<DOMAIN_APEX>` | Subdomain used for preview = prod |
| `VPS_HOSTNAME_TS` | default `<PROJECT_SLUG>-hetzner` | Tailscale hostname |
| `HETZNER_LOCATION` | default `Falkenstein (FSN1)` | |
| `ADMIN_PSEUDO` | only if `HAS_ADMIN_BOOTSTRAP` or user wants the admin bootstrap | |
| `LEGACY_HOST_LABEL` | only for "SEO migration plan" flow | Free-text label for the current host (e.g. `WordPress OVH`, `Shopify`, `Squarespace`). Used in the spec narrative. |

`PKG_MANAGER` is locked to pnpm by the detection step. All templates (`Dockerfile.tmpl`, `deploy.yml.tmpl`) hardcode pnpm. No substitution required.

### 4. Render

For each template in `templates/`, decide whether to render based on the detected flags and the chosen flow:

| Template | Target path | Render when |
|---|---|---|
| `Dockerfile.tmpl` | `Dockerfile` | bootstrap and `!HAS_DOCKERFILE` |
| `instrumentation.ts.tmpl` | `instrumentation.ts` | bootstrap, `HAS_DB`, and not already present |
| `lib-bootstrap-admin.ts.tmpl` | `lib/bootstrap-admin.ts` | bootstrap, `HAS_DB`, and not already present |
| `docker-compose.yml.tmpl` | `deploy/docker-compose.yml` | bootstrap or refresh |
| `Caddyfile.tmpl` | `deploy/Caddyfile` | bootstrap or refresh |
| `env.tmpl` | printed inline (do NOT write to disk) | bootstrap - this is the `/opt/<slug>/.env` template the user will create on the VPS |
| `deploy.yml.tmpl` | `.github/workflows/deploy.yml` | bootstrap or refresh |
| `runbook.md.tmpl` | `deploy/README.md` | bootstrap or refresh |
| `spec.md.tmpl` | `specs/deploy-hetzner.md` | bootstrap or "spec only" |
| `seo-migration.md.tmpl` | `specs/seo-migration.md` | "SEO migration plan" flow (or bootstrap when user explicitly opts in for an existing-domain go-live). Pre-fills the journal date with today and `<VPS_IPV4>` placeholder for the user to substitute. |
| `vps-bootstrap.md.tmpl` | printed inline | bootstrap - the §2.1 to §2.10 commands the user runs on Hetzner |

Substitution: replace every `{{VAR}}` with the collected value. Conditional blocks: keep the inner content (drop the markers) when the flag is true, drop the entire block (markers + content) when false.

Before writing each file: if it exists, show a diff and ask the user (do not assume "overwrite is fine"). Never write `.env` to disk - it contains secrets the user must paste on the VPS.

### 5. Print the VPS bootstrap commands

After rendering, print the contents of `templates/vps-bootstrap.md.tmpl` (substituted) as one long copy-paste block. Do not execute any of it.

### 6. Day-2 ops mode

Recover project info before routing. The compose file uses `${POSTGRES_USER}` references, not literals - so the right sources are:

- `PROJECT_SLUG`: grep `/opt/<slug>/` paths in `.github/workflows/deploy.yml` (the workflow has them hardcoded by the bootstrap step). Fallback: `basename $(pwd)`.
- `VPS_HOSTNAME_TS`: not in the repo (it's a GitHub secret). Ask the user, suggest `<PROJECT_SLUG>-hetzner` from convention.
- `IMAGE_REF`: parse the `${APP_IMAGE:-...}` default in `deploy/docker-compose.yml`, or rebuild from `git remote get-url origin`.
- `PREVIEW_HOST` / `DOMAIN_APEX`: read `deploy/README.md` (the runbook the bootstrap wrote) - it has the contact section with explicit URLs.

If any of these is ambiguous or missing, ask the user instead of guessing. Do not extract from the live VPS - that would require SSH, which the skill is forbidden from running.

Then route on the chosen op:

- **Rollback** - ask for the previous SHA (suggest reading recent merges via `git log --oneline -20 main`). Emit:
  ```
  ssh deploy@<VPS_HOSTNAME_TS>
  cd /opt/<PROJECT_SLUG>
  sed -i "s|^APP_IMAGE=.*|APP_IMAGE=<IMAGE_REF>:sha-<SHA>|" .env
  docker compose up -d app
  ```
  Warn explicitly: `prisma migrate deploy` is not reversible; if the previous SHA's schema diverges, the app may crash. Reference the expand/contract rule.

- **Restore** - print the Hetzner Cloud Backups checklist (console URL, restore vs create-image-from-backup, post-restore checks: cert LE, login admin, DNS A record if IP changed).

- **Logs / status** - emit the SSH commands listed in the runbook (`docker compose ps`, `logs -f app`, `logs -f caddy`, `stats`, `exec app sh`, `exec db psql -U <slug> -d <slug>`). User runs them.

- **Troubleshoot** - ask the user for the symptom (free text or pick from: site down, cert LE looping, **cert LE in backoff post-DNS-cutover** (`tlsv1 alert internal error`, fix via `docker compose restart caddy`), db unhealthy, login admin fails, uploads 404, GHA tailscale denied, push GHCR fails, robots/sitemap stuck in preview mode on prod (`NEXT_PUBLIC_SITE_URL` not flipped), 301 redirects returning 404). For each symptom, print the matching diagnostic block from the runbook template, with project values substituted.

- **DNS migration (SEO go-live)** - the actual J0 cutover, not the planning. Walk the user through the strict sequence: (1) verify TTL propagation on 3 resolvers, (2) flip `NEXT_PUBLIC_SITE_URL` in `/opt/<slug>/.env` + `docker compose up -d app`, (3) sanity-check preview now serves `Allow: /`, (4) tell the user to flip the registrar A record, (5) poll DNS until propagation, (6) verify HTTPS + cert + redirects + robots/sitemap (run `docker compose restart caddy` if TLS errors with `internal error`), (7) decommission preview within 30 min (VPS `SITE_ADDRESS` first, then DNS), (8) tell the user to submit sitemap + indexation requests in GSC. If `HAS_SEO_SPEC`, also append a journal entry at the bottom of `specs/seo-migration.md` with each completed step. Reference the playbook in `specs/seo-migration.md` if it exists; otherwise offer to generate it first via the "SEO migration plan" flow.

Always copy-paste, never execute against the VPS.

## Stop conditions

- Project is not Next.js: stop, explain the skill is scoped to Next.js + Prisma + Postgres + Caddy + Hetzner.
- User asks to bootstrap but the deploy files already exist and the user does not want to refresh: stop after presenting the current state.
- A target file exists and the user declines the diff: skip that file, continue with the others.

## What this skill does NOT do

- Provision Hetzner via API/Terraform (commands stay manual via the console).
- Manage DNS records programmatically (user updates the registrar manually).
- Execute SSH or Docker against the VPS.
- Generate Tailscale ACL JSON beyond pasting the snippet from the spec.
- Support stacks other than Next.js + Prisma + Postgres.
