#!/usr/bin/env bash
# Launcher for the self-hosted OpenHands Agent Canvas stack on the work hosts.
# Reads the session API key from the Canvas state dir at runtime; no secrets in git.
set -euo pipefail

CANVAS_BIN="${CANVAS_BIN:-$HOME/.npm-global/bin/agent-canvas}"
STATE_DIR="${OH_CANVAS_SAFE_STATE_DIR:-$HOME/.openhands/agent-canvas}"

if [ ! -x "$CANVAS_BIN" ]; then
  echo "agent-canvas CLI not found at $CANVAS_BIN" >&2
  exit 1
fi
if [ ! -s "$STATE_DIR/api-key.txt" ]; then
  echo "Canvas session API key not found at $STATE_DIR/api-key.txt" >&2
  echo "Start the stack once with the official launcher to generate it." >&2
  exit 1
fi

MODE="${1:-full}"
case "$MODE" in
  backend)
    OH_CANVAS_SAFE_BACKEND_PORT=19000 \
    OH_CANVAS_SAFE_AUTOMATION_PORT=19001 \
    OH_CANVAS_SAFE_STATE_DIR="$STATE_DIR" \
      "$CANVAS_BIN" --backend-only --port 12000 --host 0.0.0.0
    ;;
  ui)
    node /tmp/static-launch.mjs
    ;;
  full|*)
    echo "Usage: $0 {backend|ui}" >&2
    exit 1
    ;;
esac