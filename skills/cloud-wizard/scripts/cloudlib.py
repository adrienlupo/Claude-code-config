#!/usr/bin/env python3
"""cloud-wizard's one definition of "like local", shared by the local wizard, the
environment's setup script and the cloud session's start hook.

CONFIG is a Claude-code-config checkout (~/.claude locally, /opt/claude-config in the
cloud); PROJECT is the project's checkout.

  expected CONFIG PROJECT       the inventory a cloud session must hold (run locally)
  actual PROJECT                the inventory this session holds (run in the cloud)
  local-only CONFIG             what stays local, each with its reason (run locally)
  sync-config CONFIG            copy CONFIG's skills, commands, rules, agents, CLAUDE.md into ~/.claude
  plugins CONFIG PROJECT [--copy]
                                install every enabled plugin missing here; --copy (session start)
                                makes one installed now usable at once, since plugins load at launch
  mode                          the permission mode the session started in
  env-block PROJECT OUT         write the claude.ai env block to OUT (secret keys left empty), print key names
  secrets PROJECT RANGE         grep a git range for every local secret value; prints key names only
  redact FILE PROJECT           replace every environment and .env value in FILE by its key's name
  splice BODY REPORT            BODY with REPORT replacing its marked block, or appended
  verdict REPORT CONFIG PROJECT [OUT]
                                diff a probe report against the local inventory; OUT gets the
                                report with the verdict inside its marked block
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

CLAUDE = Path.home() / ".claude"
STATE = Path("/tmp/cloud-wizard")
KINDS = {"skills": "skill", "commands": "command", "rules": "rule", "agents": "agent"}
DIRS = {kind: top for top, kind in KINDS.items()}
OFFICIAL = {"claude-plugins-official": "anthropics/claude-plugins-official"}
SECRET_NAME = re.compile(r"KEY|SECRET|TOKEN|PASS|DSN|CREDENTIAL|PRIVATE|SIGNING|SALT|CERT")
EXAMPLE = re.compile(r"(^|/)\.env(\.[^/]*)?\.example$")
LOCAL_ENV = re.compile(r"(^|/)\.env(\.[^/]*)?$")


def load_json(path, default):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return default


def sh(*cmd, log=STATE / "commands.log"):
    log.parent.mkdir(parents=True, exist_ok=True)
    with open(log, "a") as out:
        out.write(f"$ {' '.join(cmd)}\n")
        out.flush()
        return subprocess.run(cmd, stdout=out, stderr=out, stdin=subprocess.DEVNULL).returncode == 0


def git(repo, *args):
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True).stdout


# Claude-code-config entries: tracked, present in the worktree, not switched off.
def config_entries(config):
    config = Path(config)
    off = {k for k, v in load_json(config / "settings.json", {}).get("skillOverrides", {}).items() if v == "off"}
    entries, local_only, seen = [], [], set()
    for path in git(config, "ls-files", "--", *KINDS).splitlines():
        top, _, rest = path.partition("/")
        first = rest.split("/", 1)[0]
        if (top, first) in seen:
            continue
        seen.add((top, first))
        src = config / top / first
        kind = KINDS[top]
        if not os.path.lexists(src) or first.endswith(".off"):
            continue
        if src.is_symlink() and not src.resolve().is_relative_to(config.resolve()):
            local_only.append((f"{kind} {first}", f"a symlink to {os.readlink(src)}, outside Claude-code-config"))
            continue
        if kind == "skill" and (first in off or not (src / "SKILL.md").is_file()):
            continue
        if kind in ("command", "agent"):
            if not first.endswith(".md"):
                continue
            first = first[:-3]
        entries.append((kind, first, src))
    return entries, local_only


def enabled_plugins(config, project):
    on, markets = {}, dict(OFFICIAL)
    for settings in (Path(config) / "settings.json", Path(project) / ".claude" / "settings.json"):
        s = load_json(settings, {})
        on.update(s.get("enabledPlugins", {}))
        for name, decl in s.get("extraKnownMarketplaces", {}).items():
            src = decl.get("source", {})
            markets[name] = src.get("repo") or src.get("url")
    return sorted(k for k, v in on.items() if v), markets


def installed():
    plugins = load_json(CLAUDE / "plugins" / "installed_plugins.json", {}).get("plugins", {})
    return {pid: entries[0]["installPath"] for pid, entries in plugins.items() if entries}


def plugin_contents(root):
    root = Path(root)
    manifest = load_json(root / ".claude-plugin" / "plugin.json", {})
    found = {"skill": {}, "command": {}, "agent": {}}

    def paths(key):
        declared = manifest.get(key) or []
        return [root / key] + [root / p for p in ([declared] if isinstance(declared, str) else declared)]

    for p in paths("skills"):
        candidates = [p] if (p / "SKILL.md").is_file() else sorted(p.iterdir()) if p.is_dir() else []
        for s in candidates:
            if (s / "SKILL.md").is_file():
                found["skill"][s.name] = s
    for kind, key in (("command", "commands"), ("agent", "agents")):
        for p in paths(key):
            for f in [p] if p.is_file() else sorted(p.glob("*.md")) if p.is_dir() else []:
                if f.suffix == ".md":
                    found[kind][f.stem] = f
    return found


def repo_name(project):
    url = git(project, "remote", "get-url", "origin").strip()
    return re.sub(r"\.git$", "", url.rstrip("/").split("/")[-1].split(":")[-1]) or Path(project).resolve().name


def expected(config, project):
    lines = set()
    ids, _ = enabled_plugins(config, project)
    paths = installed()
    for pid in ids:
        lines.add(f"plugin {pid}")
        if pid in paths:
            name = pid.split("@")[0]
            for kind, items in plugin_contents(paths[pid]).items():
                lines.update(f"plugin-{kind} {name}:{n}" for n in items)
    lines.update(f"{kind} {name}" for kind, name, _ in config_entries(config)[0])
    lines.update(f"mcp {s}" for s in load_json(Path(project) / ".mcp.json", {}).get("mcpServers", {}))
    lines.update({"chromium", "mode auto", f"env CLOUD_ENV={repo_name(project)}"})
    return sorted(lines)


def actual(project):
    lines = set()
    made = load_json(STATE / "plugins-this-session.json", {})
    listing = subprocess.run(["claude", "plugin", "list", "--json"], capture_output=True, text=True, cwd=project)
    try:
        plugins = json.loads(listing.stdout or "[]")
    except ValueError:
        plugins = []
        lines.add(f"FAIL  claude plugin list --json: {(listing.stderr or listing.stdout).strip()[:200]}")
    for p in plugins:
        if not (p.get("enabled") or p.get("projectEnabled")):
            continue
        pid, name = p["id"], p["id"].split("@")[0]
        lines.add(f"plugin {pid}")
        items = made[pid] if pid in made else {k: list(v) for k, v in plugin_contents(p["installPath"]).items()}
        for kind, names in items.items():
            lines.update(f"plugin-{kind} {name}:{n}" for n in names)
    copied = {(kind, n) for items in made.values() for kind, names in items.items() for n in names}
    for top, kind in KINDS.items():
        d = CLAUDE / top
        for e in sorted(d.iterdir()) if d.is_dir() else []:
            if kind == "skill" and not (e / "SKILL.md").is_file():
                continue
            if kind in ("command", "agent"):
                if e.suffix != ".md":
                    continue
                name = e.stem
            else:
                name = e.name
            if (kind, name) not in copied:
                lines.add(f"{kind} {name}")
    # an MCP server counts when it connects here, not because .mcp.json names it
    health = subprocess.run(["claude", "mcp", "list"], capture_output=True, text=True, cwd=project, timeout=180).stdout
    connected = {m.group(1) for m in re.finditer(r"^(.+?): .* - ✔ Connected", health, re.M)}
    lines.update(f"mcp {s}" for s in load_json(Path(project) / ".mcp.json", {}).get("mcpServers", {}) if s in connected)
    chromium = subprocess.run(["/usr/local/bin/chromium", "--version"], capture_output=True)
    if chromium.returncode == 0:
        lines.add("chromium")
    lines.add(f"mode {start_mode()}")
    lines.add(f"env CLOUD_ENV={os.environ.get('CLOUD_ENV', '')}")
    return sorted(lines)


def start_mode():
    return load_json(STATE / "start.json", {}).get("permission_mode") or "unknown"


def local_only(config):
    out = list(config_entries(config)[1])
    s = load_json(Path(config) / "settings.json", {})
    for event, groups in s.get("hooks", {}).items():
        for g in groups:
            for h in g.get("hooks", []):
                why = "macOS desktop notification" if "notify" in h.get("command", "") else "user-level hooks stay on this machine"
                out.append((f"hook {event}:{g.get('matcher', '*')}", why))
    if "sandbox" in s:
        out.append(("sandbox settings", "the cloud VM is its own sandbox"))
    for name, server in load_json(Path.home() / ".claude.json", {}).get("mcpServers", {}).items():
        url = server.get("url", "")
        if re.match(r"https?://(127\.0\.0\.1|localhost)", url):
            why = "listens on this machine"
        elif url:
            why = "remote server signed in here (OAuth or a token header); a claude.ai connector covers it if you connected one there"
        else:
            why = "user-level stdio server; put it in the project's .mcp.json to have it in the cloud"
        out.append((f"mcp {name} (user)", why))
    out.append(("iOS Simulator", "macOS only"))
    return out


def sync_config(config):
    config = Path(config)
    counts = {}
    for kind, name, src in config_entries(config)[0]:
        dest = CLAUDE / DIRS[kind] / src.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(src, dest, symlinks=False, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dest)
        counts[kind] = counts.get(kind, 0) + 1
    if (config / "CLAUDE.md").is_file():
        shutil.copy2(config / "CLAUDE.md", CLAUDE / "CLAUDE.md")
    return " · ".join(f"{DIRS[k]} {n}" for k, n in sorted(counts.items()))


def ensure_plugins(config, project, copy):
    ids, markets = enabled_plugins(config, project)
    known = set(load_json(CLAUDE / "plugins" / "known_marketplaces.json", {}))
    made_file = STATE / "plugins-this-session.json"
    made = load_json(made_file, {})
    present = installed()
    failed = False
    for pid in ids:
        if pid in present:
            print(f"ok    plugin {pid}")
            continue
        market = pid.partition("@")[2]
        if market not in known:
            src = markets.get(market)
            if not src:
                print(f"FAIL  plugin {pid}: marketplace {market} isn't in any extraKnownMarketplaces")
                failed = True
                continue
            if not sh("claude", "plugin", "marketplace", "add", src):
                print(f"FAIL  plugin {pid}: claude plugin marketplace add {src}  (log: {STATE}/commands.log)")
                failed = True
                continue
            known.add(market)
        if not sh("claude", "plugin", "install", pid):
            print(f"FAIL  plugin {pid}: claude plugin install  (log: {STATE}/commands.log)")
            failed = True
            continue
        if not copy:
            print(f"ok    plugin {pid}")
            continue
        usable, clashes = {}, []
        for kind, items in plugin_contents(installed()[pid]).items():
            for n, src in items.items():
                dest = CLAUDE / DIRS[kind] / src.name
                if dest.exists():
                    clashes.append(f"{kind} {n}")
                    continue
                dest.parent.mkdir(parents=True, exist_ok=True)
                (shutil.copytree if src.is_dir() else shutil.copy2)(src, dest)
                usable.setdefault(kind, []).append(n)
        made[pid] = usable
        made_file.write_text(json.dumps(made))
        clash = f"; not copied, a same-named one is already here: {', '.join(clashes)}" if clashes else ""
        print(f"ok    plugin {pid}: installed this session, its skills, commands and agents copied in{clash}."
              " Its hooks, MCP servers and LSP load once the environment rebuilds: on claude.ai, add a blank line"
              " to its setup script and save")
    for pid in sorted(set(present) - set(ids)):
        print(f"note  plugin {pid} is off in Claude-code-config but on here until the environment rebuilds")
    return not failed


def local_env_files(project):
    """The project's own .env files: not examples, not in node_modules or a nested checkout."""
    root = Path(project)
    for here, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in ("node_modules", ".git") and not (Path(here, d) / ".git").exists())
        for name in sorted(files):
            rel = str(Path(here, name).relative_to(root))
            if LOCAL_ENV.search(rel) and not EXAMPLE.search(rel):
                yield rel, parse_env(Path(here, name))


