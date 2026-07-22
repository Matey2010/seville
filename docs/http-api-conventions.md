# Seville HTTP API conventions

This document defines how Seville names, versions, and transports HTTP API
data. New endpoints should follow these rules unless an endpoint documents a
specific compatibility exception.

## Route structure

Application routes use this structure:

```text
/{group}/v{major}/{resource}
```

- `group` is a stable product area such as `system` or `nodes`.
- The major version belongs to that group. A breaking system API change moves
  `/system/v1/...` to `/system/v2/...` without forcing unrelated APIs to move.
- Route segments use lowercase kebab-case when more than one word is needed.
- Resource names are nouns. HTTP methods express the operation.
- Health checks that carry no application data may remain unversioned, such as
  `GET /healthz`.

## Field names and generated names

Protocol Buffer definitions are the canonical wire contracts. Their fields use
`snake_case`:

```proto
uint64 node_count = 1;
uint64 node_property_count = 2;
```

Generated language bindings follow their language conventions without manual
renaming:

| Context | Example |
| --- | --- |
| Protobuf source | `node_property_count` |
| Dart | `nodePropertyCount` |
| Go | `NodePropertyCount` |
| Protobuf JSON, if explicitly offered later | `nodePropertyCount` |

Do not use `nodes_amount`, `node_amount`, or hand-written casing aliases.
Countable entities use the `_count` suffix. Database-wide counters use
`uint64`; an implementation must reject an invalid negative database result
before converting it to the unsigned wire type.

Successful typed responses use `Content-Type: application/x-protobuf` and the
message defined by the endpoint's protobuf package. JSON is not an implicit
second contract. If JSON is added later, use standard protobuf JSON mapping
rather than separately named fields.

Authenticated application routes require the existing bearer token. Errors use
the existing typed API error response until a shared error package replaces it.

## System v1

The first system endpoint is:

```text
GET /system/v1/info
```

It returns a `seville.system.v1.SystemInfo` message:

```proto
message SystemInfo {
  uint64 node_count = 1;
  uint64 node_property_count = 2;
  repeated string neo4j_labels = 3;
  string go_version = 4;
  string neo4j_version = 5;
}
```

`node_count` is the number of graph Nodes that have a non-empty unique `slug`.
It does not count `Tag` nodes, alias records, unresolved
connection records, or relationships.

`node_property_count` is the total number of stored Neo4j property assignments
across those same stable Nodes. If one stable Node has `id`, `title`, and
`body`, it contributes three. The metric counts assignments, not distinct
property keys. Relationship properties and properties attached to Tag or Emoji
metadata graph roles are excluded. Neo4j labels classify Nodes but do not
determine whether a graph entity is a Seville Node.

`neo4j_labels` is the sorted list returned by Neo4j's label catalog.
`go_version` comes from the running Go process, and `neo4j_version` comes from
the connected Neo4j DBMS. These are administrative runtime facts rather than
Node properties.

The storage query should compute both values from one graph view so they
describe the same instant:

```cypher
MATCH (node)
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> ''
  AND NOT node:Tag
  AND NOT node:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(node) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(node) }
RETURN count(node) AS node_count,
       sum(size(keys(node))) AS node_property_count
```

A distinct count of property names would be a different future metric named
`node_property_key_count`; it must not change the meaning of
`node_property_count`.

## Nodes v1

`QUERY /nodes/v1/search` accepts an `application/x-protobuf`
`seville.nodes.v1.NodeSearchQuery` body and returns a flat
`NodeSearchResult`. Its `node_filter` is required. `limit` defaults to 20 and
must be between 1 and 100. The endpoint returns complete Nodes in deterministic
slug/path order and does not traverse relationships. Flutter's interactive
search builds an OR filter across slug, title, tags, and Neo4j labels with an
escaped case-insensitive regular expression, so user text remains data rather
than query syntax. Search does not increment `Node.update_count`.

