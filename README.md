# my-hands-canvas

Self-hosted [OpenHands Agent Canvas](https://docs.openhands.dev/openhands/usage/agent-canvas/) deployment for [antonockr1](https://github.com/antono4).

## What's deployed

| URL | Service |
| --- | --- |
| `https://work-1-aftnxdqtpgjwydap.prod-runtime.all-hands.dev/` | Agent Canvas UI (port 12000, backend ingress) |
| `https://work-2-aftnxdqtpgjwydap.prod-runtime.all-hands.dev/` | Agent Canvas UI (port 12001, static frontend) |

The stack runs:

- **Agent Server** (OpenHands SDK v1.44.x) on `127.0.0.1:19000` — chat/agent API (`/api`, `/sockets`, `/server_info`, …)
- **Automation backend** on `127.0.0.1:19001` — `/api/automation/*`
- **Ingress proxy** on port **12000** (work-host 1) — routes API prefixes to the backend
- **Static frontend** on port **12001** (work-host 2) — serves the prebuilt Canvas UI and proxies API paths to the backend

Both services are exposed publicly through the two work hosts; the frontend auto-injects the session API key so no login is needed.

## Restart

```bash
# 1. Backend stack (agent-server + automation + ingress on 12000)
OH_CANVAS_SAFE_BACKEND_PORT=19000 \
OH_CANVAS_SAFE_AUTOMATION_PORT=19001 \
OH_CANVAS_SAFE_STATE_DIR="$HOME/.openhands/agent-canvas" \
  agent-canvas --backend-only --port 12000 --host 0.0.0.0
```

```bash
# 2. Static UI (port 12001)
cd /tmp && node /tmp/static-launch.mjs
```

## Notes

- The static launcher reads the session API key from `~/.openhands/agent-canvas/api-key.txt` at runtime — no secret is stored in this repository.
- LLM profiles are stored encrypted at `~/.openhands/profiles/*.json` under the user's home directoryand are decrypted with the persisted `OH_SECRET_KEY` (see `scripts/static-launch.mjs` and the launcher's `secret-key.txt`).