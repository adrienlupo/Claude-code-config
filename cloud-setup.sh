#!/bin/bash
# Setup script for the claude.ai/code cloud environment (pasted there, not run locally)
git clone --depth 1 https://github.com/adrienlupo/Claude-code-config /tmp/me
mkdir -p ~/.claude/skills
cp -r /tmp/me/skills/* ~/.claude/skills/
claude plugin marketplace add mattpocock/skills
claude plugin install mattpocock-skills@mattpocock
exit 0
