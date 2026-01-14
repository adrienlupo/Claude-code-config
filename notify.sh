#!/bin/bash
# Notification si iTerm n'est pas au premier plan OU si l'onglet n'est pas actif
MESSAGE="${1:-Claude Code}"
SOUND="${2:-default}"

ACTIVE_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

if [ "$ACTIVE_APP" != "iTerm2" ]; then
    terminal-notifier -title "Claude Code" -message "$MESSAGE" -sound "$SOUND" -execute "open -a iTerm"
else
    # iTerm2 is active, check if current tab is focused
    ACTIVE_SESSION=$(osascript -e 'tell application "iTerm2" to get id of current session of current tab of current window')
    if [ "$ITERM_SESSION_ID" != "$ACTIVE_SESSION" ]; then
        terminal-notifier -title "Claude Code" -message "$MESSAGE" -sound "$SOUND" -execute "open -a iTerm"
    fi
fi
