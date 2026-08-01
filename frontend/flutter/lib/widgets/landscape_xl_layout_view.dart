import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart' show HasKeyboardHandlerComponents;
import 'package:flame/events.dart' as flame_events;
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart' hide TableRow;
import 'package:seville_proto/seville_proto.dart';

import '../audio/background_music_controller.dart';
import '../components/layout_component_registry.dart';
import '../components/classification_label_component.dart';
import '../components/graph_layout_component.dart';
import '../components/node_component.dart';
import '../components/node_layout_component.dart';
import '../components/search_hud_component.dart';
import '../constants/typography.dart';
import '../domain/node.dart';
import '../models/layout/layout.dart';
import '../utils/canvas_guides.dart';
import '../utils/layout_guidelines.dart';
import '../utils/vault_node_resolver.dart';

typedef LandscapeXlLayoutTapCallback = void Function(LayoutTapTarget target);

class LayoutTapTarget {
  const LayoutTapTarget({
    required this.key,
    required this.layout,
    this.node,
    this.resolvedNode,
    this.label,
    this.tableAction,
    this.textValue,
  });

  final String key;
  final Layout layout;
  final VaultNode? node;
  final ResolvedVaultNode? resolvedNode;
  final String? label;
  final TableAction? tableAction;
  final String? textValue;
}

class LandscapeXlLayoutView extends StatefulWidget {
  const LandscapeXlLayoutView({
    required this.layout,
    this.componentRegistry = const LayoutComponentRegistry(),
    this.vaultNodeResolver,
    this.systemInfo,
    this.nodeTrees = const {},
    this.nodeLayoutNodes = const {},
    this.queryNodes = const [],
    this.highlightedNodes = const [],
    this.selectedNodes = const [],
    this.onLayoutTap,
    required this.searchValue,
    required this.onSearchSubmitted,
    required this.onSearchNodeSelected,
    required this.onCancel,
    required this.onRefreshFanData,
    required this.onCopySelectedNodeSlug,
    required this.onSubmit,
    super.key,
  });

  final LandscapeXlLayout layout;
  final LayoutComponentRegistry componentRegistry;
  final VaultNodeResolver? vaultNodeResolver;
  final SystemInfo? systemInfo;
  final Map<FanLayout, NodeTree> nodeTrees;
  final Map<NodeLayout, ResolvedVaultNode> nodeLayoutNodes;
  final List<ResolvedVaultNode> queryNodes;
  final List<ResolvedVaultNode> highlightedNodes;
  final List<ResolvedVaultNode> selectedNodes;
  final LandscapeXlLayoutTapCallback? onLayoutTap;
  final String searchValue;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<ResolvedVaultNode> onSearchNodeSelected;
  final VoidCallback onCancel;
  final VoidCallback onRefreshFanData;
  final VoidCallback onCopySelectedNodeSlug;
  final VoidCallback onSubmit;

  @override
  State<LandscapeXlLayoutView> createState() => _LandscapeXlLayoutViewState();
}

class _LandscapeXlLayoutViewState extends State<LandscapeXlLayoutView> {
  late LandscapeXlLayoutGame _game = LandscapeXlLayoutGame(
    layout: widget.layout,
    componentRegistry: widget.componentRegistry,
    vaultNodeResolver: widget.vaultNodeResolver,
    systemInfo: widget.systemInfo,
    nodeTrees: widget.nodeTrees,
    nodeLayoutNodes: widget.nodeLayoutNodes,
    queryNodes: widget.queryNodes,
    highlightedNodes: widget.highlightedNodes,
    selectedNodes: widget.selectedNodes,
    onLayoutTap: widget.onLayoutTap,
    searchValue: widget.searchValue,
    onSearchSubmitted: widget.onSearchSubmitted,
    onSearchNodeSelected: widget.onSearchNodeSelected,
    onCancel: widget.onCancel,
    onRefreshFanData: widget.onRefreshFanData,
    onCopySelectedNodeSlug: widget.onCopySelectedNodeSlug,
    onSubmit: widget.onSubmit,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.safePadding = MediaQuery.paddingOf(context);
  }

  @override
  void didUpdateWidget(LandscapeXlLayoutView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout ||
        oldWidget.componentRegistry != widget.componentRegistry) {
      _game = LandscapeXlLayoutGame(
        layout: widget.layout,
        componentRegistry: widget.componentRegistry,
        vaultNodeResolver: widget.vaultNodeResolver,
        systemInfo: widget.systemInfo,
        nodeTrees: widget.nodeTrees,
        nodeLayoutNodes: widget.nodeLayoutNodes,
        queryNodes: widget.queryNodes,
        highlightedNodes: widget.highlightedNodes,
        selectedNodes: widget.selectedNodes,
        onLayoutTap: widget.onLayoutTap,
        searchValue: widget.searchValue,
        onSearchSubmitted: widget.onSearchSubmitted,
        onSearchNodeSelected: widget.onSearchNodeSelected,
        onCancel: widget.onCancel,
        onRefreshFanData: widget.onRefreshFanData,
        onCopySelectedNodeSlug: widget.onCopySelectedNodeSlug,
        onSubmit: widget.onSubmit,
      )..safePadding = MediaQuery.paddingOf(context);
      return;
    }
    _game.updateConfiguration(
      layout: widget.layout,
      componentRegistry: widget.componentRegistry,
      vaultNodeResolver: widget.vaultNodeResolver,
      systemInfo: widget.systemInfo,
      nodeTrees: widget.nodeTrees,
      nodeLayoutNodes: widget.nodeLayoutNodes,
      queryNodes: widget.queryNodes,
      highlightedNodes: widget.highlightedNodes,
      selectedNodes: widget.selectedNodes,
      onLayoutTap: widget.onLayoutTap,
      searchValue: widget.searchValue,
      onSearchSubmitted: widget.onSearchSubmitted,
      onSearchNodeSelected: widget.onSearchNodeSelected,
      onCancel: widget.onCancel,
      onRefreshFanData: widget.onRefreshFanData,
      onCopySelectedNodeSlug: widget.onCopySelectedNodeSlug,
      onSubmit: widget.onSubmit,
    );
  }

  @override
  Widget build(BuildContext context) =>
      GameWidget<LandscapeXlLayoutGame>(key: ValueKey(_game), game: _game);
}

class LandscapeXlLayoutGame extends FlameGame
    with HasKeyboardHandlerComponents {
  LandscapeXlLayoutGame({
    required this.layout,
    required this.componentRegistry,
    required this.vaultNodeResolver,
    required this.systemInfo,
    required this.nodeTrees,
    required this.nodeLayoutNodes,
    required this.queryNodes,
    required this.highlightedNodes,
    required this.selectedNodes,
    required this.onLayoutTap,
    required this.searchValue,
    required this.onSearchSubmitted,
    required this.onSearchNodeSelected,
    required this.onCancel,
    required this.onRefreshFanData,
    required this.onCopySelectedNodeSlug,
    required this.onSubmit,
  }) {
    final searchLayout = _searchLayoutConfig(layout);
    _searchHud = SearchHudComponent(
      layout: searchLayout,
      searchValue: searchValue,
      results: queryNodes,
      onSearchSubmitted: onSearchSubmitted,
      onCancel: onCancel,
      onRefreshFanData: onRefreshFanData,
      onCopySelectedNodeSlug: onCopySelectedNodeSlug,
      onSubmit: onSubmit,
      onNodeSelected: _selectSearchNode,
    );
  }

  LandscapeXlLayout layout;
  LayoutComponentRegistry componentRegistry;
  VaultNodeResolver? vaultNodeResolver;
  SystemInfo? systemInfo;
  Map<FanLayout, NodeTree> nodeTrees;
  Map<NodeLayout, ResolvedVaultNode> nodeLayoutNodes;
  List<ResolvedVaultNode> queryNodes;
  List<ResolvedVaultNode> highlightedNodes;
  List<ResolvedVaultNode> selectedNodes;
  LandscapeXlLayoutTapCallback? onLayoutTap;
  String searchValue;
  ValueChanged<String> onSearchSubmitted;
  ValueChanged<ResolvedVaultNode> onSearchNodeSelected;
  VoidCallback onCancel;
  VoidCallback onRefreshFanData;
  VoidCallback onCopySelectedNodeSlug;
  VoidCallback onSubmit;
  EdgeInsets _safePadding = EdgeInsets.zero;
  Vector2? _viewportSize;
  late final SearchHudComponent _searchHud;
  AudioPool? _nodeSelectionAudioPool;
  AudioPool? _nodeHoverAudioPool;
  final BackgroundMusicController _backgroundMusic =
      BackgroundMusicController();
  String? _hoveredNodeKey;
  final _GameCursorComponent _gameCursor = _GameCursorComponent();
  final NodeComponent _nodeComponent = NodeComponent();
  final ClassificationLabelComponent _classificationLabelComponent =
      ClassificationLabelComponent();
  final List<GraphLayoutComponent> _graphLayoutComponents = [];
  final List<NodeLayoutComponent> _nodeLayoutComponents = [];

  LayoutContext get layoutContext => _layoutContext(
    layout,
    highlightedNodes,
    selectedNodes,
    searchOpenned: _searchHud.isOpen,
  );

  EdgeInsets get safePadding => _safePadding;

  set safePadding(EdgeInsets value) {
    _safePadding = value;
    _syncSearchHudLayout();
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewportSize = size.clone();
    _syncSearchHudLayout();
  }

  @override
  Future<void> onLoad() async {
    mouseCursor = SystemMouseCursors.none;
    _nodeSelectionAudioPool = await FlameAudio.createPool(
      'technology-select.wav',
      maxPlayers: 4,
    );
    _nodeHoverAudioPool = await FlameAudio.createPool(
      'stone-scrap.wav',
      maxPlayers: 4,
    );
    await _backgroundMusic.start();
    images.prefix = '';
    final resolvedRoot = layout.resolve(layoutContext);
    for (final assetPath in _layoutImageAssetPaths(layout).toSet()) {
      await images.load(assetPath);
    }
    final orderedBackground = [
      ...resolvedRoot.background,
    ]..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
    for (final background in orderedBackground) {
      for (final resolved in _activeLayoutBackgrounds(
        background,
        layoutContext,
      )) {
        final background = resolved.background;
        if (background is LayoutBackgroundColor) {
          add(_LayoutColorBackgroundComponent(background, resolved.opacity));
        } else if (background is LayoutImageBackground) {
          add(_LayoutImageBackgroundComponent(background, resolved.opacity));
        } else if (background is LayoutGuidingBackground) {
          add(_LayoutGuidingBackgroundComponent(background, resolved.opacity));
        }
      }
    }
    add(_LandscapeXlSceneComponent()..priority = 100);
    for (final placement in _pathLayoutPlacements<FanLayout>(
      layout,
      layoutContext,
    )) {
      add(_FanComponent(placement)..priority = 110);
    }
    for (final placement in _pathLayoutPlacements<GraphLayout>(
      layout,
      layoutContext,
    )) {
      final component = GraphLayoutComponent(
        layoutKey: placement.key,
        layout: placement.layout,
        isLayoutVisible: () => placement.hierarchy.every(
          (layout) => layout.isVisible(layoutContext),
        ),
        selectedNodes: () => selectedNodes,
        layoutContext: () => layoutContext,
        nodeConfig: (node) => _resolvedNodeConfig(
          placement.hierarchy,
          _nodeLayoutContext(layoutContext, node),
        ),
        surface: () => _resolveGraphPlacementSurface(placement),
        isTapEnabled: () => onLayoutTap != null,
        onNodeTap: (hit) => dispatchLayoutTap(
          LayoutTapTarget(
            key: hit.key,
            layout: placement.layout,
            node: hit.resolvedNode,
            resolvedNode: hit.resolvedNode,
            label: hit.label,
          ),
        ),
      )..priority = 110;
      _graphLayoutComponents.add(component);
      add(component);
    }
    for (final placement in _pathLayoutPlacements<NodeLayout>(
      layout,
      layoutContext,
    )) {
      final component = NodeLayoutComponent(
        layoutKey: placement.key,
        layout: placement.layout,
        isLayoutVisible: () => placement.hierarchy.every(
          (layout) => layout.isVisible(layoutContext),
        ),
        resolvedNode: () => nodeLayoutNodes[placement.layout],
        layoutContext: () => layoutContext,
        nodeConfig: (node) => _resolvedNodeConfig(
          placement.hierarchy,
          _nodeLayoutContext(layoutContext, node),
        ),
        surface: () => _resolveNodePlacementSurface(placement),
        isTapEnabled: () => onLayoutTap != null,
        onNodeTap: (hit) => dispatchLayoutTap(
          LayoutTapTarget(
            key: hit.key,
            layout: placement.layout,
            node: hit.resolvedNode,
            resolvedNode: hit.resolvedNode,
            label: hit.label,
          ),
        ),
      )..priority = 110;
      _nodeLayoutComponents.add(component);
      add(component);
    }
    for (final registered in _registeredLayoutComponents(
      layout,
      componentRegistry,
      layoutContext,
    )) {
      add(
        _RegisteredLayoutComponentHost(
          hierarchy: registered.hierarchy,
          component: registered.component,
        )..priority = 120,
      );
    }
    add(_searchHud..priority = 1000);
    add(_nodeComponent..priority = 1100);
    add(_classificationLabelComponent..priority = 910);
    add(_gameCursor..priority = 2000);
  }

  void dispatchLayoutTap(LayoutTapTarget target) {
    final slug = target.resolvedNode?.node?.slug.trim() ?? '';
    final isSelectingNode =
        slug.isNotEmpty &&
        !selectedNodes.any((node) => node.node?.slug.trim() == slug);
    final audioPool = _nodeSelectionAudioPool;
    if (isSelectingNode && audioPool != null) {
      unawaited(audioPool.start(volume: 0.5));
    }
    onLayoutTap?.call(target);
  }

  void _selectSearchNode(ResolvedVaultNode resolvedNode) {
    _searchHud.close();
    final slug = resolvedNode.node?.slug.trim() ?? '';
    final isSelectingNode =
        slug.isNotEmpty &&
        !selectedNodes.any((node) => node.node?.slug.trim() == slug);
    final audioPool = _nodeSelectionAudioPool;
    if (isSelectingNode && audioPool != null) {
      unawaited(audioPool.start(volume: 0.5));
    }
    onSearchNodeSelected(resolvedNode);
  }

  void updateHoveredNode(String? nodeKey, {Path? path, GuideStyle? style}) {
    _nodeComponent.updateHoverTarget(path, style);
    if (nodeKey == _hoveredNodeKey) return;
    _hoveredNodeKey = nodeKey;
    final audioPool = _nodeHoverAudioPool;
    if (nodeKey != null && audioPool != null) {
      unawaited(audioPool.start(volume: 0.3));
    }
  }

  List<Offset>? _resolveFanPlacementPoints(
    _PathLayoutPlacement<FanLayout> placement,
  ) {
    final context = layoutContext;
    final resolvedLayouts = _resolveLayouts(
      layout,
      Size(size.x, size.y),
      safePadding,
      context,
    );
    final points = _resolvedLayoutPathPoints(
      placement.plane,
      resolvedLayouts,
      context,
    );
    if (points == null) return null;
    if (points.length >= 3 || placement.gridSteps.isNotEmpty) {
      final projection = _resolvedLayoutPathProjection(
        placement.plane,
        points,
        resolvedLayouts,
        context,
      );
      return _resolveGridPlacementPoints(
        points,
        projection,
        placement.gridSteps,
        context,
      );
    }
    return _resolvedCurvedFanSurface(
      placement.plane,
      points,
      resolvedLayouts,
      context,
    );
  }

  LayoutNodeSurface? _resolveGraphPlacementSurface(
    _PathLayoutPlacement<GraphLayout> placement,
  ) => _resolveNodePlacementSurface(placement);

  LayoutNodeSurface? _resolveNodePlacementSurface<T extends Layout>(
    _PathLayoutPlacement<T> placement,
  ) {
    final context = layoutContext;
    final resolvedLayouts = _resolveLayouts(
      layout,
      Size(size.x, size.y),
      safePadding,
      context,
    );
    final points = _resolvedLayoutPathPoints(
      placement.plane,
      resolvedLayouts,
      context,
    );
    if (points == null || points.length != 4) return null;
    final projection = _resolvedLayoutPathProjection(
      placement.plane,
      points,
      resolvedLayouts,
      context,
    );
    if (projection?.canProjectBackground ?? false) {
      final frame = _resolveGridPlacementFrame(
        projection!.flatSize,
        placement.gridSteps,
        rootFontSize: context.rootFontSize,
      );
      if (frame == null) return null;
      return (
        logicalSize: Size(
          projection.flatSize.width * (frame.right - frame.left),
          projection.flatSize.height * (frame.bottom - frame.top),
        ),
        clipPath: _curvedSurfacePath(projection, frame),
        project: (u, v) => projection.project(
          ui.lerpDouble(frame.left, frame.right, u)!,
          ui.lerpDouble(frame.top, frame.bottom, v)!,
        ),
      );
    }

    final placementPoints = _resolveGridPlacementPoints(
      points,
      projection,
      placement.gridSteps,
      context,
    );
    if (placementPoints == null || placementPoints.length != 4) return null;
    final orderedPoints = _screenOrderedQuadrilateral(placementPoints);
    return (
      logicalSize: _quadrilateralAverageSize(orderedPoints),
      clipPath: _polygonPath(orderedPoints),
      project: (u, v) => _projectiveQuadrilateralPoint(orderedPoints, u, v),
    );
  }

  void updateHoveredClassificationLabel({Path? path, GuideStyle? style}) =>
      _classificationLabelComponent.updateHoverTarget(path, style);

  void updateCursorPosition(Offset? position) =>
      _gameCursor.updatePointer(position);

  Future<bool> playBackgroundMusicTrack(int trackIndex) =>
      _backgroundMusic.playTrack(trackIndex);

  @override
  void onRemove() {
    final audioPool = _nodeSelectionAudioPool;
    final hoverAudioPool = _nodeHoverAudioPool;
    _nodeSelectionAudioPool = null;
    _nodeHoverAudioPool = null;
    _hoveredNodeKey = null;
    mouseCursor = MouseCursor.defer;
    if (audioPool != null) unawaited(audioPool.dispose());
    if (hoverAudioPool != null) unawaited(hoverAudioPool.dispose());
    unawaited(_backgroundMusic.dispose());
    super.onRemove();
  }

  void openSearchHud() {
    _syncSearchHudLayout();
    _searchHud.open(searchValue);
  }

  void closeSearchHud() => _searchHud.close();

  void performLayoutTapAction(LayoutTapAction action) {
    switch (action) {
      case SearchOpennedLayoutTapAction():
        openSearchHud();
    }
  }

  void updateConfiguration({
    required LandscapeXlLayout layout,
    required LayoutComponentRegistry componentRegistry,
    required VaultNodeResolver? vaultNodeResolver,
    required SystemInfo? systemInfo,
    required Map<FanLayout, NodeTree> nodeTrees,
    required Map<NodeLayout, ResolvedVaultNode> nodeLayoutNodes,
    required List<ResolvedVaultNode> queryNodes,
    required List<ResolvedVaultNode> highlightedNodes,
    required List<ResolvedVaultNode> selectedNodes,
    required LandscapeXlLayoutTapCallback? onLayoutTap,
    required String searchValue,
    required ValueChanged<String> onSearchSubmitted,
    required ValueChanged<ResolvedVaultNode> onSearchNodeSelected,
    required VoidCallback onCancel,
    required VoidCallback onRefreshFanData,
    required VoidCallback onCopySelectedNodeSlug,
    required VoidCallback onSubmit,
  }) {
    this.layout = layout;
    this.componentRegistry = componentRegistry;
    this.vaultNodeResolver = vaultNodeResolver;
    this.systemInfo = systemInfo;
    this.nodeTrees = nodeTrees;
    this.nodeLayoutNodes = nodeLayoutNodes;
    this.queryNodes = queryNodes;
    this.highlightedNodes = highlightedNodes;
    this.selectedNodes = selectedNodes;
    this.onLayoutTap = onLayoutTap;
    this.searchValue = searchValue;
    this.onSearchSubmitted = onSearchSubmitted;
    this.onSearchNodeSelected = onSearchNodeSelected;
    this.onCancel = onCancel;
    this.onRefreshFanData = onRefreshFanData;
    this.onCopySelectedNodeSlug = onCopySelectedNodeSlug;
    this.onSubmit = onSubmit;
    final searchLayout = _searchLayoutConfig(layout);
    _searchHud
      ..layout = searchLayout
      ..searchValue = searchValue
      ..onSearchSubmitted = onSearchSubmitted
      ..onCancel = onCancel
      ..onRefreshFanData = onRefreshFanData
      ..onCopySelectedNodeSlug = onCopySelectedNodeSlug
      ..onSubmit = onSubmit
      ..onNodeSelected = _selectSearchNode
      ..updateNodeOptions(results: queryNodes);
    _syncSearchHudLayout();
  }

  void _syncSearchHudLayout() {
    final viewportSize = _viewportSize;
    if (viewportSize == null || viewportSize.x <= 0 || viewportSize.y <= 0) {
      return;
    }
    for (final placement in _pathLayoutPlacements<SearchLayout>(
      layout,
      layoutContext,
    )) {
      final surface = _resolveNodePlacementSurface(placement);
      if (surface == null) continue;
      final bounds = _boundsForPoints([
        surface.project(0, 0),
        surface.project(1, 0),
        surface.project(1, 1),
        surface.project(0, 1),
      ]);
      _searchHud.updateLayout(placement.layout, bounds);
      return;
    }
  }
}

class _GameCursorComponent extends PositionComponent {
  Offset? _pointer;
  double _cursorAngle = 0;

  void updatePointer(Offset? pointer) {
    _pointer = pointer;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void update(double dt) {
    if (_pointer != null) _cursorAngle += dt * 0.42;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final pointer = _pointer;
    if (pointer == null || size.x <= 0 || size.y <= 0) return;
    final target = Offset(size.x - pointer.dx, size.y - pointer.dy);
    _paintTargetConnection(canvas, pointer, target);
    _paintTargetRhomboid(canvas, target);

    canvas.save();
    canvas.translate(pointer.dx, pointer.dy);
    canvas.rotate(_cursorAngle);
    _paintCurrentCursor(canvas);
    canvas.restore();
  }

  void _paintCurrentCursor(Canvas canvas) {
    const center = Offset.zero;
    const gold = Color(0xFFF2C94C);
    const cyan = Color(0xFF2FA8FF);
    final glowPaint = Paint()
      ..color = cyan.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final goldPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final cyanPaint = Paint()
      ..color = cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawCircle(center, 11, glowPaint);
    canvas.drawCircle(center, 6.5, cyanPaint);
    final outerBounds = Rect.fromCircle(center: center, radius: 12);
    for (var quadrant = 0; quadrant < 4; quadrant += 1) {
      canvas.drawArc(
        outerBounds,
        quadrant * math.pi / 2 + 0.16,
        math.pi / 2 - 0.32,
        false,
        goldPaint,
      );
    }
    for (final direction in const [
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0),
    ]) {
      canvas.drawLine(
        center + direction * 8.5,
        center + direction * 15,
        goldPaint,
      );
    }
    canvas.drawCircle(center, 1.8, Paint()..color = gold);
  }

