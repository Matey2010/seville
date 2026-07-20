# Seville Flutter Guidelines

See `CUSTOM_LAYOUTS.md` for the complete model → constants → component registry
workflow, including nesting, radial slots, perspective surfaces, responsive
scaling, and animation.

## Layout type taxonomy

- `GridLayout` (**grid-layout**) is the general two-dimensional rectangular
  layout. It owns row/column tracks, fractions, sublayouts, elements, and grid
  styling.
- `TrackLayout` (**track-layout**) is the deliberately boring one-dimensional
  line layout. Concept, era, millennium, century, decade, year, quarter, month,
  and week timelines specialize it.
- `SceneLayout` (**scene-layout**) is the compositional layout for three
  dimensions, including depth.
- `OpenBoxSpatialLayout` (**open-box-spatial-layout**) specializes
  `SceneLayout` into the existing five-surface open-box graph experience.
- `PerceptualMapLayout` (**perceptual-map-layout**) specializes `GridLayout`
  into a center-origin perceptual plane. Its directional guidelines and their
  individual visual styles belong to the layout configuration.
- `CompassLayout` (**compass-layout**) specializes `PerceptualMapLayout` into a
  radial flex container around a typed `CompassMainSlot`. The main slot can own
  any `Layout`; custom sublayouts, triangles, squares, stars, and future central
  interfaces do not require changes to compass geometry. Surrounding
  `CompassSlot` values use clockwise degrees with `0°` at the top. Optional
  `startDegrees` fixes placement and optional `spanDegrees` restricts width.
  Unrestricted slots share the remaining sweep by `LayoutSlot.fraction`; one
  unrestricted slot therefore consumes the full default `360°`.
  `CompassMainFigure` lists layout, circle, triangle, square, and star center
  figures; the selected figure may own a specialized `subLayout`.
  `CompassFrame` defines the layout's normalized bounds inside its parent.
  `positionFraction`, `anchorFraction`, and logical-pixel `translation` place
  the main slot within that frame, allowing animated off-center figures while
  their radial slots continue resolving against the same moving bounds. Grid
  projection, directional guides, radial boundaries, and viewport intersections
  all resolve against the configured frame rather than assuming a full screen.
- `LandscapeXlLayout` (**landscape-xl-layout**) owns the full-screen landscape
  hierarchy. It extends the base `Layout` and nests every child under a stable
  key in `Layout.layouts`; there is no separate depth-node tree, root wrapper,
  role tag, or frame object. `SafeAreaLayout` expresses actual inset behavior
  through its concrete type.
- `LayoutSlot` is the reusable flex-like slot primitive. `fraction`
  controls main-axis share, while optional `span`, `minWidth`, and `maxWidth`
  constrain cross-axis width in the owning configuration's fraction units.
- `Point` is the reusable coordinate entity above raw layout tracks. Each point
  owns a `Map<String, Coord>` keyed by standard or custom aliases.
  `CoordAlias.horizontal`, `vertical`, `depth`, `diagonal`, `angle`, `radius`,
  and `weight` are built in. `Coord` supports fraction, pixel, track, scalar,
  degree, and radian units with start-, center-, or end-relative rules.
- Every `Layout` owns a `Map<String, Layout>`. Its keys are child identities;
  values may be content, `SafeAreaLayout`, `Guideline`, `GuideGrid`, or other
  layouts.
  `Guideline` defines an explicit normalized line and optional arrow;
  `GuideGrid` generates Cartesian guides from layout dimensions.
  `GuideStyle` controls color, width, cap, and solid, dashed, or dotted
  patterns, including dash length and dash interval. A `GuideGrid` additionally
  controls visible axes and full-line versus intersection-dot rendering.
- `PerceptualMapSlot` names every supported perceptual-map anchor: `top`,
  `bottom`, `topRight`, `topLeft`, `bottomRight`, `bottomLeft`,
  `bottomCenter`, `topCenter`, `leftCenter`, `rightCenter`, and `center`.
