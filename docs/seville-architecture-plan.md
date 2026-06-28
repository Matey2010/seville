# Seville Architecture Plan

## Purpose

This is a living design document for Seville. It records the current direction,
the decisions behind it, and the questions that still need proper analysis.

It is not an implementation checklist yet. Each layer must be reviewed,
understood, and accepted before implementation begins. Decisions can be
replaced when analysis shows a better path.

## Product Goal

Seville is a visual interface for a knowledge base stored in an Obsidian vault.
The Flutter application will use Flame to present notes and their relationships
as an interactive visual space.

The first version is read-only:

1. An existing external tool synchronizes a selected vault folder to a private
   server.
2. A Go backend scans that folder and interprets the Obsidian Markdown files.
3. The backend stores a queryable representation in an embedded database.
4. The backend exposes a small HTTPS API.
5. The Flutter application fetches a typed knowledge snapshot with Dio.
6. The visualization converts that snapshot into its own display model.

Editing the vault from Seville is explicitly deferred until the read pipeline
works reliably.

## Current Direction

These are product-level choices already selected:

| Area | Current decision | Status |
| --- | --- | --- |
| Repository | Single monorepo | Accepted direction |
| Top-level layout | `interface`, `docs`, `backend`, `proto`, `scripts` | Accepted direction |
| Contract ownership | Dedicated `proto` workspace | Accepted direction |
| Contract format | Protocol Buffers | Accepted direction |
| Backend language | Go | Accepted direction |
| Frontend | Flutter, Flame, and Dio | Accepted direction |
| Backend location | Private remote server | Accepted direction |
| Vault transfer | External folder synchronization | Accepted direction |
| Storage | SQLite with JSON for flexible metadata | Accepted direction |
| API payload | Binary protobuf over HTTP | Accepted direction |
| Authentication | Static bearer token over HTTPS | Accepted for V1 |
| Synchronization | Scan at startup and on explicit request | Accepted for V1 |
| Dataset delivery | One revisioned knowledge snapshot | Accepted for V1 |
| Deployment | Docker Compose with Caddy | Accepted direction |
| Write-back | Deferred | Accepted for V1 |

Technical details below are proposals until their layer has been reviewed.

## System Boundary

```text
Obsidian vault
      |
      | external synchronization
      v
Remote vault folder
      |
      | scan and parse
      v
Go backend ----> SQLite
      |
      | HTTPS + binary protobuf
      v
Flutter data layer ----> Flame visualization
```

Seville does not own folder synchronization in V1. Syncthing, Git, or another
existing mechanism is responsible for placing the selected vault folder on the
server.

## Monorepo Model

### Current layout

User-facing clients live in `interface/`, with the Flutter project in
`interface/flutter/`. Documentation, backend, contract, and utility workspaces
live beside `interface/` at the repository root.

```text
seville/
├── interface/          User-facing clients
│   └── flutter/        Flutter and Flame application
├── docs/               Architecture, decisions, and project documentation
├── backend/            Go ingestion service, database, and HTTP API
├── proto/              Protobuf source, generation config, and generated code
├── scripts/            Project automation and Obsidian utility programs
└── README.md           Monorepo overview and entry points
```

The top-level structure is implemented. `backend/` is a Go module,
`proto/gen/go/` is a generated Go module, and the root `go.work` connects them.
Stable local commands live in `scripts/seville`; protobuf generation is exposed
through `scripts/generate-proto`.

### `interface/`

Owns:

- User-facing clients and their client-specific documentation.
- Shared conventions for consuming Seville's public API.

### `interface/flutter/`

Owns:

- The Flutter project and platform directories.
- Dio transport configuration.
- Local snapshot caching.
- Conversion from protobuf messages to application models.
- Flutter interface and Flame visualization.

The Flutter application consumes generated Dart code through a local path
dependency on the Dart package under `proto/`. It must not parse vault files or
depend on backend database models.

### `docs/`

Owns:

- This architecture plan.
- Accepted architecture decision records.
- Contract and data-model explanations.
- Development, deployment, and operational documentation.

Documentation should describe decisions and workflows. It must not become a
second source of truth for schemas that already exist in code.

### `backend/`

Owns:

- Production vault scanning and parsing.
- Obsidian-specific interpretation.
- SQLite schema and migrations.
- Snapshot construction.
- HTTP API and authentication.
- Backend container and deployment behavior.

The current proposal is for `backend/` to become an independent Go module
inside the monorepo. Whether generated Go code is a separate module and whether
the root uses `go.work` remain decisions for the workspace review.

### `proto/`

Owns:

- Canonical `.proto` files.
- Buf formatting, linting, generation, and compatibility configuration.
- Generated Go message package.
- Generated Dart message package.
- Contract fixtures used by both languages.

Proposed internal layout:

