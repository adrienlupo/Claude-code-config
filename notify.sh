#!/bin/bash
# Always notify with sound
MESSAGE="${1:-Claude Code}"

terminal-notifier -title "Claude Code" -message "$MESSAGE" -sound Hero