- `PerceptualMapSlotAlias` provides compact configuration names: `lb` resolves
  to left-bottom, `rb` to right-bottom, and `bc` to the bottom-center triangle
  slots. String aliases can be resolved through `resolve`.
- `PerceptualMapSlotConfig.shape` selects stacked or triangular slot geometry.
  A bottom-center triangle expands from the screen center toward the bottom
  corners while preserving slot fractions and width constraints. Its optional
  `apexSlot` is layer zero and consumes the apex before the regular slots.
- `TimelineGrid` specializes `GridLayout` for the bottom-wall temporal
  hierarchy and its named tracks.

## Core spatial metaphor: OpenBoxSpatialLayout

The spectator looks down into an open box. This viewpoint is the base guideline
for Seville's visual composition. In design terms, it is a **skeuomorphic
five-surface spatial layout shown in top-down cutaway perspective**. Use
**open-box-spatial-layout** as its concise project name and
`OpenBoxSpatialLayout` as the Flutter configuration type.

- The inset central rectangle is the **bottom of the box** and the primary
  knowledge scene. Its corners are defined by layout dimensions, not by ad-hoc
  padding.
- The four regions between the scene and the viewport edges are the **top,
  right, bottom, and left walls**. The open-box model derives each wall's
  perspective coordinates from the parent, scene, and nested walls layout.
- The open-box scene is dimension-based. The current default is
  `defaultOpenBoxLayout` with axes `[40, 10, 6]`: 40 horizontal tracks, 10
  vertical tracks, and 6 depth tracks. These axes are the CSS-grid-like
  skeleton for placing and joining perspective surfaces.
- Layouts are modeled through `Layout`, an abstract base with default axes
  `[0, 0]`, optional row/column/depth fractions, and one recursive `layouts`
  map. Dimensioned grid layouts override those axes. Guide
  geometry and presentation live in that same map as ordinary layouts. Each
  legacy spatial `subLayouts`
  entry is one named record containing both its child `layout` and parent-grid
  `area`; these must never be maintained in parallel maps. This is the project
  equivalent of CSS Grid named areas. `LayoutArea` supports `depth` and
  `depthSpan` alongside row/column spans.
- `SceneLayout` has three dimensions and composes nested surfaces. `GridLayout`
  has two dimensions and describes plain 2D panel surfaces. Every `Layout` may
  define an `elements` map from stable element ids to `LayoutElement` values.
  Each element owns its coordinate area, optional default vault path, visual
  radius, and optional empty-slot style. `TrackLayout` provides one-dimensional
  fractional slots.
  `TimelineGrid` specializes `GridLayout` with timeline identifiers such as
  `TimelineGrid.timeAxis`, `TimelineGrid.nowPointer`, and
  `TimelineGrid.conceptTimeline`. Cross-layout conversion must remain possible
  by translating through normalized layout positions.
- `LayoutDimensions.fromAxes` derives `dimensionCount` from the axes-list length;
  configuration must never repeat it manually. `GridLayout.fromAxes`,
  `SceneLayout.fromAxes`, and `OpenBoxSpatialLayout.fromAxes` hide dimensions
  construction from configuration. Their optional `columnFractions`,
  `rowFractions`, and `depthFractions` work like CSS `fr` units.
- Visible guide grids are painted from `GuideGrid` values in the owning
  layout's `layouts` map. Nested layouts are projected through their configured
  `LayoutArea`, so changing a child layout's row count or fractions also changes
  its visible grid without renderer-specific drawing code.
- Depth is an ordinary layout axis rather than a separate projection model. On
  the 36x6 bottom-wall layout, depth track `0` touches the scene and depth track
  `6` touches the user's screen. Wall areas span that depth directly. The model
  interpolates their visible outer coordinates from `depthSpan` and parent depth
  fractions, without a separate glue model.
- Each wall uses a distinct shade from the same color family so the spectator
  can read their orientation without mistaking them for separate panels.
- Wall guides come from each surface layout's own vertical tracks and fractions.
  The current defaults are four tracks for the top wall, two for the left and
  right walls, and six depth tracks for the bottom wall.