  void _paintTargetConnection(Canvas canvas, Offset pointer, Offset target) {
    final distance = (target - pointer).distance;
    if (distance < 2) return;
    canvas.drawLine(
      pointer,
      target,
      Paint()
        ..shader = ui.Gradient.linear(pointer, target, const [
          Color(0x662FA8FF),
          Color(0xCC45D483),
        ])
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintTargetRhomboid(Canvas canvas, Offset target) {
    const green = Color(0xFF45D483);
    final path = Path()
      ..moveTo(target.dx, target.dy - 13)
      ..lineTo(target.dx + 9, target.dy)
      ..lineTo(target.dx, target.dy + 13)
      ..lineTo(target.dx - 9, target.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = green.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = green.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(target, 1.8, Paint()..color = green);
  }
}

Iterable<String> _layoutImageAssetPaths(Layout layout) sync* {
  for (final background in layout.background) {
    yield* _backgroundImageAssetPaths(background);
  }
  for (final child in layout.children.values) {
    yield* _layoutImageAssetPaths(child);
  }
  for (final conditional in layout.state.values.values) {
    yield* _layoutConfigImageAssetPaths(conditional);
  }
}

Iterable<String> _layoutConfigImageAssetPaths(LayoutConfig config) sync* {
  for (final background in config.background ?? const <LayoutBackground>[]) {
    yield* _backgroundImageAssetPaths(background);
  }
  for (final conditional in config.state.values.values) {
    yield* _layoutConfigImageAssetPaths(conditional);
  }
}

Iterable<String> _backgroundImageAssetPaths(LayoutBackground background) sync* {
  if (background is LayoutImageBackground) {
    yield background.assetPath;
  } else if (background is RandomLayoutBackground) {
    for (final option in background.backgrounds) {
      yield* _backgroundImageAssetPaths(option);
    }
  } else if (background is ConditionalLayoutBackground) {
    yield* _backgroundImageAssetPaths(background.background);
  }
}

final math.Random _layoutBackgroundRandom = math.Random();
final Expando<LayoutBackground> _randomLayoutBackgroundSelections = Expando();

LayoutBackground _selectRandomLayoutBackground(
  RandomLayoutBackground background,
) => _randomLayoutBackgroundSelections[background] ??=
    background.backgrounds[_layoutBackgroundRandom.nextInt(
      background.backgrounds.length,
    )];

Iterable<({LayoutBackground background, double opacity})>
_activeLayoutBackgrounds(
  LayoutBackground background,
  LayoutContext context, {
  double inheritedOpacity = 1,
}) sync* {
  final opacity = (inheritedOpacity * background.opacity)
      .clamp(0, 1)
      .toDouble();
  if (opacity == 0) return;
  if (background is RandomLayoutBackground) {
    yield* _activeLayoutBackgrounds(
      _selectRandomLayoutBackground(background),
      context,
      inheritedOpacity: opacity,
    );
    return;
  }
  if (background is ConditionalLayoutBackground) {
    if (!background.activeCondition.isActive(context)) return;
    yield* _activeLayoutBackgrounds(
      background.background,
      context,
      inheritedOpacity: opacity,
    );
    return;
  }
  yield (background: background, opacity: opacity);
}

typedef _RegisteredLayoutComponent = ({
  List<Layout> hierarchy,
  PositionComponent component,
});

Iterable<_RegisteredLayoutComponent> _registeredLayoutComponents(
  Layout root,
  LayoutComponentRegistry registry, [
  LayoutContext context = LayoutContext.empty,
  List<Layout> ancestors = const [],
]) sync* {
  root = root.resolve(context);
  final hierarchy = [...ancestors, root];
  if (root is! LandscapeXlLayout) {
    final component = registry.build(root);
    if (component != null) {
      yield (hierarchy: hierarchy, component: component);
    }
  }
  for (final child in root.children.values) {
    yield* _registeredLayoutComponents(child, registry, context, hierarchy);
  }
}

class _RegisteredLayoutComponentHost extends PositionComponent
    with HasGameReference<LandscapeXlLayoutGame>, HasVisibility {
  _RegisteredLayoutComponentHost({
    required this.hierarchy,
    required this.component,
  });

  final List<Layout> hierarchy;
  final PositionComponent component;

  @override
  Future<void> onLoad() async {
    add(component);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    component.size = size;
  }

  @override
  void update(double dt) {
    isVisible = hierarchy.every(
      (layout) => layout.isVisible(game.layoutContext),
    );
    super.update(dt);
  }
}

typedef _PathLayoutPlacement<T extends Layout> = ({
  String key,
  LayoutPath plane,
  T layout,
  List<Layout> hierarchy,
  List<({GridLayout grid, String slot, Layout layout})> gridSteps,
});

NodeConfig _resolvedNodeConfig(
  Iterable<Layout> hierarchy,
  LayoutContext context,
) {
  var config = NodeDefaults.config.resolve(context);
  for (final layout in hierarchy) {
    config = config.merge(layout.resolveNodeConfig(context));
  }
  return config;
}

List<Layout>? _layoutHierarchyTo(
  Layout current,
  Layout target, [
  List<Layout> ancestors = const [],
]) {
  final hierarchy = [...ancestors, current];
  if (identical(current, target)) return hierarchy;
  for (final child in current.children.values) {
    final result = _layoutHierarchyTo(child, target, hierarchy);
    if (result != null) return result;
  }
  return null;
}

GuideStyle? _resolvedNodeHighlightBorderStyle(
  Layout root,
  Layout target,
  ResolvedVaultNode? node,
  LayoutContext context,
) {
  if (node == null) return null;
  final nodeContext = _nodeLayoutContext(context, node);
  final nodePath = nodeContext.currentNodePath?.trim();
  if (nodePath == null || nodePath.isEmpty) return null;
  final highlightedContext = nodeContext.withHighlightedNodePath(nodePath);
  final hierarchy = _layoutHierarchyTo(root, target) ?? [root, target];
  return _resolvedNodeConfig(hierarchy, highlightedContext).borderStyle;
}

LayoutTextConfig _resolvedTextConfig(
  Iterable<Layout> hierarchy,
  LayoutContext context,
) {
  var config = LayoutTextDefaults.config;
  for (final layout in hierarchy) {
    config = config.merge(layout.resolveTextConfig(context));
  }
  return config;
}

LabelConfig _resolvedLabelConfig(
  Iterable<Layout> hierarchy,
  LayoutContext context,
) {
  var config = LabelDefaults.config.resolve(context);
  for (final layout in hierarchy) {
    config = config.merge(layout.resolveLabelConfig(context));
  }
  return config;
}

Iterable<MapEntry<String, Layout>> _resolvedLayoutChildren(
  Layout layout,
  LayoutContext context,
) sync* {
  for (final entry in layout.children.entries) {
    yield MapEntry(entry.key, entry.value.resolve(context));
  }
}

Iterable<_PathLayoutPlacement<T>> _pathLayoutPlacements<T extends Layout>(
  Layout layout, [
  LayoutContext context = LayoutContext.empty,
  List<String> parentPath = const [],
  List<Layout> ancestors = const [],
]) sync* {
  layout = layout.resolve(context);
  final hierarchy = [...ancestors, layout];
  for (final entry in layout.children.entries) {
    final childPath = [...parentPath, entry.key];
    final child = entry.value.resolve(context);
    if (child is LayoutPath) {
      for (final layoutEntry in child.children.entries) {
        final pathLayout = layoutEntry.value.resolve(context);
        if (pathLayout is T) {
          yield (
            key: [...childPath, layoutEntry.key].join('/'),
            plane: child,
            layout: pathLayout,
            hierarchy: [...hierarchy, child, pathLayout],
            gridSteps: const [],
          );
        } else if (pathLayout is GridLayout) {
          yield* _gridPathLayoutPlacements<T>(
            child,
            pathLayout,
            [...childPath, layoutEntry.key],
            [...hierarchy, child, pathLayout],
            context,
          );
        }
      }
    }
    yield* _pathLayoutPlacements<T>(child, context, childPath, hierarchy);
  }
}

Iterable<_PathLayoutPlacement<T>> _gridPathLayoutPlacements<T extends Layout>(
  LayoutPath plane,
  GridLayout grid,
  List<String> gridPath,
  List<Layout> hierarchy, [
  LayoutContext context = LayoutContext.empty,
  List<({GridLayout grid, String slot, Layout layout})> gridSteps = const [],
]) sync* {
  for (final entry in grid.children.entries) {
    final child = entry.value.resolve(context);
    final requestedSlot = child.slot;
    if (requestedSlot == null) continue;
    final resolvedSlot = _resolveGridSlot(grid, requestedSlot);
    if (resolvedSlot == null) continue;
    final childPath = [...gridPath, entry.key];
    final childHierarchy = [...hierarchy, child];
    final childSteps = [
      ...gridSteps,
      (grid: grid, slot: resolvedSlot.key, layout: child),
    ];
    if (child is T) {
      yield (
        key: childPath.join('/'),
        plane: plane,
        layout: child,
        hierarchy: childHierarchy,
        gridSteps: childSteps,
      );
    }
    if (child is GridLayout) {
      yield* _gridPathLayoutPlacements<T>(
        plane,
        child,
        childPath,
        childHierarchy,
        context,
        childSteps,
      );
    }
  }
}

class _LayoutImageBackgroundComponent extends PositionComponent
    with HasGameReference<LandscapeXlLayoutGame> {
  _LayoutImageBackgroundComponent(this.background, this.opacity);

  final LayoutImageBackground background;
  final double opacity;
  ui.Image? _image;

  @override
  Future<void> onLoad() async {
    _image = await game.images.load(background.assetPath);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final image = _image;
    if (image == null || size.x <= 0 || size.y <= 0) return;
    for (final tile in _backgroundImageTiles(
      Rect.fromLTWH(0, 0, size.x, size.y),
      background.repeat,
    )) {
      _paintBackgroundImage(canvas, tile, image, background, opacity);
    }
  }
}

class _LayoutColorBackgroundComponent extends PositionComponent {
  _LayoutColorBackgroundComponent(this.background, this.opacity);

  final LayoutBackgroundColor background;
  final double opacity;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = background.color.withValues(
          alpha: background.color.a * opacity,
        ),
    );
  }
}

class _LayoutGuidingBackgroundComponent extends PositionComponent
    with HasGameReference<LandscapeXlLayoutGame> {
  _LayoutGuidingBackgroundComponent(this.background, this.opacity);

  final LayoutGuidingBackground background;
  final double opacity;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    if (opacity < 1) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
    }
    for (final guide in background.guides) {
      drawGuideLine(
        canvas,
        Offset(size.x * guide.start.dx, size.y * guide.start.dy),
        Offset(size.x * guide.end.dx, size.y * guide.end.dy),
        guide.style,
      );
    }
    if (opacity < 1) canvas.restore();
  }
}

void _drawPlaneLayout(
  Canvas canvas,
  Layout parent,
  Rect parentBounds,
  PlaneLayout plane,
  ResolvedVaultNode? selectedNode,
) {
  final geometry = _resolvePlaneGeometry(parent, parentBounds, plane);
  if (geometry == null) return;

  final node = selectedNode?.node;
  final borderColor = node == null
      ? plane.borderColor
      : NodeComponent.parseColor(node.frontmatter['color']) ??
            plane.resolvedBorderColor;
  _drawFilledPlaneShape(
    canvas,
    geometry.shapeFrame,
    plane.shape,
    plane.backgroundColor,
    borderColor,
    plane.borderWidth,
  );
  final planeStyle = plane.style;
  if (plane.showGeometryGuides && planeStyle != null) {
    _drawPlaneBlueprint(
      canvas,
      geometry.shapeFrame,
      geometry.center,
      plane.shape,
      planeStyle,
    );
  } else if (plane.showGeometryGuides) {
    _drawPlaneConnectors(
      canvas,
      geometry.parentFrame,
      geometry.shapeFrame,
      plane.geometryGuideStyle,
    );
    for (var index = 0; index < plane.ringGuides.length; index += 1) {
      _drawPlaneRing(
        canvas,
        geometry.center,
        geometry.ringRadii[index],
        plane.ringGuides[index].style,
      );
    }
    _drawPlaneShape(
      canvas,
      geometry.shapeFrame,
      plane.shape,
      plane.geometryGuideStyle,
    );
  }
}

void _drawPlaneBlueprint(
  Canvas canvas,
  Rect frame,
  Offset center,
  LayoutShape shape,
  PlaneLayoutStyle style,
) {
  _drawPlaneShape(canvas, frame, shape, style.borderStyle);
  switch (shape) {
    case LayoutShape.square || LayoutShape.rectangle:
      final diagonalStyle = style.diagonalStyle ?? style.borderStyle;
      drawGuideLine(canvas, frame.topLeft, frame.bottomRight, diagonalStyle);
      drawGuideLine(canvas, frame.bottomLeft, frame.topRight, diagonalStyle);

      final centerLineStyle = style.centerLineStyle ?? style.borderStyle;
      drawGuideLine(
        canvas,
        Offset(center.dx, frame.top),
        Offset(center.dx, frame.bottom),
        centerLineStyle,
      );
      drawGuideLine(
        canvas,
        Offset(frame.left, center.dy),
        Offset(frame.right, center.dy),
        centerLineStyle,
      );
    case LayoutShape.circle:
      final radiusStyle = style.radiusStyle ?? style.borderStyle;
      drawGuideLine(canvas, center, Offset(center.dx, frame.top), radiusStyle);
      _drawPlaneCenterPoint(canvas, center, style);
  }
}

void _drawPlaneCenterPoint(
  Canvas canvas,
  Offset center,
  PlaneLayoutStyle style,
) {
  final color = style.centerPointColor;
  if (color == null || style.centerPointRadius <= 0) return;
  canvas.drawCircle(
    center,
    style.centerPointRadius,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
}

void _drawFilledPlaneShape(
  Canvas canvas,
  Rect frame,
  LayoutShape shape,
  Color fillColor,
  Color borderColor,
  double borderWidth,
) {
  final fillPaint = Paint()
    ..color = fillColor
    ..style = PaintingStyle.fill;
  final strokePaint = Paint()
    ..color = borderColor
    ..strokeWidth = borderWidth
    ..style = PaintingStyle.stroke;
  switch (shape) {
    case LayoutShape.circle:
      canvas.drawOval(frame, fillPaint);
      if (borderWidth > 0) canvas.drawOval(frame, strokePaint);
    case LayoutShape.square || LayoutShape.rectangle:
      canvas.drawRect(frame, fillPaint);
      if (borderWidth > 0) canvas.drawRect(frame, strokePaint);
  }
}

void _drawPlaneShape(
  Canvas canvas,
  Rect frame,
  LayoutShape shape,
  GuideStyle style,
) {
  switch (shape) {
    case LayoutShape.circle:
      _drawGuideOval(canvas, frame, style);
    case LayoutShape.square || LayoutShape.rectangle:
      _drawGuideRect(canvas, frame, style);
  }
}

void _drawGuideRect(Canvas canvas, Rect frame, GuideStyle style) {
  drawGuideLine(canvas, frame.topLeft, frame.topRight, style);
  drawGuideLine(canvas, frame.topRight, frame.bottomRight, style);
  drawGuideLine(canvas, frame.bottomRight, frame.bottomLeft, style);
  drawGuideLine(canvas, frame.bottomLeft, frame.topLeft, style);
}

void _drawGuideOval(Canvas canvas, Rect frame, GuideStyle style) {
  const segments = 96;
  Offset pointAt(int index) {
    final theta = math.pi * 2 * index / segments;
    return Offset(
      frame.center.dx + math.cos(theta) * frame.width / 2,
      frame.center.dy + math.sin(theta) * frame.height / 2,
    );
  }

  for (var index = 0; index < segments; index += 1) {
    drawGuideLine(canvas, pointAt(index), pointAt(index + 1), style);
  }
}

typedef _ParentShapeFrame = ({Rect frame, LayoutShape shape});

_ParentShapeFrame _parentShapeFrame(Layout parent, Rect parentBounds) {
  if (parent is PlaneLayout) {
    return (frame: parentBounds, shape: parent.shape);
  }

  final innerCircle = _layoutCircleFrame(
    parent,
    parentBounds,
    LayoutCircleBoundary.inner,
  );
  return (frame: innerCircle, shape: LayoutShape.circle);
}

typedef _PlaneGeometry = ({
  Rect parentFrame,
  Rect shapeFrame,
  Offset center,
  List<double> ringRadii,
});

_PlaneGeometry? _resolvePlaneGeometry(
  Layout parent,
  Rect parentBounds,
  PlaneLayout plane,
) {
  final parentShape = _parentShapeFrame(parent, parentBounds);
  final availableFrame = parentShape.frame.deflate(
    math.max(plane.padding + plane.wrapPadding, 0),
  );
  if (availableFrame.isEmpty) return null;

  final center = Offset(
    availableFrame.left + availableFrame.width * plane.position.dx,
    availableFrame.top + availableFrame.height * plane.position.dy,
  );
  final inscribedFrame = _inscribedShapeFrame(
    plane.shape,
    availableFrame,
    parentShape.shape,
  );
  final scale = (plane.radiusFraction / 0.5).clamp(0.0, 1.0).toDouble();
  final shapeFrame = Rect.fromCenter(
    center: center,
    width: inscribedFrame.width * scale,
    height: inscribedFrame.height * scale,
  );
  if (shapeFrame.isEmpty) return null;

  final baseRadius = shapeFrame.shortestSide / 2;
  final availableRadius = availableFrame.shortestSide / 2;
  final ringRadii = [
    for (final ring in plane.ringGuides)
      baseRadius +
          (availableRadius - baseRadius) * ring.fraction.clamp(0, 1).toDouble(),
  ];
  return (
    parentFrame: parentShape.frame,
    shapeFrame: shapeFrame,
    center: center,
    ringRadii: ringRadii,
  );
}

Rect _inscribedShapeFrame(
  LayoutShape childShape,
  Rect parentFrame,
  LayoutShape parentShape,
) {
  return switch (childShape) {
    LayoutShape.rectangle => parentFrame,
    LayoutShape.square =>
      parentShape == LayoutShape.circle
          ? _layoutSquareFrameForCircle(parentFrame, fallback: parentFrame)
          : _centeredSquareFrame(parentFrame),
    LayoutShape.circle =>
      parentShape == LayoutShape.rectangle
          ? _centeredSquareFrame(parentFrame)
          : parentFrame,
  };
}

Rect _centeredSquareFrame(Rect frame) {
  final side = frame.shortestSide;
  return Rect.fromCenter(center: frame.center, width: side, height: side);
}

void _drawPlaneConnectors(
  Canvas canvas,
  Rect frame,
  Rect wrapFrame,
  GuideStyle style,
) {
  drawGuideLine(
    canvas,
    Offset(frame.center.dx, frame.top),
    Offset(wrapFrame.center.dx, wrapFrame.top),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.right, frame.center.dy),
    Offset(wrapFrame.right, wrapFrame.center.dy),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.center.dx, frame.bottom),
    Offset(wrapFrame.center.dx, wrapFrame.bottom),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.left, frame.center.dy),
    Offset(wrapFrame.left, wrapFrame.center.dy),
    style,
  );
}

void _drawPlaneRing(
  Canvas canvas,
  Offset center,
  double radius,
  GuideStyle style,
) {
  if (radius <= 0) return;
  const steps = 96;
  var previous = center + Offset(radius, 0);
  for (var index = 1; index <= steps; index += 1) {
    final radians = math.pi * 2 * index / steps;
    final next = center + Offset(math.cos(radians), math.sin(radians)) * radius;
    drawGuideLine(canvas, previous, next, style);
    previous = next;
  }
}

typedef _ResolvedLayout = ({
  Layout layout,
  Rect bounds,
  List<Layout> hierarchy,
});
typedef _HoveredNodeTarget = ({String key, Path path, GuideStyle? style});
typedef _HoveredClassificationLabelTarget = ({Path path, GuideStyle style});
typedef _TableRowPlacement = ({
  _ResolvedTableRow row,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
});
typedef _TablePanelRun = ({
  String? panelId,
  List<_ResolvedTableRow> rows,
  double width,
  LayoutSize? height,
});

class _LandscapeXlSceneComponent extends PositionComponent
    with
        HasGameReference<LandscapeXlLayoutGame>,
        flame_events.TapCallbacks,
        flame_events.HoverCallbacks {
  final Map<TableLayout, Map<String, _TablePanelFoldAnimation>>
  _tablePanelAnimations = {};
  final List<_TablePanelHeaderHit> _tablePanelHeaderHits = [];
  final List<_TableNodeHit> _tableNodeHits = [];
  final List<_TableActionHit> _tableActionHits = [];
  final List<_TableClassificationLabelHit> _tableClassificationLabelHits = [];
  final Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  _curvedLayoutPathImageMeshes = {};
  Offset? hoverPosition;

  @override
  void onRemove() {
    for (final mesh in _curvedLayoutPathImageMeshes.values) {
      mesh.dispose();
    }
    _curvedLayoutPathImageMeshes.clear();
    super.onRemove();
  }

  @override
  void update(double dt) {
    for (final animations in _tablePanelAnimations.values) {
      for (final animation in animations.values) {
        animation.update(dt);
      }
    }
    super.update(dt);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    _tablePanelHeaderHits.clear();
    _tableNodeHits.clear();
    _tableActionHits.clear();
    _tableClassificationLabelHits.clear();
    final layout = game.layout;
    final viewport = Size(size.x, size.y);
    final safePadding = game.safePadding;
    final vaultNodeResolver = game.vaultNodeResolver;
    final systemInfo = game.systemInfo;
    final selectedNodes = game.selectedNodes;
    final nodeListSources = _nodeListSources(
      selectedNodes,
      searchResults: game._searchHud.showsResults ? game.queryNodes : const [],
    );
    final selectedNode = selectedNodes.lastOrNull;
    final layoutContext = game.layoutContext;
    final resolvedLayouts = _resolveLayouts(
      layout,
      viewport,
      safePadding,
      layoutContext,
    );
    final resolvedRoot = resolvedLayouts['']?.layout ?? layout;
    bool isPanoramicPath(LayoutPath path) =>
        path.aliases.contains('panoramic-scene-plane');

    void drawGuidelines() {
      for (final resolved in resolvedLayouts.values) {
        canvas.save();
        canvas.translate(resolved.bounds.left, resolved.bounds.top);
        drawLayoutGuidelines(
          canvas,
          resolved.bounds.size,
          resolved.layout,
          layoutContext,
        );
        canvas.restore();
      }
    }

    final pathPaintEntries =
        <({int index, _ResolvedLayout owner, LayoutPath path})>[];
    var pathIndex = 0;
    for (final resolved in resolvedLayouts.values) {
      for (final entry in _resolvedLayoutChildren(
        resolved.layout,
        layoutContext,
      )) {
        final path = entry.value;
        if (path is! LayoutPath) continue;
        pathPaintEntries.add((index: pathIndex, owner: resolved, path: path));
        pathIndex += 1;
      }
    }
    pathPaintEntries.sort((left, right) {
      final leftIsPanorama = isPanoramicPath(left.path);
      final rightIsPanorama = isPanoramicPath(right.path);
      if (leftIsPanorama != rightIsPanorama) return leftIsPanorama ? -1 : 1;
      return left.index.compareTo(right.index);
    });
    var guidelinesPainted = false;
    for (final entry in pathPaintEntries) {
      final path = entry.path;
      final owner = entry.owner;
      if (!guidelinesPainted && !isPanoramicPath(path)) {
        drawGuidelines();
        guidelinesPainted = true;
      }
      if (!path.isVisible(layoutContext)) continue;
      _drawLayoutPath(
        canvas,
        viewport,
        path,
        resolvedLayouts,
        vaultNodeResolver,
        systemInfo,
        selectedNodes,
        nodeListSources,
        game._classificationLabelComponent,
        hoverPosition,
        layoutContext,
        background: path.resolveBackground(layoutContext),
        curvedImageMeshes: _curvedLayoutPathImageMeshes,
        imageFor: (assetPath) => game.images.containsKey(assetPath)
            ? game.images.fromCache(assetPath)
            : null,
        panelDefaults: resolvedRoot
            .resolvePanelConfig(layoutContext)
            .merge(owner.layout.resolvePanelConfig(layoutContext)),
        nodeConfig: _resolvedNodeConfig([
          ...owner.hierarchy,
          path,
        ], layoutContext),
        label: _resolvedLabelConfig([...owner.hierarchy, path], layoutContext),
        text: _resolvedTextConfig([...owner.hierarchy, path], layoutContext),
        tablePanelExpansion: _tablePanelExpansion,
        onTablePanelHeader: (table, panelId, path) {
          _tablePanelHeaderHits.add(
            _TablePanelHeaderHit(table: table, panelId: panelId, path: path),
          );
        },
        onTableNode: (target, path) {
          _tableNodeHits.add(_TableNodeHit(target: target, path: path));
        },
        onTableAction: (target, path) {
          _tableActionHits.add(_TableActionHit(target: target, path: path));
        },
        onTableClassificationLabel: (path, style) {
          _tableClassificationLabelHits.add(
            _TableClassificationLabelHit(path: path, style: style),
          );
        },
      );
    }
    if (!guidelinesPainted) drawGuidelines();
    for (final resolved in resolvedLayouts.values) {
      for (final ray in _resolvedLayoutChildren(
        resolved.layout,
        layoutContext,
      ).map((entry) => entry.value).whereType<LayoutSlotRayLayout>()) {
        if (!ray.visible || !ray.isVisible(layoutContext)) continue;
        final start = _resolveReference(
          ray.start,
          resolvedLayouts,
          layoutContext,
        );
        final target = _resolvePathSlotReference(
          ray.towards,
          resolvedLayouts,
          layoutContext,
        );
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawSlotRayArrow(canvas, start, target, ray);
        }
      }
      for (final ray
          in _resolvedLayoutChildren(resolved.layout, layoutContext)
              .map((entry) => entry.value)
              .whereType<LayoutSlotToDerivativeRayLayout>()) {
        if (!ray.visible || !ray.isVisible(layoutContext)) continue;
        final start = _resolvePathSlotReference(
          ray.start,
          resolvedLayouts,
          layoutContext,
        );
        final target = _resolveReference(
          ray.towards,
          resolvedLayouts,
          layoutContext,
        );
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawSlotToDerivativeRayArrow(canvas, start, target, ray);
        }
      }
      for (final stickman in _resolvedLayoutChildren(
        resolved.layout,
        layoutContext,
      ).map((entry) => entry.value).whereType<StickmanLayout>()) {
        if (!stickman.isVisible(layoutContext)) continue;
        _drawStickmanLayout(canvas, resolved.layout, resolved.bounds, stickman);
      }
      for (final plane in _resolvedLayoutChildren(
        resolved.layout,
        layoutContext,
      ).map((entry) => entry.value).whereType<PlaneLayout>()) {
        if (!plane.isVisible(layoutContext)) continue;
        _drawPlaneLayout(
          canvas,
          resolved.layout,
          resolved.bounds,
          plane,
          selectedNode,
        );
      }
    }
  }

  @override
  void onPointerMove(flame_events.PointerMoveEvent event) {
    hoverPosition = Offset(event.localPosition.x, event.localPosition.y);
    game.updateCursorPosition(hoverPosition);
    final hoveredNode = _hoveredNodeAt(hoverPosition!);
    game.updateHoveredNode(
      hoveredNode?.key,
      path: hoveredNode?.path,
      style: hoveredNode?.style,
    );
    final hoveredLabel = _hoveredClassificationLabelAt(hoverPosition!);
    game.updateHoveredClassificationLabel(
      path: hoveredLabel?.path,
      style: hoveredLabel?.style,
    );
    super.onPointerMove(event);
  }

  @override
  void onPointerMoveStop(flame_events.PointerMoveEvent event) {
    hoverPosition = null;
    game.updateCursorPosition(null);
    game.updateHoveredNode(null);
    game.updateHoveredClassificationLabel();
    super.onPointerMoveStop(event);
  }

  _HoveredNodeTarget? _hoveredNodeAt(Offset position) {
    for (final nodeHit in _tableNodeHits.reversed) {
      if (!nodeHit.path.contains(position)) continue;
      return (
        key: nodeHit.target.key,
        path: nodeHit.path,
        style: _resolvedNodeHighlightBorderStyle(
          game.layout,
          nodeHit.target.layout,
          nodeHit.target.resolvedNode,
          game.layoutContext,
        ),
      );
    }

    final layoutContext = game.layoutContext;
    final resolvedLayouts = _resolveLayouts(
      game.layout,
      Size(size.x, size.y),
      game.safePadding,
      layoutContext,
    );
    for (final placement in _pathLayoutPlacements<FanLayout>(
      game.layout,
      layoutContext,
    ).toList().reversed) {
      if (!placement.hierarchy.every(
        (layout) => layout.isVisible(layoutContext),
      )) {
        continue;
      }
      final tree = game.nodeTrees[placement.layout];
      if (tree == null) continue;
      final planePoints = game._resolveFanPlacementPoints(placement);
      if (planePoints == null) continue;
      final segments = _fanSegments(
        placement.layout,
        tree,
        _boundsForPoints(planePoints),
        resolvedLayouts,
        layoutContext,
        planePoints: planePoints,
      );
      for (final segment in segments.reversed) {
        if (!segment.path.contains(position)) continue;
        final resolvedNode = _resolvedFanNode(
          segment.occurrence,
          placement.layout,
        );
        return (
          key: '${placement.key}/${segment.occurrence.occurrenceId}',
          path: segment.path,
          style: _resolvedNodeHighlightBorderStyle(
            game.layout,
            placement.layout,
            resolvedNode,
            game.layoutContext,
          ),
        );
      }
    }
    for (final component in game._graphLayoutComponents.reversed) {
      final graphNode = component.hitTest(position);
      if (graphNode != null) {
        return (
          key: graphNode.key,
          path: graphNode.path,
          style: _resolvedNodeHighlightBorderStyle(
            game.layout,
            component.layout,
            graphNode.resolvedNode,
            game.layoutContext,
          ),
        );
      }
    }
    for (final component in game._nodeLayoutComponents.reversed) {
      final node = component.hitTest(position);
      if (node != null) {
        return (
          key: node.key,
          path: node.path,
          style: _resolvedNodeHighlightBorderStyle(
            game.layout,
            component.layout,
            node.resolvedNode,
            game.layoutContext,
          ),
        );
      }
    }

    final hit = _hitTestLayoutTap(
      game.layout,
      Size(size.x, size.y),
      game.safePadding,
      position,
      game.vaultNodeResolver,
      game.highlightedNodes,
      game.selectedNodes,
      searchResults: game._searchHud.showsResults ? game.queryNodes : const [],
      searchOpenned: game._searchHud.isOpen,
    );
    final nodePath = hit?.nodePath;
    if (hit?.target.resolvedNode?.node == null || nodePath == null) return null;
    return (
      key: hit!.target.key,
      path: nodePath,
      style: _resolvedNodeHighlightBorderStyle(
        game.layout,
        hit.target.layout,
        hit.target.resolvedNode,
        game.layoutContext,
      ),
    );
  }

  _HoveredClassificationLabelTarget? _hoveredClassificationLabelAt(
    Offset position,
  ) {
    for (final labelHit in _tableClassificationLabelHits.reversed) {
      if (labelHit.path.contains(position)) {
        return (path: labelHit.path, style: labelHit.style);
      }
    }
    return null;
  }

  @override
  void onTapUp(flame_events.TapUpEvent event) {
    final localPosition = Offset(event.localPosition.x, event.localPosition.y);
    for (final actionHit in _tableActionHits.reversed) {
      if (actionHit.path.contains(localPosition)) {
        game.dispatchLayoutTap(actionHit.target);
        return;
      }
    }
    for (final nodeHit in _tableNodeHits.reversed) {
      if (nodeHit.path.contains(localPosition)) {
        game.dispatchLayoutTap(nodeHit.target);
        return;
      }
    }
    for (final header in _tablePanelHeaderHits.reversed) {
      if (header.path.contains(localPosition)) {
        _toggleTablePanel(header.table, header.panelId);
        return;
      }
    }
    final target = _hitTestLayoutTapTarget(
      game.layout,
      Size(size.x, size.y),
      game.safePadding,
      localPosition,
      game.vaultNodeResolver,
      game.highlightedNodes,
      game.selectedNodes,
      searchResults: game._searchHud.showsResults ? game.queryNodes : const [],
      searchOpenned: game._searchHud.isOpen,
    );
    if (target == null) return;
    if (target.layout case final NodeListLayout nodeList
        when nodeList.dataSource == NodeListDataSource.searchResults) {
      final node = target.resolvedNode;
      if (node != null) game._selectSearchNode(node);
      return;
    }
    if (target.layout case PanelLayout(onTap: final action?)) {
      game.performLayoutTapAction(action);
      return;
    }
    if (target.layout.aliases.contains('cancel-interface-action') ||
        target.layout.aliases.contains('clear-selection-action')) {
      game.closeSearchHud();
    }
    game.dispatchLayoutTap(target);
  }

  double _tablePanelExpansion(TableLayout table, String panelId) {
    final panel = _tablePanel(table, panelId);
    if (panel == null || !panel.isFoldable) return 1;
    return (_tablePanelAnimations[table] ??= {})
        .putIfAbsent(
          panelId,
          () => _TablePanelFoldAnimation(
            duration: table.panelFoldDuration,
            initiallyFolded: panel.startsFolded,
          ),
        )
        .progress;
  }

  void _toggleTablePanel(TableLayout table, String panelId) {
    _tablePanelExpansion(table, panelId);
    _tablePanelAnimations[table]?[panelId]?.toggle();
  }
}