`QUERY /nodes/v1/tree` accepts an `application/x-protobuf`
`seville.nodes.v1.NodeTreeQuery` body and returns a
`seville.nodes.v1.NodeTree`. A request must provide either `root_node_id` or a
structured `root_node_filter`. A root filter permits discovery even when the
root has no stable Node ID; Neo4j's internal element ID remains store-private
while traversal is evaluated. Every matching root is returned as a depth-zero
occurrence in deterministic order: shortest stringified `slug`, then `slug`,
`path`, stable Node ID, and finally the internal locator. `root_node_id` in the
response is populated only when exactly one root is returned. The
optional unsigned `depth` defaults to `3`, with the root at depth zero. The
optional `traverse_by` field defaults to `part_of` and accepts only `part_of`
or `family`. URL query parameters remain a filterless compatibility contract
for older clients.

`QUERY` is the canonical method. The backend temporarily accepts `GET` as a
compatibility alias so a client can recover when an older HTTP runtime or proxy
rejects the custom method. Flutter attempts `QUERY` first and uses that alias
only after a method-routing response (`404`, `405`, or `501`) when no Node
filters were requested. A filtered request must never silently retry as an
unfiltered `GET`.

The optional `root_node_filter` and `node_filter` contain
`include_nodes_matching` and
`exclude_nodes_matching` lists of structured `NodeSearchParameter` values.
`include_match_mode` controls whether a candidate must match `any` (the default)
or `all` include entries. Exclude entries are always OR-combined, and matching
any exclude rejects the candidate. Use `all` for a compound selector such as a
Neo4j label plus an exact slug. When `negated` is true, the complete predicate
is inverted after include and exclude composition; this is the transport form
of Flutter's `NodeSearchFilter.reverseOf(...)` and `.reversed()` APIs.
Supported parameters are
`name`, `id`, `path`, `title`, `tag`, `slug`, and Neo4j `label`; supported operators are
case-sensitive exact, starts-with, ends-with, contains, and regular-expression
matching. Regular expressions are validated before they are passed to Neo4j's
parameterized `=~` operator. `name` addresses the
additional Neo4j `name` property transported in `Node.frontmatter`; it is not a
second identity field and does not replace `Node.id` or `Node.title`. `label`
matches values returned by Neo4j's `labels(node)`. Every returned Node also
transports those values through `Node.labels`; labels are never flattened into
frontmatter.

`root_node_filter` applies only to root discovery; `node_filter` applies to
traversed children. Rejecting an
occurrence also prunes traversal below that occurrence, so its descendants do
not appear at a later depth. Unsupported parameters, missing values, operators,
and invalid regular expressions return `400 invalid_node_search_parameter`.
Go compiles only allowlisted parameter and operator enums into Cypher predicate
fragments. Search values are always supplied through named Neo4j parameters and
are never interpolated into query text. Filtering runs in Neo4j before Node and
Emoji hydration; the backend does not fetch rejected children for in-memory
post-filtering.

The endpoint follows incoming relationships: `part_of` maps to `PART_OF` and
`family` maps to `FAMILY`, both stored as
`(child)-[:RELATIONSHIP_TYPE]->(parent)`. Each traversal path produces its own
`NodeTreeOccurrence`, identified independently from its Node. Repeated Nodes
and cycles are therefore preserved until the requested depth instead of being
deduplicated.

The HTTP value is allowlisted into `NodeRelationshipType` before reaching the
store. Cypher uses a fixed query and passes the corresponding Neo4j relationship
name as a parameter to `type(relationship)`; request text is never interpolated
into Cypher.

`QUERY` endpoints are read-only. Tree refreshes, searches, retries, and Fan
requests never mutate a Node or increment `update_count`.

Canonical Node mutations go through the store's filter-driven `MutateNodes`
boundary. The selected Node update and
`update_count = coalesce(toInteger(update_count), 0) + 1` execute in the same
Neo4j write transaction. `update_count` is store-managed and cannot be supplied
as an ordinary property mutation. Source import remains ingestion rather than a
canonical Node update and does not increment it. The legacy `counter` property
is not read, written, migrated, or removed by this policy.

## Implementation boundary

Contracts live under the corresponding versioned package in `proto/seville/`.
The backend queries Neo4j through the store and exposes authenticated handlers.
Flutter consumes generated protobuf types rather than decoding untyped maps.

Every returned `seville.node.v2.Node` includes its typed `emojis` collection,
hydrated from outgoing `HAS_EMOJI` relationships. This applies consistently to
snapshot Nodes, search results, and Nodes embedded in tree occurrences.

This endpoint reports current canonical database state without mutating it. It
must not scan a vault, run migration logic, or derive its values from the legacy
import snapshot.
