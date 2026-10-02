#!/bin/bash
# Setup script for the claude.ai/code cloud environment (pasted there, not run locally)
set -euo pipefail

# Skills: each repo's hook pulls them again at session start
git clone --depth 1 https://github.com/adrienlupo/Claude-code-config /opt/claude-config
mkdir -p ~/.claude/skills
cp -r /opt/claude-config/skills/. ~/.claude/skills/
claude plugin marketplace add mattpocock/skills
claude plugin install mattpocock-skills@mattpocock

# Headless Chromium, shared by the chrome-devtools MCP and plain scripts.
# --ignore-certificate-errors: the session's proxy re-encrypts HTTPS, and Chromium doesn't trust its certificate
PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright npx -y playwright install --with-deps chromium
chrome=$(ls /opt/ms-playwright/chromium-*/chrome-linux*/chrome | head -1)
printf '#!/bin/sh\nexec %s --no-sandbox --disable-dev-shm-usage --ignore-certificate-errors "$@"\n' "$chrome" > /usr/local/bin/chromium
chmod +x /usr/local/bin/chromium
