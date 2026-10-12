#!/bin/bash
# Run at every cloud session start by the project's hook: brings ~/.claude in step with
# Claude-code-config as pushed, and names what isn't, one ok / FAIL / note line each.
here=$(cd "$(dirname "$0")" && pwd)
config=$(cd "$here/../../.." && pwd)
log=/tmp/cloud-wizard/commands.log
mkdir -p /tmp/cloud-wizard

# Pull first, then run the pulled copy of this script.
if [ -z "${CLOUD_WIZARD_PULLED:-}" ]; then
  git -C "$config" pull -q --ff-only >>"$log" 2>&1 || echo "FAIL  git pull of Claude-code-config  (log: $log)"
  CLOUD_WIZARD_PULLED=1 exec bash "$0" "$@"
fi

lib="$here/cloudlib.py"
echo "cloud-wizard · Claude-code-config@$(git -C "$config" rev-parse --short HEAD)"
if counts=$(python3 "$lib" sync-config "$config" 2>>"$log"); then
  echo "ok    $counts"
else
  echo "FAIL  copying Claude-code-config into ~/.claude  (log: $log)"
fi
python3 "$lib" plugins "$config" "$CLAUDE_PROJECT_DIR" --copy 2>>"$log"

if version=$(/usr/local/bin/chromium --version 2>/dev/null); then
  echo "ok    $version at /usr/local/bin/chromium"
else
  echo "FAIL  /usr/local/bin/chromium: the environment's setup didn't install it  (log: /tmp/cloud-wizard/setup.log)"
fi
took=$(cat /var/lib/cloud-wizard/setup-seconds 2>/dev/null || echo 0)
[ "$took" -le 280 ] || echo "note  the environment's setup took ${took}s: over about 300s it isn't cached, and every session runs it again"
mode=$(python3 "$lib" mode)
if [ "$mode" = auto ]; then echo "ok    auto mode"; else echo "note  started in $mode mode: pick Auto in the session's mode dropdown"; fi
if [ -n "${CLOUD_ENV:-}" ]; then
  echo "ok    environment $CLOUD_ENV"
else
  echo "FAIL  CLOUD_ENV unset: this session isn't in the environment /cloud-wizard set up for the project"
fi