- The bottom wall can be subdivided into panels. Dimension presets are basic
  reusable ratios grouped under `CommonRatio.twoDimension` in
  `layout_axes.dart`, including 9x9, 40x10, 40x40, 120x120, 300x300, 36x36,
  32x6, 36x6, and 36x13. The default open box assigns the bottom wall under
  `defaultWallsLayout.subLayouts['bottom-wall']`.
  Its 36 horizontal segments are hours:
  6 hours from yesterday, 24 hours of the current day, and 6 hours from
  tomorrow.
- The horizontal time axis is the `timeline-track` sublayout of the bottom-wall
  grid and uses `defaultTimelineLayout`. The timeline is currently a 36x13 grid
  projected across the 36x6 bottom wall. Its own visible grid therefore has
  thirteen rows even though its parent wall retains six depth tracks. Two
  scene-facing spacer rows precede timeline content; the first is `2fr` and the
  second is `1fr`. Its `elements` map places the time axis on row `2` and the
  current-day band on row `3`, and the now pointer across rows `0..13`; timeline
  fractions provide interpolation for ticks, labels, and later decorations.
- The current-time pointer is a separate line positioned from local
  `DateTime.now()`. Its x-position is calculated as
  `(6 + current-hour-of-day) / 36`, so it moves through the central 24-hour
  current-day band.
- `defaultConceptTimeline` is a `TrackLayout` nested on timeline row `12`. It
  defines `ConceptTimeline.past`, `ConceptTimeline.now`, and
  `ConceptTimeline.future` with `columnRatio: [1, 4, 1]` and default vault paths
  from `time/concept/`. A future per-vault configuration may replace those
  paths without changing rendering code.
- `defaultEraTimeline` is nested on timeline row `11`. It defines
  `EraTimeline.bce` and `EraTimeline.ce` with `columnRatio: [5, 31]`, using
  `time/era/bce` and `time/era/ce`.
- Millennium, century, decade, year, quarter, month, and week tracks occupy rows
  `10`, `9`, `8`, `7`, `6`, `5`, and `4` respectively. Their fractions align
  compressed historical ranges while allowing the active millennium, century,
  decade, and year to consume the remaining span. The current decade is
  `Twenties`; the configured calendar year is `2026`.
- Quarters and months subdivide the expanded 2026 span proportionally by their
  real day counts. Each month is further divided at Monday-Sunday boundaries;
  partial weeks at month edges receive widths proportional to their actual
  number of days.
- Year, quarter, month, and week elements are configured as slots. Until a
  matching graph node exists, each slot remains unfilled with a dashed `2px`
  border and its configured label. Once a node exists, normal node color and
  title rendering replaces the placeholder treatment.
- Any timeline element with a non-null `defaultPath` is rendered from layout
  configuration. A matching graph node enriches its title and color when
  available, but is not required for visibility. Element discovery recursively
  follows nested sublayouts, so custom tracks and element ids do not require
  renderer changes.
- Timeline-to-node bindings, labeled-node selection, and screen positions are
  cached when graph data changes. Static timeline elements are recorded into a
  reusable picture and disposed/rebuilt only when graph data or viewport size
  changes. Fraction normalization avoids per-frame list allocation.
- Lines from the viewport corners to the scene corners are virtual perspective
  guides. The guides and the border around the scene are dashed to distinguish
  spatial construction from knowledge-graph edges.
- Graph content belongs primarily on the bottom of the box. Peripheral
  information may occupy a wall when that placement reinforces its meaning.

The box must remain responsive. Its scene corners are calculated from viewport
size and layout dimensions rather than stored as fixed screen positions.
Themes may change wall colors, guide colors, and surface treatment while
preserving the five-surface composition and top-down spectator perspective.

## Layout parameters