def env_block(project, out):
    """Write the claude.ai env block to OUT — the marker and every non-secret value the cloud
    can't get from a committed .env.example — and return one line per key, names only, so no
    value enters the transcript. Secret keys stay out of the block: pasted empty, a variable
    would override the value the hook writes to .env."""
    project = Path(project)
    examples = {}
    for f in git(project, "ls-files").splitlines():
        if EXAMPLE.search(f):
            for key, value in parse_env(project / f).items():
                examples.setdefault(key, set()).add(value)
    local = {}
    for rel, values in local_env_files(project):
        for key, value in values.items():
            local.setdefault(key, (rel, value))
    block, report = [f"CLOUD_ENV={repo_name(project)}"], ["CLOUD_ENV\tin the block\tthe environment's marker"]
    for key in sorted(set(examples) | set(local)):
        if key == "CLOUD_ENV":
            continue
        where, value = local.get(key, (None, ""))
        committed = bool(examples.get(key, set()) - {""})
        if SECRET_NAME.search(key):
            state = "a dev value is committed in .env.example" if committed else \
                "empty in .env.example" if key in examples else f"only in {where}"
            report.append(f"{key}\tsecret, yours to add or leave out\t{state}")
        elif committed:
            continue  # the hook's copy of .env.example gives the cloud this value
        elif re.search(r"://[^/@\s]+:[^/@\s]+@", value):
            report.append(f"{key}\tsecret (credentials in the URL), yours to add or leave out\tonly in {where}")
        elif value:
            block.append(f"{key}={value}")
            report.append(f"{key}\tin the block\tfrom {where}")
    Path(out).write_text("\n".join(block) + "\n")
    return report