```text
proto/
├── buf.yaml
├── buf.gen.yaml
├── seville/knowledge/v1/
│   └── knowledge.proto
├── gen/go/             Generated Go module
└── gen/dart/           Generated Dart package
```

Generated code is committed. A normal backend or Flutter build must not require
developers to install `protoc`, Buf, or language generators.

The generated Go and Dart packages are private monorepo packages in V1. They
are not independently published or tagged. The repository commit is the
version shared by the contract, backend, and interface.

### `scripts/`

Owns project-level utilities that do not belong in a runtime application:

- Contract generation and verification wrappers.
- Development setup and fixture generation.
- One-off vault inspection, import, export, and migration tools.
- Experiments for understanding Obsidian data.
- Deployment and maintenance helpers where shell automation is appropriate.

Production parsing rules must live in reusable Go packages under `backend/`,
not only in scripts. A script may call those packages or prototype behavior,
but the backend remains the source of truth for ingestion.

Scripts should be small and documented. Stable workflows should eventually be
exposed through one root task runner rather than requiring contributors to
remember individual script paths.

### Dependency rules

```text
proto source
  ├──> generated Go package ──> backend
  └──> generated Dart package ──> interface/flutter

backend ──HTTP/protobuf──> interface clients
scripts ──may invoke tooling──> proto/backend fixtures
docs ──describes all areas but is not a runtime dependency
```

- `backend/` must not import code from `interface/`.
- `interface/` clients must not import backend implementation packages.
- `proto/` must not contain backend or interface business logic.
- `scripts/` must not become an undeclared runtime requirement.
- Cross-language communication occurs only through the protobuf contract and
  documented HTTP behavior.

### Atomic contract changes

Because all components live in one repository, a contract change must update
the following in one pull request:

1. Protobuf source.
2. Generated Go and Dart code.
3. Backend producer code and tests.
4. Flutter consumer code and tests.
5. Compatibility fixtures or documentation when behavior changes.

CI must reject stale generated code and incompatible schema changes. Separate
contract releases, Git dependencies, and temporary cross-repository version
drift are no longer required.

### Questions for this layer

- Should the root automation use `Makefile`, `just`, or another task runner?
- Should `go.work` be committed or generated during setup?
- What exact generated package names and module paths should be used?
- Should deployment files live at the root or under `backend/deploy/`?
- Which scripts deserve long-term support versus remaining disposable
  experiments?

## Contract Layer

### Goal

Protocol Buffers define the data exchanged between the backend and Flutter.
They should not define database tables, Flame components, or every internal Go
type.

The contract is a stable boundary, not a universal model for the whole system.

### Proposed package

Use the protobuf package:

```proto
package seville.knowledge.v1;
```

The initial contract should define:

- `KnowledgeSnapshot`
- `Note`
- `Link`
- `ScanStatus`
- `ScanWarning`
- `ApiError`

### Proposed data responsibilities

`KnowledgeSnapshot` contains:

- Snapshot revision.
- Generation timestamp.
- Notes.
- Links.
- Non-fatal scan warnings.

`Note` contains:

- Stable identifier for the current path.
- Vault-relative path.
- Display title.
- Markdown body.
- Tags.
- Frontmatter.
- File modification time.

`Link` contains:

- Source note identifier.
- Original target text.
- Resolved target identifier when available.
- Optional display text.
- Link kind.
- Optional heading or block fragment.

### Compatibility rules

- Never reuse a protobuf field number.
- Reserve numbers and names of removed fields.
- Prefer additive fields.
- Use explicit presence where absence differs from a default value.
- Include an `UNSPECIFIED` zero value in every enum.
- Do not expose storage-specific fields without an API reason.
- Run breaking-change detection against the contract on the main branch.
- Pin generator and runtime versions.

### Generation proposal

Use Buf for:

- Formatting.
- Linting.
- Reproducible generation.
- Breaking-change detection.

Generate plain protobuf messages for Go and Dart. Do not generate gRPC or
Connect clients in V1.

Use one containerized generation command so contributors do not manually align
different `protoc` and plugin versions.

### Questions for this layer

- Is sending complete Markdown body content necessary for the first
  visualization?
- Should frontmatter use `google.protobuf.Struct` or a smaller typed subset?
- Which fields require presence rather than protobuf defaults?
- What constitutes a breaking semantic change even when Buf considers the wire
  format compatible?
- Should scan warnings be returned inside every snapshot or through a separate
  status endpoint?

## Vault Interpretation

### Scan scope

The backend scans `.md` files beneath one configured root folder.

Proposed exclusions:

- `.obsidian`
- Hidden directories
- Non-Markdown attachments

These exclusions require validation against the real vault before they are
fixed.

### Proposed parsing behavior

- Parse YAML frontmatter.
- Determine title from frontmatter `title`, then the first heading, then the
  filename.
