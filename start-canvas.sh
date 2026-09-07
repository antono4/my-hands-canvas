#!/usr/bin/env bash
# Bootstrap launcher — installs the minimal runtime deps for the static UI
# (sirv + httpxy) into canvas/node_modules (git-ignored), then runs the stack.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANVAS_DIR="${CANVAS_DIR:-$REPO_DIR/canvas}"
CANVAS_BIN="${CANVAS_BIN:-$HOME/.npm-global/bin/agent-canvas}"
STATE_DIR="${OH_CANVAS_SAFE_STATE_DIR:-$HOME/.openhands/agent-canvas}"
BACKEND_PORT="${OH_CANVAS_SAFE_BACKEND_PORT:-19000}"
AUTOMATION_PORT="${OH_CANVAS_SAFE_AUTOMATION_PORT:-19001}"
UI_PORT="${OH_CANVAS_SAFE_UI_PORT:-12001}"
INGRESS_PORT="${OH_CANVAS_SAFE_INGRESS_PORT:-12000}"

# ── Pre-flight checks ────────────────────────────────────────────────────────
if [ ! -d "$CANVAS_DIR/build" ]; then
  echo "Canvas frontend build not found at $CANVAS_DIR/build" >&2
  exit 1
fi
if [ ! -x "$(command -v node)" ]; then
  echo "node not found on PATH (required for the static UI)." >&2
  exit 1
fi

# Install runtime deps (sirv + httpxy) if missing — git-ignored.
ensure_deps() {
  if [ -d "$CANVAS_DIR/node_modules/sirv" ] && [ -d "$CANVAS_DIR/node_modules/httpxy" ]; then
    return
  fi
  echo "Installing Canvas runtime deps into $CANVAS_DIR/node_modules ..."
  TMP="$(mktemp -d -t canvas-deps.XXXXXX)"
  rm -rf "$TMP" && mkdir -p "$TMP"
  (cd "$TMP" && npm init -y >/dev/null 2>&1 && npm install --no-audit --no-fund sirv@3.0.2 httpxy@0.5.3 >/dev/null 2>&1)
  cp -r "$TMP/node_modules" "$CANVAS_DIR"
  rm -rf "$TMP"
}

SESSION_API_KEY="$(cat "$STATE_DIR/api-key.txt" 2>/dev/null || true)"

# Static UI + API reverse-proxy (the "Host 2" service, port 12001).
start_ui() {
  mkdir -p "$CANVAS_DIR"
  ensure_deps
  node "$CANVAS_DIR/scripts/static-server.mjs" \
    --port "$UI_PORT" \
    --host "0.0.0.0" \
    --dir "$CANVAS_DIR/build" \
    --route "/api/automation=http://127.0.0.1:$AUTOMATION_PORT" \
    --route "/api=http://127.0.0.1:$BACKEND_PORT" \
    --route "/server_info=http://127.0.0.1:$BACKEND_PORT" \
    --route "/sockets=http://127.0.0.1:$BACKEND_PORT" \
    ${SESSION_API_KEY:+--session-api-key "$SESSION_API_KEY"}
}

# Agent-server + automation behind the ingress (the "Host 1" service, port 12000).
start_backend() {
  if [ ! -x "$CANVAS_BIN" ]; then
    echo "agent-canvas CLI not found at $CANVAS_BIN" >&2
    echo "Install it with:  npm install -g @openhands/agent-canvas@1.16.0" >&2
    echo "Or set CANVAS_BIN to the path of the agent-canvas CLI." >&2
    exit 1
  fi
  if [ ! -s "$STATE_DIR/api-key.txt" ]; then
    echo "Canvas session API key not found at $STATE_DIR/api-key.txt" >&2
    echo "Start the stack once with the official launcher to generate it." >&2
    exit 1
  fi
  OH_CANVAS_SAFE_BACKEND_PORT="$BACKEND_PORT" \
  OH_CANVAS_SAFE_AUTOMATION_PORT="$AUTOMATION_PORT" \
  OH_CANVAS_SAFE_STATE_DIR="$STATE_DIR" \
    "$CANVAS_BIN" --backend-only --port "$INGRESS_PORT" --host "0.0.0.0"
}

MODE="${1:-help}"
case "$MODE" in
  backend)
    start_backend
    ;;
  ui)
    start_ui
    ;;
  full)
    echo "Starting both stacks:  ingress on :$INGRESS_PORT and static UI on :$UI_PORT"
    start_ui &
    UI_PID=$!
    trap 'kill "$UI_PID" 2>/dev/null' EXIT
    start_backend
    ;;
  help|*)
    echo "Usage:  $0 {backend|ui|full|help}"
    echo
    echo "  backend — agent-server + automation behind ingress on :$INGRESS_PORT"
    echo "  ui       — static Canvas frontend + API proxy on :$UI_PORT"
    echo "  full     — both (default ports  12000 + 12001)"
    echo
    echo "Environment:"
    echo "  CANVAS_DIR       — canvas folder (default <repo>/canvas)"
    echo "  OH_CANVAS_SAFE_STATE_DIR  — state dir (default ~/.openhands/agent-canvas)"
    echo "  OH_CANVAS_SAFE_BACKEND_PORT — agent-server port  (default 19000)"
    echo "  OH_CANVAS_SAFE_AUTOMATION_PORT — automation port     (default 19001)"
    echo "  OH_CANVAS_SAFE_INGRESS_PORT  — ingress port          (default 12000)"
    echo "  OH_CANVAS_SAFE_UI_PORT         — static UI port          (default 12001)"
    exit 1
    ;;
esac