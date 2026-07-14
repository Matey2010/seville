# Seville Backend

The Go backend ingests configured knowledge sources into Neo4j and exposes the
live graph to Seville clients through an authenticated API. Neo4j is the sole
canonical persistence layer; source Markdown is not overwritten and SQL is not
used.

## Import model

Every Markdown note must define a stable `id` in YAML frontmatter:

```md
---
id: 6ca5c09c-38a8-8ab3-a8b2-93450516d229
title: Cortex
components:
  - "[[science]]"
  - "[[culture]]"
---
```

At backend startup and on `POST /v1/admin/rescan`, the importer:

1. parses Markdown and typed YAML frontmatter using a YAML 1.2 parser;
2. normalizes frontmatter and inline tags into canonical lowercase tag IDs;
3. stores tags as `(:Node)-[:TAGGED_WITH {weight: 1.0}]->(:Tag)`;
4. rejects duplicate IDs and reports notes without IDs as scan warnings;
5. creates only IDs that do not already exist in Neo4j;
6. creates resolved `LINKS_TO` relationships for newly imported notes; and
7. serves subsequent reads from live Neo4j data.

An existing ID is deliberately not overwritten by a later source scan. Once a
note has been imported, Seville/Neo4j is authoritative for that node. This makes
rescans safe and lets a Git checkout or folder remain attached as a source of
new notes.

## Quick start

From the repository root:

```sh
cp .env.example .env
./scripts/seville start
./scripts/seville status
./scripts/seville rescan
```

Select a knowledge source and set the Neo4j connection values in `.env`. Native
paths may be absolute or home-relative.

For a locally checked-out private GitHub repository:

```dotenv
SEVILLE_SOURCE=git
SEVILLE_GIT_REPOSITORY_PATH=~/Documents/Git/my-private-vault
SEVILLE_GIT_VAULT_SUBPATH=cortex
```

The repository continues using your normal Git credentials and remote. Seville
reads Markdown from the configured subfolder; it does not fetch, merge, commit,
or push yet.

| Variable | Default | Purpose |
| --- | --- | --- |
| `SEVILLE_ADDR` | `127.0.0.1:8787` | HTTP listen address |
| `SEVILLE_SOURCE` | `vault` | Knowledge source: `vault` or `git` |
| `SEVILLE_VAULT_PATH` | Required | Vault directory |
| `SEVILLE_GIT_REPOSITORY_PATH` | Required for `git` | Local Git checkout |
| `SEVILLE_GIT_VAULT_SUBPATH` | `.` | Vault folder inside the checkout |
| `SEVILLE_NEO4J_URI` | `bolt://127.0.0.1:7687` | Neo4j Bolt URI |
| `SEVILLE_NEO4J_USERNAME` | `neo4j` | Neo4j user |
| `SEVILLE_NEO4J_PASSWORD` | Required | Neo4j password |
| `SEVILLE_NEO4J_DATABASE` | `neo4j` | Neo4j database |
| `SEVILLE_TOKEN` | Required | Client-to-Go API bearer token; not an encryption key |

`compose.yaml` contains wiring only. Put real credentials in the ignored
repository-root `.env`; never put them in Compose or commit them.

`NEO4J_AUTH` initializes a new Neo4j volume but does not change the password of
an existing database. To rotate an existing local password, change it once in
Neo4j Browser, update `SEVILLE_NEO4J_PASSWORD` in `.env`, and restart Seville.

## API

- `GET /healthz`: process health.
- `GET /v1/status`: latest import metadata.
- `GET /v1/snapshot`: live Neo4j graph as a binary protobuf snapshot.
- `POST /v1/admin/rescan`: inspect the configured source and import previously unseen IDs.

GraphQL CRUD and WebSocket change delivery are planned application boundaries;
they are not implemented yet. Clients must continue using Go rather than
connecting directly to Neo4j.

## Containers

The normal macOS launcher runs Neo4j 5.26 LTS Community in Compose and the Go
backend on the host. Neo4j data is held in the `neo4j-data` volume. Imported
nodes are subsequently edited through Seville rather than written back to
Markdown.

See [`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md)
for reconciliation, multiplayer, provenance, and recovery direction.
