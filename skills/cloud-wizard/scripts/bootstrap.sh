#!/bin/bash
# cloud-wizard: the setup script of every claude.ai environment, the same for every project.
# All it runs lives in Claude-code-config, so a change there needs no edit on claude.ai.
# Never fails: a non-zero setup script stops the session from starting, and the project's
# session-start hook names whatever is missing.
[ -d /opt/claude-config/.git ] || git clone -q --depth 1 https://github.com/adrienlupo/Claude-code-config /opt/claude-config
[ -f /opt/claude-config/skills/cloud-wizard/scripts/setup.sh ] && bash /opt/claude-config/skills/cloud-wizard/scripts/setup.sh
exit 0
