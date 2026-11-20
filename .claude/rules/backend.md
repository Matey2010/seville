---
paths:
  - "backend/**"
  - "proto/**"
---

# Backend and protobuf

- Closed unless the owner has reopened it for the current task. The API
  contract is `docs/http-api-conventions.md`. Follow its method, naming, and
  concurrency conventions, and update it in the same change as any endpoint.
- User input reaches Cypher only as named parameters or allowlisted enums.
- Every canonical Node write increments `update_count` in the same
  transaction. Writes that take `expected_update_count` reject a stale value
  with `ErrNodeConflict`. Reads never change it.
- After editing `.proto`, run `make -C scripts proto` and commit `gen/`.
- A new startup migration is a data operation: note in the change that the
  owner must back up Neo4j first.
