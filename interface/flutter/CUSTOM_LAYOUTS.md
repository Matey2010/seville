# Defining custom layouts

Seville separates layout data from Flutter rendering:

1. A `Layout` subclass describes durable structure.
2. Constants create the default configuration.
3. A widget or painter renders that model.
4. `LayoutRendererRegistry` connects the model type to its renderer.
5. A parent layout places it under a stable key in `Layout.layouts`.

Do not start by inventing a new entity. First inspect the related layout,
guide, derivative, path, grid, plane, and renderer types already in the
codebase. If an existing concept can honestly represent the behavior, extend or
configure that concept. Add a new model or renderer only when the project owner
explicitly asks for a new thing or when reuse would make dependencies unclear.
Geometry that depends on other geometry must be encoded as a dependency:
wrapping squares derive from the circles or planes they wrap, rings derive from
the plane radius they describe, and connector guides target the same anchors
that the visible shapes use.

## 1. Define the model

```dart
import 'layout.dart';

class OrbitLayout extends Layout {
  const OrbitLayout.fromAxes({
    required super.axes,
    required this.ringCount,
    super.layouts,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final int ringCount;
}
```

Keep the model immutable. Store configuration, topology, slot ownership, and
relationships here; do not store `BuildContext`, viewport pixels, animation
controllers, or mutable UI state.

## 2. Create constants

```dart
const defaultOrbitLayout = OrbitLayout.fromAxes(
  axes: [12, 12],
  ringCount: 4,
  layouts: {
    'orbit-grid': GuideGrid(
      renderMode: GuideGridRenderMode.intersections,
      intersectionSize: 2,
      style: GuideStyle(color: Color(0x334B5563)),
    ),
    'orbit-axis': Guideline(
      start: Offset(0.5, 0),
      end: Offset(0.5, 1),
      style: GuideStyle(
        color: Color(0xCCDC2626),
        pattern: GuideLinePattern.dashed,
        dashLength: 8,
        dashInterval: 6,
      ),
    ),
  },
);
```

Prefer normalized fractions for positions and sizes. They scale across users'
screens and remain independent from macOS window dimensions.

Guides are layouts. Put `Guideline` and `GuideGrid` values directly into
`Layout.layouts`; their map keys are their identities. `GuideStyle` supports
solid, dashed, and dotted patterns. Omitting a guide layout removes it.

A `Guideline` can also own line-local derivatives and markers. Use these when
the point belongs to the guide itself rather than to the whole screen or scene:

```dart
Guideline(
  start: Offset(0, 0),
  end: Offset(1, 1),
  style: diagonalStyle,
  guidelineDerivatives: {
    'center': GuidelineFractionDerivative(0.5),
  },
  markers: [
    GuidelineMarker(derivative: 'center', label: '🎯'),
  ],
)
```

The marker resolves from the guide's normalized start/end points at paint time,
so it remains aligned when the viewport changes.

## 3. Create the renderer

```dart
class OrbitView extends StatelessWidget {
  const OrbitView({required this.layout, super.key});

  final OrbitLayout layout;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: OrbitPainter(layout),
      size: Size.infinite,
    );
  }
}

Widget buildOrbitLayout(
  BuildContext context,
  Layout layout,
  LayoutRendererRegistry registry,
) {
  return OrbitView(layout: layout as OrbitLayout);
}
```

The renderer can be a normal widget, `CustomPainter`, Flame component, or a
composition of those. The model does not care.

## 4. Register it

```dart
final appLayoutRendererRegistry = defaultLayoutRendererRegistry.extended({
  OrbitLayout: buildOrbitLayout,
});

LandscapeXlLayoutScreen(
  rendererRegistry: appLayoutRendererRegistry,
);
```

Registry lookup uses the layout's exact runtime type. Every new concrete layout
type needs one registration. Registered layouts work both as hierarchy nodes
and as Compass main-slot sublayouts.

## 5. Put it inside the Compass main slot

```dart
final orbitCompass = configuredCompassLayout.copyWith(
  mainSlot: configuredCompassLayout.mainSlot.copyWith(
    figure: CompassMainFigure.layout,
    subLayout: defaultOrbitLayout,
    positionFraction: const Offset(0.5, 0.5),
    anchorFraction: const Offset(0.5, 0.5),
    availableSizeFraction: const Size(0.35, 0.35),
  ),
);
```

- `positionFraction` places the anchor inside `CompassFrame`.
- `anchorFraction` chooses the point inside the sublayout attached there.
- `availableSizeFraction` sizes custom layout figures without fixed pixels.
- `translation` adds runtime logical-pixel movement for animation.

The main figure can instead be `circle`, `triangle`, `square`, or `star`.
`CompassFigureConfig` controls size, rotation, fill, border, and parallel
internal lines.

Use `Point` when placement requires named coordinate logic:

```dart
const pointA = Point(
  id: 'A',
  coordinates: {
    CoordAlias.horizontal: Coord.fraction(0),
    CoordAlias.vertical: Coord.fraction(1),
    CoordAlias.diagonal: Coord.scalar(0),
    CoordAlias.weight: Coord.scalar(1.5),
  },
);
```

The coordinate map accepts custom string aliases in addition to the built-in
aliases. `CoordRule.fromStart`, `fromCenter`, and `fromEnd` control the origin;
units include fraction, pixels, tracks, scalar metadata, degrees, and radians.
The same point can resolve against a small sublayout or the physical screen,
which keeps cross-depth connectors logically aligned.

## 6. Define radial slots

```dart
const activitySlot = CompassSlot(
  slot: LayoutSlot(id: 'activity', label: 'Activity'),
  startDegrees: 215,
  spanDegrees: 60,
);
```

Compass degrees are clockwise and `0°` points upward. `startDegrees` fixes an
absolute start. `spanDegrees` fixes angular width. Slots without
`spanDegrees` split the remaining configured sweep according to
`LayoutSlot.fraction`; one unrestricted slot receives all `360°`.

A slot's optional `layout` field establishes ownership of a nested layout.
Rendering that nested layout into a curved wedge is intentionally separate
from ownership and can be implemented by its painter.

## 7. Add hierarchy depth

The default hierarchy is:

```text
screen
└── safeArea
    ├── outer-circle
    ├── inner-circle
    ├── inner-border (inscribed square with A–D anchors)
    └── content added later...
```

Start from `lgErgoLayoutConfig` in
`constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`. Add subsections
directly to a parent layout's `layouts` map. Use `SafeAreaLayout` when a child
must respect macOS display insets; no role or frame metadata is required.

Every layout may also declare normalized `innerCircle` and `outerCircle`
geometry. Use `Layout.center` as the canonical center reference and add
`CirleLayout` values to `layouts` only when those boundaries should be painted.
Circle visibility and style are configured like any other guide; for example
the LG Ergo scene paints its inner circle with a purple dashed `GuideStyle`
declared in the preset constants.

Classify layouts with Flutter-style `LayoutAttribute` values such as
`screen`, `rectangular`, `circular`, `triangular`, `linear`, and `safeArea`.
Attributes contribute standard derivatives automatically; explicit derivative
snapshots override values with the same names.

Use `LayoutKey.innerBorder` for a layout's meaningful content boundary. Store a
`LayoutBorderGuide` there and provide named `Point` anchors when other layouts
will connect to its corners or edges. `showAnchorDirections` derives outward
directions from the border center without four manually configured vectors.

For calculated geometry, place named snapshots in `Layout.derivatives`, select
one with `derivativeSnapshot`, and consume its names through
`derivativeAnchors`. Register derivative groups in `Layout.observables` and use
`LayoutDerivativeObserver.addListener()` when runtime code must react to a
resolved point changing.

Use `RayLayout` when geometry starts at one derivative and points toward
another. `LayoutDerivativeReference.layoutPath` addresses nested layouts, so a
ray can connect scene geometry to screen geometry without copying either
coordinate.

Put `LayoutBackgroundElement` values directly in the parent `Layout.layouts`
map. Lower `orderPosition` values paint first; guides and content always remain
above background children.

## 8. Project a grid inside a path

Use `LayoutPath.grid` to divide a quadrilateral into ordinary rows and columns
while retaining the path's perspective:

```dart
LayoutPath(
  points: [screenA, sceneA, sceneD, screenD],
  style: planeStyle,
  grid: PerspectiveGridLayout(
    guideStyle: dashedGridStyle,
    rowsConfig: {
      'timeline': GridAxisVariable(size: GridTrackSize.pt(20)),
      'hour': GridAxisVariable(size: GridTrackSize.fr(1)),
      'day': GridAxisVariable(size: GridTrackSize.fr(1)),
      'week': GridAxisVariable(size: GridTrackSize.fr(1)),
    },
    columnsConfig: {
      'past-pointer': GridAxisVariable(size: GridTrackSize.pt(20)),
      'previous': GridAxisVariable(size: GridTrackSize.fr(1)),
      'current': GridAxisVariable(size: GridTrackSize.fr(1)),
      'next': GridAxisVariable(size: GridTrackSize.fr(1)),
      'future-pointer': GridAxisVariable(size: GridTrackSize.pt(20)),
    },
    areas: {
      'current-day': PerspectiveGridArea(
        row: 'day',
        column: 'current',
        aliases: ['today'],
        label: 'today',
      ),
    },
  ),
)
```