Every `Layout` accepts `visibility: List<LayoutCondition>`. A layout is visible
only when every configured condition is active for the current `LayoutContext`.
The default empty list is visible because there are no failed conditions. Use
`visibility` for direct show/hide configuration such as no-Node-selected or
has-active-Nodes UI. Use `ConditionalDerivative` when geometry must select
between alternatives. Compose these condition-bearing primitives directly;
layouts do not introduce an intermediate mode or named condition-group layer.
Layout configuration constructs conditions only through `LayoutCondition`
factories. Use `LayoutCondition.not(...)` to negate another condition instead
of addressing concrete condition implementation classes.

`defaultOpenBoxLayout` is the complete default composition.
`OpenBoxSpatialLayout` is a reusable `SceneLayout` subtype, so it can itself be
placed in another layout's `subLayouts`. Its immediate children are deliberately
small:

- parent plane: `defaultOpenBoxLayout`, axes `[40, 10, 6]`
- `defaultWallsLayout`, containing the top, left, right, and bottom grids
- the scene grid, declared directly in the parent's `scene` placement

The walls object owns four placements, each pairing a wall grid with its area
and depth span. The parent similarly owns `walls` and `scene` placements. The
model derives wall coordinates from those spans. Parent fraction arrays
participate in coordinate normalization, while each surface's fractions control
its internal tracks.

Other configured behavior includes:

- bottom wall time axis position: one track behind the bottom-wall lip
- bottom wall now-pointer x-position: calculated from local current time
- concept timeline: Past/Now/Future slots with relative widths `1fr 4fr 1fr`
- layout-owned grid visibility and line styling
- guide color and wall surface colors

`lib/constants/layout_defaults.dart` is the working six-plane configuration:
one open-box parent, one scene grid, and one walls object containing four wall
grids. Each named sublayout declaration contains its layout and area together.
There are no parallel area maps, standalone `LayoutDimensions`, glue
declarations, or abstract namespace classes. Reusable axes presets live in
`lib/constants/layout_axes.dart`. Configuration is ordered from larger to
smaller: `defaultOpenBoxLayout` then `defaultWallsLayout`.
Timeline configuration lives under `lib/constants/timeline/`: layouts are in
`defaults.dart`, while default vault paths are in `paths.dart`.

## Inner and outer circles

Every `Layout` may define an `innerCircle` and an `outerCircle`. Both use the
owning layout bounds as their coordinate space:

- `center` is a normalized `Offset`; `(0.5, 0.5)` is the layout center.
- `radiusFraction` is measured against the layout's shortest side; `0.5`
  touches its nearest edges.
- `Layout.center` resolves to the inner circle's center first, then the outer
  circle's center, and finally `(0.5, 0.5)`.

The circles are geometry references, not mandatory decoration. Add a
`CirleLayout` to `layout.layouts` when either boundary should be visible.
This keeps centering and radial calculations usable even when the circles are
hidden.

## Inner borders and anchors

Every visual layout may expose its meaningful content boundary under
`LayoutKey.innerBorder`. The value is a `LayoutBorderGuide`, so the border stays
inside the same recursive layout map as all other geometry. Borders should be
quiet alignment aids rather than containers: prefer a thin, partially
transparent dashed stroke.

A border may reference the layout bounds, inner circle, or outer circle. A
square referencing a circle is mathematically inscribed in it, so its four
corners touch the circle. Named `Point` values on the border are durable anchors
for later connections, labels, angles, and animation.

## Derivatives and observables

`Layout.derivatives` stores named `LayoutDerivativeSnapshot` values.
`derivativeSnapshot` selects the active snapshot, and `getDerivatives()` always
returns that snapshot unless a different name is requested explicitly. A
derivative is computed from current layout geometry rather than copied into the
preset as a fixed coordinate.

LG Ergo defines A, B, C, and D as `CircleRayIntersectionDerivative` values:
each point is the intersection of the outer circle with a diagonal ray.
`LayoutBorderGuide.derivativeAnchors` consumes those names, making the square a
result of the circle intersections. Resizing or moving the circle therefore
recomputes the square anchors automatically.

`Layout.observables` describes groups of derivative names and their comparison
tolerance. `LayoutDerivativeObserver` establishes a baseline on its first
`evaluate()` call, then notifies listeners with `LayoutDerivativeChange`
records whenever watched resolved points move beyond that tolerance. This is
the layout equivalent of Vue computed values plus watchers: presets remain
immutable, while runtime observers react to changed results.

