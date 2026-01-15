#!/bin/bash
# Always notify with sound
MESSAGE="${1:-Claude Code}"
SOUND="${2:-default}"

terminal-notifier -title "Claude Code" -message "$MESSAGE" -sound "$SOUND" -execute "open -a iTerm"