class _TablePanelFoldAnimation {
  _TablePanelFoldAnimation({
    required double duration,
    required bool initiallyFolded,
  }) : _expanded = !initiallyFolded,
       _controller = EffectController(
         duration: duration,
         curve: Curves.easeInOutCubic,
       ) {
    if (_expanded) _controller.setToEnd();
  }

  final EffectController _controller;
  bool _expanded;

  double get progress => _controller.progress.clamp(0, 1);

  void toggle() => _expanded = !_expanded;

  void update(double dt) {
    if (_expanded) {
      _controller.advance(dt);
    } else {
      _controller.recede(dt);
    }
  }
}

class _TablePanelHeaderHit {
  const _TablePanelHeaderHit({
    required this.table,
    required this.panelId,
    required this.path,
  });

  final TableLayout table;
  final String panelId;
  final Path path;
}

class _TableNodeHit {
  const _TableNodeHit({required this.target, required this.path});

  final LayoutTapTarget target;
  final Path path;
}

class _TableActionHit {
  const _TableActionHit({required this.target, required this.path});

  final LayoutTapTarget target;
  final Path path;
}

class _TableClassificationLabelHit {
  const _TableClassificationLabelHit({required this.path, required this.style});

  final Path path;
  final GuideStyle style;
}

class _FanComponent extends PositionComponent
    with HasGameReference<LandscapeXlLayoutGame>, flame_events.TapCallbacks {
  _FanComponent(this.placement);

  final _PathLayoutPlacement<FanLayout> placement;

  bool get _isVisible => placement.hierarchy.every(
    (layout) => layout.isVisible(game.layoutContext),
  );

  @override
  void onTapDown(flame_events.TapDownEvent event) {
    event.continuePropagation = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    final fan = placement.layout;
    if (!_isVisible) return;
    final nodeTree = game.nodeTrees[fan];
    final resolvedLayouts = _resolveLayouts(
      game.layout,
      Size(size.x, size.y),
      game.safePadding,
      game.layoutContext,
    );
    final planePoints = game._resolveFanPlacementPoints(placement);
    if (planePoints == null) return;
    _drawFanLayout(
      canvas,
      _boundsForPoints(planePoints),
      fan,
      nodeTree,
      resolvedLayouts,
      game.layoutContext,
      nodeConfig: (node) => _resolvedNodeConfig(
        placement.hierarchy,
        _nodeLayoutContext(game.layoutContext, node),
      ),
      imageFor: (assetPath) => game.images.containsKey(assetPath)
          ? game.images.fromCache(assetPath)
          : null,
      planePoints: planePoints,
    );
  }

  @override
  void onTapUp(flame_events.TapUpEvent event) {
    event.continuePropagation = true;
    final tapHandler = game.onLayoutTap;
    final fan = placement.layout;
    final nodeTree = game.nodeTrees[fan];
    if (tapHandler == null || nodeTree == null || !_isVisible) {
      return;
    }
    final resolvedLayouts = _resolveLayouts(
      game.layout,
      Size(size.x, size.y),
      game.safePadding,
      game.layoutContext,
    );
    final planePoints = game._resolveFanPlacementPoints(placement);
    if (planePoints == null) return;
    final occurrence = _hitTestFan(
      fan,
      nodeTree,
      _boundsForPoints(planePoints),
      resolvedLayouts,
      Offset(event.localPosition.x, event.localPosition.y),
      game.layoutContext,
      planePoints: planePoints,
    );
    if (occurrence == null) return;
    final resolvedNode = _resolvedFanNode(occurrence, fan);
    game.dispatchLayoutTap(
      LayoutTapTarget(
        key: '${placement.key}/${occurrence.occurrenceId}',
        layout: fan,
        node: resolvedNode,
        resolvedNode: resolvedNode,
        label: _nodePresentation(
          occurrence.node,
          fan,
          nodeConfig: _resolvedNodeConfig(
            placement.hierarchy,
            _nodeLayoutContext(game.layoutContext, resolvedNode),
          ),
        ).text,
      ),
    );
    event.continuePropagation = false;
  }
}

LayoutContext _layoutContext(
  Layout root,
  List<ResolvedVaultNode> highlightedNodes,
  List<ResolvedVaultNode> selectedNodes, {
  bool searchOpenned = false,
}) {
  final selectedPath = selectedNodes.lastOrNull?.path;
  final selectedPaths = [for (final node in selectedNodes) node.path];
  final nodeContext = LayoutContext(
    searchOpenned: searchOpenned,
    selectedNodePath: selectedPath,
    selectedNodePaths: selectedPaths,
    highlightedNodePaths: [for (final node in highlightedNodes) node.path],
    activeNodeSlugs: [
      for (final node in selectedNodes)
        if (node.node case final graphNode?)
          if (graphNode.slug.trim().isNotEmpty) graphNode.slug.trim(),
    ],
    activeNodePaths: [
      for (final path in selectedPaths)
        if (path.trim().isNotEmpty) path.trim(),
    ],
    rootFontSize: root.text.fontSize ?? LayoutTextDefaults.rootFontSize,
  );
  return nodeContext;
}

LayoutContext _nodeLayoutContext(
  LayoutContext context,
  ResolvedVaultNode resolvedNode,
) {
  final node = resolvedNode.node;
  final resolvedPath = resolvedNode.path.trim();
  final nodePath = node?.path.trim();
  return context.withCurrentNode(
    path: resolvedPath.isNotEmpty
        ? resolvedPath
        : nodePath == null || nodePath.isEmpty
        ? null
        : nodePath,
    slug: node?.slug.trim(),
  );
}

SearchLayout _searchLayoutConfig(Layout root) =>
    _searchLayoutConfigOrNull(root) ?? SearchLayout();

SearchLayout? _searchLayoutConfigOrNull(Layout root) {
  if (root is SearchLayout) return root;
  for (final child in root.children.values) {
    final searchLayout = _searchLayoutConfigOrNull(child);
    if (searchLayout != null) return searchLayout;
  }
  return null;
}

void _drawLayoutPath(
  Canvas canvas,
  Size size,
  LayoutPath layoutPath,
  Map<String, _ResolvedLayout> layouts,
  VaultNodeResolver? vaultNodeResolver,
  SystemInfo? systemInfo,
  List<ResolvedVaultNode> selectedNodes,
  _NodeListSources nodeListSources,
  ClassificationLabelComponent classificationLabelComponent,
  Offset? hoverPosition,
  LayoutContext layoutContext, {
  required List<LayoutBackground> background,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
  required ui.Image? Function(String assetPath) imageFor,
  required PanelConfig panelDefaults,
  required NodeConfig nodeConfig,
  required LabelConfig label,
  required LayoutTextConfig text,
  required double Function(TableLayout table, String panelId)
  tablePanelExpansion,
  required void Function(TableLayout table, String panelId, Path path)
  onTablePanelHeader,
  required void Function(LayoutTapTarget target, Path path) onTableNode,
  required void Function(LayoutTapTarget target, Path path) onTableAction,
  required void Function(Path path, GuideStyle style)
  onTableClassificationLabel,
}) {
  final resolvedPoints = _resolvedLayoutPathPoints(
    layoutPath,
    layouts,
    layoutContext,
  );
  if (resolvedPoints == null) return;
  final projection = _resolvedLayoutPathProjection(
    layoutPath,
    resolvedPoints,
    layouts,
    layoutContext,
  );
  final style = layoutPath.style;
  final path =
      projection?.path ??
      _linearLayoutPath(resolvedPoints, close: style?.close ?? true);

  _drawLayoutPathBackgrounds(
    canvas,
    path,
    resolvedPoints,
    background,
    layoutContext,
    imageFor,
    layoutPath: layoutPath,
    projection: projection,
    curvedImageMeshes: curvedImageMeshes,
  );

  if (style != null) {
    final fillPaint = Paint()
      ..color = style.fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  final strokeStyle = style?.strokeStyle;
  if (strokeStyle != null) {
    _drawGuidePath(canvas, path, strokeStyle);
  }

  final ticks = layoutPath.ticks;
  if (ticks != null) {
    _drawPathTicks(canvas, size, resolvedPoints, ticks);
  }

  canvas.save();
  canvas.clipPath(path);

  void drawTable(
    TableLayout table,
    List<Offset> tablePoints, {
    PanelConfig? inheritedPanel,
    NodeConfig? inheritedNodeConfig,
  }) {
    _drawTableLayout(
      canvas,
      tablePoints,
      table,
      _tableData(selectedNodes, systemInfo),
      hoverPosition,
      classificationLabelComponent,
      nodeListSources: nodeListSources,
      layoutContext: layoutContext,
      panelDefaults:
          inheritedPanel ??
          panelDefaults.merge(layoutPath.resolvePanelConfig(layoutContext)),
      nodeConfig: (inheritedNodeConfig ?? nodeConfig).merge(
        table.resolveNodeConfig(layoutContext),
      ),
      label: label,
      text: text,
      panelExpansion: (panelId) => tablePanelExpansion(table, panelId),
      onPanelHeader: (panelId, path) =>
          onTablePanelHeader(table, panelId, path),
      onNode: onTableNode,
      onAction: (action, rowKey, value, path) => onTableAction(
        LayoutTapTarget(
          key:
              'table/${table.aliases.firstOrNull ?? 'table'}/$rowKey/${action.name}',
          layout: table,
          label: value,
          tableAction: action,
          textValue: value,
        ),
        path,
      ),
      onClassificationLabel: onTableClassificationLabel,
    );
  }

  for (final composition in _resolvedLayoutChildren(
    layoutPath,
    layoutContext,
  ).map((entry) => entry.value).whereType<ColumnLayout>()) {
    if (!composition.isVisible(layoutContext)) continue;
    _drawFlexComposition(
      canvas,
      _screenOrderedQuadrilateral(resolvedPoints),
      composition,
      layoutContext,
      nodeListSources,
      text: text.merge(composition.resolveTextConfig(layoutContext)),
      projection: projection,
    );
  }
  for (final composition in _resolvedLayoutChildren(
    layoutPath,
    layoutContext,
  ).map((entry) => entry.value).whereType<RowLayout>()) {
    if (!composition.isVisible(layoutContext)) continue;
    _drawFlexComposition(
      canvas,
      _screenOrderedQuadrilateral(resolvedPoints),
      composition,
      layoutContext,
      nodeListSources,
      text: text.merge(composition.resolveTextConfig(layoutContext)),
      projection: projection,
    );
  }
  for (final grid in _resolvedLayoutChildren(
    layoutPath,
    layoutContext,
  ).map((entry) => entry.value).whereType<GridLayout>()) {
    if (!grid.isVisible(layoutContext)) continue;
    _drawGridBackgrounds(
      canvas,
      resolvedPoints,
      grid,
      layoutContext,
      imageFor,
      layoutPath: layoutPath,
      projection: projection,
      curvedImageMeshes: curvedImageMeshes,
    );
    _drawGridComposition(
      canvas,
      _screenOrderedQuadrilateral(resolvedPoints),
      grid,
      layoutContext,
      nodeListSources,
      text: text.merge(grid.resolveTextConfig(layoutContext)),
      projection: projection,
    );
  }
  for (final table in _resolvedLayoutChildren(
    layoutPath,
    layoutContext,
  ).map((entry) => entry.value).whereType<TableLayout>()) {
    if (!table.isVisible(layoutContext)) continue;
    drawTable(table, resolvedPoints);
  }
  for (final entry in _resolvedLayoutChildren(layoutPath, layoutContext)) {
    final grid = entry.value;
    if (grid is! GridLayout || !grid.isVisible(layoutContext)) continue;
    final placements = _gridPathLayoutPlacements<TableLayout>(
      layoutPath,
      grid,
      [entry.key],
      [layoutPath, grid],
      layoutContext,
    );
    for (final placement in placements) {
      if (!placement.hierarchy.every(
        (layout) => layout.isVisible(layoutContext),
      )) {
        continue;
      }
      final tablePoints = _resolveGridPlacementPoints(
        resolvedPoints,
        projection,
        placement.gridSteps,
        layoutContext,
      );
      if (tablePoints == null) continue;
      var inheritedPanel = panelDefaults.merge(
        layoutPath.resolvePanelConfig(layoutContext),
      );
      var inheritedNodeConfig = nodeConfig;
      for (final step in placement.gridSteps) {
        inheritedPanel = inheritedPanel.merge(
          step.grid.resolvePanelConfig(layoutContext),
        );
        inheritedNodeConfig = inheritedNodeConfig.merge(
          step.grid.resolveNodeConfig(layoutContext),
        );
      }
      drawTable(
        placement.layout,
        tablePoints,
        inheritedPanel: inheritedPanel,
        inheritedNodeConfig: inheritedNodeConfig,
      );
    }
  }
  canvas.restore();
}

void _drawGridBackgrounds(
  Canvas canvas,
  List<Offset> owningPoints,
  GridLayout grid,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  required LayoutPath layoutPath,
  required _LayoutPathProjection? projection,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  _drawSurfaceBackgrounds(
    canvas,
    owningPoints,
    grid,
    frame,
    layoutContext,
    imageFor,
    layoutPath: layoutPath,
    projection: projection,
    curvedImageMeshes: curvedImageMeshes,
  );
  final isCurved = projection?.canProjectBackground ?? false;
  final tracks = _resolvedGridTracks(
    grid,
    Size(
      (isCurved
                  ? projection!.flatSize
                  : _quadrilateralAverageSize(owningPoints))
              .width *
          (frame.right - frame.left),
      (isCurved
                  ? projection!.flatSize
                  : _quadrilateralAverageSize(owningPoints))
              .height *
          (frame.bottom - frame.top),
    ),
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return;
  for (final child in _resolveGridChildren(grid, tracks, layoutContext)) {
    final childFrame = _scaleFlexSurfaceRect(frame, child.frame);
    if (child.layout case final GridLayout childGrid) {
      _drawGridBackgrounds(
        canvas,
        owningPoints,
        childGrid,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
        frame: childFrame,
      );
    } else if (child.layout is RowLayout || child.layout is ColumnLayout) {
      _drawFlexBackgrounds(
        canvas,
        owningPoints,
        child.layout,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
        frame: childFrame,
      );
    } else {
      _drawSurfaceBackgrounds(
        canvas,
        owningPoints,
        child.layout,
        childFrame,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
      );
    }
  }
}

void _drawFlexBackgrounds(
  Canvas canvas,
  List<Offset> owningPoints,
  Layout composition,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  required LayoutPath layoutPath,
  required _LayoutPathProjection? projection,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  _drawSurfaceBackgrounds(
    canvas,
    owningPoints,
    composition,
    frame,
    layoutContext,
    imageFor,
    layoutPath: layoutPath,
    projection: projection,
    curvedImageMeshes: curvedImageMeshes,
  );
  final vertical = composition is ColumnLayout;
  if (!vertical && composition is! RowLayout) return;
  final children = _resolvedLayoutChildren(composition, layoutContext)
      .where((entry) => entry.value.isVisible(layoutContext))
      .toList(growable: false);
  if (children.isEmpty) return;
  final surfaceSize = projection?.canProjectBackground ?? false
      ? projection!.flatSize
      : _quadrilateralAverageSize(owningPoints);
  final mainPixels = vertical
      ? surfaceSize.height * (frame.bottom - frame.top)
      : surfaceSize.width * (frame.right - frame.left);
  final crossPixels = vertical
      ? surfaceSize.width * (frame.right - frame.left)
      : surfaceSize.height * (frame.bottom - frame.top);
  if (mainPixels <= 0) return;
  final stops = _gridTrackStops(
    [
      for (final child in children)
        child.value.resolveSize(layoutContext).primary,
    ],
    mainPixels,
    rootFontSize: layoutContext.rootFontSize,
  );
  for (var index = 0; index < children.length; index += 1) {
    final child = children[index].value;
    final start = stops[index];
    final end = stops[index + 1];
    final crossRange = _resolveFlexCrossAxisRange(
      composition,
      child,
      crossPixels,
      layoutContext,
    );
    final childFrame = vertical
        ? (
            left: frame.left,
            top: ui.lerpDouble(frame.top, frame.bottom, start)!,
            right: frame.right,
            bottom: ui.lerpDouble(frame.top, frame.bottom, end)!,
          )
        : (
            left: ui.lerpDouble(frame.left, frame.right, start)!,
            top: ui.lerpDouble(frame.top, frame.bottom, crossRange.start)!,
            right: ui.lerpDouble(frame.left, frame.right, end)!,
            bottom: ui.lerpDouble(frame.top, frame.bottom, crossRange.end)!,
          );
    if (child is GridLayout) {
      _drawGridBackgrounds(
        canvas,
        owningPoints,
        child,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
        frame: childFrame,
      );
    } else if (child is RowLayout || child is ColumnLayout) {
      _drawFlexBackgrounds(
        canvas,
        owningPoints,
        child,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
        frame: childFrame,
      );
    } else {
      _drawSurfaceBackgrounds(
        canvas,
        owningPoints,
        child,
        childFrame,
        layoutContext,
        imageFor,
        layoutPath: layoutPath,
        projection: projection,
        curvedImageMeshes: curvedImageMeshes,
      );
    }
  }
}

void _drawSurfaceBackgrounds(
  Canvas canvas,
  List<Offset> owningPoints,
  Layout layout,
  _FlexSurfaceRect frame,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  required LayoutPath layoutPath,
  required _LayoutPathProjection? projection,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
}) {
  final resolvedBackground = layout.resolveBackground(layoutContext);
  if (resolvedBackground.isEmpty) return;
  final isCurved = projection?.canProjectBackground ?? false;
  final points = isCurved
      ? _curvedSurfaceCorners(projection!, frame)
      : _quadrilateralSlice(
          _screenOrderedQuadrilateral(owningPoints),
          left: frame.left,
          right: frame.right,
          top: frame.top,
          bottom: frame.bottom,
        );
  final path = isCurved
      ? _curvedSurfacePath(projection!, frame)
      : _polygonPath(points);
  final backgrounds = [...resolvedBackground]
    ..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
  for (final background in backgrounds) {
    _drawLayoutPathBackground(
      canvas,
      path,
      points,
      background,
      layoutContext,
      imageFor,
      layoutPath: layoutPath,
      projection: isCurved ? projection : null,
      curvedImageMeshes: curvedImageMeshes,
      surfaceFrame: frame,
    );
  }
}

void _drawLayoutPathBackgrounds(
  Canvas canvas,
  Path path,
  List<Offset> points,
  List<LayoutBackground> configuredBackground,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  required LayoutPath layoutPath,
  required _LayoutPathProjection? projection,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
}) {
  final orderedBackground = [...configuredBackground]
    ..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
  for (final background in orderedBackground) {
    _drawLayoutPathBackground(
      canvas,
      path,
      points,
      background,
      layoutContext,
      imageFor,
      layoutPath: layoutPath,
      projection: projection,
      curvedImageMeshes: curvedImageMeshes,
    );
  }
}

void _drawLayoutPathBackground(
  Canvas canvas,
  Path path,
  List<Offset> points,
  LayoutBackground background,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  required LayoutPath layoutPath,
  required _LayoutPathProjection? projection,
  required Map<(LayoutPath, LayoutImageBackground), _CurvedLayoutPathImageMesh>
  curvedImageMeshes,
  double inheritedOpacity = 1,
  _FlexSurfaceRect surfaceFrame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  final opacity = (inheritedOpacity * background.opacity)
      .clamp(0, 1)
      .toDouble();
  if (opacity == 0) return;
  if (background is RandomLayoutBackground) {
    _drawLayoutPathBackground(
      canvas,
      path,
      points,
      _selectRandomLayoutBackground(background),
      layoutContext,
      imageFor,
      layoutPath: layoutPath,
      projection: projection,
      curvedImageMeshes: curvedImageMeshes,
      inheritedOpacity: opacity,
      surfaceFrame: surfaceFrame,
    );
    return;
  }
  if (background is ConditionalLayoutBackground) {
    if (!background.activeCondition.isActive(layoutContext)) return;
    _drawLayoutPathBackground(
      canvas,
      path,
      points,
      background.background,
      layoutContext,
      imageFor,
      layoutPath: layoutPath,
      projection: projection,
      curvedImageMeshes: curvedImageMeshes,
      inheritedOpacity: opacity,
      surfaceFrame: surfaceFrame,
    );
    return;
  }
  if (background is LayoutBackgroundColor) {
    canvas.drawPath(
      path,
      Paint()
        ..color = background.color.withValues(
          alpha: background.color.a * opacity,
        )
        ..style = PaintingStyle.fill,
    );
    return;
  }
  if (background is! LayoutImageBackground) return;

  final image = imageFor(background.assetPath);
  if (image == null || points.length < 3) return;

  if (projection case final projection? when projection.canProjectBackground) {
    final key = (layoutPath, background);
    final cachedMesh = curvedImageMeshes[key];
    final mesh = cachedMesh?.matches(projection, image, surfaceFrame) ?? false
        ? cachedMesh!
        : _CurvedLayoutPathImageMesh(
            projection: projection,
            image: image,
            background: background,
            surfaceFrame: surfaceFrame,
          );
    if (!identical(mesh, cachedMesh)) {
      cachedMesh?.dispose();
      curvedImageMeshes[key] = mesh;
    }
    canvas.save();
    canvas.clipPath(path);
    mesh.draw(canvas, opacity);
    canvas.restore();
    return;
  }

  final bounds = _boundsForPoints(points);
  if (bounds.isEmpty) return;
  canvas.save();
  canvas.clipPath(path);
  var imageRect = bounds;
  if (points.length == 4) {
    final leftHeight = (points[3] - points[0]).distance;
    final rightHeight = (points[2] - points[1]).distance;
    final topWidth = (points[1] - points[0]).distance;
    final bottomWidth = (points[2] - points[3]).distance;
    final flatWidth = (topWidth + bottomWidth) / 2;
    final flatHeight = (leftHeight + rightHeight) / 2;
    if (flatWidth <= 0 || flatHeight <= 0) {
      canvas.restore();
      return;
    }
    final perspectivePoints = [
      _tableLayoutPoint(points, row: 0, column: 0),
      _tableLayoutPoint(points, row: 0, column: 1),
      _tableLayoutPoint(points, row: 1, column: 1),
      _tableLayoutPoint(points, row: 1, column: 0),
    ];
    canvas.transform(
      _rectToQuadTransform(flatWidth, flatHeight, perspectivePoints),
    );
    imageRect = Rect.fromLTWH(0, 0, flatWidth, flatHeight);
  }
  for (final tile in _backgroundImageTiles(imageRect, background.repeat)) {
    _paintBackgroundImage(canvas, tile, image, background, opacity);
  }
  canvas.restore();
}

void _paintBackgroundImage(
  Canvas canvas,
  Rect tile,
  ui.Image image,
  LayoutImageBackground background,
  double opacity,
) {
  canvas.save();
  final radians = background.rotationDegrees * math.pi / 180;
  if (radians != 0 || background.scale != 1) {
    canvas
      ..translate(tile.center.dx, tile.center.dy)
      ..rotate(radians)
      ..scale(background.scale)
      ..translate(-tile.center.dx, -tile.center.dy);
  }
  paintImage(
    canvas: canvas,
    rect: tile,
    image: image,
    fit: _backgroundImageBoxFit(background.fit),
    alignment: _backgroundImageAlignment(background.position),
    opacity: opacity,
  );
  canvas.restore();
}

BoxFit _backgroundImageBoxFit(LayoutBackgroundFit fit) => switch (fit) {
  LayoutBackgroundFit.cover => BoxFit.cover,
  LayoutBackgroundFit.contain => BoxFit.contain,
  LayoutBackgroundFit.fill => BoxFit.fill,
};

Alignment _backgroundImageAlignment(Offset position) =>
    Alignment(position.dx * 2 - 1, position.dy * 2 - 1);

