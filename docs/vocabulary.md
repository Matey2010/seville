# Vocabulary

Canonical names shared by Neo4j, Go, protobuf, and Flutter. Check this file
before naming a domain entity or API contract. Add a term here before using it
in code.

## Node

The primary data unit. Its unique, human-readable **slug** is its only
application identity, displayed as `[[slug]]`. Never add a Node `id`/UUID or
persist Neo4j `elementId()`. Title, Markdown body, frontmatter, Emoji,
timestamps, and labels are Node data.

Every canonical Node carries the reserved `:Node` label, which backs the
`slug_unique` constraint. `:Node` is hidden from users and cannot be edited;
other labels (e.g. `Science`) are the only user-facing classification. Renaming
or deleting a label affects every Node carrying it.

Don't call it Note, SevilleNote, or Knowledge. Neo4j is the live database;
there is no Markdown or file mirror.

`update_count` is a store-managed counter incremented by every canonical write
and never by reads. Clients send their last observed value to detect stale
writes. `modified_at` is operational, not semantic, time.

## NodeConnection

A directed connection from a Node to a resolved Node or an unresolved target
reference, parsed from Markdown. Resolved connections are `LINKS_TO`
relationships. `PART_OF` and `FAMILY` are separate relationship types.

## NodeGraph

A bounded API response of Nodes and the connections between them. An empty
root requests the global view (optionally narrowed by a search term); a root
slug requests a local neighborhood. `has_more` marks truncation.

## Temporal span

Optional canonical placement in time: a native Neo4j `DATE` interval with an
inclusive start and exclusive end, plus a granularity (year, season, month,
week, day, range). It never changes the slug. Never infer it from an ambiguous
slug.

A **Date Node** has slug `DD-MM-YYYY`, label `Date`, and a one-day span. It is
shown as a calendar label on the time HUD, not as a graph body.

## Location (planned)

Optional canonical placement in space: a native Neo4j `POINT` plus a place
hierarchy. Never infer it from labels or slugs.

## Objective

A real-world goal the owner commits to reach: a Node with the `Objective`
label, not a separate entity. Inspired by RPG quest systems, named for
professional use; never call it Quest in code, API, or UI. Its structure
(steps, state, priority) is still being designed; see
[roadmap.md](roadmap.md#objectives--design). Only the name is settled.

## Draft

Local Flutter form state for a Node being created or edited. It becomes a
Node only when `POST /api/v1/node/` returns one, and it is kept open on API
failure or conflict.

## Node appearance rule

Shared, revisioned presentation configuration, not a Node. It matches one
field (label, slug, title, or a named frontmatter value) by case-insensitive
exact, contains, or starts-with matching. Among enabled matches, the highest
weight wins and list order breaks ties. A rule supplies a `#RRGGBB` color, a
gravity scale (0–3×), and a size scale (0.5–2×).
