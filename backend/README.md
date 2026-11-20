# Backend

The Go API over Neo4j. API contract: [../docs/http-api-conventions.md](../docs/http-api-conventions.md).
Startup migrations: [../docs/architecture.md](../docs/architecture.md#backend-startup-migrations).

## Run

The owner starts the backend from the repository root:

```sh
cp .env.example .env              # then set real credentials
make -C scripts start | status | stop
```

Startup connects to Neo4j, applies the idempotent startup migrations, and serves the API.

## Configuration (`.env` at the repository root)

| Variable | Default | Purpose |
| --- | --- | --- |
| `SEVILLE_ADDR` | `127.0.0.1:8787` | Listen address |
| `SEVILLE_NEO4J_URI` | `bolt://127.0.0.1:7687` | A non-local URI skips Docker |
| `SEVILLE_NEO4J_USERNAME` | `neo4j` | |
| `SEVILLE_NEO4J_PASSWORD` | required | Initializes a new volume only. To rotate it, change it in Neo4j Browser and then in `.env`. |
| `SEVILLE_NEO4J_DATABASE` | `neo4j` | |
| `SEVILLE_TOKEN` | `local-seville-token` (to become required; roadmap P0) | Client bearer token |
| `SEVILLE_NEO4J_QUERY_LOG` | `false` | Logs Cypher, parameters, and timings. It can leak slugs and search terms, so enable it only while diagnosing. |

`compose.yaml` holds wiring only. Credentials belong in the ignored `.env`.

## Layout

| Package | Role |
| --- | --- |
| `cmd/seville` | API server |
| `internal/server` | HTTP handlers and auth |
| `internal/store` | Neo4j queries; all canonical writes go through `MutateNodes` |
| `internal/markdown` | Extracts connections from Node bodies |
| `internal/config` | Environment configuration |
