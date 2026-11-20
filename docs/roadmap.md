# Roadmap

The single list of planned work. It replaces the former `TODO.md` and quality
ledger. Update it when priorities change; delete items when they ship.

## Direction

Seville is an operating system for one person, its owner. It helps them choose
what to do, do it, and see progress toward real-world goals. The graph atlas of
Nodes on time and location planes is the foundation it reads from and writes
to.

**Feature test:** does it shorten the path from "I want X" to "X is done and
recorded"? Prefer small loops the owner uses daily over capabilities nobody
uses. Use each shipped feature for about a week before starting the next.

## P0 — Safety and hygiene

Small items that protect data or remove noise. Do these first.

1. ~~**Neo4j backups.**~~ Done 2026-11-19: age-encrypted daily dumps to the
   external SSD at 04:00, with a restore test passed (8,977 Nodes). See
   [data-runbook.md](data-runbook.md#backups). Run `backup-verify` monthly.
2. **API exposure.**
   - [compose.yaml](../compose.yaml) publishes Caddy on all interfaces
     (`8787:8787`); bind it to `127.0.0.1`.
   - Server and client fall back to the token `local-seville-token`; fail at
     startup when `SEVILLE_TOKEN` is unset.
3. **Remove dead API surface** (needs backend reopened). The client never calls:
   - `GET /v2/status` and `GET /v2/snapshot`
   - `GET /system/v1/info`
   - `QUERY|GET /api/v1/node/tree`, which served the retired Fan layout
   - filter-driven `PATCH /api/v1/node/`
   - `seville/notification/v1`

4. **Read-flow bugs** (client; found by reading code, not yet seen in the app):
   - R-01: the Node list shows "No Nodes yet" while the graph is loading or has
     failed. It needs separate loading, error-with-retry, and empty states.
   - R-02: with a search submitted, the list falls back to graph Nodes when
     search is loading, empty, or failed, which hides search errors.
   - R-03: graph search matches body text; sidebar search matches only slug,
     title, and label. Unify them or explain the difference.
   - R-04: the search field allows 256 characters; the API allows 256 UTF-8
     bytes.
   - R-05: check in the app whether refresh resets pan/zoom or flickers.
5. **Static-check baseline.**
   - 10 `golangci-lint` issues, fixed when the backend is next reopened.
   - Migrate `package:flutter/material.dart` to `package:material_ui`.

## P1 — Objectives

The next feature. The design is below.

1. **Objectives v1.**
   - Settle the open decisions below and record the names in
     [vocabulary.md](vocabulary.md).
   - Reopen the backend for Objective state endpoints.
   - Add an Objective log pane, and show the one tracked Objective on the HUD.
2. **Slug rename policy.** Objectives get renamed. Decide between an alias and
   a link rewrite before many exist, since the slug is the only identity.
3. **"What now" home.** When Objectives exist, the tracked Objective and its
   next step become the default view; the full graph stays one click away.
4. **Quick capture.** An inbox Node with an automatic slug, reachable from a
   global hotkey, so a thought can be recorded without choosing a slug.
5. **Claude access.** An MCP server over the existing API (search, read,
   create, Objective state), so Claude can plan from and update the graph.

## P2 — Location plane

1. **Bottom location plane.**
   - A place hierarchy plus native Neo4j `POINT` values.
   - Shares the time plane's camera and plane contract.
   - An Objective with a location becomes a waypoint.
   - Top and right stay unassigned.
2. **Viewport queries for both planes.** Replace the bounded 200-Node overview
   with a query carrying the visible window and an explicit include-undated
   flag. Debounce camera changes, page large results, and never use
   `modified_at` as semantic time.

## P3 — Atlas

Unordered. Pick these up when they serve Objectives or daily use.

- Pagination or clustering for broad graph exploration.
- Visible graph filters and optional `PART_OF`/`FAMILY` relationship layers.
- Rendered Markdown in the reader, keeping source editing.
- Backlinks, connection suggestions, and navigation to unresolved targets.
- **Latest** view of recently changed Nodes. This needs server-side ordering;
  confirm that `modified_at` means what "recent" should mean.
- Importers for new external sources (e.g. Concepts `.concepts`/`.concept`
  exports, new Obsidian vaults). Inspect real sample files first, then define
  identity, duplicate handling, and provenance. The old Obsidian importer was
  removed on 2026-11-19 because its format no longer matches.
- Multi-peer recovery (content hashes, signed change events), after backups.

## Engineering practice

- Ship in small slices the owner can verify in the app before the next one.
  Recent commits of more than 5,000 lines are hard to verify by hand.
- Split `knowledge_workspace.dart` (about 1,250 lines) and `neo4j.go` (about
  1,500 lines) when they are next touched for a feature.

---

## Objectives — design

Status: the name **Objective** is approved (2026-11-19). Everything else in
this section is a proposal until the owner settles the open decisions.

An Objective is a real-world goal the owner commits to reach. The design takes
its mechanics from RPG quest systems but uses professional naming: "Quest"
never appears in code, API, or UI.

| RPG mechanic | Seville |
| --- | --- |
| Main / side quest | Objective priority (proposed: `primary` / `secondary`) |
| Quest objectives with counters ("3/5") | **Key Results** (proposed name): measurable steps, each finishable in one sitting |
| Quest giver | Source: a person, Node, or commitment, as a connection |
| Tracked quest + waypoint | One tracked Objective on the HUD; its next Key Result answers "what now?" |
| Quest log | Objective log: active, completed, failed, abandoned |
| Level, reward, XP | Effort estimate; explicit reward; optional progress per life area |
| Turn-in | Completion writes a short outcome note |
| Prerequisites, chains | `REQUIRES` / `PART_OF` between Objectives |

**Fit with the model.**

- An Objective is a Node with the `Objective` label, not a new entity. It gets
  search, labels, colors, body, and connections for free.
- Its temporal span is its active window or deadline, so it appears on the time
  HUD.
- An optional `POINT` places it on the location plane.
- State (`available → active → completed | failed | abandoned`) is a canonical
  property guarded by `update_count`. State changes are operational events, not
  semantic time.

**Open decisions.**

1. Name and shape of the steps: Key Results as child Nodes `PART_OF` the
   Objective (recommended, since time and location attach there) or a list
   embedded in the body.
2. Priority as `primary`/`secondary`, or a numeric priority.
3. Progress points per life area: keep or drop? Which areas count? If kept,
   award points only for outcomes, never for creating items.
4. What the tracked Objective looks like on the HUD.
