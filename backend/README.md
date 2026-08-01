# Seville Backend

The Go backend ingests configured knowledge sources into Neo4j and exposes the
live graph to Seville clients through an authenticated API. Neo4j is the sole
canonical persistence layer; source Markdown is not overwritten and SQL is not
used.

## Legacy import model

Every Markdown source file must define a stable Node `id` in YAML frontmatter:

```md
---
id: 6ca5c09c-38a8-8ab3-a8b2-93450516d229
title: Cortex
components:
  - "[[science]]"
  - "[[culture]]"
---
```

The manual Obsidian migration tool:

1. parses Markdown and typed YAML frontmatter using a YAML 1.2 parser;
2. normalizes frontmatter and inline tags into canonical lowercase tag IDs;
3. stores tags as `(node)-[:TAGGED_WITH {weight: 1.0}]->(:Tag)`;
4. rejects duplicate IDs and reports source records without IDs as import warnings;
5. creates only IDs that do not already exist in Neo4j;
6. creates resolved `LINKS_TO` relationships for newly imported nodes; and
7. serves subsequent reads from live Neo4j data.

An existing ID is deliberately not overwritten by a later source scan. Once a
source file has been imported, Seville/Neo4j is authoritative for that Node. This makes
repeated migrations conservative, but changed source IDs can still create
apparent duplicates.

## Quick start

From the repository root:

```sh
cp .env.example .env
make -C scripts start
make -C scripts status
```

Normal startup connects only to Neo4j and starts the API. It does not inspect
or import any knowledge source. The old one-way vault importer is preserved as
an explicit migration tool at
[`../scripts/migrations/obsidian/`](../scripts/migrations/obsidian/).

Set the Neo4j connection values in `.env`. Source settings are needed only when
running an explicit migration. Native source paths may be absolute or
home-relative.

For a locally checked-out private GitHub repository:

```dotenv
SEVILLE_SOURCE=git
SEVILLE_GIT_REPOSITORY_PATH=~/Documents/Git/my-private-vault
SEVILLE_GIT_VAULT_SUBPATH=cortex
```

The migration reads the existing checkout using your normal Git credentials.
It does not fetch, merge, commit, or push.

| Variable | Default | Purpose |
| --- | --- | --- |
| `SEVILLE_ADDR` | `127.0.0.1:8787` | HTTP listen address |
| `SEVILLE_SOURCE` | `vault` | Migration source: `vault` or `git`; ignored by normal startup |
| `SEVILLE_VAULT_PATH` | Migration only | Vault directory |
| `SEVILLE_GIT_REPOSITORY_PATH` | Migration only | Local Git checkout |
| `SEVILLE_GIT_VAULT_SUBPATH` | `.` | Migration vault folder inside the checkout |
| `SEVILLE_NEO4J_URI` | `bolt://127.0.0.1:7687` | Neo4j Bolt URI |
| `SEVILLE_NEO4J_USERNAME` | `neo4j` | Neo4j user |
| `SEVILLE_NEO4J_PASSWORD` | Required | Neo4j password |
| `SEVILLE_NEO4J_DATABASE` | `neo4j` | Neo4j database |
| `SEVILLE_NEO4J_QUERY_LOG` | `false` | Print generated Node read/mutation Cypher, parameters, selected roots, and latency |
| `SEVILLE_TOKEN` | Required | Client-to-Go API bearer token; not an encryption key |

`compose.yaml` contains wiring only. Put real credentials in the ignored
repository-root `.env`; never put them in Compose or commit them.

`NEO4J_AUTH` initializes a new Neo4j volume but does not change the password of
an existing database. To rotate an existing local password, change it once in
Neo4j Browser, update `SEVILLE_NEO4J_PASSWORD` in `.env`, and restart Seville.

For temporary Node-tree query debugging, set
`SEVILLE_NEO4J_QUERY_LOG=true` in `.env`. The macOS launcher mirrors new backend
log entries into its console. Each root and depth query prints a copyable block
of sorted Neo4j Browser `:param` commands followed by the exact Cypher, then
reports the selected root and these timings:

- `dispatch_duration`: Go driver time until `Session.Run` returns;
- `total_duration`: total Go-side time through result consumption;
- `server_available_after`: Neo4j server time until results became available;
- `server_consumed_after`: Neo4j server result-consumption time.

Disable the flag after diagnosis because query parameters can contain Node IDs
and search values and the output is intentionally verbose.

## API

- `GET /healthz`: process health.
- `GET /v2/status`: latest import metadata.
- `GET /v2/snapshot`: live Neo4j graph as a binary `NodeSnapshot`.
- `GET /system/v1/info`: stable Node and Node-property counts, the 12 most
  frequently assigned Neo4j labels, Go version, and Neo4j version as binary
  `SystemInfo`. Label frequency is descending, with label name as the stable
  tie-breaker.
- `QUERY /api/v1/node/tree`: depth-limited incoming relationship tree as binary
  `NodeTree`; either `root_node_id` or a structured `root_node_filter` selects
  the root set, while the allowlisted `traverse_by` selects `PART_OF` or
  `FAMILY`. Every filter match becomes a depth-zero occurrence.
  Filter includes support explicit `any` (default) or `all` matching; excludes
  always reject on any match, and filter-level negation reverses the complete
  composed predicate.
  `GET` is accepted only as a compatibility alias for clients or proxies
  without `QUERY` support. Tree reads never mutate Node counters.
- `QUERY /api/v1/node/search`: structured flat Node search as binary
  `NodeSearchResult`. The protobuf body carries a required `node_filter` and an
  optional limit from 1 through 100; the default limit is 20. Search returns
  complete Nodes, including labels, tags, frontmatter, and assigned Emoji.
- `POST /api/v1/node/`: create one Node from a protobuf `NodeCreateRequest`.
  The backend assigns its stable ID, initializes `update_count` to zero, safely
  applies validated Neo4j labels, and returns the complete Node with status 201.
  An existing slug returns 409.
- `PATCH /api/v1/node/`: filter-driven scalar property updates and removals
  as protobuf. Every matched Node increments `update_count` atomically with the
  requested mutation; `counter` and `update_count` are client-reserved.

Source migration is intentionally not exposed through the running API. Future
user-facing migration should be a deliberate workflow with preview, source
identity, provenance, and duplicate/conflict reporting.

GraphQL CRUD and WebSocket change delivery are planned application boundaries;
they are not implemented yet. Clients must continue using Go rather than
connecting directly to Neo4j.

Canonical Node property writes use the store's `MutateNodes` boundary. It
combines an allowlisted `NodeSearchFilter`, a parameterized property map, and an
atomic `update_count` increment. Read queries and source import do not increment
`update_count`; the legacy `counter` property is left untouched for a separate
owner-controlled migration.

## Containers

The normal macOS launcher runs Neo4j 5.26 LTS Community in Compose and the Go
backend on the host. Neo4j data is held in the `neo4j-data` volume. Imported
nodes are subsequently edited through Seville rather than written back to
Markdown.

See [`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md)
for reconciliation, multiplayer, provenance, and recovery direction.
