# Seville Architecture

## Purpose

This is the living architecture document for Seville. It distinguishes the
system that exists now from the direction we are deliberately building toward.

Seville is a graph-native knowledge environment: a personal system today, and
eventually a shared, durable knowledge world. Markdown, Git repositories, and
future datasets are ways to introduce or synchronize knowledge. They are not
the permanent application database. Neo4j is Seville's canonical live graph.

## Product direction

The long-term goal is closer to a persistent multiplayer world or a
decentralized Wikipedia than to a note viewer:

- people explore and change a shared knowledge graph in real time;
- durable knowledge survives individual machines and services;
- transient presence and UI state do not pollute durable knowledge;
- personal layouts and preferences remain separable from shared facts;
- every durable change can eventually carry authorship and provenance;
- peers can retain enough replicated data to recover missing parts;
- no blockchain or global consensus is required for ordinary editing.

The implementation should reach that goal incrementally. The current local
system remains useful at every stage.

## Architecture today

```text
Git checkout or Markdown folder (explicit migration only)
              |
              v
     Go source adapters and parser
              |
              v
       normalization/reconciliation
              |
              v
     Neo4j canonical live graph
              |
              v
 authenticated Go protobuf HTTP API
              |
              v
       Seville Flutter client
```

### Responsibilities

| Layer | Owns |
| --- | --- |
| Source adapters | Reading a local Git checkout or direct Markdown folder |
| Go ingestion | YAML parsing, stable identity, normalization, validation, link resolution, and reconciliation policy |
| Neo4j | Canonical nodes, tags, relationships, scan state, and live graph queries |
| Go API | Authentication, application rules, snapshots, status, and live graph reads |
| Seville client | Flame-component interaction and rendering, layout, local UI state, and graph presentation |
| Protocol Buffers | Current Go-to-client wire contract |

SQLite and SQL are not part of Seville. Neo4j is the only application
persistence layer.

### Client rendering boundary

The current client uses Flame components for all interface rendering and
interaction. Flutter widgets provide application composition and host the
`GameWidget`. Widgets are reserved for a future explicitly designed HUD, which
does not exist yet; ordinary layout content must not be introduced as a widget,
gesture overlay, or parallel hit-test layer.

## Repository boundaries

```text
seville/          User-facing clients; Flutter is the current macOS client
backend/          Go ingestion, graph storage, and API
proto/            Canonical protobuf contracts and generated packages
scripts/          macOS process control and focused maintenance utilities
docs/             Cross-workspace architecture and operational documentation
compose.yaml      Local Neo4j service wiring
```

The product is named Seville. `seville/flutter` is one client implementation,
not the identity of the whole project and not a generic `interface` folder.

## Knowledge sources

The legacy migration accepts two source modes:

- `git`: Markdown below a configured subfolder of an existing local Git
  checkout;
- `vault`: Markdown directly below a configured folder.

The Git adapter reads a checkout only when the migration is run. It does not
fetch, pull, merge, commit, or push. Git can provide early collaboration,
history, and per-file conflict handling, while Seville remains responsible for
graph semantics.

The configured knowledge root is either:

- `SEVILLE_GIT_REPOSITORY_PATH` + `SEVILLE_GIT_VAULT_SUBPATH`; or
- `SEVILLE_VAULT_PATH`.

There is intentionally no Neo4j-to-Markdown exporter in the architecture.
Once imported, a Node is edited through Seville and Neo4j. Sources remain
useful for discovering new records and later for governed synchronization.

## Identity and parsing

Every durable source document must define a stable frontmatter `id`. It becomes
`Node.id` and is the domain identity across imports, APIs, and future
replicas.

Neo4j's `elementId()` is an internal database locator. It must never be stored,
shared, or queried as Seville's durable identity.

The parser:

1. reads Markdown and typed YAML frontmatter;
2. requires a unique frontmatter `id`;
3. preserves structured frontmatter as JSON and exposes a flattened
   compatibility representation to the current protobuf contract;
4. normalizes tags into stable lowercase tag IDs;
5. extracts wiki links, Markdown links, and embeds; and
6. records warnings for invalid or incomplete source records.

Duplicate IDs stop the scan because silently choosing one would corrupt
identity. Notes without IDs are skipped and reported.

## Neo4j graph model

The current core graph uses:

```cypher
(:Node {
  id, path, title, body, tags, frontmatter_json
})

(:Tag {id, name})

(:Node)-[:TAGGED_WITH {
  weight: 1.0,
  source: "markdown"
}]->(:Tag)

(:Node)-[:LINKS_TO]->(:Node)
```

`Node.id` and `Tag.id` are unique. Unresolved targets are retained as
`SevilleUnresolvedLink` records rather than discarded. `SevilleScanState`
stores ingestion status and diagnostics.

Tags are graph entities, not merely strings. Weighted `TAGGED_WITH`
relationships create a foundation for ranked search and later source-specific
confidence.

## Current ingestion policy

The legacy manual Obsidian migration scans its configured source. It is kept
outside normal startup and the running API. Its operation is deliberately
conservative:

- unseen IDs are created;
- existing Neo4j nodes are not overwritten by source files;
- tags are merged and normalized for scanned nodes;
- resolved connections are created for newly imported nodes;
- absent source files do not delete graph nodes;
- duplicate IDs fail the scan;
- malformed or ID-less source records are reported.

This is import-plus-discovery, not complete bidirectional synchronization.

## Synchronization direction

The next reconciliation model should attach provenance and a content hash to
every incoming record. A source checkpoint identifies what each adapter has
already observed.

