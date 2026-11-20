# Domain model

Definitions live in `docs/vocabulary.md`. These are the invariants:

- `Node` is the only core entity, and its unique slug is its only identity.
  Never add ids or UUIDs, persist `elementId()`, or create a parallel entity.
  Model new concepts such as Objective as labeled Nodes plus relationships and
  properties.
- Reject ambiguous duplicate slugs instead of picking one. Direct Neo4j edits
  must preserve slug uniqueness.
- `:Node` is reserved: hidden from users and never editable.
- Semantic placement (`DATE` spans, future `POINT` locations) is canonical
  data, kept separate from operational timestamps (`modified_at`, last
  opened). Never infer placement from slugs or labels.
- Appearance rules are presentation settings, not Nodes. Preserve their
  weights and order when moving data.
