#!/bin/bash
# Run by bootstrap.sh once per environment snapshot, as root, before Claude Code launches:
# Claude-code-config into ~/.claude, every enabled plugin (installed now, it loads at launch),
# headless Chromium. Always exits 0: a failing setup script stops the session from starting,
# and the session-start hook names whatever is missing.
here=$(cd "$(dirname "$0")" && pwd)
config=$(cd "$here/../../.." && pwd)
mkdir -p /tmp/cloud-wizard /var/lib/cloud-wizard
exec >>/tmp/cloud-wizard/setup.log 2>&1

# Headless Chromium for the chrome-devtools MCP and plain scripts (cdn.playwright.dev and
# playwright.download.prss.microsoft.com must be allowed), in parallel with the plugins: a setup
# over about five minutes is never cached, and every session pays it again.
# --ignore-certificate-errors: the session's proxy re-encrypts HTTPS with a certificate Chromium doesn't trust.
if [ ! -x /usr/local/bin/chromium ]; then
  (
    PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright npx -y playwright install --with-deps chromium
    chrome=$(ls /opt/ms-playwright/chromium-*/chrome-linux*/chrome 2>/dev/null | head -1)
    if [ -n "$chrome" ]; then
      printf '#!/bin/sh\nexec %s --no-sandbox --disable-dev-shm-usage --ignore-certificate-errors "$@"\n' "$chrome" > /usr/local/bin/chromium
      chmod +x /usr/local/bin/chromium
    fi
  ) &
fi

python3 "$here/cloudlib.py" sync-config "$config"

# The repository is cloned before this runs, at a path the docs don't give: its project-scope
# plugins load at launch when it's found here, and are installed at session start otherwise.
project=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$project" ] || project=$(find / -maxdepth 4 -name .git -type d -not -path '/proc/*' -not -path '/opt/*' 2>/dev/null | head -1 | sed 's|/\.git$||')
python3 "$here/cloudlib.py" plugins "$config" "${project:-/nonexistent}"

wait
echo "$SECONDS" >/var/lib/cloud-wizard/setup-seconds
exit 0
