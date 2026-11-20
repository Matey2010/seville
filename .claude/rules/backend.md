---
paths:
  - "backend/**"
  - "proto/**"
  - "scripts/migrations/**"
---

# Backend and protobuf

- Closed unless the owner has reopened it for the current task. The API
  contract is `docs/http-api-conventions.md`. Follow its method, naming, and
  concurrency conventions, and update it in the same change as any endpoint.
- User input reaches Cypher only as named parameters or allowlisted enums.
- Canonical writes go through `MutateNodes` and atomically increment
  `update_count`. Reads never change it.
- After editing `.proto`, run `make -C scripts proto` and commit `gen/`.
- Don't build on the legacy routes listed in the API doc; they are scheduled
  for removal.
- A new startup migration is a data operation: note in the change that the
  owner must back up Neo4j first.
