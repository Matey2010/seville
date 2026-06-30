# Seville Flutter Interface Guidelines

## Core spatial metaphor: OpenBoxSpatialLayout

The spectator looks down into an open box. This viewpoint is the base guideline
for Seville's visual composition. In design terms, it is a **skeuomorphic
five-surface spatial layout shown in top-down cutaway perspective**. Use
**open-box-spatial-layout** as its concise project name and
`OpenBoxSpatialLayout` as the Flutter configuration type.

- The inset central rectangle is the **bottom of the box** and the primary
  knowledge scene.
- The four regions between the scene and the viewport edges are the **top,
  right, bottom, and left walls**.
- Each wall uses a distinct shade from the same color family so the spectator
  can read their orientation without mistaking them for separate panels.
- Wall-row guides divide each wall into placement rows. The current default is
  two rows for the top, right, and left walls, and three rows for the bottom
  wall.
- The bottom wall can be subdivided into grid panels. Grid sizes are basic
  reusable primitives, including `DefaultGrid.g9x9`, `DefaultGrid.g36x36`,
  `DefaultGrid.g32x6`, and `DefaultGrid.g36x6`. The current desktop
  layout assigns `OpenBoxSpatialLayout.defaults.desktop.bottomWallGrid` to that
  36x6 grid. Its 36 horizontal segments are hours: 6 hours from yesterday,
  24 hours of the current day, and 6 hours from tomorrow.
- The first strong line on the bottom wall is a configurable horizontal time
  axis. It lives on the lid/lip line where the bottom wall meets the box bottom
  and is controlled by `bottomWallTimeAxisY`.
- The current-time pointer is a separate line positioned from local
  `DateTime.now()`. Its x-position is calculated as
  `(6 + current-hour-of-day) / 36`, so it moves through the central 24-hour
  current-day band.
- Nodes can be explicitly assigned to bottom-wall grid cells through
  `OpenBoxSpatialLayout.defaults.desktop.bottomWallNodePlacements`. The current
  default places the `time/concept/now` node across the two center cells of the
  bottom row on the 36x6 grid.
- Lines from the viewport corners to the scene corners are virtual perspective
  guides. The guides and the border around the scene are dashed to distinguish
  spatial construction from knowledge-graph edges.
- Graph content belongs primarily on the bottom of the box. Peripheral
  information may occupy a wall when that placement reinforces its meaning.

The box must remain responsive. Its scene corners are calculated from viewport
size and shared padding constants rather than stored as fixed screen
coordinates. Themes may change wall colors, guide colors, and surface treatment
while preserving the five-surface composition and top-down spectator
perspective.

## Layout parameters

`OpenBoxSpatialLayout` owns the layout family, while its `desktop` sub-entity
owns the geometry and visual parameters for the current Flutter interface:

- viewport-to-scene padding: horizontal, top, and bottom padding
- scene depth: where the box bottom ends vertically inside the viewport
- wall rows: independent row counts for top, right, bottom, and left walls
- bottom wall grid: a reusable `LayoutGrid`, currently `DefaultGrid.g36x6`,
  rendered directly on the bottom wall surface
- bottom wall time axis y-position: currently on the lip line of the bottom wall
- bottom wall now-pointer x-position: calculated from local current time
- bottom wall node placements: explicit node-to-grid-cell assignments, currently
  placing `time/concept/now` on the two bottom-center cells
- guide color and wall surface colors

The initial desktop configuration uses `DefaultGrid.g36x6`, two rows for the
top, right, and left walls, and three rows for the bottom wall.

## Flutter code structure

The Flutter interface is built from explicit models, constants, utilities, and
rendering components. Do not spread design-system concepts across widgets and
components just because that is where they are first used.

- `lib/models/` contains durable interface and graph models: semantic data
  types, layout presets, grid primitives, and other objects that describe the
  world.
- `lib/constants/` contains shared constant values: colors, dimensions, tokens,
  and other literal values that are reused or define visual language.
- `lib/utils/` contains small reusable helpers: drawing helpers, formatting
  helpers, geometry helpers, and other stateless operations.
- `lib/graph/` contains graph-specific rendering and layout behavior. It may
  consume models, constants, and utils, but it should not define broad interface
  models or shared tokens inline.
- Widgets and Flame components should orchestrate and render. They should not
  become storage for global design rules, raw color systems, layout presets, or
  reusable helper algorithms.

If a concept can be named independently from the widget currently using it,
promote it into the appropriate folder before adding more behavior around it.

## Quality verification

Seville does not use unit tests as a quality gate for the interface. Do not add
unit tests by default. The project favors higher-level verification:

- static analysis for code correctness and lint-level feedback
- real builds to prove the application still compiles as an application
- manual visual review for spatial/interface decisions
- integral and system testing for full user flows when those flows stabilize

Verification ownership belongs to the project owner. After each Codex task,
Codex should provide concrete directions for how the project owner can verify
the change manually or through integral/system checks. Codex may report commands
it ran, but the final verification result is decided by the project owner.

Avoid adding narrow widget, function, or unit tests. If an automated check is
added later, it should protect a stable integration contract or a system-level
behavior rather than freeze temporary implementation details.

## Guidelines

A guideline is the interface equivalent of the Ukrainian term
_направляюча лінія_. It is a non-content alignment aid and must therefore be
visually distinct from graph edges and the box's perspective seams.

All structural guides are red and dashed. This includes the primary horizontal
and vertical guidelines, the box-bottom border, the corner perspective seams,
and the wall-row divisions. Row divisions are calculated from each wall's row
count, so walls can be split into different densities without hardcoded guide
positions. The primary guides span the full viewport and cross at the center of
the box bottom. They are implemented as reusable `GuidelineComponent` instances
so later editing tools can add, remove, or reposition guides without changing
graph rendering.

The current geometry and rendering live in
`lib/graph/graph_field.dart`. The open-box layout model lives in
`lib/models/open_box_spatial_layout.dart`, reusable grid primitives live in
`lib/models/layout_grid.dart`, shared colors live in
`lib/constants/interface_colors.dart`, and dashed guide drawing lives in
`lib/utils/canvas_guides.dart`.