- Extract frontmatter tags and inline `#tags`.
- Extract standard Markdown links.
- Extract Obsidian wiki links such as `[[Note]]`.
- Preserve aliases such as `[[Note|Display text]]`.
- Preserve heading and block fragments.
- Keep unresolved and ambiguous links instead of discarding them.

Use a Markdown AST parser rather than regular expressions for standard Markdown
structure. Obsidian-specific wiki syntax may require a focused extension or
separate parser.

### Proposed link resolution

Resolve a link in this order:

1. Explicit vault-relative path.
2. Path relative to the source note.
3. Unique filename match.
4. Otherwise mark it unresolved or ambiguous.

This algorithm must be checked against Obsidian's actual resolution behavior
before implementation.

### Identity proposal

In V1, derive a note ID deterministically from its normalized vault-relative
path. A rename is therefore represented as deletion plus creation.

Persistent identity across renames is deferred because it requires metadata
inside the vault or a reliable reconciliation strategy.

### Failure behavior

- One malformed file should produce a warning, not destroy the whole snapshot.
- A filesystem or database failure should fail the scan.
- A failed scan must leave the previous successful snapshot available.
- The backend must never modify vault files in V1.

### Questions for this layer

- Which real frontmatter fields are important to the visualization?
- Does the selected folder contain links to notes outside that folder?
- Should links outside the selected folder become unresolved external nodes?
- Are embeds different from normal links for visualization purposes?
- Are aliases, block references, canvases, or attachments needed in V1?
- How closely must behavior match Obsidian's own link resolver?

## Storage Layer

### Proposed engine

Use embedded SQLite rather than operating a separate database service.

Reasons:

- One backend instance and one knowledge base.
- Simple backup and deployment.
- Transactions protect the last valid snapshot.
- Good indexing and query support.
- JSON columns can preserve flexible frontmatter.

### Proposed normalized model

Tables:

- `notes`
- `links`
- `scan_state`
- `schema_migrations`

Store commonly queried values in typed columns. Store flexible frontmatter as
JSON. Do not mirror protobuf binary blobs as the primary database model.

### Scan transaction

1. Read and parse candidate files.
2. Resolve relationships.
3. Validate the candidate dataset.
4. Begin a database transaction.
5. Replace or reconcile notes and links.
6. Update scan metadata and revision.
7. Commit atomically.

The snapshot revision should be deterministic for identical normalized content.

### Questions for this layer

- Is full replacement fast enough for the actual vault size?
- Which queries will the backend need besides producing the full snapshot?
- Should Markdown bodies live in SQLite or be read from disk when building a
  snapshot?
- What backup and restore procedure is required?
- Which SQLite driver has the best portability and maintenance tradeoff?

## HTTP API

### Transport decision

Use ordinary HTTP endpoints with binary protobuf request and response bodies.
Dio can request bytes and generated Dart messages can decode them directly.

This avoids adopting an RPC framework before the project requires RPC
features.

### Proposed endpoints

```text
GET  /healthz
GET  /v1/snapshot
POST /v1/admin/rescan
```

`GET /healthz`:

- No authentication.
- Reports process availability only.

`GET /v1/snapshot`:

- Requires bearer authentication.
- Returns `KnowledgeSnapshot`.
- Uses `Content-Type: application/x-protobuf`.
- Returns an `ETag` derived from the snapshot revision.
- Honors `If-None-Match` with `304 Not Modified`.

`POST /v1/admin/rescan`:

- Requires bearer authentication.
- Runs or requests a vault scan.
- Returns `ScanStatus`.

### Error behavior

- API failures return an appropriate HTTP status.
- Structured API error details use protobuf `ApiError`.
- Internal details and filesystem paths must not be exposed to clients.
- A scan with non-fatal file warnings may still return success.

### Questions for this layer

- Should rescan be synchronous or queued?
- What maximum snapshot size is acceptable?
- Should HTTP compression be mandatory?
- Should scan status have its own read endpoint?
- What timeout limits are appropriate for the actual deployment?

## Authentication And Security

### V1 proposal

- One long random bearer token.
- HTTPS is mandatory.
- Caddy terminates TLS.
- The backend compares tokens in constant time.
- The token comes from deployment secrets, never source control or images.
- Flutter stores the token with platform secure storage.

This is intentionally a single-user authentication model. Accounts, refresh
tokens, and permissions are deferred.

### Required protections

- Mount the synchronized vault read-only.
- Run the backend as a non-root user.
- Keep SQLite on a separate writable persistent volume.
- Expose only Caddy publicly.
- Apply HTTP server timeouts and request-size limits.
- Avoid logging tokens, complete note bodies, or sensitive frontmatter.

### Questions for this layer

