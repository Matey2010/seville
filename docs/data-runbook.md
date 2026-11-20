# Data runbook

Neo4j's `neo4j-data` Docker volume is the only complete copy of Seville data.
Markdown sources and Git do not contain edits made in Seville. Appearance rules
live in the same database (`ObsivilianColorRuleSet` / `ObsivilianColorRule`).

## Before risky operations

Volume deletion, Compose project renames, Neo4j upgrades, a backend version
with a new startup migration, and manual Cypher writes are data operations.
Take and verify a backup first. Automated backups are a P0 roadmap item.

Never commit `.env`, database dumps, or credentials.

## Inspect

Neo4j Browser: `http://127.0.0.1:7474`.

```cypher
// One Node
MATCH (n:Node {slug: $slug}) RETURN n, labels(n);

// Label usage
MATCH (n:Node) UNWIND labels(n) AS label
WITH label WHERE label <> 'Node'
RETURN label, count(*) AS node_count ORDER BY node_count DESC;

// Duplicate slugs (must be empty)
MATCH (n) WHERE n.slug IS NOT NULL
WITH n.slug AS slug, count(*) AS copies WHERE copies > 1
RETURN slug, copies ORDER BY slug;
```

## Move appearance rules only

A full database backup and restore moves rules with Nodes. To copy only the
rules:

1. `GET /api/v1/graph/color-rules` on the source.
2. `GET` the same route on the destination to read its revision.
3. `PUT` the source rules to the destination with that revision.

`PUT` replaces the whole destination ruleset and keeps weights and order.

## Obsidian import

Run `make -C scripts migrate-obsidian` manually. See
[scripts/migrations/obsidian/README.md](../scripts/migrations/obsidian/README.md).
