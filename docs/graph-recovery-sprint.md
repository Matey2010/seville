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

Query by Seville's stable ID:

```cypher
MATCH (n {id: $id})
RETURN n, labels(n);
```

Do not query a frontmatter ID with `elementId(n)`. `elementId()` is a Neo4j
internal locator and is not Seville identity.

Useful checks:

```cypher
MATCH (n)
WHERE n.id IS NOT NULL
  AND NOT n:Tag
  AND NOT n:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(n) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(n) }
RETURN count(n);

MATCH (n)-[r:TAGGED_WITH]->(t:Tag)
RETURN n.id, t.name, r.weight
LIMIT 100;

MATCH (a)-[:LINKS_TO]->(b)
RETURN a.id, b.id
LIMIT 100;
```

## Legacy migration semantics

The manual `make -C scripts migrate-obsidian` target
discovers source state but is not a destructive mirror operation:

- new stable IDs are imported;
- existing canonical nodes are preserved;
- source disappearance does not delete a graph node;
- duplicate IDs fail the scan;
- missing IDs produce warnings and are skipped.

Migration diagnostics are written to the command's standard output and error.
Duplicate-ID errors include both paths so the source can be repaired safely.

## What is protected today

- Docker preserves Neo4j data in its named volume across container restarts.
- Git can preserve source Markdown history and help merge independent file
  changes.
- Stable frontmatter IDs let repeated scans recognize records.
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

1. compare stable-ID and content-hash inventories;
2. identify missing nodes, relationships, events, and attachments;
3. retrieve them from authorized surviving peers;
4. verify signatures and hashes;
5. replay accepted changes into Neo4j; and
6. report gaps that no peer can supply.

The architectural plan is documented in
[`seville-architecture-plan.md`](seville-architecture-plan.md).