Iterable<Rect> _backgroundImageTiles(Rect bounds, int repeat) sync* {
  final tileWidth = bounds.width / repeat;
  for (var index = 0; index < repeat; index += 1) {
    yield Rect.fromLTWH(
      bounds.left + tileWidth * index,
      bounds.top,
      tileWidth,
      bounds.height,
    );
  }
}

Path _linearLayoutPath(List<Offset> points, {required bool close}) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  if (close) path.close();
  return path;
}

void _drawGuidePath(Canvas canvas, Path path, GuideStyle style) {
  final paint = Paint()
    ..color = style.color
    ..strokeWidth = style.strokeWidth
    ..strokeCap = style.strokeCap
    ..style = PaintingStyle.stroke;
  if (style.pattern == GuideLinePattern.solid) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final metric in path.computeMetrics()) {
    final step = style.pattern == GuideLinePattern.dotted
        ? math.max(style.dashInterval, style.strokeWidth * 2)
        : style.dashLength + style.dashInterval;
    for (var offset = 0.0; offset < metric.length; offset += step) {
      if (style.pattern == GuideLinePattern.dotted) {
        final tangent = metric.getTangentForOffset(offset);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            style.strokeWidth / 2,
            paint..style = PaintingStyle.fill,
          );
        }
      } else {
        canvas.drawPath(
          metric.extractPath(
            offset,
            math.min(offset + style.dashLength, metric.length),
          ),
          paint,
        );
      }
    }
  }
}

class _CubicLayoutPathSegment {
  const _CubicLayoutPathSegment({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  Offset pointAt(double t) {
    final inverse = 1 - t;
    return start * (inverse * inverse * inverse) +
        control1 * (3 * inverse * inverse * t) +
        control2 * (3 * inverse * t * t) +
        end * (t * t * t);
  }
}

class _ResolvedLayoutPathCurve {
  _ResolvedLayoutPathCurve._({
    required this.startIndex,
    required this.endIndex,
    required this.points,
    required this.segments,
    required this.averageY,
    required this.length,
  });

  static _ResolvedLayoutPathCurve? resolve(
    List<Offset> pathPoints, {
    required Offset from,
    required Offset through,
    required Offset to,
  }) {
    final startIndex = _matchingPathPointIndex(pathPoints, from);
    final endIndex = _matchingPathPointIndex(pathPoints, to);
    if (startIndex == null || endIndex == null) return null;
    final curvePoints = [from, through, to];
    final segments = <_CubicLayoutPathSegment>[];
    for (var index = 0; index < curvePoints.length - 1; index += 1) {
      final start = curvePoints[index];
      final end = curvePoints[index + 1];
      final before = index == 0
          ? start - (end - start)
          : curvePoints[index - 1];
      final after = index + 2 >= curvePoints.length
          ? end + (end - start)
          : curvePoints[index + 2];
      final isCollapsed = (end - start).distance <= 0.000001;
      segments.add(
        _CubicLayoutPathSegment(
          start: start,
          control1: isCollapsed ? start : start + (end - before) / 6,
          control2: isCollapsed ? end : end - (after - start) / 6,
          end: end,
        ),
      );
    }
    if (segments.isEmpty) return null;
    var length = 0.0;
    var previous = segments.first.start;
    for (final segment in segments) {
      for (var sample = 1; sample <= 32; sample += 1) {
        final point = segment.pointAt(sample / 32);
        length += (point - previous).distance;
        previous = point;
      }
    }
    return _ResolvedLayoutPathCurve._(
      startIndex: startIndex,
      endIndex: endIndex,
      points: List<Offset>.unmodifiable(curvePoints),
      segments: segments,
      averageY:
          curvePoints.fold<double>(0, (sum, point) => sum + point.dy) /
          curvePoints.length,
      length: length,
    );
  }

  final int startIndex;
  final int endIndex;
  final List<Offset> points;
  final List<_CubicLayoutPathSegment> segments;
  final double averageY;
  final double length;

  Offset pointAt(double t) {
    final scaled = t.clamp(0, 1).toDouble() * segments.length;
    final index = math.min(scaled.floor(), segments.length - 1);
    return segments[index].pointAt(scaled - index);
  }
}

int? _matchingPathPointIndex(List<Offset> points, Offset target) {
  for (var index = 0; index < points.length; index += 1) {
    if ((points[index] - target).distance <= 0.000001) return index;
  }
  return null;
}

class _LayoutPathCurveBoundary {
  const _LayoutPathCurveBoundary(this.curve, {required this.reversed});

  final _ResolvedLayoutPathCurve curve;
  final bool reversed;

  Offset pointAt(double t) => curve.pointAt(reversed ? 1 - t : t);
}

class _LayoutPathProjection {
  _LayoutPathProjection._({
    required this.sourcePoints,
    required this.path,
    required this.top,
    required this.bottom,
  });

  static _LayoutPathProjection? resolve(
    List<Offset> points,
    List<({Offset? from, Offset? through, Offset? to})> configuredCurves, {
    required bool close,
  }) {
    if (configuredCurves.isEmpty || points.length < 2) return null;
    final curves = <_ResolvedLayoutPathCurve>[];
    for (final configuredCurve in configuredCurves) {
      final from = configuredCurve.from;
      final through = configuredCurve.through;
      final to = configuredCurve.to;
      if (from == null || through == null || to == null) return null;
      final curve = _ResolvedLayoutPathCurve.resolve(
        points,
        from: from,
        through: through,
        to: to,
      );
      if (curve == null) return null;
      curves.add(curve);
    }
    final curvedEdges =
        <(int, int), ({_ResolvedLayoutPathCurve curve, bool reversed})>{
          for (final curve in curves)
            (curve.startIndex, curve.endIndex): (curve: curve, reversed: false),
          for (final curve in curves)
            (curve.endIndex, curve.startIndex): (curve: curve, reversed: true),
        };
    final sourcePoints = <Offset>[
      ...points,
      for (final curve in curves) ...curve.points,
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final segmentCount = points.length == 2
        ? 1
        : close
        ? points.length
        : points.length - 1;
    for (var index = 0; index < segmentCount; index += 1) {
      final nextIndex = (index + 1) % points.length;
      final curvedEdge = curvedEdges[(index, nextIndex)];
      if (curvedEdge == null) {
        path.lineTo(points[nextIndex].dx, points[nextIndex].dy);
        continue;
      }
      final segments = curvedEdge.reversed
          ? curvedEdge.curve.segments.reversed
          : curvedEdge.curve.segments;
      for (final segment in segments) {
        final control1 = curvedEdge.reversed
            ? segment.control2
            : segment.control1;
        final control2 = curvedEdge.reversed
            ? segment.control1
            : segment.control2;
        final end = curvedEdge.reversed ? segment.start : segment.end;
        path.cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          end.dx,
          end.dy,
        );
      }
    }
    if (close && points.length > 2) path.close();

    final verticallyOrdered = [...curves]
      ..sort((left, right) => left.averageY.compareTo(right.averageY));
    final topCurve = verticallyOrdered.first;
    final bottomCurve = verticallyOrdered.length > 1
        ? verticallyOrdered.last
        : null;
    return _LayoutPathProjection._(
      sourcePoints: List<Offset>.unmodifiable(sourcePoints),
      path: path,
      top: _LayoutPathCurveBoundary(
        topCurve,
        reversed: topCurve.pointAt(0).dx > topCurve.pointAt(1).dx,
      ),
      bottom: bottomCurve == null
          ? null
          : _LayoutPathCurveBoundary(
              bottomCurve,
              reversed: bottomCurve.pointAt(0).dx > bottomCurve.pointAt(1).dx,
            ),
    );
  }

  final List<Offset> sourcePoints;
  final Path path;
  final _LayoutPathCurveBoundary top;
  final _LayoutPathCurveBoundary? bottom;

  bool get canProjectBackground => bottom != null;

  Size get flatSize {
    final bottomBoundary = bottom;
    if (bottomBoundary == null) return Size.zero;
    final leftHeight = (bottomBoundary.pointAt(0) - top.pointAt(0)).distance;
    final rightHeight = (bottomBoundary.pointAt(1) - top.pointAt(1)).distance;
    return Size(
      (top.curve.length + bottomBoundary.curve.length) / 2,
      (leftHeight + rightHeight) / 2,
    );
  }

  int get meshSegmentCount =>
      (flatSize.width / 2).ceil().clamp(128, 1536).toInt();

  Offset project(double u, double v) =>
      Offset.lerp(top.pointAt(u), bottom!.pointAt(u), v)!;
}

_LayoutPathProjection? _resolvedLayoutPathProjection(
  LayoutPath layoutPath,
  List<Offset> points,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext,
) {
  final rawPoints = [
    for (final reference in layoutPath.points)
      _resolveReference(reference, layouts, layoutContext),
  ];

  Offset? structuralEndpoint(LayoutDerivativeReference reference) {
    final resolved = _resolveReference(reference, layouts, layoutContext);
    if (resolved == null) return null;
    for (var index = 0; index < rawPoints.length; index += 1) {
      final rawPoint = rawPoints[index];
      if (rawPoint != null &&
          (rawPoint - resolved).distance <= 0.000001 &&
          index < points.length) {
        return points[index];
      }
    }
    return resolved;
  }

  return _LayoutPathProjection.resolve(points, [
    for (final curve in layoutPath.curves)
      (
        from: structuralEndpoint(curve.from),
        through: _resolveReference(curve.through, layouts, layoutContext),
        to: structuralEndpoint(curve.to),
      ),
  ], close: layoutPath.style?.close ?? true);
}

List<Offset>? _resolvedCurvedFanSurface(
  LayoutPath layoutPath,
  List<Offset> points,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext,
) {
  if (points.length != 2 || layoutPath.curves.isEmpty) return null;
  final curve = layoutPath.curves.first;
  final from = _resolveReference(curve.from, layouts, layoutContext);
  final through = _resolveReference(curve.through, layouts, layoutContext);
  final to = _resolveReference(curve.to, layouts, layoutContext);
  if (from == null || through == null || to == null) return null;

  final forward =
      (points.first - from).distance <= (points.last - from).distance;
  final start = forward ? points.first : points.last;
  final end = forward ? points.last : points.first;
  final resolvedCurve = _ResolvedLayoutPathCurve.resolve(
    [start, end],
    from: start,
    through: through,
    to: end,
  );
  if (resolvedCurve == null) return null;

  const sampleCount = 96;
  final root = Offset.lerp(start, end, 0.5)!;
  return [
    root,
    for (var index = 0; index <= sampleCount; index += 1)
      resolvedCurve.pointAt(index / sampleCount),
  ];
}

class _CurvedLayoutPathImageMesh {
  _CurvedLayoutPathImageMesh({
    required _LayoutPathProjection projection,
    required this.image,
    required LayoutImageBackground background,
    this.surfaceFrame = const (left: 0, top: 0, right: 1, bottom: 1),
  }) : sourcePoints = projection.sourcePoints,
       meshSegmentCount = projection.meshSegmentCount,
       _vertices = _buildVertexTiles(
         projection,
         image,
         background,
         surfaceFrame,
       ),
       _shader = ui.ImageShader(
         image,
         TileMode.clamp,
         TileMode.clamp,
         Float64List.fromList(const [
           1,
           0,
           0,
           0,
           0,
           1,
           0,
           0,
           0,
           0,
           1,
           0,
           0,
           0,
           0,
           1,
         ]),
         filterQuality: FilterQuality.medium,
       ) {
    _paint.shader = _shader;
  }

  final List<Offset> sourcePoints;
  final int meshSegmentCount;
  final ui.Image image;
  final _FlexSurfaceRect surfaceFrame;
  final List<ui.Vertices> _vertices;
  final ui.ImageShader _shader;
  final Paint _paint = Paint();

  bool matches(
    _LayoutPathProjection projection,
    ui.Image candidateImage, [
    _FlexSurfaceRect candidateFrame = const (
      left: 0,
      top: 0,
      right: 1,
      bottom: 1,
    ),
  ]) {
    if (!identical(image, candidateImage) ||
        meshSegmentCount != projection.meshSegmentCount ||
        surfaceFrame != candidateFrame ||
        sourcePoints.length != projection.sourcePoints.length) {
      return false;
    }
    for (var index = 0; index < sourcePoints.length; index += 1) {
      if (sourcePoints[index] != projection.sourcePoints[index]) return false;
    }
    return true;
  }

  void draw(Canvas canvas, double opacity) {
    _paint.colorFilter = ColorFilter.mode(
      Color.fromARGB((opacity * 255).round(), 255, 255, 255),
      BlendMode.modulate,
    );
    for (final vertices in _vertices) {
      canvas.drawVertices(vertices, BlendMode.src, _paint);
    }
  }

  void dispose() {
    for (final vertices in _vertices) {
      vertices.dispose();
    }
    _shader.dispose();
  }

  static List<ui.Vertices> _buildVertexTiles(
    _LayoutPathProjection projection,
    ui.Image image,
    LayoutImageBackground background,
    _FlexSurfaceRect surfaceFrame,
  ) => [
    for (var index = 0; index < background.repeat; index += 1)
      _buildVertices(projection, image, background, (
        left: ui.lerpDouble(
          surfaceFrame.left,
          surfaceFrame.right,
          index / background.repeat,
        )!,
        top: surfaceFrame.top,
        right: ui.lerpDouble(
          surfaceFrame.left,
          surfaceFrame.right,
          (index + 1) / background.repeat,
        )!,
        bottom: surfaceFrame.bottom,
      )),
  ];

  static ui.Vertices _buildVertices(
    _LayoutPathProjection projection,
    ui.Image image,
    LayoutImageBackground background,
    _FlexSurfaceRect surfaceFrame,
  ) {
    final flatSize = Size(
      projection.flatSize.width * (surfaceFrame.right - surfaceFrame.left),
      projection.flatSize.height * (surfaceFrame.bottom - surfaceFrame.top),
    );
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fit = _backgroundImageBoxFit(background.fit);
    final fitted = applyBoxFit(fit, imageSize, flatSize);
    final alignment = _backgroundImageAlignment(background.position);
    final sourceRect = alignment.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final destinationRect = alignment.inscribe(
      fitted.destination,
      Offset.zero & flatSize,
    );
    final left = destinationRect.left / flatSize.width;
    final right = destinationRect.right / flatSize.width;
    final top = destinationRect.top / flatSize.height;
    final bottom = destinationRect.bottom / flatSize.height;
    final positions = <Offset>[];
    final textureCoordinates = <Offset>[];
    final rotationRadians = background.rotationDegrees * math.pi / 180;
    final rotationCosine = math.cos(rotationRadians);
    final rotationSine = math.sin(rotationRadians);
    Offset transformedDestination(double x, double y) {
      final centeredX = x - 0.5;
      final centeredY = y - 0.5;
      return Offset(
        0.5 +
            background.scale *
                (rotationCosine * centeredX - rotationSine * centeredY),
        0.5 +
            background.scale *
                (rotationSine * centeredX + rotationCosine * centeredY),
      );
    }

    final sampleCount =
        (projection.meshSegmentCount *
                (surfaceFrame.right - surfaceFrame.left).abs())
            .ceil()
            .clamp(8, projection.meshSegmentCount);
    for (var index = 0; index <= sampleCount; index += 1) {
      final stop = index / sampleCount;
      final localU = ui.lerpDouble(left, right, stop)!;
      final topDestination = transformedDestination(localU, top);
      final bottomDestination = transformedDestination(localU, bottom);
      final textureX = ui.lerpDouble(sourceRect.left, sourceRect.right, stop)!;
      positions
        ..add(
          projection.project(
            ui.lerpDouble(
              surfaceFrame.left,
              surfaceFrame.right,
              topDestination.dx,
            )!,
            ui.lerpDouble(
              surfaceFrame.top,
              surfaceFrame.bottom,
              topDestination.dy,
            )!,
          ),
        )
        ..add(
          projection.project(
            ui.lerpDouble(
              surfaceFrame.left,
              surfaceFrame.right,
              bottomDestination.dx,
            )!,
            ui.lerpDouble(
              surfaceFrame.top,
              surfaceFrame.bottom,
              bottomDestination.dy,
            )!,
          ),
        );
      textureCoordinates
        ..add(Offset(textureX, sourceRect.top))
        ..add(Offset(textureX, sourceRect.bottom));
    }
    return ui.Vertices(
      ui.VertexMode.triangleStrip,
      positions,
      textureCoordinates: textureCoordinates,
    );
  }
}

TableData _tableData(
  List<ResolvedVaultNode> selectedNodes,
  SystemInfo? systemInfo,
) {
  final selectedNode = selectedNodes.lastOrNull;
  return TableData({
    if (selectedNode != null) ..._nodeInfoValues(selectedNode),
    'selected_node_slugs': _selectedNodeSlugs(selectedNodes),
    'selected_node_labels': _selectedNodeLabels(selectedNodes),
    'added': [
      for (final node in selectedNodes)
        if (node.isVirtual) node,
    ],
    'updated': const <ResolvedVaultNode>[],
    'deleted': const <ResolvedVaultNode>[],
    'node_count': systemInfo?.nodeCount,
    'node_property_count': systemInfo?.nodePropertyCount,
    'neo4j_labels': systemInfo?.neo4jLabels,
    'go_version': systemInfo?.goVersion,
    'neo4j_version': systemInfo?.neo4jVersion,
  });
}

List<String> _selectedNodeSlugs(List<ResolvedVaultNode> selectedNodes) {
  final slugs = <String>{};
  for (final selectedNode in selectedNodes) {
    final slug = selectedNode.node?.slug.trim() ?? '';
    if (slug.isNotEmpty) slugs.add(slug);
  }
  return slugs.toList(growable: false);
}

List<String> _selectedNodeLabels(List<ResolvedVaultNode> selectedNodes) {
  final labels = <String>{};
  for (final selectedNode in selectedNodes) {
    for (final label in selectedNode.node?.labels ?? const <String>[]) {
      final normalizedLabel = label.trim();
      if (normalizedLabel.isNotEmpty) labels.add(normalizedLabel);
    }
  }
  return labels.toList(growable: false)..sort((left, right) {
    final normalizedComparison = left.toLowerCase().compareTo(
      right.toLowerCase(),
    );
    return normalizedComparison != 0
        ? normalizedComparison
        : left.compareTo(right);
  });
}

void _drawPathTicks(
  Canvas canvas,
  Size size,
  List<Offset> points,
  LayoutPathTickStyle ticks,
) {
  if (ticks.count <= 0 ||
      ticks.edgeStartIndex < 0 ||
      ticks.edgeEndIndex < 0 ||
      ticks.edgeStartIndex >= points.length ||
      ticks.edgeEndIndex >= points.length) {
    return;
  }
  final start = points[ticks.edgeStartIndex];
  final end = points[ticks.edgeEndIndex];
  final edge = end - start;
  final edgeLength = edge.distance;
  if (edgeLength == 0) return;

  final direction = edge / edgeLength;
  final normal = Offset(-direction.dy, direction.dx);
  final centroid =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  final midpoint = Offset.lerp(start, end, 0.5)!;
  final centroidDelta = centroid - midpoint;
  final dot = centroidDelta.dx * normal.dx + centroidDelta.dy * normal.dy;
  final inward = dot >= 0 ? normal : -normal;
  final tickLength = size.shortestSide * ticks.lengthFraction;
  final inset = ticks.insetFraction.clamp(0.0, 0.45);
  final usableStart = inset;
  final usableEnd = 1 - inset;
  final divisor = math.max(ticks.count - 1, 1);

  for (var index = 0; index < ticks.count; index += 1) {
    final t = ticks.count == 1
        ? 0.5
        : usableStart + (usableEnd - usableStart) * index / divisor;
    final origin = Offset.lerp(start, end, t)!;
    drawGuideLine(canvas, origin, origin + inward * tickLength, ticks.style);
  }
}

List<Offset> _paddedPathPoints(List<Offset> points, LayoutPathPadding padding) {
  if (padding.isEmpty || points.length < 3) return points;

  final centroid =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  return [
    for (final point in points)
      point +
          Offset(
            point.dx < centroid.dx ? padding.left : -padding.right,
            point.dy < centroid.dy ? padding.top : -padding.bottom,
          ),
  ];
}

List<Offset>? _resolvedLayoutPathPoints(
  LayoutPath layoutPath,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext,
) {
  final points = [
    for (final reference in layoutPath.points)
      _resolveReference(reference, layouts, layoutContext),
  ];
  if (points.length < 2 || points.any((point) => point == null)) return null;
  return _paddedPathPoints(points.cast<Offset>(), layoutPath.padding);
}

typedef _NodeListEntryFrame = ({
  ResolvedVaultNode resolvedNode,
  Node node,
  List<Offset> points,
});

typedef _NodeListSources = ({
  List<ResolvedVaultNode> virtualNodes,
  List<ResolvedVaultNode> searchResults,
});

_NodeListSources _nodeListSources(
  List<ResolvedVaultNode> selectedNodes, {
  List<ResolvedVaultNode> searchResults = const [],
}) => (
  virtualNodes: [
    for (final node in selectedNodes)
      if (node.isVirtual) node,
  ],
  searchResults: searchResults,
);

void _drawNodeListLayout(
  Canvas canvas,
  List<Offset> points,
  NodeListLayout layout,
  _NodeListSources sources,
  LayoutContext layoutContext, {
  NodeConfig? nodeConfig,
}) {
  final resolvedNodeConfig = nodeConfig ?? layout.node;
  final entries = _nodeListEntries(layout, sources, points);
  final borderWidth = layout.layoutBorderWidth ?? layout.style.strokeWidth;
  for (final entry in entries) {
    final path = _polygonPath(entry.points);
    canvas.drawPath(
      path,
      Paint()
        ..color = NodeComponent.backgroundColor(
          NodeComponent.colorFor(entry.node).resolve(),
          entry.node.slug,
          layoutContext,
          layout,
          isVirtual: entry.resolvedNode.isVirtual,
          config: resolvedNodeConfig,
        )
        ..style = PaintingStyle.fill,
    );
    NodeComponent.renderBorder(
      canvas,
      path,
      resolvedNodeConfig.borderStyle ?? layout.style,
      borderWidth,
      isVirtual: entry.resolvedNode.isVirtual,
    );
    final center =
        entry.points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
        entry.points.length.toDouble();
    final topWidth = (entry.points[1] - entry.points[0]).distance;
    final bottomWidth = (entry.points[2] - entry.points[3]).distance;
    _paintNodeLabel(
      canvas,
      _nodePresentation(entry.node, layout, nodeConfig: resolvedNodeConfig),
      center,
      math.min(topWidth, bottomWidth) * 0.88,
      resolvedNodeConfig.labelColor ?? NodeDefaults.labelColor,
      layout.labelSize,
    );
  }
}

List<_NodeListEntryFrame> _nodeListEntries(
  NodeListLayout layout,
  _NodeListSources sources,
  List<Offset> points,
) {
  if (points.length != 4) return const [];
  final nodes = switch (layout.dataSource) {
    NodeListDataSource.virtualNodes => sources.virtualNodes,
    NodeListDataSource.searchResults => sources.searchResults,
  };
  final resolvedNodes = [
    for (final resolvedNode in nodes)
      if (resolvedNode.node case final node?)
        (resolvedNode: resolvedNode, node: node),
  ];
  if (resolvedNodes.isEmpty) return const [];
  return [
    for (var index = 0; index < resolvedNodes.length; index += 1)
      (
        resolvedNode: resolvedNodes[index].resolvedNode,
        node: resolvedNodes[index].node,
        points: _quadrilateralSlice(
          points,
          top: index / resolvedNodes.length,
          bottom: (index + 1) / resolvedNodes.length,
        ),
      ),
  ];
}

_NodeListEntryFrame? _hitTestNodeList(
  NodeListLayout layout,
  _NodeListSources sources,
  List<Offset> points,
  Offset position,
) {
  for (final entry in _nodeListEntries(layout, sources, points).reversed) {
    if (_polygonContains(entry.points, position)) return entry;
  }
  return null;
}

Path _polygonPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

String _nodePresentationLabel(
  Node node,
  Layout layout, {
  bool forceSlug = false,
}) => _nodePresentation(node, layout, forceSlug: forceSlug).text;

typedef _NodePresentation = ({
  String text,
  bool isSlug,
  Color? colorOverride,
  List<FontFeature>? fontFeatures,
});

_NodePresentation _nodePresentation(
  Node node,
  Layout layout, {
  bool forceSlug = false,
  NodeConfig? nodeConfig,
}) {
  final resolvedNodeConfig = nodeConfig ?? layout.node;
  final slug = node.slug.trim();
  final content = resolvedNodeConfig.content;
  if (!forceSlug && content != null) {
    return (
      text: content.resolve(node, resolvedNodeConfig),
      isSlug: content.isSlug,
      colorOverride: content.isSlug
          ? resolvedNodeConfig.slugColor ?? NodeDefaults.slugColor
          : null,
      fontFeatures: content.isSlug
          ? (resolvedNodeConfig.slugTransform ?? NodeDefaults.slugTransform)
                .fontFeatures
          : null,
    );
  }
  if (!forceSlug) {
    final emoji = node.primaryEmojiCharacter;
    if (emoji != null) {
      return (
        text: emoji,
        isSlug: false,
        colorOverride: null,
        fontFeatures: null,
      );
    }
  }
  if (slug.isNotEmpty) {
    return (
      text: resolvedNodeConfig.formatSlug(slug),
      isSlug: true,
      colorOverride: resolvedNodeConfig.slugColor ?? NodeDefaults.slugColor,
      fontFeatures:
          (resolvedNodeConfig.slugTransform ?? NodeDefaults.slugTransform)
              .fontFeatures,
    );
  }
  return (
    text: node.displayLabel,
    isSlug: false,
    colorOverride: null,
    fontFeatures: null,
  );
}

typedef _FanSegment = ({
  NodeTreeOccurrence occurrence,
  Path path,
  Offset labelPoint,
  double labelWidth,
});

typedef _FanOccurrenceHierarchy = ({
  List<NodeTreeOccurrence> roots,
  List<NodeTreeOccurrence> occurrences,
  Map<String, List<NodeTreeOccurrence>> childrenByParent,
});

typedef _FanFrame = ({
  Offset center,
  double growthAngle,
  double startTheta,
  double endTheta,
  double regularRadius,
  List<Offset> boundaryPoints,
  List<double> boundaryStops,
  List<double> rowStops,
  List<double> columnStops,
});

void _drawFanLayout(
  Canvas canvas,
  Rect bounds,
  FanLayout fan,
  NodeTree? tree,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext, {
  required NodeConfig Function(ResolvedVaultNode node) nodeConfig,
  required ui.Image? Function(String assetPath) imageFor,
  required List<Offset> planePoints,
}) {
  _drawFanBackgrounds(canvas, fan, planePoints, layoutContext, imageFor);
  if (tree == null || tree.occurrences.isEmpty) return;
  final hierarchy = _fanOccurrenceHierarchy(fan, tree);
  if (hierarchy == null) return;
  final frame = _resolveFanFrame(
    fan,
    hierarchy,
    bounds,
    layouts,
    layoutContext,
    planePoints: planePoints,
  );
  if (frame == null) return;
  final segments = _fanSegmentsInFrame(fan, hierarchy, frame);
  for (final segment in segments) {
    final node = segment.occurrence.node;
    final resolvedNode = _resolvedFanNode(segment.occurrence, fan);
    final config = nodeConfig(resolvedNode);
    final fillColor = NodeComponent.backgroundColor(
      NodeComponent.colorFor(node).resolve(),
      node.slug,
      layoutContext,
      fan,
      config: config,
    );
    canvas.drawPath(
      segment.path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }
  _drawFanGrid(canvas, fan, frame);
  for (final segment in segments) {
    final resolvedNode = _resolvedFanNode(segment.occurrence, fan);
    final config = nodeConfig(resolvedNode);
    final borderStyle = config.borderStyle;
    if (borderStyle == null) continue;
    final borderWidth = fan.layoutBorderWidth ?? borderStyle.strokeWidth;
    NodeComponent.renderBorder(
      canvas,
      segment.path,
      borderStyle,
      borderWidth,
      isVirtual: false,
    );
  }
  for (final segment in segments) {
    final node = segment.occurrence.node;
    final resolvedNode = _resolvedFanNode(segment.occurrence, fan);
    final config = nodeConfig(resolvedNode);
    _paintNodeLabel(
      canvas,
      _nodePresentation(node, fan, nodeConfig: config),
      segment.labelPoint,
      segment.labelWidth,
      config.labelColor ?? NodeDefaults.labelColor,
      config.text.fontSize ?? LayoutTextDefaults.rootFontSize,
    );
  }
}

void _drawFanBackgrounds(
  Canvas canvas,
  FanLayout fan,
  List<Offset> surfacePoints,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor,
) {
  if (surfacePoints.length < 3) return;
  final path = _polygonPath(surfacePoints);
  final backgrounds = [...fan.resolveBackground(layoutContext)]
    ..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
  for (final background in backgrounds) {
    _drawFanBackground(canvas, path, background, layoutContext, imageFor);
  }
}

void _drawFanBackground(
  Canvas canvas,
  Path path,
  LayoutBackground background,
  LayoutContext layoutContext,
  ui.Image? Function(String assetPath) imageFor, {
  double inheritedOpacity = 1,
}) {
  final opacity = (inheritedOpacity * background.opacity)
      .clamp(0, 1)
      .toDouble();
  if (opacity == 0) return;
  if (background is RandomLayoutBackground) {
    _drawFanBackground(
      canvas,
      path,
      _selectRandomLayoutBackground(background),
      layoutContext,
      imageFor,
      inheritedOpacity: opacity,
    );
    return;
  }
  if (background is ConditionalLayoutBackground) {
    if (!background.activeCondition.isActive(layoutContext)) return;
    _drawFanBackground(
      canvas,
      path,
      background.background,
      layoutContext,
      imageFor,
      inheritedOpacity: opacity,
    );
    return;
  }
  if (background is LayoutBackgroundColor) {
    canvas.drawPath(
      path,
      Paint()
        ..color = background.color.withValues(
          alpha: background.color.a * opacity,
        )
        ..style = PaintingStyle.fill,
    );
    return;
  }
  if (background is! LayoutImageBackground) return;

  final image = imageFor(background.assetPath);
  final bounds = path.getBounds();
  if (image == null || bounds.isEmpty) return;
  canvas.save();
  canvas.clipPath(path);
  for (final tile in _backgroundImageTiles(bounds, background.repeat)) {
    _paintBackgroundImage(canvas, tile, image, background, opacity);
  }
  canvas.restore();
}

void _paintNodeLabel(
  Canvas canvas,
  _NodePresentation presentation,
  Offset center,
  double maxWidth,
  Color color,
  double fontSize,
) {
  final label = presentation.text;
  if (label.isEmpty || maxWidth < fontSize * 2) return;
  final textPainter = _nodeLabelTextPainter(
    presentation,
    maxWidth: maxWidth,
    color: color,
    fontSize: fontSize,
  );
  textPainter.paint(
    canvas,
    center - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}

TextPainter _nodeLabelTextPainter(
  _NodePresentation presentation, {
  required double maxWidth,
  required Color color,
  required double fontSize,
}) => TextPainter(
  text: TextSpan(
    text: LayoutText.defaultRepresentation(presentation.text),
    style: TextStyle(
      // Alegreya Sans SC deliberately displays lowercase as small caps.
      // Node slugs are syntax, so keep their stored casing legible.
      fontFamily: presentation.isSlug ? null : SevilleTypography.fontFamily,
      color: presentation.colorOverride ?? color,
      fontSize: fontSize,
      fontWeight: presentation.isSlug ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: presentation.fontFeatures,
    ),
  ),
  maxLines: 1,
  ellipsis: '…',
  textDirection: TextDirection.ltr,
  textAlign: TextAlign.center,
)..layout(maxWidth: maxWidth);

List<_FanSegment> _fanSegments(
  FanLayout fan,
  NodeTree tree,
  Rect bounds,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext, {
  required List<Offset> planePoints,
}) {
  final hierarchy = _fanOccurrenceHierarchy(fan, tree);
  if (hierarchy == null) return const [];
  final frame = _resolveFanFrame(
    fan,
    hierarchy,
    bounds,
    layouts,
    layoutContext,
    planePoints: planePoints,
  );
  return frame == null ? const [] : _fanSegmentsInFrame(fan, hierarchy, frame);
}

_FanOccurrenceHierarchy? _fanOccurrenceHierarchy(FanLayout fan, NodeTree tree) {
  final depthLimitedOccurrences = tree.occurrences
      .where((occurrence) => occurrence.depth < fan.maxDepth)
      .toList(growable: false);
  final roots = depthLimitedOccurrences
      .where((occurrence) => occurrence.depth == 0)
      .take(fan.maxSectionCount)
      .toList(growable: false);
  if (roots.isEmpty) return null;

  final uncappedChildren = <String, List<NodeTreeOccurrence>>{};
  for (final occurrence in depthLimitedOccurrences) {
    if (!occurrence.hasParentOccurrenceId()) continue;
    uncappedChildren
        .putIfAbsent(occurrence.parentOccurrenceId, () => [])
        .add(occurrence);
  }
  final occurrences = <NodeTreeOccurrence>[];
  final childrenByParent = <String, List<NodeTreeOccurrence>>{};
  void addVisibleOccurrence(NodeTreeOccurrence occurrence) {
    occurrences.add(occurrence);
    final children = (uncappedChildren[occurrence.occurrenceId] ?? const [])
        .take(fan.maxSectionCount)
        .toList(growable: false);
    if (children.isEmpty) return;
    childrenByParent[occurrence.occurrenceId] = children;
    for (final child in children) {
      addVisibleOccurrence(child);
    }
  }

  for (final root in roots) {
    addVisibleOccurrence(root);
  }
  return (
    roots: roots,
    occurrences: occurrences,
    childrenByParent: childrenByParent,
  );
}

_FanFrame? _resolveFanFrame(
  FanLayout fan,
  _FanOccurrenceHierarchy hierarchy,
  Rect bounds,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext, {
  required List<Offset> planePoints,
}) {
  if (planePoints.length < 3) return null;

  final boundaryMidpoint = planePoints.length > 2
      ? Offset.lerp(planePoints[1], planePoints.last, 0.5)
      : null;
  final hasExplicitRoot =
      boundaryMidpoint != null &&
      (planePoints.first - boundaryMidpoint).distance <= 0.000001;
  final center = hasExplicitRoot
      ? planePoints.first
      : fan.position.resolve(bounds);
  final target = fan.growthDirection == null
      ? bounds.center
      : _resolveReference(fan.growthDirection!, layouts, layoutContext);
  final growthVector = (target == null || (target - center).distance == 0)
      ? const Offset(0, 1)
      : target - center;
  final growthAngle = math.atan2(growthVector.dy, growthVector.dx);
  final angleSpan = fan.angleSpanDegrees * math.pi / 180;
  final startTheta = -angleSpan / 2;
  final endTheta = angleSpan / 2;
  final sampledBoundaryDistances = <double>[];
  final boundaryPoints = <Offset>[];
  const radiusSamples = 144;
  for (var index = 0; index <= radiusSamples; index += 1) {
    final theta = startTheta + angleSpan * index / radiusSamples;
    final angle = growthAngle + theta;
    final distance = _rayPolygonBoundaryDistance(
      center,
      Offset(math.cos(angle), math.sin(angle)),
      planePoints,
    );
    if (distance != null && distance > 0) {
      sampledBoundaryDistances.add(distance);
      boundaryPoints.add(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
      );
    }
  }
  if (sampledBoundaryDistances.isEmpty || boundaryPoints.length < 2) {
    return null;
  }
  final regularRadius = sampledBoundaryDistances.reduce(math.min);
  final boundaryStops = <double>[0];
  for (var index = 1; index < boundaryPoints.length; index += 1) {
    boundaryStops.add(
      boundaryStops.last +
          (boundaryPoints[index] - boundaryPoints[index - 1]).distance,
    );
  }
  if (boundaryStops.last <= 0) return null;
  final deepestDepth = hierarchy.occurrences.fold<int>(
    0,
    (deepest, occurrence) => math.max(deepest, occurrence.depth.toInt()),
  );
  final rowCount = math.min(
    fan.maxDepth,
    math.max(fan.minDepth, deepestDepth + 1),
  );
  final rowStops = _gridTrackStops(
    [for (final row in fan.rowsConfig.values.take(rowCount)) row],
    regularRadius,
    rootFontSize: layoutContext.rootFontSize,
  );
  final columnStops = _fanTopLevelStops(fan, hierarchy, startTheta, endTheta);
  return (
    center: center,
    growthAngle: growthAngle,
    startTheta: startTheta,
    endTheta: endTheta,
    regularRadius: regularRadius,
    boundaryPoints: boundaryPoints,
    boundaryStops: boundaryStops,
    rowStops: rowStops,
    columnStops: columnStops,
  );
}

List<_FanSegment> _fanSegmentsInFrame(
  FanLayout fan,
  _FanOccurrenceHierarchy hierarchy,
  _FanFrame frame,
) {
  final segments = <_FanSegment>[];
  late void Function(NodeTreeOccurrence, double, double) addOccurrence;
  addOccurrence = (occurrence, startTheta, endTheta) {
    final occurrenceDepth = occurrence.depth.toInt();
    if (occurrenceDepth + 1 >= frame.rowStops.length) return;
    final innerStop = frame.rowStops[occurrenceDepth];
    final outerStop = frame.rowStops[occurrenceDepth + 1];
    final middleStop = (innerStop + outerStop) / 2;
    final middleTheta = (startTheta + endTheta) / 2;
    final reachesBoundary = outerStop >= 1;
    const outerLabelDepth = 0.72;
    final labelStart = reachesBoundary
        ? Offset.lerp(
            _fanFramePoint(frame, innerStop, startTheta),
            _fanFramePoint(frame, outerStop, startTheta),
            outerLabelDepth,
          )!
        : _fanFramePoint(frame, middleStop, startTheta);
    final labelEnd = reachesBoundary
        ? Offset.lerp(
            _fanFramePoint(frame, innerStop, endTheta),
            _fanFramePoint(frame, outerStop, endTheta),
            outerLabelDepth,
          )!
        : _fanFramePoint(frame, middleStop, endTheta);
    final labelPoint = reachesBoundary
        ? Offset.lerp(labelStart, labelEnd, 0.5)!
        : _fanFramePoint(frame, middleStop, middleTheta);
    segments.add((
      occurrence: occurrence,
      path: _fanAreaPath(frame, innerStop, outerStop, startTheta, endTheta),
      labelPoint: labelPoint,
      labelWidth: math.max((labelEnd - labelStart).distance - 8, 0),
    ));

    final children =
        hierarchy.childrenByParent[occurrence.occurrenceId] ?? const [];
    if (children.isEmpty) return;
    final childStops = _fanSectionStops(
      fan,
      hierarchy,
      children,
      startTheta,
      endTheta,
    );
    for (var index = 0; index < children.length; index += 1) {
      addOccurrence(children[index], childStops[index], childStops[index + 1]);
    }
  };
  final rootStops = _equalSectionStops(
    hierarchy.roots.length,
    frame.startTheta,
    frame.endTheta,
  );
  for (var index = 0; index < hierarchy.roots.length; index += 1) {
    addOccurrence(
      hierarchy.roots[index],
      rootStops[index],
      rootStops[index + 1],
    );
  }
  return segments;
}

List<double> _fanTopLevelStops(
  FanLayout fan,
  _FanOccurrenceHierarchy hierarchy,
  double startTheta,
  double endTheta,
) {
  final rootStops = _equalSectionStops(
    hierarchy.roots.length,
    startTheta,
    endTheta,
  );
  final stops = <double>[startTheta];
  for (var rootIndex = 0; rootIndex < hierarchy.roots.length; rootIndex += 1) {
    final root = hierarchy.roots[rootIndex];
    final children = hierarchy.childrenByParent[root.occurrenceId] ?? const [];
    final childStops = _fanSectionStops(
      fan,
      hierarchy,
      children,
      rootStops[rootIndex],
      rootStops[rootIndex + 1],
    );
    stops.addAll(childStops.skip(1));
  }
  return stops;
}

List<double> _equalSectionStops(
  int sectionCount,
  double startTheta,
  double endTheta,
) {
  if (sectionCount <= 0) return [startTheta, endTheta];
  final span = endTheta - startTheta;
  return [
    for (var index = 0; index <= sectionCount; index += 1)
      startTheta + span * index / sectionCount,
  ];
}

List<double> _fanSectionStops(
  FanLayout fan,
  _FanOccurrenceHierarchy hierarchy,
  List<NodeTreeOccurrence> sections,
  double startTheta,
  double endTheta,
) {
  if (sections.isEmpty) return [startTheta, endTheta];
  final weights = [
    for (final section in sections)
      switch (fan.sectionSizing) {
        FanSectionSizing.equal => 1.0,
        FanSectionSizing.directPartsWeighted =>
          1.0 + (hierarchy.childrenByParent[section.occurrenceId]?.length ?? 0),
      },
  ];
  final totalWeight = weights.fold<double>(0, (sum, weight) => sum + weight);
  final span = endTheta - startTheta;
  final stops = <double>[startTheta];
  var consumedWeight = 0.0;
  for (final weight in weights) {
    consumedWeight += weight;
    stops.add(startTheta + span * consumedWeight / totalWeight);
  }
  stops[stops.length - 1] = endTheta;
  return stops;
}

void _drawFanGrid(Canvas canvas, FanLayout fan, _FanFrame frame) {
  final style = fan.gridStyle;
  if (style == null || frame.rowStops.length < 2) return;

  for (final rowStop in frame.rowStops.skip(1)) {
    _drawFanArc(canvas, frame, rowStop, style);
  }
  final rootStop = frame.rowStops[1];
  for (final theta in frame.columnStops) {
    drawGuideLine(
      canvas,
      _fanFramePoint(frame, rootStop, theta),
      _fanFramePoint(frame, 1, theta),
      style,
    );
  }
}

void _drawFanArc(
  Canvas canvas,
  _FanFrame frame,
  double rowStop,
  GuideStyle style,
) {
  const steps = 48;
  var previous = _fanFramePoint(frame, rowStop, frame.startTheta);
  for (var index = 1; index <= steps; index += 1) {
    final theta =
        frame.startTheta + (frame.endTheta - frame.startTheta) * index / steps;
    final next = _fanFramePoint(frame, rowStop, theta);
    drawGuideLine(canvas, previous, next, style);
    previous = next;
  }
}

Path _fanAreaPath(
  _FanFrame frame,
  double innerStop,
  double outerStop,
  double startTheta,
  double endTheta,
) {
  const epsilon = 0.000001;
  final isInsetCircle =
      innerStop.abs() <= epsilon &&
      outerStop < 1 - epsilon &&
      ((endTheta - startTheta).abs() - math.pi * 2).abs() <= epsilon;
  if (isInsetCircle) {
    return Path()..addOval(
      Rect.fromCircle(
        center: frame.center,
        radius: frame.regularRadius * outerStop,
      ),
    );
  }

  const steps = 18;
  final path = Path();
  for (var index = 0; index <= steps; index += 1) {
    final theta = startTheta + (endTheta - startTheta) * index / steps;
    final point = _fanFramePoint(frame, outerStop, theta);
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  for (var index = steps; index >= 0; index -= 1) {
    final theta = startTheta + (endTheta - startTheta) * index / steps;
    final point = _fanFramePoint(frame, innerStop, theta);
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

Offset _fanFramePoint(_FanFrame frame, double rowStop, double theta) {
  if (rowStop >= 1) {
    return _equalizedFanBoundaryPoint(frame, theta);
  }
  final angle = frame.growthAngle + theta;
  final direction = Offset(math.cos(angle), math.sin(angle));
  return frame.center + direction * (frame.regularRadius * rowStop);
}

Offset _equalizedFanBoundaryPoint(_FanFrame frame, double theta) {
  final angleSpan = frame.endTheta - frame.startTheta;
  if (angleSpan == 0 || frame.boundaryPoints.length < 2) {
    return frame.boundaryPoints.first;
  }
  final fraction = ((theta - frame.startTheta) / angleSpan).clamp(0.0, 1.0);
  final targetDistance = frame.boundaryStops.last * fraction;
  var upperIndex = 1;
  while (upperIndex < frame.boundaryStops.length - 1 &&
      frame.boundaryStops[upperIndex] < targetDistance) {
    upperIndex += 1;
  }
  final lowerIndex = upperIndex - 1;
  final lowerStop = frame.boundaryStops[lowerIndex];
  final segmentLength = frame.boundaryStops[upperIndex] - lowerStop;
  final segmentFraction = segmentLength <= 0
      ? 0.0
      : (targetDistance - lowerStop) / segmentLength;
  return Offset.lerp(
    frame.boundaryPoints[lowerIndex],
    frame.boundaryPoints[upperIndex],
    segmentFraction,
  )!;
}

double? _rayPolygonBoundaryDistance(
  Offset origin,
  Offset direction,
  List<Offset> polygon,
) {
  if (polygon.length < 3) return null;
  const epsilon = 0.000001;
  double? farthest;
  for (var index = 0; index < polygon.length; index += 1) {
    final start = polygon[index];
    final end = polygon[(index + 1) % polygon.length];
    final edge = end - start;
    final fromOrigin = start - origin;
    final denominator = _cross2d(direction, edge);
    if (denominator.abs() <= epsilon) {
      if (_cross2d(fromOrigin, direction).abs() > epsilon) continue;
      for (final endpoint in [start, end]) {
        final projection =
            (endpoint - origin).dx * direction.dx +
            (endpoint - origin).dy * direction.dy;
        if (projection >= 0 && (farthest == null || projection > farthest)) {
          farthest = projection;
        }
      }
      continue;
    }
    final distance = _cross2d(fromOrigin, edge) / denominator;
    final edgeFraction = _cross2d(fromOrigin, direction) / denominator;
    if (distance < -epsilon ||
        edgeFraction < -epsilon ||
        edgeFraction > 1 + epsilon) {
      continue;
    }
    final clampedDistance = math.max(distance, 0.0);
    if (farthest == null || clampedDistance > farthest) {
      farthest = clampedDistance;
    }
  }
  return farthest;
}

double _cross2d(Offset left, Offset right) =>
    left.dx * right.dy - left.dy * right.dx;

typedef _LayoutTapHit = ({LayoutTapTarget target, Path? nodePath});

bool _isTappablePanel(Layout layout) =>
    layout is PanelLayout &&
    (layout.onTap != null || layout.aliases.contains('action-button'));

LayoutTapTarget? _hitTestLayoutTapTarget(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding,
  Offset position,
  VaultNodeResolver? vaultNodeResolver,
  List<ResolvedVaultNode> highlightedNodes,
  List<ResolvedVaultNode> selectedNodes, {
  List<ResolvedVaultNode> searchResults = const [],
  bool searchOpenned = false,
}) => _hitTestLayoutTap(
  root,
  size,
  safePadding,
  position,
  vaultNodeResolver,
  highlightedNodes,
  selectedNodes,
  searchResults: searchResults,
  searchOpenned: searchOpenned,
)?.target;

_LayoutTapHit? _hitTestLayoutTap(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding,
  Offset position,
  VaultNodeResolver? vaultNodeResolver,
  List<ResolvedVaultNode> highlightedNodes,
  List<ResolvedVaultNode> selectedNodes, {
  List<ResolvedVaultNode> searchResults = const [],
  bool searchOpenned = false,
}) {
  final layoutContext = _layoutContext(
    root,
    highlightedNodes,
    selectedNodes,
    searchOpenned: searchOpenned,
  );
  final nodeListSources = _nodeListSources(
    selectedNodes,
    searchResults: searchResults,
  );
  final resolvedLayouts = _resolveLayouts(
    root,
    size,
    safePadding,
    layoutContext,
  );
  for (final resolved in resolvedLayouts.values.toList().reversed) {
    final children = _resolvedLayoutChildren(
      resolved.layout,
      layoutContext,
    ).toList().reversed;
    for (final entry in children) {
      final child = entry.value;
      if (child is LayoutPath && child.children.isNotEmpty) {
        final points = [
          for (final reference in child.points)
            _resolveReference(reference, resolvedLayouts, layoutContext),
        ];
        if (points.length == 4 && points.every((point) => point != null)) {
          final paddedPoints = _paddedPathPoints(
            points.cast<Offset>(),
            child.padding,
          );
          final compositionPoints = _screenOrderedQuadrilateral(paddedPoints);
          final projection = _resolvedLayoutPathProjection(
            child,
            paddedPoints,
            resolvedLayouts,
            layoutContext,
          );
          for (final compositionEntry in _resolvedLayoutChildren(
            child,
            layoutContext,
          ).toList().reversed) {
            final composition = compositionEntry.value;
            if (composition is! ColumnLayout &&
                composition is! RowLayout &&
                composition is! GridLayout) {
              continue;
            }
            final hit = composition is GridLayout
                ? _hitTestGridComposition(
                    composition,
                    compositionPoints,
                    position,
                    '${entry.key}/${compositionEntry.key}',
                    layoutContext,
                    nodeListSources,
                    projection: projection,
                  )
                : _hitTestFlexComposition(
                    composition,
                    compositionPoints,
                    position,
                    '${entry.key}/${compositionEntry.key}',
                    layoutContext,
                    nodeListSources,
                    projection: projection,
                  );
            if (hit != null) return hit;
          }
        }
      }
    }
  }
  return null;
}

bool _polygonContains(List<Offset> points, Offset position) {
  if (points.length < 3) return false;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path.contains(position);
}

void _drawFlexComposition(
  Canvas canvas,
  List<Offset> points,
  Layout composition,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  required LayoutTextConfig text,
  _LayoutPathProjection? projection,
}) {
  if (points.length != 4) return;
  if (projection?.canProjectBackground ?? false) {
    _drawCurvedFlexComposition(
      canvas,
      composition,
      projection!,
      layoutContext,
      nodeListSources,
      text: text,
    );
    return;
  }

  final leftHeight = (points[3] - points[0]).distance;
  final rightHeight = (points[2] - points[1]).distance;
  final topWidth = (points[1] - points[0]).distance;
  final bottomWidth = (points[2] - points[3]).distance;
  final flatWidth = (topWidth + bottomWidth) / 2;
  final flatHeight = (leftHeight + rightHeight) / 2;
  if (flatWidth <= 0 || flatHeight <= 0) return;

  final flatPoints = [
    Offset.zero,
    Offset(flatWidth, 0),
    Offset(flatWidth, flatHeight),
    Offset(0, flatHeight),
  ];
  final recorder = ui.PictureRecorder();
  final flatCanvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, flatWidth, flatHeight),
  )..clipRect(Rect.fromLTWH(0, 0, flatWidth, flatHeight));
  _drawFlatFlexComposition(
    flatCanvas,
    flatPoints,
    composition,
    layoutContext,
    nodeListSources,
    text,
  );

  final picture = recorder.endRecording();
  final clipPath = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    clipPath.lineTo(point.dx, point.dy);
  }
  clipPath.close();
  canvas.save();
  canvas.clipPath(clipPath);
  canvas.transform(_rectToQuadTransform(flatWidth, flatHeight, points));
  canvas.drawPicture(picture);
  canvas.restore();
  picture.dispose();
}

void _drawGridComposition(
  Canvas canvas,
  List<Offset> points,
  GridLayout grid,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  required LayoutTextConfig text,
  _LayoutPathProjection? projection,
}) {
  if (points.length != 4) return;
  if (projection?.canProjectBackground ?? false) {
    _drawCurvedGridComposition(
      canvas,
      grid,
      projection!,
      layoutContext,
      nodeListSources,
      text: text,
    );
    return;
  }

  final leftHeight = (points[3] - points[0]).distance;
  final rightHeight = (points[2] - points[1]).distance;
  final topWidth = (points[1] - points[0]).distance;
  final bottomWidth = (points[2] - points[3]).distance;
  final flatWidth = (topWidth + bottomWidth) / 2;
  final flatHeight = (leftHeight + rightHeight) / 2;
  if (flatWidth <= 0 || flatHeight <= 0) return;

  final flatPoints = [
    Offset.zero,
    Offset(flatWidth, 0),
    Offset(flatWidth, flatHeight),
    Offset(0, flatHeight),
  ];
  final recorder = ui.PictureRecorder();
  final flatCanvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, flatWidth, flatHeight),
  )..clipRect(Rect.fromLTWH(0, 0, flatWidth, flatHeight));
  _drawFlatGridComposition(
    flatCanvas,
    flatPoints,
    grid,
    layoutContext,
    nodeListSources,
    text,
  );

