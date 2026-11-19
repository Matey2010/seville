# Graph Recovery and Synchronization Runbook

## Current recovery boundary

Seville's canonical live data is the Neo4j `neo4j-data` volume. Markdown and a
local Git checkout are import/synchronization sources; they are not complete
backups of edits made directly in Seville.

Current data path:

```text
local source -> Go ingestion -> Neo4j -> authenticated API -> Seville client
```

## Normal macOS workflow

Configure `.env`, then use the single supported Make target:

```sh
make -C scripts interface
```

It verifies Docker for a local Neo4j URI, starts the Neo4j container, starts
the Go API, waits for health, and then starts the macOS client. The project
owner performs final runtime verification.

Backend-only controls are:

```sh
make -C scripts start
make -C scripts status
make -C scripts stop
```

## Inspect the graph

For local development, Neo4j Browser is available through the loopback-bound
HTTP port configured by Compose, normally `http://127.0.0.1:7474`.

Query by a Node's unique slug:

```cypher
MATCH (n:Node {slug: $slug})
RETURN n, labels(n);
```

`elementId()` is a Neo4j internal locator and is not Obsivilian identity. The
reserved `:Node` label marks canonical Nodes and is covered by the
`slug_unique` constraint on `slug`; editable labels are separate classifiers.

Useful checks:

```cypher
MATCH (n:Node)
WHERE n.slug IS NOT NULL AND trim(toString(n.slug)) <> ''
WITH n.slug AS slug, count(n) AS copies
WHERE copies = 1
RETURN count(*) AS readable_node_count;

MATCH (n:Node)
WHERE n.slug IS NOT NULL
UNWIND labels(n) AS label
WITH label, n WHERE label <> 'Node'
RETURN label, count(*) AS node_count
LIMIT 100;

MATCH (a)-[:LINKS_TO]->(b)
RETURN a.slug, b.slug
LIMIT 100;

MATCH (n) WHERE n.slug IS NOT NULL
WITH n.slug AS slug, count(*) AS copies
WHERE copies > 1
RETURN slug, copies ORDER BY slug;
```

## Legacy migration semantics

The manual `make -C scripts migrate-obsidian` target
discovers source state but is not a destructive mirror operation:

- new unique slugs are imported;
- existing canonical nodes are preserved;
- source disappearance does not delete a graph node;
- duplicate slugs fail the scan;
- a missing frontmatter slug uses the relative Markdown path without `.md`.

Migration diagnostics are written to the command's standard output and error.
Duplicate-slug errors include both paths so the source can be repaired safely.

## What is protected today

- Docker preserves Neo4j data in its named volume across container restarts.
- Git can preserve source Markdown history and help merge independent file
  changes.
- Stable slugs let repeated scans recognize records.
- Conservative ingestion prevents a stale source file from overwriting an
  existing Neo4j record.

This is not yet decentralized recovery. A destroyed Neo4j volume can lose
Seville-native edits that were never represented in a source dataset.

## Backup before risky operations

Treat volume deletion, Compose project renaming, database upgrades, and manual
Cypher mutations as data operations. Before them, create and verify an
appropriate Neo4j backup/export for the deployed edition and environment. Do
not assume a Git repository contains all canonical graph state.

Never commit `.env`, database dumps containing private knowledge, or copied
service credentials.

## Planned recovery model

The next safety layer adds source checkpoints, content hashes, provenance,
conflict records, and tombstones. Later, signed append-only change events and
content-addressed blobs allow multiple peers to retain verifiable subsets and
restore missing material.

Recovery success should eventually mean:

1. compare stable-slug and content-hash inventories;
2. identify missing nodes, relationships, events, and attachments;
3. retrieve them from authorized surviving peers;
4. verify signatures and hashes;
5. replay accepted changes into Neo4j; and
6. report gaps that no peer can supply.

The architectural plan is documented in
[`seville-architecture-plan.md`](seville-architecture-plan.md).
