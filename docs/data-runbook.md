# Data runbook

Neo4j's `neo4j-data` Docker volume is the live copy of all Seville data,
including appearance rules (`ObsivilianColorRuleSet` / `ObsivilianColorRule`).
Backups are the only other copy.

## Backups

[`scripts/backup.sh`](../scripts/backup.sh), driven by Make, works like this:

1. Stop Neo4j for a few seconds.
2. Take a `neo4j-admin database dump` (the faithful format: constraints, `DATE`
   values, and rules included).
3. Restart Neo4j.
4. Encrypt the dump with `age` to the backup drive.
5. Prune old backups: keep the 14 newest plus the first of each of the last 12
   months.

The plaintext dump exists only in a private temp folder on the Mac's
FileVault disk.

| Setting (`.env`) | Default |
| --- | --- |
| `SEVILLE_BACKUP_DIR` | `/Volumes/Memoria/Backups/seville` (external SSD) |
| `SEVILLE_BACKUP_AGE_KEY` | `~/.config/seville/backup-age-key.txt` |
| `SEVILLE_BACKUP_KEEP` | `14` |
| `SEVILLE_BACKUP_HOUR` | `4` (daily run hour) |

**The age key is the only way to decrypt.** Keep a copy in a password manager
and never on the backup drive. Losing it makes every backup unreadable.

```sh
make -C scripts backup-setup        # once: key + folder (done 2026-11-19)
make -C scripts backup              # back up now
make -C scripts backup-verify       # test-restore the newest backup in a throwaway container
make -C scripts backup-schedule     # daily LaunchAgent; log: ~/Library/Logs/seville-backup.log
make -C scripts backup-unschedule
make -C scripts backup-restore FILE=/Volumes/Memoria/Backups/seville/<file>.dump.age
```

- **Drive unplugged:** the run is skipped. A macOS notification appears once
  the last success, recorded in `~/.config/seville/last-backup`, is more than
  3 days old.
- **Verify** loads a backup into a temporary volume and container and reports
  Node, `LINKS_TO`, and color-rule counts. It never touches live data. Run it
  monthly and after changing the backup setup.
- **Restore** asks for confirmation, takes a fresh backup first, replaces the
  live database, then needs `make -C scripts restart` for the Go API.
- **Permissions (scheduled runs):** macOS grants removable-volume access per
  app, and command-line tools started by launchd can't ask for it.
  - `backup-schedule` therefore builds a background app,
    `~/Applications/Seville Backup.app`, which launchd opens daily. Allow it
    once when macOS asks about removable volumes; everything it runs inherits
    that permission.
  - The app is rebuilt only when its script changes, which would trigger the
    prompt again.
  - Each run checks that it can write before stopping Neo4j, and sends a
    notification if it can't.

## Before risky operations

Run `make -C scripts backup` before:

- volume deletion or a Compose project rename;
- a Neo4j upgrade;
- a backend version with a new startup migration;
- manual Cypher writes.

Never commit `.env`, database dumps, or credentials.

## Inspect

Neo4j Browser: `http://127.0.0.1:7474`.

```cypher
// One Node
MATCH (n:Node {slug: $slug}) RETURN n, labels(n);

// Label usage
MATCH (n:Node) UNWIND labels(n) AS label
WITH label WHERE label <> 'Node'
RETURN label, count(*) AS node_count ORDER BY node_count DESC;

// Duplicate slugs (must be empty)
MATCH (n) WHERE n.slug IS NOT NULL
WITH n.slug AS slug, count(*) AS copies WHERE copies > 1
RETURN slug, copies ORDER BY slug;
```

## Move appearance rules only

A full database backup and restore moves rules with Nodes. To copy only the
rules:

1. `GET /api/v1/graph/color-rules` on the source.
2. `GET` the same route on the destination to read its revision.
3. `PUT` the source rules to the destination with that revision.

`PUT` replaces the whole destination ruleset and keeps weights and order.
