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
}
```

`node_count` is the number of Neo4j nodes labeled `Node` that have a non-empty
stable Seville `id`. It does not count `Tag` nodes, alias records, unresolved
connection records, or relationships.

`node_property_count` is the total number of stored Neo4j property assignments
across those same stable Nodes. If one stable Node has `id`, `title`, and
`body`, it contributes three. The metric counts assignments, not distinct
property keys. Relationship properties and properties attached to other labels
are excluded.

The storage query should compute both values from one graph view so they
describe the same instant:

```cypher
MATCH (node:Node)
WHERE node.id IS NOT NULL AND trim(toString(node.id)) <> ''
RETURN count(node) AS node_count,
       sum(size(keys(node))) AS node_property_count
```

A distinct count of property names would be a different future metric named
`node_property_key_count`; it must not change the meaning of
`node_property_count`.

## Nodes v1

`QUERY /nodes/v1/tree` accepts an `application/x-protobuf`
`seville.nodes.v1.NodeTreeQuery` body and returns a
`seville.nodes.v1.NodeTree`. The optional `root_node_id` field overrides
`SEVILLE_ROOT_NODE_ID`; one of them must provide the stable root Node ID. The
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

The optional `node_filter` contains `include_nodes_matching` and
`exclude_nodes_matching` lists of structured `NodeSearchParameter` values.
Entries within each list are OR-combined. When includes exist, a candidate must
match at least one; matching any exclude rejects it. Supported parameters are
`name`, `id`, `path`, `title`, `tag`, and Neo4j `label`; supported operators are
case-sensitive exact, starts-with, ends-with, contains, and Go regular-expression
matching. `name` addresses the
additional Neo4j `name` property transported in `Node.frontmatter`; it is not a
second identity field and does not replace `Node.id` or `Node.title`. `label`
matches values returned by Neo4j's `labels(node)` and is not transported as
frontmatter.

Filters apply to traversed children, not the requested root. Rejecting an
occurrence also prunes traversal below that occurrence, so its descendants do
not appear at a later depth. Unsupported parameters, missing values, operators,
and invalid regular expressions return `400 invalid_node_search_parameter`.

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

After successfully resolving the tree, the store increments the Neo4j
`counter` property once for each unique Node included in that response. The
root is included; repeated occurrences and cycles do not increment the same
Node more than once per request. Snapshot hydration does not increment
counters. Counter values are normalized with `toInteger`, with missing or
non-numeric values treated as zero.

`QUERY` describes the safe, idempotent graph lookup. The `counter` mutation is
server-side access telemetry, analogous to request logging, rather than the
requested effect of the method. Client retries, refreshes, and separate Fan
requests can still increment the returned Nodes again, so `counter` must not be
interpreted as a count of unique human views.

## Implementation boundary

Contracts live under the corresponding versioned package in `proto/seville/`.
The backend queries Neo4j through the store and exposes authenticated handlers.
Flutter consumes generated protobuf types rather than decoding untyped maps.

Every returned `seville.node.v2.Node` includes its typed `emojis` collection,
hydrated from outgoing `HAS_EMOJI` relationships. This applies consistently to
both snapshot Nodes and Nodes embedded in tree occurrences.

This endpoint reports current canonical database state and mutates only the
request counters described above. It must not scan a vault, run migration
logic, or derive its values from the legacy import snapshot.