## Layout attributes

Every `Layout` accepts a list of `LayoutAttribute` values using Flutter's
lower-camel enum convention: `screen`, `rectangular`, `circular`, `triangular`,
`linear`, and `safeArea`. Attributes classify behavior without string tags and
contribute standard derivatives:

- screen, rectangular, and SafeArea layouts provide center, named corners, and
  A–D corner aliases;
- circular layouts provide center and four cardinal circle points;
- triangular layouts provide center and three vertices;
- linear layouts provide start, midpoint, and end.

`getDerivatives()` merges these attribute derivatives first and then the active
explicit snapshot. Explicit derivatives therefore override defaults without
copying the entire characteristic set.

## Rays

`RayLayout` has a fixed starting derivative and a `towards` derivative that
defines its direction. A vector alone has direction and magnitude but no fixed
origin; the scene projection has an origin, so ray is the more useful layout
name. Both references may include a nested `layoutPath` and derivative snapshot,
allowing rays to cross layout boundaries.

LG Ergo defines screen-corner A–D derivatives and draws four rays from the
SafeArea square's derived A–D anchors toward the corresponding physical-screen
corners. The renderer resolves both layouts into screen coordinates before
painting, so SafeArea padding does not distort the correspondence.

## Ordered layout backgrounds

Backgrounds are normal children in `Layout.layouts`. Each
`LayoutBackgroundElement` declares an asset, `orderPosition`, fit, opacity, and
normalized alignment. The frontend selects background children, sorts them by
ascending `orderPosition` and then map key for deterministic ties, and paints
them behind the parent layout's guides and content.

`LayoutBackgroundElement` extends the same base `Layout` as every other
renderable layout type. Configuration and geometry records such as
`LayoutArea`, `LayoutDimensions`, and derivative snapshots remain value objects;
anything that participates as a rendered layout belongs to the `Layout`
hierarchy.

LG Ergo places `assets/please-stand-by.png` at root background position `0`
with `cover` fitting, so it fills the physical screen while preserving its
aspect ratio. A backend may replace or periodically update configuration, but
visual stacking remains a frontend responsibility.

## Screen composition

`main.dart` owns only the application shell and selects
`LandscapeXlLayoutScreen`
as `MaterialApp.home`. The fresh starting hierarchy is declared entirely in
`constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`:

1. `lgErgoLayoutConfig` fills the physical screen.
2. Its `safe-area` child applies Flutter's runtime display insets.
3. The SafeArea layout owns the top and bottom planes so their future controls,
   radial branches, temporal bands, and overlays share one parent context.
4. The SafeArea layout also owns the inner- and outer-circle geometry and their
   visible guide layouts.
5. Its `inner-border` is a square inscribed in the outer circle. A, B, C, and D
   run clockwise from the bottom-left corner, with outward directions derived
   automatically from the square's center.

The screen layout owns four configured dashed `Guideline` entries. Horizontal,
vertical, and both corner-to-corner diagonals span the full screen and intersect
at its center.

New top- and bottom-plane layers are added beneath their respective
`LayoutPath.layouts` maps inside `safe-area`, not beside `safe-area` at the
screen root. Existing graph, perceptual-map, and Compass models remain
available but inactive.

The top plane presents its occurrence-preserving `NodeTree` through a
`FanLayout`. Cardinal fan positions span 180 degrees, angular positions span 90
degrees, and other positions span 360 degrees. Internal bands use a regular
radius and equal angular sections; only the final band conforms to the owning
plane boundary. Its separator endpoints divide the visible polygon boundary by
equal path length so triangular and trapezoidal planes retain equal outer cells.
Fan data matching belongs to the optional `FanLayout.nodeFilter`. Its
`includeNodesMatching` and `excludeNodesMatching` lists contain structured
`NodeSearchParameter` values. They are part of the Riverpod request identity
and are enforced by the tree API before Flame rendering. Include entries are
OR-matched when present, any exclude match rejects, and a rejected occurrence
prunes that branch. Painters and components must not independently reimplement
the filter.