- How is the token initially transferred to each Flutter installation?
- Is the server reachable from the public internet or only through a VPN?
- Is bearer-token rotation required in V1?
- Does the knowledge base contain data requiring encrypted backups?

## Flutter Data Layer

### Responsibilities

The Flutter application should keep transport and visualization separate:

```text
Dio client
    -> protobuf messages
    -> application/domain models
    -> visualization model
    -> Flame components
```

Flame components must not make network requests or depend directly on generated
protobuf classes.

### Proposed client behavior

- Configure Dio with the server URL, bearer-token interceptor, byte response
  type, and explicit timeouts.
- Decode successful responses with generated Dart protobuf classes.
- Decode protobuf `ApiError` responses where possible.
- Cache the latest successful snapshot bytes and ETag.
- Send `If-None-Match` on later requests.
- Use the cached snapshot during startup or temporary network failure.
- Reject corrupt or undecodable snapshots without deleting the last valid
  cache.

### Questions for this layer

- Which state-management approach should own loading and cache state?
- What local cache package fits all intended Flutter platforms?
- Should the first screen wait for a snapshot or render progressively?
- How should stale cached data be shown to the user?
- Which contract fields become domain types instead of passing through?

## Deployment

### Proposed shape

Use Docker Compose with:

- A Go backend container.
- A Caddy reverse-proxy container.
- A read-only vault mount.
- A persistent SQLite volume.
- Deployment secrets supplied outside the repository.

External synchronization updates the server-side vault folder. The backend
does not participate in transfer or conflict resolution.

### Questions for this layer

- Which external synchronization tool will be used?
- How does synchronization signal that a set of writes is complete?
- Where will backups be stored?
- Which host platform and CPU architecture must the image support?
- What logging and basic monitoring are required?

## Test Strategy

### Contract tests

- Protobuf formatting and linting.
- Reproducible generation.
- No uncommitted generated differences.
- Breaking-change detection against the main branch.
- Generated Go package compiles.
- Generated Dart package passes analysis.

### Scanner tests

Use fixture vaults covering:

- YAML frontmatter.
- Heading-derived titles.
- Frontmatter and inline tags.
- Wiki links, aliases, and fragments.
- Standard Markdown links.
- Duplicate filenames.
- Missing targets.
- Malformed YAML.
- Unicode filenames and content.
- Deleted and renamed files.

### Backend tests

- Successful atomic scan.
- Rollback after fatal scan failure.
- Previous snapshot remains available after failure.
- Deterministic revisions.
- Stale database records are removed.
- Authentication success and failure.
- Protobuf content types and decoding.
- ETag and `304` behavior.
- Rescan behavior.

### Flutter tests

- Bearer-token interceptor.
- Byte response decoding.
- Protobuf error decoding.
- `304` handling.
- Local cache fallback.
- Corrupt response handling.
- Contract-to-domain conversion.

### End-to-end test

Run one fixture through:

```text
vault files
  -> scanner
  -> SQLite
  -> HTTP protobuf response
  -> Dart protobuf decode
  -> Flutter domain model
```

## Explicitly Deferred

The following are not part of V1:

- Editing vault files from Flutter.
- Multi-user accounts and permissions.
- Automatic conflict resolution.
- Stable note identity across renames.
- Filesystem watchers.
- Incremental change streams.
- Pagination.
- gRPC or Connect.
- Attachments and media transfer.
- Full Obsidian plugin compatibility.
- Offline client edits.

Deferral does not mean these are impossible. It means V1 should avoid choices
that unnecessarily block them.

## Review Order

We will analyze and approve one layer at a time:

1. Monorepo layout, workspace boundaries, and dependency rules.
2. Protobuf model and compatibility policy.
3. Vault parsing and link-resolution semantics.
4. SQLite model and scan transaction.
5. HTTP API behavior.
6. Authentication and remote deployment.
7. Flutter client and cache boundary.
8. End-to-end delivery sequence.

For each layer:

1. State the problem and required behavior.
2. Examine realistic alternatives.
3. Identify dependencies and compatibility risks.
4. Test assumptions against the actual vault or a representative fixture.
5. Record the decision and rejected alternatives here.
6. Convert only the accepted decision into implementation tasks.

## Current Implementation Slice

The first local backend slice is implemented:

- Independent Go modules for `backend/` and generated Go protobuf code.
- A root `go.work` workspace.
- Markdown scanning with basic frontmatter, tags, wiki links, and Markdown
  links.
- Atomic SQLite snapshot replacement.
- Bearer-authenticated protobuf HTTP endpoints with ETag support.
- Docker Compose and Caddy deployment files.
- Stable local development commands.

The parser is intentionally an initial implementation. YAML completeness,
Markdown AST adoption, Obsidian-compatible resolution edge cases, generated
Dart code, Flutter integration, and CI compatibility checks remain for the
next reviews.
