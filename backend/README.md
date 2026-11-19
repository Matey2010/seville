# Seville Backend

The Go backend ingests configured knowledge sources into Neo4j and exposes the
live graph to Seville clients through an authenticated API. Neo4j is the sole
canonical persistence layer; source Markdown is not overwritten and SQL is not
used.

## Legacy import model

Each imported Node uses its readable `slug` as its unique identity. A Markdown
file may set it in YAML frontmatter; otherwise the importer uses its relative
path without the `.md` extension:

```md
---
slug: cortex
title: Cortex
components:
  - "[[science]]"
  - "[[culture]]"
---
```

Every canonical Node also carries the reserved Neo4j `:Node` label. It is an
internal marker, omitted from user-facing labels. The `slug_unique` constraint
on `:Node(slug)` enforces unique Node slugs; user labels remain editable
classifiers. Startup backfills `:Node` on existing slugged records after
checking for duplicates. It removes only five inspected legacy shells
(`armor`, `career`, `game`, `science`, `weapon`) when each still has exactly the
`slug` and `counter: 1` properties, no label or relationship, and a titled
counterpart. If any other duplicate remains, startup stops with its slug.
Back up Neo4j before the first startup with this migration, since removing
those five shells is a database deletion.

The manual Obsidian migration tool:

1. parses Markdown and typed YAML frontmatter using a YAML 1.2 parser;
2. ignores source tag metadata, keeping Neo4j labels as the classification system;
3. rejects duplicate slugs within the source;
4. creates only slugs that do not already exist in Neo4j;
5. creates resolved `LINKS_TO` relationships for newly imported nodes; and
6. serves subsequent reads from live Neo4j data.

An existing slug is deliberately not overwritten by a later source scan. Once
a source file has been imported, Obsivilian/Neo4j is authoritative for that
Node. Changing a source slug can create an apparent duplicate.

On startup, the backend backfills native `DATE` intervals for calendar Nodes
whose exact slug identifies a day (`DD-MM-YYYY` or ISO), year (`YYYY`), month
(`YYYY-MM`), or ISO week (`YYYY-Wnn`). Explicit BCE Year titles are also
recognized using astronomical years (`1 BCE` is year zero). A pre-existing
native `date` property on a calendar Node supplies a day interval. Recurring
Month and Season Nodes without a year remain unplaced. The migration is
idempotent and increments `update_count` only for Nodes it changes. Review a
Neo4j backup before first startup with this migration.
It also accepts the observed `cortex-time-calendar-YYYY-MM-*` plus matching
`YYYY MM DD: MM` title format, and dated Event slugs whose date agrees with
their `Event YYYY-MM-DD` title. Generic `Time` topics remain unplaced.
Clearing time placement records an internal opt-out so a later startup does
not infer the same span again; manually saving a span removes that opt-out.

On backend startup, this version discards legacy `TAGGED_WITH` assignments,
legacy tag records and properties, and tag-based color rules. It does not turn
those assignments into Neo4j labels.

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

Disable the flag after diagnosis because query parameters can contain Node slugs
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
  `NodeTree`; either `root_node_slug` or a structured `root_node_filter` selects
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
  complete Nodes, including labels, frontmatter, and assigned Emoji.
- `QUERY /api/v1/node/graph`: bounded `LINKS_TO` graph as binary `NodeGraph`.
  An optional root slug requests a local graph; without it the endpoint
  returns a bounded global view that can filter by a search term. Depth is at
  most two and the Node limit is at most 200. `has_more` reports truncation;
  the response includes only connections whose endpoints are present. Records
  sharing a slug are omitted until the duplicate is resolved in Neo4j.
  An unfiltered global view samples up to half its limit from the full dated
  range so a bounded overview can show the time plane.
- `PUT /api/v1/node/{slug}/temporal`: replace or clear the Node's time span
  with an expected `update_count`. Its start and exclusive end are stored as
  native Neo4j `DATE` properties; stale writes return 409. The API accepts
  signed ISO calendar years for BCE dates.
- `QUERY /api/v1/label/search`: native Neo4j labels on canonical Nodes, with
  usage counts, as binary `LabelSearchResult`.
- `PUT /api/v1/node/{slug}/labels`: replaces one Node's complete label set when
  `expected_update_count` matches; returns the updated Node.
- `PATCH /api/v1/label/{name}`: renames a label across all canonical Nodes.
  It rejects a name already in use and updates exact label color rules.
- `DELETE /api/v1/label/{name}`: removes a label from all canonical Nodes and
  deletes its exact label color rules.
- `GET /api/v1/graph/color-rules`: the shared binary `NodeColorRuleSet` and
  its revision. An unset database returns an empty ruleset at revision zero.
- `PUT /api/v1/graph/color-rules`: replace the complete ordered ruleset as
  protobuf. The supplied revision must match the stored revision; a stale
  save returns 409. Up to 100 validated rules are stored atomically. Higher
  weight wins, and list order resolves equal weights. Each rule can also set
  gravity scale (0–3×) and circle size scale (0.5–2×); older rules use 1×.
  Legacy exact-ID rules are read as slug rules when they resolve to one unique
  Node; other ID rules cannot be translated and are omitted from the editor.
- `POST /api/v1/node/`: create one Node from a protobuf `NodeCreateRequest`.
  The caller chooses its unique slug. The backend initializes `update_count` to zero, safely
  applies validated Neo4j labels, reconciles connections from its Markdown
  body in the same transaction, and returns the complete Node with status 201.
  An existing slug returns 409.
- `PATCH /api/v1/node/{slug}`: update one known Node body using
  `NodeBodyUpdateRequest`. An expected `update_count` guards against stale
  edits. Body, timestamp, counter, and outgoing connections change in one
  transaction; a stale edit returns 409.
- `PATCH /api/v1/node/`: filter-driven scalar property updates and removals
  as protobuf. Every matched Node increments `update_count` atomically with the
  requested mutation; body must use the Node-specific endpoint to keep
  connections synchronized.

Source migration is intentionally not exposed through the running API. Future
user-facing migration should be a deliberate workflow with preview, source
identity, provenance, and duplicate/conflict reporting.

Clients use the Go protobuf HTTP API and never connect directly to Neo4j.

### Moving appearance rules to another server

Appearance rules, their colors, gravity and size scales, integer weights, list
positions, and revision live in the
same Neo4j database as canonical Nodes, under `ObsivilianColorRuleSet` and
`ObsivilianColorRule` labels. A full Neo4j database backup and restore moves
them together. The Node-only Markdown importer and `NodeSnapshot` export do
not include presentation rules.

For a Node-only transfer, use the API instead: read the source ruleset with
`GET /api/v1/graph/color-rules`, read the destination ruleset to obtain its
current revision, then `PUT` the source rules in a `NodeColorRuleSet` carrying
the destination revision. The response confirms the new revision. This keeps
weights and ordering intact. Back up destination rules first if they matter;
`PUT` replaces the entire destination ruleset. Each server currently has one
shared ruleset for its bearer-token users; there are no per-user accounts.

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
for the current knowledge product and source reconciliation direction.
