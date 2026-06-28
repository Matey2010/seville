# Seville Backend

The backend scans a read-only Obsidian vault, stores the latest successful
snapshot in SQLite, and exposes it through a small authenticated HTTP API.

## Quick start

From the repository root:

```sh
cp .env.example .env
./scripts/seville start
./scripts/seville status
./scripts/seville rescan
```

Set `SEVILLE_VAULT_PATH` to a filesystem path in `.env`. Native commands accept
an absolute path or a home-relative path:

```sh
SEVILLE_VAULT_PATH=/Users/you/Documents/MyVault
# or
SEVILLE_VAULT_PATH=~/Documents/MyVault
```

The service listens on `http://127.0.0.1:8787` by default. `GET /healthz` is
public; all `/v1/` endpoints require `Authorization: Bearer <token>`.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `SEVILLE_ADDR` | `127.0.0.1:8787` | HTTP listen address |
| `SEVILLE_VAULT_PATH` | Required | Vault directory; must start with `/` or `~/` |
| `SEVILLE_DB_PATH` | `.local/seville.db` | SQLite database |
| `SEVILLE_TOKEN` | `local-seville-token` | Local bearer token |

The launcher reads `.env` values literally; tokens do not need shell escaping.

The service scans once at startup. Later scans are triggered with
`POST /v1/admin/rescan`.

## API

- `GET /healthz`: process health.
- `GET /v1/status`: latest scan metadata.
- `GET /v1/snapshot`: binary `KnowledgeSnapshot` protobuf with ETag support.
- `POST /v1/admin/rescan`: synchronously scan and atomically replace storage.

## Direct Go commands

From the repository root:

```sh
go test ./backend/...
go run ./backend/cmd/seville
```

The protobuf Go module is generated and committed under `proto/gen/go`.

## Containers

`compose.yaml` runs the backend behind Caddy. Set `SEVILLE_VAULT_PATH` and
`SEVILLE_TOKEN`, then run:

```sh
docker compose up --build -d
```

The vault is mounted read-only and SQLite data is held in a named volume.
For Docker Compose, `SEVILLE_VAULT_PATH` must begin with `/`; Compose does not
expand `~` reliably in bind-mount paths.
Docker Compose is not included in every Docker CLI installation; Docker
Desktop is the simplest way to install it on macOS.
