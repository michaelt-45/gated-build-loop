#!/bin/sh
# Exits (and prints the limits) as soon as the 5-hour or weekly usage reaches a threshold.
# Run it in the background; the orchestrator is notified when it exits.
# Needs statusline-tee.sh so that /tmp/claude-statusline-last.json exists.
# Usage: quota_watch.sh [five_hour_pct=88] [seven_day_pct=92]
FIVE=${1:-88}
WEEK=${2:-92}
FILE=${CLAUDE_STATUSLINE_FILE:-/tmp/claude-statusline-last.json}
while true; do
  hit=$(python3 - "$FILE" "$FIVE" "$WEEK" <<'EOF'
import json, sys
try:
    r = json.load(open(sys.argv[1]))["rate_limits"]
    five, week = float(sys.argv[2]), float(sys.argv[3])
    print(1 if r["five_hour"]["used_percentage"] >= five or r["seven_day"]["used_percentage"] >= week else 0)
except Exception:
    print(0)
EOF
)
  if [ "$hit" = "1" ]; then
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['rate_limits'])" "$FILE"
    exit 0
  fi
  sleep 60
done