def parse_env(path):
    out = {}
    try:
        text = Path(path).read_text()
    except (OSError, UnicodeDecodeError):
        return out
    for line in text.splitlines():
        m = re.match(r"\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip().strip("'\"")
    return out


def secrets(project, rng):
    project = Path(project)
    tracked = git(project, "ls-files").splitlines()
    committed = {v for f in tracked if EXAMPLE.search(f) for v in parse_env(project / f).values()}
    values = {}
    for rel, env in local_env_files(project):
        for key, value in env.items():
            if len(value) >= 8 and value not in committed:
                values[f"{rel}:{key}"] = value
    user = load_json(Path.home() / ".claude.json", {})
    servers = list(user.get("mcpServers", {}).items())
    servers += [i for p in user.get("projects", {}).values() for i in (p.get("mcpServers") or {}).items()]
    for name, server in servers:
        for field in ("headers", "env"):
            for key, value in (server.get(field) or {}).items():
                value = re.sub(r"^Bearer\s+", "", str(value))
                if len(value) >= 8:
                    values[f"~/.claude.json:{name}.{key}"] = value
    diff = git(project, "log", "-p", rng)
    leaks = sorted(k for k, v in values.items() if v in diff)
    for k in leaks:
        print(f"LEAK  {k}")
    print(f"{'FAIL' if leaks else 'ok'}    {len(values)} secret values checked against {rng} (values under 8 characters skipped)")
    return not leaks


MARK, END = "<!-- cloud-wizard:report", "<!-- cloud-wizard:report:end -->"


def read_text(path):
    # GitHub hands back \r\n once a body has been edited in its web UI
    return Path(path).read_text().replace("\r", "")


def splice(body, report):
    body, report = read_text(body), read_text(report).strip()
    if MARK in body and END in body:
        head, rest = body.split(MARK, 1)
        return head + report + rest.split(END, 1)[1]
    return (body.rstrip() + "\n\n" + report + "\n").lstrip()


BENIGN = {"PATH", "HOME", "PWD", "OLDPWD", "SHELL", "TERM", "USER", "LOGNAME", "HOSTNAME", "TMPDIR", "SHLVL",
          "CLOUD_ENV", "CLAUDE_PROJECT_DIR", "CLAUDE_ENV_FILE", "CLAUDE_CODE_REMOTE", "CLAUDE_CODE_REMOTE_SESSION_ID"}


def redact(path, project):
    """Replace, in PATH, every value of this machine's environment and of the project's .env
    files by its key's name — the report goes to GitHub."""
    values = {k: v for k, v in os.environ.items() if k not in BENIGN and not k.startswith("LC_")}
    for _, env in local_env_files(project):
        values.update(env)
    text = read_text(path)
    for key, value in sorted(values.items(), key=lambda kv: -len(kv[1])):
        if len(value) >= 12 and not value.startswith("/") and not value.isdigit():
            text = text.replace(value, f"<{key}>")
    Path(path).write_text(text)


def verdict(report, config, project):
    text = read_text(report)
    block = re.search(r"### Inventory\n```\n(.*?)```", text, re.S)
    have = set(block.group(1).split("\n")) - {""} if block else set()
    want = set(expected(config, project))
    missing = sorted(want - have)
    gaps = [m for m in missing if m.startswith("mode ")]
    missing = [m for m in missing if not m.startswith("mode ")]
    fails = [l for l in text.splitlines() if l.startswith("FAIL")]
    lines = ["### Verdict"]
    if not block:
        lines.append("No inventory in the report: the probe didn't run report.sh to the end.")
    # the session must have pulled what GitHub has — a full snapshot alone proves no update arrives
    pulled = re.search(r"^cloud-wizard · Claude-code-config@(\w+)", text, re.M)
    pushed = git(config, "rev-parse", "@{u}").strip()
    if not pulled:
        fails.append("FAIL  no Claude-code-config@ line: session.sh didn't run at session start")
    elif pushed and not pushed.startswith(pulled.group(1)):
        fails.append(f"FAIL  the session ran Claude-code-config@{pulled.group(1)}, GitHub has {pushed[:7]}")
    lines += [f"- missing: `{m}`" for m in missing]
    lines += [f"- gap (doesn't block parity): `{g}` — the session started in "
              f"`{next((h for h in have if h.startswith('mode ')), 'mode unknown')[5:]}`; pick Auto in the session's mode dropdown"
              for g in gaps]
    lines += [f"- failed at session start: `{f}`" for f in fails]
    ok = bool(block) and not missing and not fails
    lines.append("**Parity holds.**" if ok else "**The setup needs adjusting** — each line above names what.")
    return "\n".join(lines), ok


def main(argv):
    cmd, args = argv[0], argv[1:]
    if cmd == "expected":
        print("\n".join(expected(*args)))
    elif cmd == "actual":
        print("\n".join(actual(*args)))
    elif cmd == "local-only":
        for item, why in local_only(*args):
            print(f"{item}\t{why}")
    elif cmd == "sync-config":
        print(sync_config(*args))
    elif cmd == "plugins":
        return 0 if ensure_plugins(args[0], args[1], "--copy" in args) else 1
    elif cmd == "mode":
        print(start_mode())
    elif cmd == "env-block":
        print("\n".join(env_block(*args)))
    elif cmd == "secrets":
        return 0 if secrets(*args) else 1
    elif cmd == "redact":
        redact(*args)
    elif cmd == "splice":
        sys.stdout.write(splice(*args))
    elif cmd == "verdict":
        text, ok = verdict(*args[:3])
        print(text)
        if len(args) > 3:
            report = read_text(args[0]).strip()
            Path(args[3]).write_text(report.replace(END, text + "\n" + END) if END in report else report + "\n" + text)
        return 0 if ok else 1
    else:
        sys.exit(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]) if len(sys.argv) > 1 else __doc__)