Selected Nodes have an explicit center configuration at
`safe-area/inner-circle-plane/wrapped-scene-square/scene-graph-plane/scene-graph`.
Its transparent `LayoutPath` follows the wrapped scene square. Its `GraphLayout`
renders the complete Riverpod-selected Node pool in equal centered cells, with
each circular Node occupying half of its cell by default. More selected Nodes
therefore produce smaller circles. It is visible only when
`LayoutCondition.not(LayoutCondition.noSelectedNode())` is active and does not
request a `NodeTree`; connections and graph-distance placement remain future
extensions.

`PerceptualMapScreen` lives under `lib/screens/perceptual_map_screen.dart`. It consumes
`defaultPerceptualMapLayout`, a `PerceptualMapLayout` with a 120x120
coordinate plane, layout-owned grid styling, and four dashed directional arrows
from the center. Four solid blue diagonal rays form a secondary X-shaped
orientation guide behind the red cardinal arrows. The blue rays target the
viewport corners, so their angles adapt to screen aspect ratio and are not
forced to remain perpendicular. Both guideline families span fully to the
viewport edges. Its `bottomCenter` slot is a full center-to-bottom triangle with
eleven equal layers: Now, Day, Week, Month, Quarter, Season, Year, Decade,
Century, Millennia, and Era. The neighboring `bottomLeft` and `bottomRight`
triangles repeat the same eleven-band structure. They occupy 7:30–9 o'clock
and 3–4:30 respectively. `Prev` and `Next` occupy apex layer zero; `Yesterday`
and `Tomorrow` occupy layer one immediately after them. Navigation and
screen-switching state is intentionally deferred.

## Row and column composition

Use `ColumnLayout` and `RowLayout` when content has semantic interface order
that must remain independent from a plane's perspective-grid axes. Their
children remain in `Map<String, Layout> layouts`, where each map key is the
child's stable identity.

Every `Layout` owns a `GridAxisVariable size`. A row resolves child sizes along
its horizontal main axis; a column resolves them along its vertical main axis.
Use the same track vocabulary used elsewhere:

- `LayoutSize.fr(value)` consumes a weighted share of remaining space;
- `LayoutSize.px(value)` (or `pt`) consumes a fixed visual extent; and
- `LayoutSize.calculatedFr(...)` keeps computed fractional sizing available.

`LayoutSize` is the global axis-sizing entity formerly named `GridTrackSize`.
Renderable components derive geometric extent from their owning layout rather
than carrying a parallel viewport-size abstraction.

Do not add parallel `flex`, `extent`, width, or height fields to composition
layouts. For example, a browser-like action surface is expressed as a column
containing fixed-pixel navigation and action rows around a `1fr` content panel.
Nested row children use their own `size` values for button proportions.

## Flutter code structure

The Flutter interface is built from explicit models, constants, utilities, and
rendering components. Do not spread design-system concepts across widgets and
components just because that is where they are first used.

Model files are ordered around their reason for existence. After imports, put
the primary public model first, followed by its conditions, context, and
immediately related definitions. Supporting typedefs, key constants, enums,
helper value objects, and concrete variants follow the headliner. File
organization should let a reader understand the stable public shape before
encountering its interchangeable implementation vocabulary.

- `lib/models/` contains durable interface and graph models: semantic data
  types, layout presets, dimension primitives, and other objects that describe
  the world.
- `lib/screens/` contains complete application surfaces. Screens consume layout
  models and rendering utilities but do not own reusable spatial rules.
- `lib/constants/` contains shared constant values: colors, dimensions, tokens,
  layout defaults, and other literal values that are reused or define visual
  language. Update reusable layout presets in
  `lib/constants/layout_defaults.dart`.
- `lib/utils/` contains small reusable helpers: drawing helpers, formatting
  helpers, geometry helpers, and other stateless operations.
