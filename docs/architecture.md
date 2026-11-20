# Architecture

## Boundary

```text
Markdown folder / Git checkout --manual import--> Go migration tool
                                                        |
                                                        v
                                             Neo4j (canonical data)
                                                        |
                                       Go API (protobuf over HTTP, bearer token)
                                                        |
                                                        v
                                   Flutter macOS client (Riverpod + Dio)
```

- Neo4j 5.26 Community runs in Docker (`neo4j-data` volume). The Go API runs on
  the host at `127.0.0.1:8787`. There is no SQL store.
- Flutter never connects to Neo4j. Generated protobuf types are the only wire
  types. Endpoints and methods: [http-api-conventions.md](http-api-conventions.md).
- The Go backend owns Markdown connection parsing. Creating or editing a body
  rewrites that Node's outgoing `LINKS_TO` in the same transaction. Creating a
  Node can resolve older unambiguous `[[slug]]` references.

## Client

- One full-window graph: `InteractiveViewer` for pan/zoom, positioned Node
  widgets for interaction, `CustomPaint` for connections.
- Forge2D provides circular collisions and gentle drift around semantic
  anchors. The time plane sets the vertical anchor; the location plane will
  set the bottom one.
- The global view is a 200-Node overview. When unfiltered, it reserves up to
  half its slots for a chronological sample of dated Nodes.
- Screen behavior rules live in `.claude/rules/client.md`.

## Backend startup migrations

Startup is idempotent and never imports sources. It:

- applies `:Node` to slugged records, aborting on duplicate slugs and removing
  five known legacy shells (`armor`, `career`, `game`, `science`, `weapon`);
- backfills temporal spans for calendar slugs (`DD-MM-YYYY`, ISO dates, `YYYY`,
  `YYYY-MM`, `YYYY-Wnn`, BCE titles); clearing a span records an opt-out so it
  is not re-inferred;
- discards legacy tag data (`TAGGED_WITH`, tag-based color rules).

Back up Neo4j before running a backend version that adds a startup migration.
