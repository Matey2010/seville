# HTTP API

## Conventions

- **Routes:** `/{group}/v{major}/{resource}`. Each group versions
  independently. Segments are lowercase kebab-case nouns. `GET /healthz` is
  unversioned.
- **Methods:**
  - `QUERY`: safe structured reads with a protobuf body.
  - `POST`: create with a caller-chosen unique slug.
  - `PATCH`: partial mutation.
  - `PUT`: complete replacement at a known URI.
  - `DELETE`: removal.

  Never `CREATE` or `MUTATE`, and no `GET` aliases for `QUERY` routes.
- **Wire format:** `application/x-protobuf` using messages from
  `proto/seville/`. JSON is not a contract. Fields are `snake_case`; generated
  Dart and Go names follow their language conventions. Counts use the `_count`
  suffix and `uint64`.
- **Auth:** every route except `/healthz` requires `Authorization: Bearer
  $SEVILLE_TOKEN`.
- **Concurrency:** canonical writes carry `expected_update_count` (or a ruleset
  `revision`). A stale value returns `409` and leaves the client draft open.
  Reads never increment `update_count`.
- **Safety:** request values reach Cypher only as named parameters or
  allowlisted enums. Labels must match `[A-Za-z_][A-Za-z0-9_]*`. Regular
  expressions are validated before use.

## Endpoints

| Route | Purpose |
| --- | --- |
| `QUERY /api/v1/node/graph` | `NodeGraphQuery` → `NodeGraph`. Optional `root_node_slug` for a local `LINKS_TO` neighborhood, otherwise the global view filtered by search term. `depth` ≤ 2, `limit` 1–200. Only connections with both endpoints present; `has_more` on truncation. |
| `QUERY /api/v1/node/search` | `NodeSearchQuery` → `NodeSearchResult`. Required `node_filter`; `limit` 1–100, default 20; deterministic slug order; no traversal. |
| `POST /api/v1/node/` | `NodeCreateRequest` (slug, labels, body) → `201` Node. Parses connections in the same transaction. Existing slug → `409 node_already_exists`. |
| `PATCH /api/v1/node/{slug}` | `NodeBodyUpdateRequest`. Body, `modified_at`, counter, and outgoing connections update atomically. |
| `PUT /api/v1/node/{slug}/labels` | Replace one Node's labels. |
| `PUT /api/v1/node/{slug}/temporal` | `NodeTemporalUpdateRequest`. Replace or clear the span (`DATE` start inclusive, end exclusive; signed ISO years for BCE). Ordinary mutation cannot touch these fields. |
| `QUERY /api/v1/label/search` | Labels on canonical Nodes with usage counts. |
| `PATCH /api/v1/label/{name}` | Rename a label on all Nodes, updating exact-label color rules. Rejects a name already in use. |
| `DELETE /api/v1/label/{name}` | Remove a label from all Nodes and delete its exact-label color rules. |
| `GET /api/v1/graph/color-rules` | `NodeColorRuleSet` with revision (empty at revision 0). |
| `PUT /api/v1/graph/color-rules` | Replace the ordered ruleset atomically (≤ 100 rules). |

## Node filters

`node_filter` and `root_node_filter` hold `include_nodes_matching` and
`exclude_nodes_matching` lists of `NodeSearchParameter`.

- **Parameters:** `name`, `path`, `title`, `slug`, `label`.
- **Operators:** exact, starts-with, ends-with, contains, regex; all
  case-sensitive.
- **Composition:** `include_match_mode` is `any` (the default) or `all`. Any
  exclude match rejects. `negated` inverts the composed predicate.
- **Errors:** invalid input returns `400 invalid_node_search_parameter`.

The client's Find uses `node/graph` with `search`: a case-insensitive
substring match over slug, title, body, and labels. It uses `node/search` only
for exact-slug lookups.
