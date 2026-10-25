# Seville project context

## Vocabulary and product

- Read `docs/vocabulary.md` before naming a domain entity or API contract.
- `Node` is the primary domain and API unit. Neo4j labels classify Nodes but do
  not identify them. Do not introduce a parallel Note or Knowledge entity.
- Seville is a native Flutter knowledge graph client. Do not restore Flame,
  `GameWidget`, the declarative Layout library, or LG Ergo presets.
- Keep Go, Neo4j, and protobuf contracts unchanged until the project owner
  explicitly reopens backend development. The existing graph, search, create,
  and body update endpoints are the client baseline.

## Supported runtime

- macOS is the production runtime. Android phone landscape is experimental for
  owner verification; portrait is disabled.
- Web, Chrome, iOS, Linux, and Windows are unimplemented unless the owner says
  otherwise.
- When giving run or process-control instructions, use
  `make -C scripts interface`. The owner performs all application and Pixel
  runtime verification.

## HTTP methods

- Use `QUERY` for safe structured reads with a request body, including Node
  search and graph traversal.
- Use `POST` to create a Node with a server-assigned ID, `PATCH` for partial
  mutation, `PUT` for complete replacement at a known URI, and `DELETE` for
  removal. Do not introduce `CREATE` or `MUTATE` HTTP methods.

## Client structure

- Flutter widgets own layout, text input, accessibility, gestures, and the
  visible graph. Riverpod owns API request state; Dio and generated protobuf
  types cross the existing Go API boundary.
- The graph uses the same normalized Node positions for connection paint and
  positioned Node widgets. Keep the position calculation independent of widgets
  and recompute it when graph data changes, not on each pointer event.
- A single focused canonical Node selects a local graph. With no focus, show
  the bounded global graph; a submitted search narrows that global request.
- Node creation keeps its draft in the native form until the API accepts it.
  Body editing preserves unsaved text on API failure and uses the Node's last
  observed `update_count` for conflict detection.
- Keep the interface responsive for the experimental Android landscape size
  without a second layout engine or copied screen tree.

## Development ownership and checks

- Codex must not launch, build-run, or runtime-debug Seville, and must not ask
  permission to do so. The owner exclusively runs and debugs the final app.
- Applications and services do not use automated tests. Do not add test files,
  test dependencies, test runners, or CI steps that run tests.
- Non-interactive formatting, dependency resolution, and static analysis are
  permitted. Do not treat static checks as runtime verification.