`rowsConfig` and `columnsConfig` are ordered maps of the same `GridAxisVariable`
type. The map key is the track identity, so identity and measurement cannot
drift apart as they could with parallel ID and fraction lists.
`GridTrackSize.fr` divides remaining space, while `GridTrackSize.px` preserves a
fixed logical-pixel width; `GridTrackSize.pt` is its readable alias.
`GridTrackSize.calculatedFr` is a Vue-like calculated track: it behaves like its
fallback fraction today, and its `derivative` names the future layout/context
value that should drive it.

The current LG Ergo preset removes `now` from the grid itself. `now` is a red
overlay `RayLayout`, while the base plane keeps equal `previous`, `current`, and
`next` columns. Calculated derivatives can drive future overlay layers, for
example
`now-in-current-hour.passed`, `now-in-current-hour.left`,
`now-in-current-day.passed`, and `now-in-current-day.left`. The current LG Ergo
bottom time grid keeps the base plane simpler: rows `hour`, `day`, and `week`
share `previous`, `current`, and `next` columns, while fine passed/left
adjustment belongs to a later timeline-point layer. The surrounding screen
and safe-area anchors stay unpadded; each plane owns its own padding tracks via
`LayoutPath.padding` with `lgErgoLayoutDefaults.padding`. The `left-plane`
provides the 12-segment x/space plane between scene-left and screen-left; its
grid contains only the real space rows, not fake padding tracks. The scene inner
circle uses the owning layout's `padding + borderWidth` as an inset, while the
outer circle remains the scene boundary for anchors and shape framing.

`areas` owns content and paint independently from track geometry. An area
references its starting row and column by their stable map keys, then spans
tracks with `rowSpan` and `columnSpan`. `GridSpan.full` means from the starting
track through every remaining track, including rows added later.
`rowOffset` and `columnOffset` allow fractional placement inside the starting
track, so an area can span, for example, one full column plus half of the next.

Fills are painted before the dashed grid, keeping structural lines visible.
`PerspectiveGridArea.borderStyle` can draw dashed border-only areas, useful for
wrapping an outer padded rim and an inner content rim inside the same
perspective grid.
`topStartIndex`, `topEndIndex`, `bottomStartIndex`, and
`bottomEndIndex` select the four path points used for projection.

## 9. Add a human scale figure to a scene

`StickmanLayout` is a renderable layout entity for the center-scene human scale
reference. Put it in the owning scene/safe-area `layouts` map:

```dart
'scene-stickman': StickmanLayout(
  aliases: ['stickman', 'person', 'human-scale'],
  heightCm: 200,
  rangeStart: -0.1,
  rangeEnd: 1.1,
  style: stickmanStyle,
),
```

The body itself is drawn in logical vertical `0..1`, where `1.0` equals
`heightCm`. The render frame can extend outside that body range; `-0.1..1.1`
means 20cm of conceptual space around a 200cm figure. When the parent layout has
an `outerCircle`, the figure is fitted into the inscribed scene square of that
circle.

## 10. Preview graph nodes inside a scene

`GraphPreviewLayout` is a lightweight placeholder for future graph-backed
content. It draws normalized circle nodes and optional edges inside the same
scene frame used by `StickmanLayout`, so constants can sketch graph intent
before database nodes are connected:

```dart
'scene-graph-preview': GraphPreviewLayout(
  aliases: ['graph-preview', 'knowledge-preview'],
  nodeStyle: nodeStyle,
  edgeStyle: edgeStyle,
  nodes: [
    GraphPreviewNode(id: 'self', position: Offset(0.5, 0.05)),
    GraphPreviewNode(id: 'memory', position: Offset(0.34, 0.13)),
  ],
  edges: [GraphPreviewEdge(from: 'self', to: 'memory')],
),
```

Node positions are normalized to the scene square: `Offset(0, 0)` is top-left,
`Offset(1, 1)` is bottom-right. Use this for visual prototypes only; replace it
with graph/database-backed layout data when the graph layer is ready.

## 11. Animate without mutating constants

Keep defaults immutable and derive transient layouts in `AnimatedBuilder`:

```dart
AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    final t = Curves.easeInOut.transform(controller.value);
    final animatedMainSlot = configuredCompassLayout.mainSlot.copyWith(
      positionFraction: Offset.lerp(
        const Offset(0.5, 0.5),
        const Offset(0.65, 0.42),
        t,
      ),
      figureConfig:
          configuredCompassLayout.mainSlot.figureConfig?.copyWith(
            rotationDegrees: 90 + 90 * t,
          ),
    );
    return CompassView(
      layout: configuredCompassLayout.copyWith(mainSlot: animatedMainSlot),
      rendererRegistry: appLayoutRendererRegistry,
    );
  },
);
```

Animate normalized position, fractions, degrees, and depth for device-independent
motion. Use logical-pixel `translation` only for short local effects. For many
simultaneously animated graph objects, keep the immutable layout as topology
and move per-frame transforms into a `CustomPainter`, Flame component tree, or
GPU shader.
