#!/usr/bin/env bash
# sync-mata-state.sh — Push MATA agent states to Star Office UI
set -o pipefail
export PATH="/opt/homebrew/bin:$PATH"

JOIN_KEY="mata_crew_001"
API="http://127.0.0.1:19000/agent-push"
MATA_DIR="$HOME/mata"

map_state() {
  case "$1" in
    *busy*) echo "writing" ;;
    *thinking*) echo "researching" ;;
    *dead*) echo "error" ;;
    *) echo "idle" ;;
  esac
}

while true; do
  for entry in "ag-crew:co:agent_1776086634668_821u:ag-crew co" \
               "daily-manager:co:agent_1776086634682_qxs3:daily-mgr co" \
               "x-crew:co:agent_1776086634694_x7m3:大管家"; do
    CREW=$(echo "$entry" | cut -d: -f1)
    AGENT=$(echo "$entry" | cut -d: -f2)
    AGENT_ID=$(echo "$entry" | cut -d: -f3)
    NAME=$(echo "$entry" | cut -d: -f4)

    STATUS=$(cd "$MATA_DIR" && bb status "$CREW" 2>&1 | grep "$AGENT " | head -1 || echo "idle")
    STATE=$(map_state "$STATUS")
    PCT=$(echo "$STATUS" | grep -oE '[0-9]+%' | head -1 || echo "")
    DETAIL="$NAME ${PCT:+| context $PCT}"

    curl -s -X POST "$API" \
      -H "Content-Type: application/json" \
      -d "{\"agentId\":\"$AGENT_ID\", \"joinKey\":\"$JOIN_KEY\", \"state\":\"$STATE\", \"detail\":\"$DETAIL\", \"name\":\"$NAME\"}" > /dev/null 2>&1
  done
  sleep 10
done