Default policy:

| Incoming state | Action |
| --- | --- |
| New stable ID | Create a canonical graph record with provenance |
| Same ID and same content hash | No-op |
| Source changed, canonical record unchanged since last checkpoint | Apply the update |
| Source and canonical record both changed | Record a conflict; never overwrite silently |
| Record missing from source | Mark missing/tombstoned according to policy; do not immediately delete |
| Invalid record or duplicate ID | Quarantine/report it without contaminating valid data |

Adapters should converge on a common ingestion record containing stable ID,
content, relationships, source identity, source revision, observed time, and
content hash. Git, local folders, remote APIs, archives, and future peer data
then use the same reconciliation engine.

## API boundary

The current authenticated API is:

- `GET /healthz` — process health;
- `GET /v2/status` — latest ingestion status;
- `GET /v2/snapshot` — live Neo4j graph as `NodeSnapshot` protobuf;

The read-only system endpoint `GET /system/v1/info` reports the
stable Node count and total Node property-assignment count directly from Neo4j.
Its contract and the conventions for group-local versions, protobuf fields,
generated casing, and count types are defined in
[`http-api-conventions.md`](http-api-conventions.md).

Migration is not currently an API operation. A future user-facing migration
workflow should add preview, provenance, source checkpoints, and explicit
duplicate/conflict handling before it writes to the canonical graph.

The client never connects directly to Neo4j. Go is the security and application
boundary.

GraphQL is the planned CRUD/query boundary because it fits selective graph
reads and evolving clients. WebSockets will provide presence and live change
notifications. Protocol Buffers can remain useful for efficient snapshots and
internal contracts while GraphQL becomes the interactive application API.

## Security model

Two current secrets have separate jobs:

- `SEVILLE_TOKEN` authenticates a client request to the Go API. It does not
  encrypt or decrypt passwords.
- `SEVILLE_NEO4J_PASSWORD` authenticates Go to Neo4j.

Real values live only in the ignored `.env` for local development. Compose
contains variable wiring, not secrets. Local Neo4j ports bind to loopback.

For remote deployment:

- expose Go through HTTPS, not Neo4j directly;
- keep Neo4j on a private network;
- replace one shared API token with per-user authentication and authorization;
- store service secrets in the host's secret manager;
- rotate secrets independently;
- audit durable mutations.

A password manager such as Bitwarden can protect a developer's credentials.
A server-side secret manager or injected deployment secret should protect
production service credentials; user vault contents should not be treated as
application configuration.

## Durable, transient, and personal state

The multiplayer design separates three categories:

| State | Examples | Durability |
| --- | --- | --- |
| Durable shared knowledge | Nodes, relationships, tags, edits, provenance | Persist and replicate |
| Transient collaboration | Cursor, presence, temporary selection, typing indicators | Broadcast with expiry; do not preserve as knowledge |
| Personal configuration | Layout, theme, filters, private workspace choices | Store per user and sync independently |

This boundary prevents real-time activity from becoming permanent graph noise
and lets privacy policies differ from shared knowledge policy.

## Recovery and decentralization direction

Neo4j remains the canonical live/materialized graph. Long-term durability can
be strengthened with an append-only change history containing stable event ID,
actor, timestamp, operation, affected stable IDs, previous/current hashes, and
signature.

Content-addressed attachments and signed events enable peers to compare compact
hash inventories, request missing material, verify what they receive, and
retain configured subsets. Recovery then reconstructs missing graph state from
surviving event and content replicas.

This is not cryptocurrency consensus. Seville needs provenance, signatures,
content addressing, replication, and conflict policies—not proof-of-work or a
single globally ordered blockchain.

Federation comes after the central multiplayer semantics are stable. Trust,
moderation, authorization, erasure policy, and conflicting histories must be
explicit before independent servers exchange durable changes.

## Search direction

Search should combine graph and text signals rather than spend an LLM request
on ordinary retrieval. Initial ranking can weight:

1. exact ID/title/alias matches;
2. explicit tag weights;
3. title and body text relevance;
4. graph proximity and relationship type; and
5. user/context signals that do not mutate shared knowledge.

LLMs may later interpret or summarize results, but they should not replace the
deterministic search index and graph query path.

## Delivery roadmap

1. **Standalone foundation — current.** Local source adapters, Go ingestion,
   Neo4j, authenticated snapshot API, and macOS Flutter client.
2. **Safe reconciliation.** Source identities, checkpoints, content hashes,
   provenance, tombstones, and explicit conflict records.
3. **Application CRUD and search.** Go GraphQL API, mutations, weighted search,
   and graph-native editing.
4. **Central multiplayer.** User accounts, permissions, WebSockets, presence,
   and server-side secret management.
5. **Verifiable history.** Immutable signed change events and
   content-addressed attachments.
6. **Replication and recovery.** Peer inventories, configurable replication,
   partial datasets, and reconstruction tooling.
7. **Federation.** Independent Seville servers exchanging governed,
   verifiable knowledge.

## Non-negotiable design rules

- Neo4j is the canonical application database; do not reintroduce SQL.
- Stable frontmatter IDs are domain identity; never depend on Neo4j internal
  IDs.
- Clients use Go APIs; they do not receive database credentials.
- Source adapters may propose changes but may not silently overwrite newer
  canonical edits.
- Deletion and conflict are explicit states, not accidental side effects.
- Durable shared knowledge, transient presence, and personal configuration
  remain separate.
- Current production support is macOS only until the project owner expands it.
