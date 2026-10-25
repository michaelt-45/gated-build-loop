#!/bin/sh
# Status-line command that saves Claude Code's status-line input (including rate_limits) for quota_watch.sh,
# then hands it to your normal status line (optional).
# settings.json: "statusLine": {"type": "command", "command": "sh ~/.claude/skills/gated-build-loop/scripts/statusline-tee.sh"}
# Optional: STATUSLINE_NEXT="node ~/.claude/hooks/my-statusline.js"
input=$(cat)
printf '%s' "$input" > "${CLAUDE_STATUSLINE_FILE:-/tmp/claude-statusline-last.json}" 2>/dev/null
if [ -n "$STATUSLINE_NEXT" ]; then
  printf '%s' "$input" | sh -c "$STATUSLINE_NEXT"
fi