- `lib/graph/` contains graph-specific rendering and layout behavior. It may
  consume models, constants, and utils, but it should not define broad interface
  models or shared tokens inline.
- Flame components orchestrate and render interface content. Flutter widgets
  are limited to application composition, the `GameWidget` host, and an
  explicitly introduced HUD. No HUD exists today: panels, controls, overlays,
  graphs, and layout content remain Flame components. Neither layer stores
  global design rules, raw color systems, layout presets, or reusable helper
  algorithms.

If a concept can be named independently from the widget currently using it,
promote it into the appropriate folder before adding more behavior around it.
Before creating a new model, layout type, guide type, renderer concept, painter
helper, or configuration object, first inspect the nearby layout/model/utility
code and decide whether the existing entity should be reused or extended. New
entities are appropriate when the project owner explicitly asks for one or when
reuse would make the existing abstraction lie. Related geometry must stay
related in code: derive wrappers, rings, connectors, and anchors from the same
source shape instead of maintaining independent values that only visually align.

## Quality verification

The Flutter interface does not contain or run automated tests. Do not add unit,
widget, integration, golden, snapshot, or system tests. Do not add test
dependencies, test directories, Xcode test targets, test runners, or pipeline
steps that execute tests. Test coverage is not accepted as evidence that a
layout or interaction still behaves correctly after a change.

Automated verification is limited to formatting and static analysis. The
project owner exclusively performs final visual, interaction, build, and
runtime verification in the real macOS application.

## Guidelines

A guideline is the interface equivalent of the Ukrainian term
_направляюча лінія_. It is a non-content alignment aid and must therefore be
visually distinct from graph edges and the box's perspective seams.

Structural perspective guides are red and dashed. This includes the primary
horizontal and vertical guidelines, the box-bottom border, and the corner
perspective seams. Every alignment aid is a `Guideline` or `GuideGrid` inside
`Layout.layouts`. Shared `GuideStyle` supports solid, dashed, and dotted
patterns, configurable dash length and interval, stroke width, color, and cap.
`drawGuideGrids` projects Cartesian guide grids onto rectangular and
perspective surfaces and recursively follows nested two-dimensional layouts.
Explicit guidelines
use normalized endpoints, so later editing tools can add, remove, or reposition
them without changing layout subclasses or graph rendering.

The current geometry and rendering live in
`lib/graph/graph_field.dart`. The open-box layout model lives in
`lib/models/open_box_spatial_layout.dart`, reusable dimension primitives live in
`lib/models/layout.dart`, timeline-specific grid identifiers live in
`lib/models/timeline_grid.dart`, the Past/Now/Future track lives in
`lib/models/concept_timeline.dart`, and the BCE/CE track lives in
`lib/models/era_timeline.dart`. The second-screen layout lives in
`lib/models/perceptual_map_layout.dart`; the active compass layout lives in
`lib/models/compass_layout.dart`. The recursive screen/safe-area/scene hierarchy lives in
`lib/models/landscape_xl_layout.dart`. Default dimensions and layout presets live in
`lib/constants/layout_defaults.dart`, reusable guide entities live in
`lib/constants/layout_guides.dart`, perceptual-map defaults live in
`lib/constants/perceptual_map_defaults.dart`, the active hierarchy preset lives
in `lib/constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`,
timeline defaults live under `lib/constants/timeline/`, shared colors live in
`lib/constants/interface_colors.dart`. Flame components own rendering and use
the canvas primitives in
`lib/utils/guide_grid_painter.dart`, explicit guideline drawing lives in
`lib/utils/layout_guidelines.dart`, perceptual slot drawing lives in
`lib/utils/perceptual_map_slots.dart`, generic degree-based compass slot drawing
lives in `lib/utils/compass_slots.dart`, generic center-figure drawing lives in
`lib/utils/compass_figure_painter.dart`, and dashed guide drawing lives in
`lib/utils/canvas_guides.dart`. Recursive layout composition, SafeArea geometry,
and the `GameWidget` host live in `lib/widgets/landscape_xl_layout_view.dart`;
the layout render tree inside that host is composed entirely of Flame
components.
