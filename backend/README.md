# Backend

The Go API over Neo4j. API contract: [../docs/http-api-conventions.md](../docs/http-api-conventions.md).
Startup migrations: [../docs/architecture.md](../docs/architecture.md#backend-startup-migrations).

## Run

The owner starts the backend from the repository root:

```sh
cp .env.example .env              # then set real credentials
make -C scripts start | status | stop
```

Normal startup connects to Neo4j and serves the API. It never imports sources.

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
| `SEVILLE_SOURCE`, `SEVILLE_VAULT_PATH`, `SEVILLE_GIT_REPOSITORY_PATH`, `SEVILLE_GIT_VAULT_SUBPATH` | | Obsidian migration only; see [../scripts/migrations/obsidian/](../scripts/migrations/obsidian/) |

`compose.yaml` holds wiring only. Credentials belong in the ignored `.env`.

## Layout

| Package | Role |
| --- | --- |
| `cmd/seville` | API server |
| `cmd/migrate-obsidian-vault` | Manual Markdown import |
| `internal/server` | HTTP handlers and auth |
| `internal/store` | Neo4j queries; all canonical writes go through `MutateNodes` |
| `internal/scanner` | Markdown and frontmatter parsing, connection extraction |
| `internal/config` | Environment configuration |
