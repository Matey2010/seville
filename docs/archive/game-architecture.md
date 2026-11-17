# Seville 2D Game Architecture (archived)

This document records the former in-client game direction. The knowledge
client no longer includes its gameplay kernel, systems, or world layout.
Game development is delegated outside this repository's active client plan.

## Goal

Seville grows into a 2D persistent world without discarding its existing Flame
renderer, declarative Layout tree, Riverpod application state, Node model, or Go
API boundary. Terraria is the main reference for world interaction and
multiplayer authority. The Sims 3 is the main reference for composable actor
simulation. See [`REFFERENCES.md`](../../REFFERENCES.md).

The first game slice establishes extension points before committing the project
to one combat model, one stat list, or one network package.

## Runtime boundary

```text
Flutter app and transient overlays
                |
                v
LandscapeXlLayoutGame (FlameGame + collision detection)
                |
                v
GameplayKernel
  |             |                 |
  v             v                 v
CollisionSystem RpgSystem         MultiplayerSystem
  |             |                 |
Flame hitboxes  composable rules  authoritative messages
```

`LandscapeXlLayoutGame` remains the current game host. `GameplayKernel` is a
Flame component inside it, so systems share Flame's lifecycle and deterministic
frame ordering without importing Riverpod providers. Existing Layout components
remain responsible for their own paint and hit geometry.

## Gameplay systems and events

`GameplaySystem` is the extension boundary for independent simulation
concerns. Systems have stable IDs, explicit update order, and receive queued
`GameplayEvent` values through `GameplayKernel`. Events produced during a frame
are delivered at the start of the next gameplay update, which prevents one
collision callback from mutating another system midway through its update.

New systems should own one concern. Examples include inventory, crafting,
combat, status effects, quests, time, weather, and world generation. A system
must not become a generic service locator or a second application-state store.

## Collision counting

The Flame game uses `HasCollisionDetection`. A physical actor extends
`CollisionBodyComponent` and adds the Flame hitbox or hitboxes matching its
rendered body. Collision starts and ends become gameplay events.

`CollisionSystem` counts a collision once when a pair of actor IDs first makes
contact. It keeps a reference count underneath so callbacks from both bodies or
multiple hitboxes do not inflate the total or end an active pair too early. Its
`ValueNotifier<CollisionSnapshot>` exposes the lifetime count and active pairs
to a future Flame HUD or diagnostics panel without making rendering part of the
collision model.

Example component:

```dart
class PlayerBody extends CollisionBodyComponent {
  PlayerBody({required super.actorId, required super.gameplay});

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox());
  }
}
```

Movement resolution and physics response are deliberately separate from
counting. A later movement or physics system can resolve contact while the
counter remains a stable diagnostic and gameplay signal.

## RPG composition

`RpgSystem` owns runtime `RpgActor` state. Stats use open-ended `RpgStatKey`
values, and modifiers are keyed by source so equipment or an effect can replace
or remove its contribution without reconstructing the complete stat.

Behavior is supplied by ordered `RpgRule` modules. Combat, needs, skills,
crafting, progression, AI, and status effects should be separate rules that
respond to gameplay events and update only their own concern. This avoids a
single inheritance hierarchy such as `Player -> Warrior -> FireWarrior` and
keeps future content data-driven.

A gameplay actor is runtime simulation state. A Seville `Node` remains the
canonical durable data unit. A future actor may reference a Node for authored
identity or content, but it must not silently turn transient position, velocity,
or presence into durable graph properties.

## Layout-owned HUD

The game world and its HUD remain in one declarative Layout tree. LG Ergo's
`game-scene` is a nested `GridLayout`: its `scene-graph` child is the world
surface and its `possessions` `RowLayout` is HUD composition. The Flame Graph
component paints below the ordinary Layout scene, so Layout panels, creation
controls, and possessions remain readable and interactive above the world.

The scene uses `LayoutCondition.gameplay()` as its visibility gate. Continue
switches the Riverpod-owned base scene from menu to gameplay; Escape or the
close panel switches it back without clearing selected Nodes. Creation drafts
still take precedence as the node-creation scene. Its small
Layout-owned status strip identifies the registered Collision, RPG, and
Multiplayer systems while the world surface remains visibly distinct from the
surrounding HUD.

The nested world scale is 500m wide and 200m tall. The reusable Character
creator body remains a physical 1m × 2m model, but the gameplay view gives it a
15× perspective footprint: 15m × 30m. Its row tracks are `85m + 30m + 85m`,
and its columns are `242.5m + 15m + 242.5m`, so the midpoint stays exactly at
world `(250m, 100m)` while the character appears 2.5 times closer than the
previous 6× view. Ground begins below the projected feet at world `y = 115m`;
independently selected `LayoutBackground.random(...)` SVG layers occupy the
space above the projected head. The Graph and world-scale Grid remain siblings
beneath the Layout HUD.

`GameplayKernel.update()` always delegates to Flame's component update after
dispatching queued events. Empty event frames must still update child systems;
otherwise continuous rules such as RPG simulation silently stop.

Typography, text flow, contrast colors, labels, panels, and backgrounds continue
to resolve through Layout inheritance. Localization keys, bidi direction, font
fallbacks, and color-vision profiles should extend this same configuration and
renderer resolution path; they must not become painter-local switches or a
parallel Flutter-widget HUD. `LayoutTextFlow` remains spatial text orientation,
not bidi direction.

## Multiplayer foundation

`MultiplayerSystem` has a transport interface and a server-authoritative message
flow:

1. the client connects with a world ID and player ID;
2. the authority sends a complete world snapshot;
3. the client sends commands describing intent;
4. the authority validates and broadcasts ordered world deltas; and
5. presence is broadcast separately from durable world state.

Only `WorldSnapshotMessage`, `WorldDeltaMessage`, and
`PlayerPresenceMessage` enter the gameplay event stream. A local command is not
applied as truth before an authoritative delta returns. Server ticks let the
client discard stale messages and provide the ordering seam needed for later
prediction and reconciliation.

`InMemoryMultiplayerServer` and `InMemoryMultiplayerTransport` provide the first
working authority. Multiple in-process clients can join the same world, observe
presence, submit commands, and receive the same ordered deltas. The transport
can later be replaced by WebSockets without changing RPG rules or world
components. Its replaceable world reducer validates the same command-to-state
boundary a production server will own, while the default reducer retains the
latest accepted payload for each command type so late joiners receive useful
snapshot state.

The in-memory authority is not a production network server. The next networked
slice belongs in the Go API and should add authentication, command validation,
rate limits, reconnect snapshots, heartbeat/expiry, and protobuf contracts
before exposing remote play.

## Next vertical slices

1. Add a tile-world Layout/component pair whose paint, hitbox, and coordinate
   conversion use one geometry source.
2. Add controllable actor movement and collision response, then expose the
   collision count through a Flame-rendered diagnostic panel.
3. Add inventory and health as the first `RpgRule` modules.
4. Define protobuf command, snapshot, delta, and presence envelopes and host
   them over authenticated Go WebSockets.
5. Add client interpolation first; add prediction and reconciliation only for
   movement that needs it.

The project owner continues to run and verify the macOS application. The Sims 3
for Windows is a design reference, not a declaration that Seville currently
supports Windows.
