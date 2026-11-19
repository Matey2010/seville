# Obsidian vault migration

This directory preserves Seville's original one-way Obsidian/Markdown vault
importer as explicit migration tooling. It is not part of backend or client
startup. Starting Seville must never scan or import a vault.

## Run manually

First back up the target Neo4j database and configure the source and database
connection in the repository-root `.env`. Then, from the repository root, run:

```sh
make -C scripts migrate-obsidian
```

The Make target exports the relevant source and Neo4j variables from `.env`,
then runs the Go migration command. It does not start Seville, Docker, or the
macOS client. The target Neo4j service must already be reachable.

## Source contract

- `SEVILLE_SOURCE=vault` reads `SEVILLE_VAULT_PATH`.
- `SEVILLE_SOURCE=git` reads the local checkout at
  `SEVILLE_GIT_REPOSITORY_PATH` and the relative
  `SEVILLE_GIT_VAULT_SUBPATH`.
- A Markdown file may set its Node `slug` in YAML frontmatter; otherwise its
  relative path without `.md` becomes the slug.
- Hidden directories, including `.obsidian`, are skipped.
- Duplicate slugs abort the migration. Malformed files are reported as warnings
  and skipped.

## Write behavior and limitations

The importer creates previously unseen Node slugs and their connections.
It deliberately does not overwrite an existing Node or delete a Node whose
source file disappeared. It is a legacy bootstrap migration, not a general
synchronization system, and it does not maintain source provenance or conflict
records. Review the migration output and target graph before running it again;
changing source slugs can create apparent duplicates.
If an older imported record has the same path but no slug, the importer stops
instead of creating a second Node for that file.

The reusable implementation lives in
`backend/internal/migration/obsidian_vault.go`; parsing remains in
`backend/internal/scanner`, and Neo4j writes remain in
`backend/internal/store`. A future knowledge-base migration should add a source
adapter that produces a `NodeSnapshot` and reuse the storage boundary instead
of copying Cypher or database connection code.
