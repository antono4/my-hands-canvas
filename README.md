# my-hands-canvas

Self-hosted [OpenHands Agent Canvas](https://docs.openhands.dev/openhands/usage/agent-canvas/) deployment untuk [antonockr1](https://github.com/antono4).

## Yang ada di repo ini

Semua file untuk kedua layanan (Host 1 dan Host 2) sekarang **ada di repository ini** — jadi kapan pun runtime-nya hidup kembali, stack-nya bisa langsung dijalankan dari sini:

| Path | Isi |
| --- | --- |
| `canvas/build/` | **Frontend statis Agent Canvas** — SPA OpenHands yang tadinya disajikan di port 12001 (build resmi `@openhands/agent-canvas@1.16.0`) |
| `canvas/scripts/` | **Launcher + reverse-proxy** — `static-server.mjs` (serve SPA + proxy `/api`, `/sockets`, `/server_info` ke backend), `ingress.mjs`, `dev-*.mjs` |
| `canvas/bin/` | CLI `agent-canvas` (untuk `--backend-only`) |
| `canvas/config/` | `defaults.json` — versi pin, port, path (agent-server 1.44.0, automation 1.9.0) |
| `canvas/tools/` | Utilitas pendukung dari package resmi |
| `index.html` | Landing page bergaya app.all-hands.dev (menauta ke kedua host) |
| `start-canvas.sh` | Bootstrap launcher — menjalankan kedua service dari repo ini |

## Arsitektur stack (port asli)

| URL | Service | Port |
| --- | --- | --- |
| Host 1 (`work-1`) | **Ingress proxy** → agent-server + automation | `12000` |
| Host 2 (`work-2`) | **Static frontend** (Canvas SPA + API proxy) | `12001` |
| (internal) | Agent Server (OpenHands SDK `v1.44.x`) | `127.0.0.1:19000` |
| (internal) | Automation backend | `127.0.0.1:19001` |

Kedua service itu membaca API key dari `~/.openhands/agent-canvas/api-key.txt` pada runtime — **tidak ada secret di repo ini**.

## Menjalankan dari repo ini

```bash
# 1. Cepat (launcher otomatis install deps + start kedua service)
./start-canvas.sh full
```

```bash
# 2. Hanya frontend statis (Host 2, port 12001)
./start-canvas.sh ui
```

```bash
# 3. Hanya backend + ingress (Host 1, port 12000)
./start-canvas.sh backend
```

Persyaratan: Node ≥ 22, dan untuk mode `backend`/`full` juga `agent-canvas` CLI (install: `npm install -g @openhands/agent-canvas@1.16.0`).

## Notes

- `start-canvas.sh` membaca API key dari `~/.openhands/agent-canvas/api-key.txt` pada runtime — **tidak ada secret di repo ini**.
- Frontend yang disalin ke `canvas/build/` adalah build resmi dari `@openhands/agent-canvas@1.16.0` (MIT); bisa diperbarui dengan `npm pack @openhands/agent-canvas` dan mengganti foldernya).
- Runtime deps (`sirv` + `httpxy`) di-install otomatis ke `canvas/node_modules/` saat `./start-canvas.sh ui` pertama dijalankan (git-ignored).
- LLM profiles tersimpan terenkripsi di `~/.openhands/profiles/*.json` and didekripsi dengan `OH_SECRET_KEY` (lihat `canvas/scripts/dev-safe.mjs`).