  final picture = recorder.endRecording();
  canvas.save();
  canvas.clipPath(_polygonPath(points));
  canvas.transform(_rectToQuadTransform(flatWidth, flatHeight, points));
  canvas.drawPicture(picture);
  canvas.restore();
  picture.dispose();
}

void _drawFlatGridComposition(
  Canvas canvas,
  List<Offset> points,
  GridLayout grid,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources,
  LayoutTextConfig text,
) {
  if (points.length != 4) return;
  final size = _quadrilateralAverageSize(points);
  final tracks = _resolvedGridTracks(
    grid,
    size,
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return;
  for (final child in _resolveGridChildren(grid, tracks, layoutContext)) {
    final childPoints = _quadrilateralSlice(
      points,
      left: child.frame.left,
      right: child.frame.right,
      top: child.frame.top,
      bottom: child.frame.bottom,
    );
    final layout = child.layout;
    final childText = text.merge(layout.resolveTextConfig(layoutContext));
    if (layout is PanelLayout) {
      _drawPanelLayout(canvas, childPoints, layout, childText);
    } else if (layout is NodeListLayout) {
      _drawNodeListLayout(
        canvas,
        childPoints,
        layout,
        nodeListSources,
        layoutContext,
      );
    } else if (layout is ColumnLayout || layout is RowLayout) {
      _drawFlatFlexComposition(
        canvas,
        childPoints,
        layout,
        layoutContext,
        nodeListSources,
        childText,
      );
    } else if (layout is GridLayout) {
      _drawFlatGridComposition(
        canvas,
        childPoints,
        layout,
        layoutContext,
        nodeListSources,
        childText,
      );
    }
  }
  _drawFlatGridGuides(canvas, points, grid, tracks);
}

void _drawFlatFlexComposition(
  Canvas canvas,
  List<Offset> points,
  Layout composition,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources,
  LayoutTextConfig text,
) {
  for (final child in _resolveFlexChildren(
    composition,
    points,
    layoutContext,
  )) {
    final layout = child.layout;
    final childText = text.merge(layout.resolveTextConfig(layoutContext));
    if (layout is PanelLayout) {
      _drawPanelLayout(canvas, child.points, layout, childText);
    } else if (layout is NodeListLayout) {
      _drawNodeListLayout(
        canvas,
        child.points,
        layout,
        nodeListSources,
        layoutContext,
      );
    } else if (layout is ColumnLayout || layout is RowLayout) {
      _drawFlatFlexComposition(
        canvas,
        child.points,
        layout,
        layoutContext,
        nodeListSources,
        childText,
      );
    } else if (layout is GridLayout) {
      _drawFlatGridComposition(
        canvas,
        child.points,
        layout,
        layoutContext,
        nodeListSources,
        childText,
      );
    }
  }
}

typedef _FlexSurfaceRect = ({
  double left,
  double top,
  double right,
  double bottom,
});

typedef _ResolvedGridTracks = ({
  List<String> rowKeys,
  List<String> columnKeys,
  List<double> rowStops,
  List<double> columnStops,
  Size size,
  double rootFontSize,
});

typedef _ResolvedGridSlot = ({String key, GridSlot slot});

/// Resolves exact slot identity before aliases. Duplicate aliases resolve to
/// the first slot in the authored map order.
_ResolvedGridSlot? _resolveGridSlot(GridLayout grid, String name) {
  final exact = grid.slots[name];
  if (exact != null) return (key: name, slot: exact);
  for (final entry in grid.slots.entries) {
    if (entry.value.aliases.contains(name)) {
      return (key: entry.key, slot: entry.value);
    }
  }
  return null;
}

List<Offset>? _resolveGridPlacementPoints(
  List<Offset> points,
  _LayoutPathProjection? projection,
  List<({GridLayout grid, String slot, Layout layout})> gridSteps,
  LayoutContext layoutContext,
) {
  if (gridSteps.isEmpty) return points;
  if (points.length != 4) return null;
  final flatSize = projection?.canProjectBackground ?? false
      ? projection!.flatSize
      : _quadrilateralAverageSize(points);
  final frame = _resolveGridPlacementFrame(
    flatSize,
    gridSteps,
    rootFontSize: layoutContext.rootFontSize,
  );
  if (frame == null) return null;
  return projection?.canProjectBackground ?? false
      ? _curvedSurfaceCorners(projection!, frame)
      : _quadrilateralSlice(
          _screenOrderedQuadrilateral(points),
          left: frame.left,
          right: frame.right,
          top: frame.top,
          bottom: frame.bottom,
        );
}

_FlexSurfaceRect? _resolveGridPlacementFrame(
  Size flatSize,
  List<({GridLayout grid, String slot, Layout layout})> gridSteps, {
  double rootFontSize = LayoutTextDefaults.rootFontSize,
}) {
  var frame = const (left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);
  for (final step in gridSteps) {
    final tracks = _resolvedGridTracks(
      step.grid,
      Size(
        flatSize.width * (frame.right - frame.left),
        flatSize.height * (frame.bottom - frame.top),
      ),
      rootFontSize: rootFontSize,
    );
    if (tracks == null) return null;
    final resolvedSlot = _resolveGridSlot(step.grid, step.slot);
    if (resolvedSlot == null) return null;
    final areaFrame = _resolveGridSlotFrame(
      resolvedSlot.slot,
      tracks,
      layout: step.layout,
    );
    if (areaFrame == null) return null;
    frame = _scaleFlexSurfaceRect(frame, areaFrame);
  }
  return frame;
}

_ResolvedGridTracks? _resolvedGridTracks(
  GridLayout grid,
  Size size, {
  double rootFontSize = LayoutTextDefaults.rootFontSize,
}) {
  if (grid.rowsConfig.isEmpty || grid.columnsConfig.isEmpty || size.isEmpty) {
    return null;
  }
  return (
    rowKeys: grid.rowsConfig.keys.toList(growable: false),
    columnKeys: grid.columnsConfig.keys.toList(growable: false),
    rowStops: _gridTrackStops(
      grid.rowsConfig.values.toList(),
      size.height,
      rootFontSize: rootFontSize,
    ),
    columnStops: _gridTrackStops(
      grid.columnsConfig.values.toList(),
      size.width,
      rootFontSize: rootFontSize,
    ),
    size: size,
    rootFontSize: rootFontSize,
  );
}

Iterable<({String key, Layout layout, _FlexSurfaceRect frame})>
_resolveGridChildren(
  GridLayout grid,
  _ResolvedGridTracks tracks,
  LayoutContext layoutContext,
) sync* {
  for (final entry in _resolvedLayoutChildren(grid, layoutContext)) {
    final layout = entry.value;
    if (!layout.isVisible(layoutContext)) continue;
    final slotName = layout.slot;
    if (slotName == null) continue;
    final resolvedSlot = _resolveGridSlot(grid, slotName);
    if (resolvedSlot == null) continue;
    final frame = _resolveGridSlotFrame(
      resolvedSlot.slot,
      tracks,
      layout: layout,
    );
    if (frame == null) continue;
    yield (key: entry.key, layout: layout, frame: frame);
  }
}

_FlexSurfaceRect? _resolveGridSlotFrame(
  GridSlot slot,
  _ResolvedGridTracks tracks, {
  Layout? layout,
}) {
  final rowIndex = tracks.rowKeys.indexOf(slot.row);
  final columnIndex = tracks.columnKeys.indexOf(slot.column);
  if (rowIndex < 0 || columnIndex < 0) return null;
  final rowStartIndex = rowIndex + slot.rowOffset;
  final columnStartIndex = columnIndex + slot.columnOffset;
  final rowEndIndex = _gridAreaEnd(
    rowStartIndex,
    slot.rowSpan,
    tracks.rowKeys.length,
  );
  final columnEndIndex = _gridAreaEnd(
    columnStartIndex,
    slot.columnSpan,
    tracks.columnKeys.length,
  );
  if (rowStartIndex < 0 ||
      rowEndIndex > tracks.rowKeys.length ||
      rowStartIndex >= rowEndIndex ||
      columnStartIndex < 0 ||
      columnEndIndex > tracks.columnKeys.length ||
      columnStartIndex >= columnEndIndex) {
    return null;
  }
  final frame = (
    left: _gridStopAt(tracks.columnStops, columnStartIndex),
    top: _gridStopAt(tracks.rowStops, rowStartIndex),
    right: _gridStopAt(tracks.columnStops, columnEndIndex),
    bottom: _gridStopAt(tracks.rowStops, rowEndIndex),
  );
  if (slot.initialSpan != GridSlotSpan.content || layout == null) return frame;
  final contentHeight = _gridAreaContentHeight(
    layout,
    LayoutTextDefaults.config,
    tracks.rootFontSize,
  );
  final contentSpan = tracks.size.height <= 0
      ? 0.0
      : contentHeight / tracks.size.height;
  final maxBottom = slot.maxSpan == GridSlotSpan.track
      ? frame.bottom
      : math.min(frame.top + contentSpan, frame.bottom);
  return (
    left: frame.left,
    top: frame.top,
    right: frame.right,
    bottom: math.min(frame.top + contentSpan, maxBottom),
  );
}

double _gridAreaContentHeight(
  Layout layout,
  LayoutTextConfig inheritedText,
  double rootFontSize,
) {
  final text = inheritedText.merge(layout.text);
  final ownHeight =
      (text.fontSize ?? rootFontSize) * (text.height ?? 1.2) +
      layout.layoutPadding * 2;
  final visibleChildren = layout.children.values.toList(growable: false);
  if (visibleChildren.isEmpty) return ownHeight;
  final childHeights = [
    for (final child in visibleChildren)
      _gridAreaContentHeight(child, text, rootFontSize),
  ];
  if (layout is ColumnLayout) {
    return childHeights.fold<double>(0, (sum, height) => sum + height) +
        layout.layoutGap * math.max(childHeights.length - 1, 0);
  }
  return childHeights.reduce(math.max) + layout.layoutPadding * 2;
}

Size _quadrilateralAverageSize(List<Offset> points) => Size(
  ((points[1] - points[0]).distance + (points[2] - points[3]).distance) / 2,
  ((points[3] - points[0]).distance + (points[2] - points[1]).distance) / 2,
);

void _drawFlatGridGuides(
  Canvas canvas,
  List<Offset> points,
  GridLayout grid,
  _ResolvedGridTracks tracks,
) {
  final style = grid.guideStyle;
  if (style == null) return;
  for (final stop in tracks.rowStops.skip(1).take(tracks.rowStops.length - 2)) {
    drawGuideLine(
      canvas,
      _projectiveQuadrilateralPoint(points, 0, stop),
      _projectiveQuadrilateralPoint(points, 1, stop),
      style,
    );
  }
  for (final stop
      in tracks.columnStops.skip(1).take(tracks.columnStops.length - 2)) {
    drawGuideLine(
      canvas,
      _projectiveQuadrilateralPoint(points, stop, 0),
      _projectiveQuadrilateralPoint(points, stop, 1),
      style,
    );
  }
}

void _drawCurvedFlexComposition(
  Canvas canvas,
  Layout composition,
  _LayoutPathProjection projection,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  required LayoutTextConfig text,
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  for (final child in _resolveCurvedFlexChildren(
    composition,
    frame,
    projection,
    layoutContext,
  )) {
    final layout = child.layout;
    final childText = text.merge(layout.resolveTextConfig(layoutContext));
    if (layout is PanelLayout) {
      _drawCurvedPanelLayout(
        canvas,
        projection,
        child.frame,
        layout,
        childText,
      );
    } else if (layout is NodeListLayout) {
      _drawNodeListLayout(
        canvas,
        _curvedSurfaceCorners(projection, child.frame),
        layout,
        nodeListSources,
        layoutContext,
      );
    } else if (layout is ColumnLayout || layout is RowLayout) {
      _drawCurvedFlexComposition(
        canvas,
        layout,
        projection,
        layoutContext,
        nodeListSources,
        text: childText,
        frame: child.frame,
      );
    } else if (layout is GridLayout) {
      _drawCurvedGridComposition(
        canvas,
        layout,
        projection,
        layoutContext,
        nodeListSources,
        text: childText,
        frame: child.frame,
      );
    }
  }
}

void _drawCurvedGridComposition(
  Canvas canvas,
  GridLayout grid,
  _LayoutPathProjection projection,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  required LayoutTextConfig text,
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  final tracks = _resolvedGridTracks(
    grid,
    Size(
      projection.flatSize.width * (frame.right - frame.left),
      projection.flatSize.height * (frame.bottom - frame.top),
    ),
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return;
  for (final child in _resolveGridChildren(grid, tracks, layoutContext)) {
    final childFrame = _scaleFlexSurfaceRect(frame, child.frame);
    final layout = child.layout;
    final childText = text.merge(layout.resolveTextConfig(layoutContext));
    if (layout is PanelLayout) {
      _drawCurvedPanelLayout(canvas, projection, childFrame, layout, childText);
    } else if (layout is NodeListLayout) {
      _drawNodeListLayout(
        canvas,
        _curvedSurfaceCorners(projection, childFrame),
        layout,
        nodeListSources,
        layoutContext,
      );
    } else if (layout is ColumnLayout || layout is RowLayout) {
      _drawCurvedFlexComposition(
        canvas,
        layout,
        projection,
        layoutContext,
        nodeListSources,
        text: childText,
        frame: childFrame,
      );
    } else if (layout is GridLayout) {
      _drawCurvedGridComposition(
        canvas,
        layout,
        projection,
        layoutContext,
        nodeListSources,
        text: childText,
        frame: childFrame,
      );
    }
  }
  _drawCurvedGridGuides(canvas, projection, frame, grid, tracks);
}

_FlexSurfaceRect _scaleFlexSurfaceRect(
  _FlexSurfaceRect parent,
  _FlexSurfaceRect child,
) => (
  left: ui.lerpDouble(parent.left, parent.right, child.left)!,
  top: ui.lerpDouble(parent.top, parent.bottom, child.top)!,
  right: ui.lerpDouble(parent.left, parent.right, child.right)!,
  bottom: ui.lerpDouble(parent.top, parent.bottom, child.bottom)!,
);

void _drawCurvedGridGuides(
  Canvas canvas,
  _LayoutPathProjection projection,
  _FlexSurfaceRect frame,
  GridLayout grid,
  _ResolvedGridTracks tracks,
) {
  final style = grid.guideStyle;
  if (style == null) return;
  for (final stop in tracks.rowStops.skip(1).take(tracks.rowStops.length - 2)) {
    final y = ui.lerpDouble(frame.top, frame.bottom, stop)!;
    _drawGuidePath(
      canvas,
      _curvedSurfaceHorizontalPath(
        projection,
        left: frame.left,
        right: frame.right,
        y: y,
      ),
      style,
    );
  }
  for (final stop
      in tracks.columnStops.skip(1).take(tracks.columnStops.length - 2)) {
    final x = ui.lerpDouble(frame.left, frame.right, stop)!;
    drawGuideLine(
      canvas,
      projection.project(x, frame.top),
      projection.project(x, frame.bottom),
      style,
    );
  }
}

Iterable<({String key, Layout layout, _FlexSurfaceRect frame})>
_resolveCurvedFlexChildren(
  Layout composition,
  _FlexSurfaceRect frame,
  _LayoutPathProjection projection,
  LayoutContext layoutContext,
) sync* {
  final vertical = composition is ColumnLayout;
  if (!vertical && composition is! RowLayout) return;
  final children = _resolvedLayoutChildren(composition, layoutContext)
      .where((entry) => entry.value.isVisible(layoutContext))
      .toList(growable: false);
  if (children.isEmpty) return;

  final mainPixels = vertical
      ? projection.flatSize.height * (frame.bottom - frame.top)
      : projection.flatSize.width * (frame.right - frame.left);
  final crossPixels = vertical
      ? projection.flatSize.width * (frame.right - frame.left)
      : projection.flatSize.height * (frame.bottom - frame.top);
  if (mainPixels <= 0) return;
  final stops = _gridTrackStops(
    [
      for (final child in children)
        child.value.resolveSize(layoutContext).primary,
    ],
    mainPixels,
    rootFontSize: layoutContext.rootFontSize,
  );
  for (var index = 0; index < children.length; index += 1) {
    final entry = children[index];
    final start = stops[index];
    final end = stops[index + 1];
    final crossRange = _resolveFlexCrossAxisRange(
      composition,
      entry.value,
      crossPixels,
      layoutContext,
    );
    yield (
      key: entry.key,
      layout: entry.value,
      frame: vertical
          ? (
              left: frame.left,
              top: ui.lerpDouble(frame.top, frame.bottom, start)!,
              right: frame.right,
              bottom: ui.lerpDouble(frame.top, frame.bottom, end)!,
            )
          : (
              left: ui.lerpDouble(frame.left, frame.right, start)!,
              top: ui.lerpDouble(frame.top, frame.bottom, crossRange.start)!,
              right: ui.lerpDouble(frame.left, frame.right, end)!,
              bottom: ui.lerpDouble(frame.top, frame.bottom, crossRange.end)!,
            ),
    );
  }
}

List<Offset> _curvedSurfaceCorners(
  _LayoutPathProjection projection,
  _FlexSurfaceRect frame,
) => [
  projection.project(frame.left, frame.top),
  projection.project(frame.right, frame.top),
  projection.project(frame.right, frame.bottom),
  projection.project(frame.left, frame.bottom),
];

Path _curvedSurfacePath(
  _LayoutPathProjection projection,
  _FlexSurfaceRect frame,
) {
  final horizontalFraction = (frame.right - frame.left).abs();
  final samples = (projection.meshSegmentCount * horizontalFraction / 8)
      .ceil()
      .clamp(8, 96);
  final path = _curvedSurfaceHorizontalPath(
    projection,
    left: frame.left,
    right: frame.right,
    y: frame.top,
    samples: samples,
  );
  for (var index = samples; index >= 0; index -= 1) {
    final x = ui.lerpDouble(frame.left, frame.right, index / samples)!;
    final point = projection.project(x, frame.bottom);
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

Path _curvedSurfaceHorizontalPath(
  _LayoutPathProjection projection, {
  required double left,
  required double right,
  required double y,
  int? samples,
}) {
  final sampleCount =
      samples ??
      (projection.meshSegmentCount * (right - left).abs() / 8).ceil().clamp(
        8,
        96,
      );
  final path = Path();
  for (var index = 0; index <= sampleCount; index += 1) {
    final x = ui.lerpDouble(left, right, index / sampleCount)!;
    final point = projection.project(x, y);
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path;
}

void _drawCurvedPanelLayout(
  Canvas canvas,
  _LayoutPathProjection projection,
  _FlexSurfaceRect frame,
  PanelLayout panel,
  LayoutTextConfig text,
) {
  final path = _curvedSurfacePath(projection, frame);
  if (panel.borderStyle case final borderStyle?) {
    _drawGuidePath(canvas, path, borderStyle);
  }
  final label = text.value?.resolve();
  if (label == null || label.isEmpty) return;
  canvas.save();
  canvas.clipPath(path);
  _drawProjectedPanelText(canvas, projection, frame, text, label);
  canvas.restore();
}

void _drawProjectedPanelText(
  Canvas canvas,
  _LayoutPathProjection projection,
  _FlexSurfaceRect frame,
  LayoutTextConfig text,
  String label,
) {
  final style = _panelTextStyle(text);
  final glyphs = [
    for (final character in label.characters)
      TextPainter(
        text: TextSpan(text: character, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(),
  ];
  final textWidth = glyphs.fold<double>(0, (sum, glyph) => sum + glyph.width);
  final flatWidth = projection.flatSize.width;
  final flatHeight = projection.flatSize.height;
  if (textWidth <= 0 || flatWidth <= 0 || flatHeight <= 0) return;

  final centerU = (frame.left + frame.right) / 2;
  final centerV = (frame.top + frame.bottom) / 2;
  var cursor = -textWidth / 2;
  for (final glyph in glyphs) {
    final glyphCenter = cursor + glyph.width / 2;
    final u = centerU + glyphCenter / flatWidth;
    final origin = projection.project(u, centerV);
    final horizontal = _projectedSurfaceAxis(
      projection,
      u,
      centerV,
      horizontal: true,
    );
    final vertical = _projectedSurfaceAxis(
      projection,
      u,
      centerV,
      horizontal: false,
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.transform(
      Float64List.fromList([
        horizontal.dx,
        horizontal.dy,
        0,
        0,
        vertical.dx,
        vertical.dy,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
    glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
    canvas.restore();
    cursor += glyph.width;
  }
}

Offset _projectedSurfaceAxis(
  _LayoutPathProjection projection,
  double u,
  double v, {
  required bool horizontal,
}) {
  final logicalExtent = horizontal
      ? projection.flatSize.width
      : projection.flatSize.height;
  if (logicalExtent <= 0) {
    return horizontal ? const Offset(1, 0) : const Offset(0, 1);
  }
  final halfStep = 0.5 / logicalExtent;
  final startParameter = ((horizontal ? u : v) - halfStep).clamp(0.0, 1.0);
  final endParameter = ((horizontal ? u : v) + halfStep).clamp(0.0, 1.0);
  final logicalDistance = (endParameter - startParameter) * logicalExtent;
  if (logicalDistance <= 0) {
    return horizontal ? const Offset(1, 0) : const Offset(0, 1);
  }
  final start = horizontal
      ? projection.project(startParameter, v)
      : projection.project(u, startParameter);
  final end = horizontal
      ? projection.project(endParameter, v)
      : projection.project(u, endParameter);
  return (end - start) / logicalDistance;
}

_LayoutTapHit? _hitTestCurvedFlexComposition(
  Layout composition,
  _LayoutPathProjection projection,
  Offset position,
  String path,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  final children = _resolveCurvedFlexChildren(
    composition,
    frame,
    projection,
    layoutContext,
  ).toList().reversed;
  for (final child in children) {
    final childPath = '$path/${child.key}';
    final layout = child.layout;
    if (layout is ColumnLayout || layout is RowLayout) {
      final nested = _hitTestCurvedFlexComposition(
        layout,
        projection,
        position,
        childPath,
        layoutContext,
        nodeListSources,
        frame: child.frame,
      );
      if (nested != null) return nested;
    } else if (layout is GridLayout) {
      final nested = _hitTestCurvedGridComposition(
        layout,
        projection,
        position,
        childPath,
        layoutContext,
        nodeListSources,
        frame: child.frame,
      );
      if (nested != null) return nested;
    }
    final corners = _curvedSurfaceCorners(projection, child.frame);
    if (layout is NodeListLayout) {
      final entry = _hitTestNodeList(
        layout,
        nodeListSources,
        corners,
        position,
      );
      if (entry != null) {
        return (
          target: LayoutTapTarget(
            key: '$childPath/${entry.node.slug}',
            layout: layout,
            node: entry.resolvedNode,
            resolvedNode: entry.resolvedNode,
            label: _nodePresentationLabel(entry.node, layout),
          ),
          nodePath: _polygonPath(entry.points),
        );
      }
    }
    if (_isTappablePanel(layout) &&
        _curvedSurfacePath(projection, child.frame).contains(position)) {
      return (
        target: LayoutTapTarget(
          key: childPath,
          layout: layout,
          label: layout.resolveTextConfig(layoutContext).value?.resolve(),
        ),
        nodePath: null,
      );
    }
  }
  return null;
}

_LayoutTapHit? _hitTestGridComposition(
  GridLayout grid,
  List<Offset> points,
  Offset position,
  String path,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  _LayoutPathProjection? projection,
}) {
  if (projection?.canProjectBackground ?? false) {
    return _hitTestCurvedGridComposition(
      grid,
      projection!,
      position,
      path,
      layoutContext,
      nodeListSources,
    );
  }
  if (points.length != 4) return null;
  final tracks = _resolvedGridTracks(
    grid,
    _quadrilateralAverageSize(points),
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return null;
  final children = _resolveGridChildren(
    grid,
    tracks,
    layoutContext,
  ).toList().reversed;
  for (final child in children) {
    final childPath = '$path/${child.key}';
    final childPoints = _quadrilateralSlice(
      points,
      left: child.frame.left,
      right: child.frame.right,
      top: child.frame.top,
      bottom: child.frame.bottom,
    );
    final layout = child.layout;
    if (layout is ColumnLayout || layout is RowLayout) {
      final nested = _hitTestFlexComposition(
        layout,
        childPoints,
        position,
        childPath,
        layoutContext,
        nodeListSources,
      );
      if (nested != null) return nested;
    } else if (layout is GridLayout) {
      final nested = _hitTestGridComposition(
        layout,
        childPoints,
        position,
        childPath,
        layoutContext,
        nodeListSources,
      );
      if (nested != null) return nested;
    }
    final hit = _hitTestGridLeaf(
      layout,
      childPoints,
      position,
      childPath,
      layoutContext,
      nodeListSources,
    );
    if (hit != null) return hit;
  }
  return null;
}

_LayoutTapHit? _hitTestCurvedGridComposition(
  GridLayout grid,
  _LayoutPathProjection projection,
  Offset position,
  String path,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  _FlexSurfaceRect frame = const (left: 0, top: 0, right: 1, bottom: 1),
}) {
  final tracks = _resolvedGridTracks(
    grid,
    Size(
      projection.flatSize.width * (frame.right - frame.left),
      projection.flatSize.height * (frame.bottom - frame.top),
    ),
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return null;
  final children = _resolveGridChildren(
    grid,
    tracks,
    layoutContext,
  ).toList().reversed;
  for (final child in children) {
    final childPath = '$path/${child.key}';
    final childFrame = _scaleFlexSurfaceRect(frame, child.frame);
    final layout = child.layout;
    if (layout is ColumnLayout || layout is RowLayout) {
      final nested = _hitTestCurvedFlexComposition(
        layout,
        projection,
        position,
        childPath,
        layoutContext,
        nodeListSources,
        frame: childFrame,
      );
      if (nested != null) return nested;
    } else if (layout is GridLayout) {
      final nested = _hitTestCurvedGridComposition(
        layout,
        projection,
        position,
        childPath,
        layoutContext,
        nodeListSources,
        frame: childFrame,
      );
      if (nested != null) return nested;
    }
    final childPoints = _curvedSurfaceCorners(projection, childFrame);
    if (_isTappablePanel(layout) &&
        _curvedSurfacePath(projection, childFrame).contains(position)) {
      return (
        target: LayoutTapTarget(
          key: childPath,
          layout: layout,
          label: layout.resolveTextConfig(layoutContext).value?.resolve(),
        ),
        nodePath: null,
      );
    }
    final hit = _hitTestGridLeaf(
      layout,
      childPoints,
      position,
      childPath,
      layoutContext,
      nodeListSources,
    );
    if (hit != null) return hit;
  }
  return null;
}

_LayoutTapHit? _hitTestGridLeaf(
  Layout layout,
  List<Offset> points,
  Offset position,
  String path,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources,
) {
  if (layout is NodeListLayout) {
    final entry = _hitTestNodeList(layout, nodeListSources, points, position);
    if (entry != null) {
      return (
        target: LayoutTapTarget(
          key: '$path/${entry.node.slug}',
          layout: layout,
          node: entry.resolvedNode,
          resolvedNode: entry.resolvedNode,
          label: _nodePresentationLabel(entry.node, layout),
        ),
        nodePath: _polygonPath(entry.points),
      );
    }
  }
  if (_isTappablePanel(layout) && _polygonContains(points, position)) {
    return (
      target: LayoutTapTarget(
        key: path,
        layout: layout,
        label: layout.resolveTextConfig(layoutContext).value?.resolve(),
      ),
      nodePath: null,
    );
  }
  return null;
}

_LayoutTapHit? _hitTestFlexComposition(
  Layout composition,
  List<Offset> points,
  Offset position,
  String path,
  LayoutContext layoutContext,
  _NodeListSources nodeListSources, {
  _LayoutPathProjection? projection,
}) {
  if (projection?.canProjectBackground ?? false) {
    return _hitTestCurvedFlexComposition(
      composition,
      projection!,
      position,
      path,
      layoutContext,
      nodeListSources,
    );
  }
  final children = _resolveFlexChildren(
    composition,
    points,
    layoutContext,
  ).toList().reversed;
  for (final child in children) {
    final childPath = '$path/${child.key}';
    final layout = child.layout;
    if (layout is ColumnLayout || layout is RowLayout) {
      final nested = _hitTestFlexComposition(
        layout,
        child.points,
        position,
        childPath,
        layoutContext,
        nodeListSources,
      );
      if (nested != null) return nested;
    } else if (layout is GridLayout) {
      final nested = _hitTestGridComposition(
        layout,
        child.points,
        position,
        childPath,
        layoutContext,
        nodeListSources,
      );
      if (nested != null) return nested;
    }
    if (layout is NodeListLayout) {
      final entry = _hitTestNodeList(
        layout,
        nodeListSources,
        child.points,
        position,
      );
      if (entry != null) {
        return (
          target: LayoutTapTarget(
            key: '$childPath/${entry.node.slug}',
            layout: layout,
            node: entry.resolvedNode,
            resolvedNode: entry.resolvedNode,
            label: _nodePresentationLabel(entry.node, layout),
          ),
          nodePath: _polygonPath(entry.points),
        );
      }
    }
    if (_isTappablePanel(layout) && _polygonContains(child.points, position)) {
      return (
        target: LayoutTapTarget(
          key: childPath,
          layout: layout,
          label: layout.resolveTextConfig(layoutContext).value?.resolve(),
        ),
        nodePath: null,
      );
    }
  }
  return null;
}

Iterable<({String key, Layout layout, List<Offset> points})>
_resolveFlexChildren(
  Layout composition,
  List<Offset> points,
  LayoutContext layoutContext,
) sync* {
  final vertical = composition is ColumnLayout;
  if (!vertical && composition is! RowLayout) return;
  final children = _resolvedLayoutChildren(composition, layoutContext)
      .where((entry) => entry.value.isVisible(layoutContext))
      .toList(growable: false);
  if (children.isEmpty) return;

  final mainPixels = vertical
      ? ((points[3] - points[0]).distance + (points[2] - points[1]).distance) /
            2
      : ((points[1] - points[0]).distance + (points[2] - points[3]).distance) /
            2;
  final crossPixels = vertical
      ? ((points[1] - points[0]).distance + (points[2] - points[3]).distance) /
            2
      : ((points[3] - points[0]).distance + (points[2] - points[1]).distance) /
            2;
  if (mainPixels <= 0) return;

  final stops = _gridTrackStops(
    [
      for (final child in children)
        child.value.resolveSize(layoutContext).primary,
    ],
    mainPixels,
    rootFontSize: layoutContext.rootFontSize,
  );
  for (var index = 0; index < children.length; index += 1) {
    final entry = children[index];
    final start = stops[index];
    final end = stops[index + 1];
    final crossRange = _resolveFlexCrossAxisRange(
      composition,
      entry.value,
      crossPixels,
      layoutContext,
    );
    yield (
      key: entry.key,
      layout: entry.value,
      points: vertical
          ? _quadrilateralSlice(points, top: start, bottom: end)
          : _quadrilateralSlice(
              points,
              left: start,
              right: end,
              top: crossRange.start,
              bottom: crossRange.end,
            ),
    );
  }
}

({double start, double end}) _resolveFlexCrossAxisRange(
  Layout composition,
  Layout child,
  double availablePixels,
  LayoutContext layoutContext,
) {
  if (composition case RowLayout(crossAxisAlignment: final alignment?)) {
    if (availablePixels <= 0) return (start: 0, end: 0);
    if (alignment.stretches) return (start: 0, end: 1);
    final childSize = child.resolveSize(layoutContext).secondary;
    final extentPixels = childSize == null
        ? _layoutIntrinsicHeight(
            child,
            LayoutTextDefaults.config.merge(
              composition.resolveTextConfig(layoutContext),
            ),
            layoutContext,
          )
        : _resolveCrossAxisPixels(
            childSize.primary,
            availablePixels,
            layoutContext.rootFontSize,
          );
    final extent = (extentPixels / availablePixels).clamp(0.0, 1.0);
    final start = (1 - extent) * alignment.fraction;
    return (start: start, end: start + extent);
  }
  return (start: 0, end: 1);
}

double _resolveCrossAxisPixels(
  LayoutSize size,
  double availablePixels,
  double rootFontSize,
) => switch (size.unit) {
  LayoutSizeUnit.pixels => size.value,
  LayoutSizeUnit.rootEms => size.value * rootFontSize,
  LayoutSizeUnit.fraction ||
  LayoutSizeUnit.calculatedFraction => size.value * availablePixels,
};

double _layoutIntrinsicHeight(
  Layout layout,
  LayoutTextConfig inheritedText,
  LayoutContext layoutContext,
) {
  final text = inheritedText.merge(layout.resolveTextConfig(layoutContext));
  final value = text.value?.resolve();
  final ownHeight = value == null || value.isEmpty
      ? layout.layoutPadding * 2
      : (text.fontSize ?? layoutContext.rootFontSize) * (text.height ?? 1.2) +
            layout.layoutPadding * 2;
  final children = _resolvedLayoutChildren(layout, layoutContext)
      .map((entry) => entry.value)
      .where((child) => child.isVisible(layoutContext))
      .toList(growable: false);
  if (children.isEmpty) return ownHeight;
  final childHeights = [
    for (final child in children)
      _layoutIntrinsicHeight(child, text, layoutContext),
  ];
  final childrenHeight = layout is ColumnLayout
      ? childHeights.fold<double>(0, (sum, height) => sum + height) +
            layout.layoutGap * math.max(childHeights.length - 1, 0)
      : childHeights.reduce(math.max);
  return math.max(ownHeight, childrenHeight + layout.layoutPadding * 2);
}

List<Offset> _quadrilateralSlice(
  List<Offset> points, {
  double left = 0,
  double right = 1,
  double top = 0,
  double bottom = 1,
}) {
  return [
    _projectiveQuadrilateralPoint(points, left, top),
    _projectiveQuadrilateralPoint(points, right, top),
    _projectiveQuadrilateralPoint(points, right, bottom),
    _projectiveQuadrilateralPoint(points, left, bottom),
  ];
}

Offset _projectiveQuadrilateralPoint(List<Offset> points, double x, double y) {
  final transform = _rectToQuadTransform(1, 1, points);
  final transformedX = transform[0] * x + transform[4] * y + transform[12];
  final transformedY = transform[1] * x + transform[5] * y + transform[13];
  final transformedW = transform[3] * x + transform[7] * y + transform[15];
  if (transformedW.abs() <= 0.000001) {
    return Offset(transformedX, transformedY);
  }
  return Offset(transformedX / transformedW, transformedY / transformedW);
}

List<Offset> _screenOrderedQuadrilateral(List<Offset> points) {
  if (points.length != 4) return points;
  final byVertical = [...points]
    ..sort((left, right) => left.dy.compareTo(right.dy));
  final top = byVertical.take(2).toList()
    ..sort((left, right) => left.dx.compareTo(right.dx));
  final bottom = byVertical.skip(2).toList()
    ..sort((left, right) => left.dx.compareTo(right.dx));
  return [top[0], top[1], bottom[1], bottom[0]];
}

void _drawPanelLayout(
  Canvas canvas,
  List<Offset> points,
  PanelLayout panel,
  LayoutTextConfig text,
) {
  if (points.length != 4) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  if (panel.borderStyle case final borderStyle?) {
    for (var index = 0; index < points.length; index += 1) {
      drawGuideLine(
        canvas,
        points[index],
        points[(index + 1) % points.length],
        borderStyle,
      );
    }
  }
  final label = text.value?.resolve();
  if (label == null || label.isEmpty) return;
  final center =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  final textPainter = TextPainter(
    text: TextSpan(text: label, style: _panelTextStyle(text)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  textPainter.paint(
    canvas,
    center - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}

TextStyle _panelTextStyle(LayoutTextConfig text) => TextStyle(
  fontFamily: text.fontFamily ?? SevilleTypography.fontFamily,
  color: text.color ?? LayoutTextDefaults.config.color,
  fontSize: text.fontSize ?? LayoutTextDefaults.rootFontSize,
  fontWeight: text.fontWeight ?? FontWeight.w600,
  fontStyle: text.fontStyle,
  letterSpacing: text.letterSpacing,
  wordSpacing: text.wordSpacing,
  height: text.height,
  shadows: text.effects,
  fontFeatures: text.fontFeatures,
);

NodeTreeOccurrence? _hitTestFan(
  FanLayout fan,
  NodeTree tree,
  Rect bounds,
  Map<String, _ResolvedLayout> layouts,
  Offset position,
  LayoutContext layoutContext, {
  required List<Offset> planePoints,
}) {
  final segments = _fanSegments(
    fan,
    tree,
    bounds,
    layouts,
    layoutContext,
    planePoints: planePoints,
  );
  for (final segment in segments.reversed) {
    if (segment.path.contains(position)) return segment.occurrence;
  }
  return null;
}

ResolvedVaultNode _resolvedFanNode(
  NodeTreeOccurrence occurrence,
  Layout layout,
) {
  final node = occurrence.node;
  return ResolvedVaultNode(
    path: node.path,
    color: NodeComponent.colorFor(node),
    label: _nodePresentationLabel(node, layout),
    node: node,
    resolvedStatus: LayoutHttpStatus.ok,
  );
}

Rect _boundsForPoints(List<Offset> points) {
  return Rect.fromLTRB(
    points.map((point) => point.dx).reduce(math.min),
    points.map((point) => point.dy).reduce(math.min),
    points.map((point) => point.dx).reduce(math.max),
    points.map((point) => point.dy).reduce(math.max),
  );
}

void _drawTableLayout(
  Canvas canvas,
  List<Offset> parentPoints,
  TableLayout table,
  TableData data,
  Offset? hoverPosition,
  ClassificationLabelComponent classificationLabelComponent, {
  required _NodeListSources nodeListSources,
  required LayoutContext layoutContext,
  required PanelConfig panelDefaults,
  required NodeConfig nodeConfig,
  required LabelConfig label,
  required LayoutTextConfig text,
  required double Function(String panelId) panelExpansion,
  required void Function(String panelId, Path path) onPanelHeader,
  required void Function(LayoutTapTarget target, Path path) onNode,
  required void Function(
    TableAction action,
    String rowKey,
    String value,
    Path path,
  )
  onAction,
  required void Function(Path path, GuideStyle style) onClassificationLabel,
}) {
  if (parentPoints.length < 4 || table.tableColumnsConfig.isEmpty) {
    return;
  }

  final effectivePanel = panelDefaults
      .merge(table.resolvePanelConfig(layoutContext))
      .merge(table.tableConfig?.panel ?? const PanelConfig());
  final rows = _tableRowsWithFoldProgress(
    table,
    _tableLayoutRows(table, data, effectivePanel),
    panelExpansion,
  );
  if (rows.isEmpty) return;

  final panelPath = Path()
    ..moveTo(parentPoints.first.dx, parentPoints.first.dy);
  for (final corner in parentPoints.skip(1)) {
    panelPath.lineTo(corner.dx, corner.dy);
  }
  panelPath.close();

  final tablePoints = _paddedPathPoints(
    parentPoints,
    LayoutPathPadding.all(table.padding),
  );
  final panelBounds = _boundsForPoints(tablePoints);
  if (panelBounds.width <= 48 || panelBounds.height <= 48) return;

  final leftLength = (tablePoints[3] - tablePoints[0]).distance;
  final rightLength = (tablePoints[2] - tablePoints[1]).distance;
  final averageHeight = (leftLength + rightLength) / 2;
  final topWidth = (tablePoints[1] - tablePoints[0]).distance;
  final bottomWidth = (tablePoints[2] - tablePoints[3]).distance;
  final averageWidth = (topWidth + bottomWidth) / 2;
  final placements = _tableRowPlacements(
    table,
    rows,
    effectivePanel,
    averageWidth,
    averageHeight,
    rootFontSize: layoutContext.rootFontSize,
  );
  final columns = table.tableColumnsConfig.entries.toList(growable: false);
  final columnStops = _gridTrackStops(
    [for (final column in columns) column.value],
    averageWidth,
    rootFontSize: layoutContext.rootFontSize,
  );
  final tableTransformPoints = [
    _tableLayoutPoint(tablePoints, row: 0, column: 0),
    _tableLayoutPoint(tablePoints, row: 0, column: 1),
    _tableLayoutPoint(tablePoints, row: 1, column: 1),
    _tableLayoutPoint(tablePoints, row: 1, column: 0),
  ];
  final flatTablePoints = [
    Offset.zero,
    Offset(averageWidth, 0),
    Offset(averageWidth, averageHeight),
    Offset(0, averageHeight),
  ];
  final tableTransform = _rectToQuadTransform(
    averageWidth,
    averageHeight,
    tableTransformPoints,
  );
  for (final placement in placements) {
    final row = placement.row;
    final panelId = row.panelId;
    if (!row.section || panelId == null) continue;
    final panel = _tablePanel(table, panelId);
    if (panel == null || !panel.isFoldable) continue;
    onPanelHeader(
      panelId,
      _polygonPath([
        for (final point in _tableCellPoints(
          flatTablePoints,
          placement.rowStart,
          placement.rowEnd,
          placement.columnStart,
          placement.columnEnd,
        ))
          _transformCanvasPoint(tableTransform, point),
      ]),
    );
  }
  final recorder = ui.PictureRecorder();
  final tableCanvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, averageWidth, averageHeight),
  )..clipRect(Rect.fromLTWH(0, 0, averageWidth, averageHeight));

  final tableLinePaint = Paint()
    ..color = table.guideStyle.color
    ..strokeWidth = table.guideStyle.strokeWidth
    ..style = PaintingStyle.stroke;

  final highlight = table.cellHighlight;
  if (highlight != null && hoverPosition != null) {
    final highlightPaint = Paint()
      ..color = highlight.color
      ..style = PaintingStyle.fill;
    for (final placement in placements) {
      for (var column = 0; column < columnStops.length - 1; column += 1) {
        final columnStart = _tablePlacementColumn(
          placement,
          columnStops[column],
        );
        final columnEnd = _tablePlacementColumn(
          placement,
          columnStops[column + 1],
        );
        if (!_tableCellPath(
          tablePoints,
          placement.rowStart,
          placement.rowEnd,
          columnStart,
          columnEnd,
        ).contains(hoverPosition)) {
          continue;
        }
        if (highlight.rows) {
          _drawTableCellFill(
            tableCanvas,
            flatTablePoints,
            placement.rowStart,
            placement.rowEnd,
            placement.columnStart,
            placement.columnEnd,
            highlightPaint,
          );
        }
        if (highlight.columns) {
          _drawTableCellFill(
            tableCanvas,
            flatTablePoints,
            placement.rowStart,
            placement.rowEnd,
            columnStart,
            columnEnd,
            highlightPaint,
          );
        }
        break;
      }
    }
  }

  _TableRowPlacement? previousPlacement;
  for (final placement in placements) {
    final previous = previousPlacement;
    previousPlacement = placement;
    if (previous == null || previous.row.panelId != placement.row.panelId) {
      continue;
    }
    tableCanvas.drawLine(
      _tableLayoutPoint(
        flatTablePoints,
        row: placement.rowStart,
        column: placement.columnStart,
      ),
      _tableLayoutPoint(
        flatTablePoints,
        row: placement.rowStart,
        column: placement.columnEnd,
      ),
      tableLinePaint,
    );
  }
  for (final columnStop in columnStops.skip(1).take(columnStops.length - 2)) {
    for (final placement in placements) {
      if (placement.row.section) continue;
      final resolvedColumn = _tablePlacementColumn(placement, columnStop);
      tableCanvas.drawLine(
        _tableLayoutPoint(
          flatTablePoints,
          row: placement.rowStart,
          column: resolvedColumn,
        ),
        _tableLayoutPoint(
          flatTablePoints,
          row: placement.rowEnd,
          column: resolvedColumn,
        ),
        tableLinePaint,
      );
    }
  }
  for (final placement in placements) {
    final row = placement.row;
    if (row.spacer) continue;
    final rowStart = placement.rowStart;
    final rowEnd = placement.rowEnd;
    if (rowEnd - rowStart <= 0.000001) continue;
    if (row.section) {
      _drawTableCellFill(
        tableCanvas,
        flatTablePoints,
        rowStart,
        rowEnd,
        placement.columnStart,
        placement.columnEnd,
        Paint()
          ..color = table.guideStyle.color.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );
      if (row.label.isNotEmpty) {
        _paintTextInTableCell(
          tableCanvas,
          flatTablePoints,
          rowStart: rowStart,
          rowEnd: rowEnd,
          columnStart: placement.columnStart,
          columnEnd: placement.columnEnd,
          text: _tablePanelTitle(table, row, panelExpansion),
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: SevilleTypography.fontFamily,
            color: nodeConfig.labelColor ?? NodeDefaults.labelColor,
            fontSize: table.labelSize,
            fontWeight: FontWeight.w900,
          ),
        );
      }
      continue;
    }
    final firstValueColumnIndex = columns.indexWhere(
      (column) => column.key != 'key',
    );
    if (row.key != null && firstValueColumnIndex >= 0) {
      final value = _formatTableValue(row.value);
      final valueCellPath = _tableCellPath(
        flatTablePoints,
        rowStart,
        rowEnd,
        _tablePlacementColumn(placement, columnStops[firstValueColumnIndex]),
        _tablePlacementColumn(
          placement,
          columnStops[firstValueColumnIndex + 1],
        ),
      ).transform(tableTransform);
      for (final action in row.actions) {
        if (action.copiesToClipboard) {
          onAction(action, row.key!, value, valueCellPath);
        }
      }
    }
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex += 1) {
      final column = columns[columnIndex];
      final columnStart = _tablePlacementColumn(
        placement,
        columnStops[columnIndex],
      );
      final columnEnd = _tablePlacementColumn(
        placement,
        columnStops[columnIndex + 1],
      );
      final isKeyColumn = column.key == 'key';
      final rowLayout = isKeyColumn || row.key == null
          ? null
          : table.children[row.key];
      if (rowLayout is NodeListLayout && rowLayout.isVisible(layoutContext)) {
        final flatCellPoints = _tableCellPoints(
          flatTablePoints,
          rowStart,
          rowEnd,
          columnStart,
          columnEnd,
        );
        _drawNodeListLayout(
          tableCanvas,
          flatCellPoints,
          rowLayout,
          nodeListSources,
          layoutContext,
          nodeConfig: nodeConfig.merge(
            rowLayout.resolveNodeConfig(layoutContext),
          ),
        );
        for (final entry in _nodeListEntries(
          rowLayout,
          nodeListSources,
          flatCellPoints,
        )) {
          onNode(
            LayoutTapTarget(
              key: 'table/${row.panelId}/${row.key}/${entry.node.slug}',
              layout: rowLayout,
              node: entry.resolvedNode,
              resolvedNode: entry.resolvedNode,
              label: _nodePresentation(
                entry.node,
                rowLayout,
                nodeConfig: nodeConfig.merge(
                  rowLayout.resolveNodeConfig(layoutContext),
                ),
              ).text,
            ),
            _polygonPath([
              for (final point in entry.points)
                _transformCanvasPoint(tableTransform, point),
            ]),
          );
        }
        continue;
      }
      final classificationLabels = isKeyColumn
          ? const <String>[]
          : _classificationLabels(row.key, row.value);
      if (classificationLabels.isNotEmpty) {
        final labelFrames = classificationLabelComponent.renderLabels(
          tableCanvas,
          labels: classificationLabels,
          bounds: _tableCellPath(
            flatTablePoints,
            rowStart,
            rowEnd,
            columnStart,
            columnEnd,
          ).getBounds(),
          fontSize: table.valueSize,
          config: label,
          textConfig: text,
          context: layoutContext,
        );
        for (final frame in labelFrames) {
          final hoverStyle = frame.hoverStyle;
          if (hoverStyle == null) continue;
          onClassificationLabel(
            frame.path.transform(tableTransform),
            hoverStyle,
          );
        }
        continue;
      }
      final isNodeSlugValue = !isKeyColumn && _isNodeSlugField(row.key);
      _paintTextInTableCell(
        tableCanvas,
        flatTablePoints,
        rowStart: rowStart,
        rowEnd: rowEnd,
        columnStart: columnStart,
        columnEnd: columnEnd,
        text: isKeyColumn
            ? row.label
            : _formatTableRowValue(row.key, row.value, nodeConfig),
        maxLines: isKeyColumn ? 2 : 3,
        style: TextStyle(
          fontFamily: isNodeSlugValue ? null : SevilleTypography.fontFamily,
          color: isKeyColumn
              ? nodeConfig.labelColor ?? NodeDefaults.labelColor
              : isNodeSlugValue
              ? nodeConfig.slugColor ?? NodeDefaults.slugColor
              : nodeConfig.valueColor ?? NodeDefaults.valueColor,
          fontSize: isKeyColumn ? table.labelSize : table.valueSize,
          fontWeight: isKeyColumn
              ? FontWeight.w800
              : isNodeSlugValue
              ? FontWeight.w700
              : FontWeight.w600,
          fontFeatures: isNodeSlugValue
              ? (nodeConfig.slugTransform ?? NodeDefaults.slugTransform)
                    .fontFeatures
              : null,
          height: isKeyColumn ? null : 1.25,
        ),
      );
    }
  }
  _drawTablePanelBorders(
    tableCanvas,
    flatTablePoints,
    placements,
    table.panelBorderStyle ?? table.guideStyle,
  );

  final tablePicture = recorder.endRecording();
  canvas.save();
  canvas.clipPath(panelPath);
  canvas.transform(tableTransform);
  canvas.drawPicture(tablePicture);
  canvas.restore();
  tablePicture.dispose();
}

void _drawTablePanelBorders(
  Canvas canvas,
  List<Offset> points,
  List<_TableRowPlacement> placements,
  GuideStyle style,
) {
  var startIndex = 0;
  while (startIndex < placements.length) {
    final panelId = placements[startIndex].row.panelId;
    var endIndex = startIndex + 1;
    while (endIndex < placements.length &&
        placements[endIndex].row.panelId == panelId) {
      endIndex += 1;
    }
    final first = placements[startIndex];
    final last = placements[endIndex - 1];
    final corners = [
      _tableLayoutPoint(points, row: first.rowStart, column: first.columnStart),
      _tableLayoutPoint(points, row: first.rowStart, column: first.columnEnd),
      _tableLayoutPoint(points, row: last.rowEnd, column: last.columnEnd),
      _tableLayoutPoint(points, row: last.rowEnd, column: last.columnStart),
    ];
    for (var index = 0; index < corners.length; index += 1) {
      drawGuideLine(
        canvas,
        corners[index],
        corners[(index + 1) % corners.length],
        style,
      );
    }
    startIndex = endIndex;
  }
}

class _ResolvedTableRow {
  const _ResolvedTableRow({
    this.key,
    this.panelId,
    required this.label,
    required this.value,
    required this.size,
    this.section = false,
    this.spacer = false,
    this.actions = const [],
  });

  final String? key;
  final String? panelId;
  final String label;
  final Object? value;
  final LayoutSize size;
  final bool section;
  final bool spacer;
  final List<TableAction> actions;
}

List<_ResolvedTableRow> _buildTableRows(
  TableDefinition definition,
  TableData data, {
  required LayoutSize Function(LayoutSize rowSize) sectionSize,
  required String Function(Object? value) formatValue,
  required PanelConfig panelDefaults,
  bool Function(Object? value)? includeValue,
}) {
  final config = definition.tableConfig;
  if (config == null) return const [];

  final rows = config.rowConfig.orderedRows;
  final panels = config.orderedPanels;
  final panelIds = panels.map((entry) => entry.key).toSet();

  Iterable<_ResolvedTableRow> rowsForPanel(
    String panelId,
    PanelConfig panel,
  ) sync* {
    final owningRows = [
      for (final row in rows)
        if (panelIds.contains(row.value.panelId) &&
            row.value.panelId == panelId)
          row,
    ];
    final hasPopulatedRow = owningRows.any(
      (row) => includeValue?.call(data[row.key]) ?? true,
    );
    if (!hasPopulatedRow && !panel.keepsEmpty) return;
    final panelRows = [
      for (final row in owningRows)
        if (row.value.includeWhenEmpty ||
            (includeValue?.call(data[row.key]) ?? true))
          row,
    ];
    _sortTableRows(panelRows, panel.rowOrdering, data, formatValue);

    final panelTitle = panel.title?.trim();
    if (panelTitle != null && panelTitle.isNotEmpty) {
      final panelSize = panel.size ?? panelDefaults.foldedPanelSize;
      final titleSize = panelRows.isEmpty
          ? panelSize
          : panelRows.first.value.size;
      if (titleSize == null) return;
      yield _ResolvedTableRow(
        panelId: panelId,
        label: panelTitle,
        value: null,
        size: sectionSize(titleSize),
        section: true,
      );
    }
    for (final row in panelRows) {
      yield _ResolvedTableRow(
        key: row.key,
        panelId: panelId,
        label: row.value.label ?? row.key,
        value: data[row.key],
        size: row.value.size,
        actions: row.value.actions,
      );
    }
  }

  return [for (final panel in panels) ...rowsForPanel(panel.key, panel.value)];
}

void _sortTableRows(
  List<MapEntry<String, TableRow>> rows,
  TableRowOrdering ordering,
  TableData data,
  String Function(Object? value) formatValue,
) {
  switch (ordering) {
    case TableRowOrdering.asConfigured:
      return;
    case TableRowOrdering.keyAlphabetical:
      rows.sort((left, right) => left.key.compareTo(right.key));
    case TableRowOrdering.valueAlphabetical:
      rows.sort(
        (left, right) =>
            formatValue(data[left.key]).compareTo(formatValue(data[right.key])),
      );
  }
}

PanelConfig? _tablePanel(TableLayout table, String panelId) {
  return table.tableConfig?.panels[panelId];
}

List<_ResolvedTableRow> _tableRowsWithFoldProgress(
  TableLayout table,
  List<_ResolvedTableRow> rows,
  double Function(String panelId) panelExpansion,
) => [
  for (final row in rows)
    if (row.section || row.spacer || row.panelId == null)
      row
    else
      _ResolvedTableRow(
        key: row.key,
        panelId: row.panelId,
        label: row.label,
        value: row.value,
        size: _scaledTableTrack(
          row.size,
          _tablePanel(table, row.panelId!)?.isFoldable ?? false
              ? panelExpansion(row.panelId!)
              : 1,
        ),
        section: row.section,
        spacer: row.spacer,
        actions: row.actions,
      ),
];

LayoutSize _scaledTableTrack(LayoutSize track, double factor) {
  final size = track.primary;
  final value = size.value * factor.clamp(0, 1);
  final scaled = switch (size.unit) {
    LayoutSizeUnit.fraction => LayoutSize.fr(value),
    LayoutSizeUnit.pixels => LayoutSize.px(value),
    LayoutSizeUnit.rootEms => LayoutSize.rem(value),
    LayoutSizeUnit.calculatedFraction => LayoutSize.calculatedFr(
      value,
      derivative: size.derivative ?? '',
    ),
  };
  final secondary = track.secondary;
  return secondary == null
      ? scaled
      : LayoutSize.twoDimensional(primary: scaled, secondary: secondary);
}

String _tablePanelTitle(
  TableLayout table,
  _ResolvedTableRow row,
  double Function(String panelId) panelExpansion,
) {
  final panelId = row.panelId;
  if (panelId == null) return row.label;
  final panel = _tablePanel(table, panelId);
  if (panel == null || !panel.isFoldable) return row.label;
  final marker = panelExpansion(panelId) > 0.5 ? '▾' : '▸';
  return '$marker ${row.label}';
}

List<_ResolvedTableRow> _tableLayoutRows(
  TableLayout table,
  TableData data,
  PanelConfig panelDefaults,
) {
  final configuredRows = table.tableConfig == null
      ? const <_ResolvedTableRow>[]
      : _buildTableRows(
          table,
          data,
          sectionSize: _tableSeparatorSize,
          formatValue: _formatTableValue,
          includeValue: _tableValueIsPopulated,
          panelDefaults: panelDefaults,
        );
  if (!table.includeUnconfiguredFields) {
    return configuredRows;
  }

  final configuredKeys = {
    for (final row
        in table.tableConfig?.rowConfig.rows.entries ??
            const <MapEntry<String, TableRow>>[])
      row.key,
  };
  final unconfiguredEntries =
      data.values.entries
          .where(
            (entry) =>
                !configuredKeys.contains(entry.key) &&
                _tableValueIsPopulated(entry.value),
          )
          .toList()
        ..sort((left, right) => left.key.compareTo(right.key));
  final unconfiguredRows = [
    for (final entry in unconfiguredEntries)
      _ResolvedTableRow(
        key: entry.key,
        panelId: table.unconfiguredFieldPanelId,
        label: entry.key,
        value: entry.value,
        size: table.unconfiguredFieldSize,
      ),
  ];
  final panelId = table.unconfiguredFieldPanelId;
  if (panelId == null) {
    return [...configuredRows, ...unconfiguredRows];
  }
  final panelKeys = {
    for (final row
        in table.tableConfig?.rowConfig.rows.entries ??
            const <MapEntry<String, TableRow>>[])
      if (row.value.panelId == panelId) row.key,
  };
  final lastPanelRow = configuredRows.lastIndexWhere(
    (row) => row.key != null && panelKeys.contains(row.key),
  );
  final insertionIndex = lastPanelRow < 0 ? 0 : lastPanelRow + 1;
  return [
    ...configuredRows.take(insertionIndex),
    ...unconfiguredRows,
    ...configuredRows.skip(insertionIndex),
  ];
}

List<_TableRowPlacement> _tableRowPlacements(
  TableLayout table,
  List<_ResolvedTableRow> rows,
  PanelConfig panelDefaults,
  double availableWidth,
  double availableHeight, {
  required double rootFontSize,
}) {
  final panelRuns = <_TablePanelRun>[];
  for (final row in rows) {
    if (panelRuns.isEmpty || panelRuns.last.panelId != row.panelId) {
      final panel = row.panelId == null
          ? null
          : _tablePanel(table, row.panelId!);
      final panelSize = _tablePanelSize(panelDefaults, panel);
      panelRuns.add((
        panelId: row.panelId,
        rows: <_ResolvedTableRow>[row],
        width: _tablePanelWidth(panelDefaults, panel, availableWidth),
        height: panelSize?.secondary,
      ));
    } else {
      panelRuns.last.rows.add(row);
    }
  }

  final bands = <List<_TablePanelRun>>[];
  var usedWidth = 0.0;
  for (final panel in panelRuns) {
    if (bands.isEmpty ||
        (bands.last.isNotEmpty && usedWidth + panel.width > 1.000001)) {
      bands.add([]);
      usedWidth = 0;
    }
    bands.last.add(panel);
    usedWidth += panel.width;
  }

  final bandTracks = <LayoutSize>[];
  for (var index = 0; index < bands.length; index += 1) {
    if (index > 0) bandTracks.add(LayoutSize.px(table.panelGap));
    final configuredHeight = _largestTableBandHeight([
      for (final panel in bands[index])
        if (panel.height != null) panel.height!,
    ], availableHeight);
    final demand = bands[index]
        .map(
          (panel) => panel.rows.fold<double>(
            0,
            (sum, row) => sum + math.max(row.size.primary.value, 0),
          ),
        )
        .fold<double>(0, math.max);
    bandTracks.add(
      configuredHeight?.primary ?? LayoutSize.fr(math.max(demand, 0.000001)),
    );
  }
  final bandStops = _gridTrackStops(
    bandTracks,
    availableHeight,
    rootFontSize: rootFontSize,
  );
  final horizontalGap = availableWidth <= 0
      ? 0.0
      : (table.panelGap / availableWidth).clamp(0.0, 1.0);
  final placements = <_TableRowPlacement>[];
  var trackIndex = 0;
  for (final band in bands) {
    final bandStart = bandStops[trackIndex];
    final bandEnd = bandStops[trackIndex + 1];
    trackIndex += 2;
    final usableWidth = math.max(
      1 - horizontalGap * math.max(band.length - 1, 0),
      0,
    );
    var columnStart = 0.0;
    for (final panel in band) {
      final columnEnd = math
          .min(columnStart + panel.width * usableWidth, 1.0)
          .toDouble();
      final rowStops = _gridTrackStops(
        [for (final row in panel.rows) row.size.primary],
        availableHeight * (bandEnd - bandStart),
        rootFontSize: rootFontSize,
      );
      for (var index = 0; index < panel.rows.length; index += 1) {
        placements.add((
          row: panel.rows[index],
          rowStart: bandStart + rowStops[index] * (bandEnd - bandStart),
          rowEnd: bandStart + rowStops[index + 1] * (bandEnd - bandStart),
          columnStart: columnStart,
          columnEnd: columnEnd,
        ));
      }
      columnStart = columnEnd + horizontalGap;
    }
  }
  return placements;
}

double _tablePanelWidth(
  PanelConfig panelDefaults,
  PanelConfig? panel,
  double availableWidth,
) {
  final size = _tablePanelSize(panelDefaults, panel)?.primary;
  if (size == null) return 1;
  final width = size.unit == LayoutSizeUnit.pixels
      ? size.value / math.max(availableWidth, 1)
      : _gridTrackFractionValue(size);
  return width.clamp(0.000001, 1.0);
}

LayoutSize? _tablePanelSize(PanelConfig panelDefaults, PanelConfig? panel) =>
    panel == null ? null : panel.size ?? panelDefaults.foldedPanelSize;

LayoutSize? _largestTableBandHeight(
  List<LayoutSize> heights,
  double availableHeight,
) {
  if (heights.isEmpty) return null;
  final safeHeight = math.max(availableHeight, 1);
  double demand(LayoutSize size) {
    final scalar = size.primary;
    return scalar.unit == LayoutSizeUnit.pixels
        ? scalar.value / safeHeight
        : _gridTrackFractionValue(scalar);
  }

  return heights.reduce(
    (largest, candidate) =>
        demand(candidate) > demand(largest) ? candidate : largest,
  );
}

double _tablePlacementColumn(_TableRowPlacement placement, double column) =>
    placement.columnStart +
    (placement.columnEnd - placement.columnStart) * column;

List<String> _classificationLabels(String? key, Object? value) {
  if (key != 'labels' &&
      key != 'selected_node_labels' &&
      key != 'neo4j_labels') {
    return const [];
  }
  if (value is! Iterable) return const [];
  return [
    for (final item in value)
      if (item.toString().trim().isNotEmpty) item.toString().trim(),
  ];
}

bool _tableValueIsPopulated(Object? value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

Offset _tableLayoutPoint(
  List<Offset> points, {
  required double row,
  required double column,
}) {
  final firstSide = Offset.lerp(points[0], points[3], row)!;
  final secondSide = Offset.lerp(points[1], points[2], row)!;
  final visualLeft = firstSide.dx <= secondSide.dx ? firstSide : secondSide;
  final visualRight = firstSide.dx <= secondSide.dx ? secondSide : firstSide;
  return Offset.lerp(visualLeft, visualRight, column)!;
}

void _drawTableCellFill(
  Canvas canvas,
  List<Offset> points,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
  Paint paint,
) {
  canvas.drawPath(
    _tableCellPath(points, rowStart, rowEnd, columnStart, columnEnd),
    paint,
  );
}

Float64List _rectToQuadTransform(
  double width,
  double height,
  List<Offset> quad,
) {
  final x0 = quad[0].dx;
  final y0 = quad[0].dy;
  final x1 = quad[1].dx;
  final y1 = quad[1].dy;
  final x2 = quad[2].dx;
  final y2 = quad[2].dy;
  final x3 = quad[3].dx;
  final y3 = quad[3].dy;

  final dx1 = x1 - x2;
  final dy1 = y1 - y2;
  final dx2 = x3 - x2;
  final dy2 = y3 - y2;
  final dx3 = x0 - x1 + x2 - x3;
  final dy3 = y0 - y1 + y2 - y3;
  final denominator = dx1 * dy2 - dx2 * dy1;

  var g = 0.0;
  var h = 0.0;
  if (denominator.abs() > 0.000001) {
    g = (dx3 * dy2 - dx2 * dy3) / denominator;
    h = (dx1 * dy3 - dx3 * dy1) / denominator;
  }

  final a = x1 - x0 + g * x1;
  final b = x3 - x0 + h * x3;
  final c = x0;
  final d = y1 - y0 + g * y1;
  final e = y3 - y0 + h * y3;
  final f = y0;
  final safeWidth = math.max(width, 0.000001);
  final safeHeight = math.max(height, 0.000001);

  return Float64List.fromList([
    a / safeWidth,
    d / safeWidth,
    0,
    g / safeWidth,
    b / safeHeight,
    e / safeHeight,
    0,
    h / safeHeight,
    0,
    0,
    1,
    0,
    c,
    f,
    0,
    1,
  ]);
}

Offset _transformCanvasPoint(Float64List transform, Offset point) {
  final w = transform[3] * point.dx + transform[7] * point.dy + transform[15];
  final safeW = w.abs() <= 0.000001 ? 1.0 : w;
  return Offset(
    (transform[0] * point.dx + transform[4] * point.dy + transform[12]) / safeW,
    (transform[1] * point.dx + transform[5] * point.dy + transform[13]) / safeW,
  );
}

Path _tableCellPath(
  List<Offset> points,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
) {
  return _polygonPath(
    _tableCellPoints(points, rowStart, rowEnd, columnStart, columnEnd),
  );
}

List<Offset> _tableCellPoints(
  List<Offset> points,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
) => [
  _tableLayoutPoint(points, row: rowStart, column: columnStart),
  _tableLayoutPoint(points, row: rowStart, column: columnEnd),
  _tableLayoutPoint(points, row: rowEnd, column: columnEnd),
  _tableLayoutPoint(points, row: rowEnd, column: columnStart),
];

LayoutSize _tableSeparatorSize(LayoutSize fieldSize) {
  const separatorScale = 0.5;
  final size = fieldSize.secondary ?? fieldSize.primary;
  return switch (size.unit) {
    LayoutSizeUnit.fraction => LayoutSize.fr(size.value * separatorScale),
    LayoutSizeUnit.pixels => LayoutSize.px(size.value * separatorScale),
    LayoutSizeUnit.rootEms => LayoutSize.rem(size.value * separatorScale),
    LayoutSizeUnit.calculatedFraction => LayoutSize.calculatedFr(
      size.value * separatorScale,
      derivative: size.derivative ?? '',
    ),
  };
}

Map<String, Object?> _nodeInfoValues(ResolvedVaultNode selectedNode) {
  final node = selectedNode.node;
  final frontmatter = node?.frontmatter ?? const <String, String>{};
  return {
    'id': node?.id,
    'slug': node?.slug ?? selectedNode.path,
    'path': node?.path,
    'title': node?.title,
    'body': node?.body,
    'tags': node?.tags,
    'labels': node?.labels,
    'frontmatter': frontmatter,
    'modified_at': node != null && node.hasModifiedAt()
        ? node.modifiedAt.toDateTime().toIso8601String()
        : null,
    'emojis': node == null
        ? null
        : [
            for (final emoji in node.emojis)
              {
                'id': emoji.id,
                'character': emoji.character,
                'title': emoji.title,
                'codes': emoji.codes,
                'group_name': emoji.groupName,
                'subgroup': emoji.subgroup,
                'category': emoji.category,
                'source': emoji.source,
                'counter': emoji.counter,
                'created_at': emoji.hasCreatedAt()
                    ? emoji.createdAt.toDateTime().toIso8601String()
                    : null,
                'updated_at': emoji.hasUpdatedAt()
                    ? emoji.updatedAt.toDateTime().toIso8601String()
                    : null,
              },
          ],
    'update_count': node?.updateCount,
    'version':
        frontmatter['version'] ??
        frontmatter['node_version'] ??
        frontmatter['schema_version'],
    'classification':
        frontmatter['classification'] ??
        frontmatter['class'] ??
        frontmatter['type'] ??
        frontmatter['kind'],
  };
}

void _paintTextInTableCell(
  Canvas canvas,
  List<Offset> points, {
  required double rowStart,
  required double rowEnd,
  required double columnStart,
  required double columnEnd,
  required String text,
  required TextStyle style,
  int maxLines = 2,
  TextAlign textAlign = TextAlign.left,
}) {
  final rowCenter = (rowStart + rowEnd) / 2;
  final left = _tableLayoutPoint(points, row: rowCenter, column: columnStart);
  final right = _tableLayoutPoint(points, row: rowCenter, column: columnEnd);
  final width = (right - left).distance;
  final height =
      ((_tableLayoutPoint(points, row: rowEnd, column: columnStart) -
                  _tableLayoutPoint(points, row: rowStart, column: columnStart))
              .distance +
          (_tableLayoutPoint(points, row: rowEnd, column: columnEnd) -
                  _tableLayoutPoint(points, row: rowStart, column: columnEnd))
              .distance) /
      2;
  if (width <= 8 || height <= 8) return;

  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: math.max(width - 12, 4));
  final textStart = left.dx <= right.dx ? left : right;
  final centerY = (left.dy + right.dy) / 2;
  final x = switch (textAlign) {
    TextAlign.center => textStart.dx + (width - textPainter.width) / 2,
    TextAlign.right ||
    TextAlign.end => textStart.dx + width - textPainter.width - 6,
    TextAlign.left || TextAlign.start || TextAlign.justify => textStart.dx + 6,
  };
  textPainter.paint(canvas, Offset(x, centerY - textPainter.height / 2));
}

String _formatTableValue(Object? value) =>
    LayoutText.defaultRepresentation(value);

bool _isNodeSlugField(String? key) =>
    key == 'slug' || key == 'selected_node_slugs';

String _formatTableRowValue(String? key, Object? value, NodeConfig nodeConfig) {
  if (!_isNodeSlugField(key)) return _formatTableValue(value);
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((slug) => slug.isNotEmpty)
        .map(nodeConfig.formatSlug)
        .join(', ');
  }
  final slug = value?.toString().trim() ?? '';
  return slug.isEmpty ? '—' : nodeConfig.formatSlug(slug);
}

void _drawStickmanLayout(
  Canvas canvas,
  Layout parent,
  Rect parentBounds,
  StickmanLayout stickman,
) {
  final frame = _stickmanFrame(parent, parentBounds);
  final range = stickman.rangeEnd - stickman.rangeStart;
  if (frame.isEmpty || range <= 0) return;

  final unitPx = frame.height / range;
  final centerX = frame.left + frame.width * stickman.centerX;
  Offset point(double x, double y) {
    return Offset(
      centerX + x * unitPx,
      frame.top + (y - stickman.rangeStart) * unitPx,
    );
  }

  final paint = Paint()
    ..color = stickman.style.color
    ..strokeWidth = stickman.style.strokeWidth
    ..strokeCap = stickman.style.strokeCap
    ..style = PaintingStyle.stroke;

  final headCenter = point(0, stickman.headRadius);
  canvas.drawCircle(headCenter, stickman.headRadius * unitPx, paint);

  final neck = point(0, stickman.headRadius * 2);
  final hip = point(0, stickman.hipY);
  final leftShoulder = point(-stickman.shoulderHalfWidth, stickman.shoulderY);
  final rightShoulder = point(stickman.shoulderHalfWidth, stickman.shoulderY);
  final leftHand = point(-stickman.handHalfWidth, stickman.handY);
  final rightHand = point(stickman.handHalfWidth, stickman.handY);
  final leftFoot = point(-stickman.footHalfWidth, stickman.footY);
  final rightFoot = point(stickman.footHalfWidth, stickman.footY);

  canvas.drawLine(neck, hip, paint);
  canvas.drawLine(leftShoulder, rightShoulder, paint);
  canvas.drawLine(leftShoulder, leftHand, paint);
  canvas.drawLine(rightShoulder, rightHand, paint);
  canvas.drawLine(hip, leftFoot, paint);
  canvas.drawLine(hip, rightFoot, paint);
}

Rect _stickmanFrame(Layout parent, Rect parentBounds) {
  return _layoutInnerSquareFrame(parent, parentBounds);
}

Rect _layoutInnerSquareFrame(Layout parent, Rect parentBounds) {
  return _layoutSquareFrameForCircle(
    _layoutCircleFrame(parent, parentBounds, LayoutCircleBoundary.outer),
    fallback: parentBounds,
  );
}

Rect _layoutCircleFrame(
  Layout parent,
  Rect parentBounds,
  LayoutCircleBoundary boundary,
) {
  return parent
      .resolveCircleBounds(parentBounds.size, boundary)
      .shift(parentBounds.topLeft);
}

Rect _layoutSquareFrameForCircle(Rect circleFrame, {required Rect fallback}) {
  final squareHalfSide = circleFrame.shortestSide / 2 / math.sqrt(2);
  return Rect.fromCenter(
    center: circleFrame.center,
    width: squareHalfSide * 2,
    height: squareHalfSide * 2,
  );
}

double _gridAreaEnd(double start, double span, int trackCount) {
  if (span == GridSpan.full) return trackCount.toDouble();
  return (start + math.max(span, 0.0001)).clamp(0, trackCount).toDouble();
}

double _gridStopAt(List<double> stops, double track) {
  if (stops.isEmpty) return 0;
  final clampedTrack = track.clamp(0, stops.length - 1).toDouble();
  final index = clampedTrack.floor();
  if (index >= stops.length - 1) return stops.last;

  final fraction = clampedTrack - index;
  return stops[index] + (stops[index + 1] - stops[index]) * fraction;
}

List<double> _gridTrackStops(
  List<LayoutSize> tracks,
  double availablePixels, {
  double rootFontSize = LayoutTextDefaults.rootFontSize,
}) {
  final primaryTracks = [for (final track in tracks) track.primary];
  final safePixels = math.max(availablePixels, 0);
  final fixedPixels = primaryTracks
      .where(_isFixedGridTrack)
      .fold<double>(
        0,
        (sum, track) =>
            sum + math.max(_gridTrackFixedPixels(track, rootFontSize), 0),
      );
  final fractionTotal = primaryTracks
      .where((track) => !_isFixedGridTrack(track))
      .fold<double>(
        0,
        (sum, track) => sum + math.max(_gridTrackFractionValue(track), 0),
      );
  final fractionPixels = math.max(safePixels - fixedPixels, 0);
  final rawSizes = [
    for (final track in primaryTracks)
      _isFixedGridTrack(track)
          ? math.max(_gridTrackFixedPixels(track, rootFontSize), 0)
          : fractionTotal == 0
          ? 0
          : fractionPixels *
                math.max(_gridTrackFractionValue(track), 0) /
                fractionTotal,
  ];
  final total = rawSizes.fold<double>(0, (sum, size) => sum + size);
  if (total <= 0) return const [0, 1];
  final stops = <double>[0];
  var cursor = 0.0;
  for (final size in rawSizes) {
    cursor += size / total;
    stops.add(cursor.clamp(0, 1));
  }
  stops[stops.length - 1] = 1;
  return stops;
}

bool _isFixedGridTrack(LayoutSize track) =>
    track.unit == LayoutSizeUnit.pixels || track.unit == LayoutSizeUnit.rootEms;

double _gridTrackFixedPixels(LayoutSize track, double rootFontSize) =>
    track.unit == LayoutSizeUnit.rootEms
    ? track.value * math.max(rootFontSize, 0)
    : track.value;

double _gridTrackFractionValue(LayoutSize track) {
  if (track.unit != LayoutSizeUnit.calculatedFraction) return track.value;

  final now = DateTime.now();
  final hourPassed =
      (now.minute * 60 + now.second + now.millisecond / 1000) / 3600;
  final hourPassedFraction = hourPassed.clamp(0.0, 1.0);
  final hourLeftFraction = 1 - hourPassedFraction;
  final dayPassed =
      (now.hour * 3600 +
          now.minute * 60 +
          now.second +
          now.millisecond / 1000) /
      86400;
  final dayPassedFraction = dayPassed.clamp(0.0, 1.0);
  final dayLeftFraction = 1 - dayPassedFraction;

  return switch (track.derivative) {
    'now-in-current-hour.passed' => hourPassedFraction,
    'now-in-current-hour.left' => hourLeftFraction,
    'now-in-current-day.passed' => dayPassedFraction,
    'now-in-current-day.left' => dayLeftFraction,
    'now-in-time-grid.balance-before-now' =>
      track.value + hourLeftFraction - 0.5 + dayLeftFraction - 0.5,
    'now-in-time-grid.balance-after-now' =>
      track.value + hourPassedFraction - 0.5 + dayPassedFraction - 0.5,
    _ => track.value,
  };
}

Map<String, _ResolvedLayout> _resolveLayouts(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolvedRoot = root.resolve(layoutContext);
  final resolved = <String, _ResolvedLayout>{
    '': (
      layout: resolvedRoot,
      bounds: Offset.zero & size,
      hierarchy: [resolvedRoot],
    ),
  };

  void visit(
    Layout parent,
    Rect parentBounds,
    List<String> parentPath,
    List<Layout> parentHierarchy,
    EdgeInsets remainingSafePadding,
  ) {
    for (final entry in _resolvedLayoutChildren(parent, layoutContext)) {
      final child = entry.value;
      if (!child.isVisible(layoutContext)) continue;
      var bounds = parentBounds;
      var childSafePadding = remainingSafePadding;
      if (child is SafeAreaLayout) {
        bounds = Rect.fromLTRB(
          bounds.left + remainingSafePadding.left,
          bounds.top + remainingSafePadding.top,
          bounds.right - remainingSafePadding.right,
          bounds.bottom - remainingSafePadding.bottom,
        );
        childSafePadding = EdgeInsets.zero;
      } else if (child is PlaneLayout) {
        final geometry = _resolvePlaneGeometry(parent, bounds, child);
        if (geometry != null) {
          bounds = geometry.shapeFrame;
        }
      }
      final path = [...parentPath, entry.key];
      final hierarchy = [...parentHierarchy, child];
      resolved[path.join('/')] = (
        layout: child,
        bounds: bounds,
        hierarchy: hierarchy,
      );
      visit(child, bounds, path, hierarchy, childSafePadding);
    }
  }

  visit(resolvedRoot, Offset.zero & size, const [], [
    resolvedRoot,
  ], safePadding);
  return resolved;
}

Offset? _resolveReference(
  LayoutDerivativeReference reference,
  Map<String, _ResolvedLayout> layouts, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final derivative = resolved.layout
      .getDerivatives(reference.snapshot, layoutContext)
      .values[reference.derivative];
  if (derivative == null) return null;
  return resolved.bounds.topLeft +
      derivative.resolve(resolved.layout, resolved.bounds.size, layoutContext);
}

Offset? _resolvePathSlotReference(
  LayoutPathSlotReference reference,
  Map<String, _ResolvedLayout> layouts, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final path = resolved.layout.children[reference.path]?.resolve(layoutContext);
  if (path is! LayoutPath) return null;
  final grid = path.children[reference.grid]?.resolve(layoutContext);
  if (grid is! GridLayout) return null;
  final resolvedSlot = _resolveGridSlot(grid, reference.slot);
  if (resolvedSlot == null) return null;

  final points = _resolvedLayoutPathPoints(path, layouts, layoutContext);
  if (points == null || points.length != 4) return null;
  final projection = _resolvedLayoutPathProjection(
    path,
    points,
    layouts,
    layoutContext,
  );
  final tracks = _resolvedGridTracks(
    grid,
    projection?.canProjectBackground ?? false
        ? projection!.flatSize
        : _quadrilateralAverageSize(points),
    rootFontSize: layoutContext.rootFontSize,
  );
  if (tracks == null) return null;
  final frame = _resolveGridSlotFrame(
    resolvedSlot.slot,
    tracks,
    layout: _gridChildForSlot(grid, reference.slot, layoutContext),
  );
  if (frame == null) return null;
  final corners = projection?.canProjectBackground ?? false
      ? _curvedSurfaceCorners(projection!, frame)
      : _quadrilateralSlice(
          _screenOrderedQuadrilateral(points),
          left: frame.left,
          right: frame.right,
          top: frame.top,
          bottom: frame.bottom,
        );
  return reference.position.resolve(_boundsForPoints(corners));
}

Layout? _gridChildForSlot(
  GridLayout grid,
  String slot,
  LayoutContext layoutContext,
) {
  final targetSlot = _resolveGridSlot(grid, slot);
  if (targetSlot == null) return null;
  for (final child in grid.children.values) {
    final resolved = child.resolve(layoutContext);
    final requestedSlot = resolved.slot;
    if (requestedSlot == null) continue;
    final childSlot = _resolveGridSlot(grid, requestedSlot);
    if (childSlot?.key == targetSlot.key) return resolved;
  }
  return null;
}

void _drawSlotRayArrow(
  Canvas canvas,
  Offset start,
  Offset target,
  LayoutSlotRayLayout ray,
) {
  final delta = target - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final base = target - direction * ray.arrowSize;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final paint = Paint()
    ..color = ray.style.color
    ..strokeWidth = ray.style.strokeWidth
    ..strokeCap = ray.style.strokeCap
    ..style = PaintingStyle.stroke;
  canvas.drawLine(target, base + perpendicular * ray.arrowSize * 0.5, paint);
  canvas.drawLine(target, base - perpendicular * ray.arrowSize * 0.5, paint);
}

void _drawSlotToDerivativeRayArrow(
  Canvas canvas,
  Offset start,
  Offset target,
  LayoutSlotToDerivativeRayLayout ray,
) {
  final delta = target - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final base = target - direction * ray.arrowSize;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final paint = Paint()
    ..color = ray.style.color
    ..strokeWidth = ray.style.strokeWidth
    ..strokeCap = ray.style.strokeCap
    ..style = PaintingStyle.stroke;
  canvas.drawLine(target, base + perpendicular * ray.arrowSize * 0.5, paint);
  canvas.drawLine(target, base - perpendicular * ray.arrowSize * 0.5, paint);
}
