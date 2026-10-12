#!/bin/bash
# Cloud sessions only (claude --cloud, claude.ai/code): Claude-code-config's skills, commands,
# rules, agents and plugins through cloud-wizard, then this project's own setup.
# One ok / FAIL line per step; the session reads them as its first context.
[ "$CLAUDE_CODE_REMOTE" = true ] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
mkdir -p /tmp/cloud-wizard
rm -f /tmp/cloud-wizard/hook.done
cat >/tmp/cloud-wizard/start.json
log=/tmp/cloud-session.log
run() { if "$@" >>"$log" 2>&1; then echo "ok    $*"; else echo "FAIL  $*  (log: $log)"; fi; }

{
  wizard=/opt/claude-config/skills/cloud-wizard/scripts/session.sh
  if [ -f "$wizard" ]; then
    bash "$wizard"
  else
    echo "FAIL  $wizard missing: this environment's setup script isn't cloud-wizard's bootstrap; run /cloud-wizard locally"
  fi

  # This project
@PROJECT_STEPS@
} 2>&1 | tee /tmp/cloud-wizard/hook.out
touch /tmp/cloud-wizard/hook.done
