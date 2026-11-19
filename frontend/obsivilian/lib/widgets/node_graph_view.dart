import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';
import '../domain/node_color_rules.dart';
import 'graph_world_layout.dart';
import 'node_graph_physics.dart';

/// Native Flutter view of one bounded NodeGraph response.
class NodeGraphView extends StatefulWidget {
  const NodeGraphView({
    required this.graph,
    required this.selectedNodeSlug,
    required this.onNodeSelected,
    required this.colorRules,
    super.key,
  });

  final NodeGraph graph;
  final String? selectedNodeSlug;
  final void Function(Node node, Offset globalAnchor) onNodeSelected;
  final List<NodeColorRule> colorRules;

  @override
  State<NodeGraphView> createState() => _NodeGraphViewState();
}

class _NodeGraphViewState extends State<NodeGraphView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformation = TransformationController();
  late final Ticker _ticker;
  NodeGraphPhysics? _physics;
  GraphWorldLayout? _layout;
  NodeGraph? _layoutGraph;
  Map<String, double> _layoutDiameters = {};
  bool _cameraInitialized = false;
  Duration? _lastFrame;
  double _accumulator = 0;
  double _simulationTime = 0;
  Map<String, NodeColorRule> _matchedRules = {};
  Map<String, Color> _ruleColors = {};
  Map<String, double> _sizeScales = {};
  Map<String, double> _gravityScales = {};

  @override
  void initState() {
    super.initState();
    _resolveColors();
    _transformation.addListener(_onCameraChanged);
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void didUpdateWidget(covariant NodeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph ||
        oldWidget.colorRules != widget.colorRules) {
      _resolveColors();
    }
  }

  void _resolveColors() {
    final matched = <String, NodeColorRule>{};
    final colors = <String, Color>{};
    final sizes = <String, double>{};
    final gravity = <String, double>{};
    for (final node in widget.graph.nodes) {
      final rule = matchingNodeColorRule(node, widget.colorRules);
      sizes[node.slug] = rule != null && rule.hasSizeScale()
          ? rule.sizeScale
          : 1;
      gravity[node.slug] = rule != null && rule.hasGravityScale()
          ? rule.gravityScale
          : 1;
      if (rule == null) continue;
      matched[node.slug] = rule;
      final hex = rule.colorHex;
      if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
        colors[node.slug] = Color(
          0xFF000000 | int.parse(hex.substring(1), radix: 16),
        );
      }
    }
    _matchedRules = matched;
    _ruleColors = colors;
    _sizeScales = sizes;
    _gravityScales = gravity;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _physics?.dispose();
    _transformation.removeListener(_onCameraChanged);
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.nodes.isEmpty) {
      _physics?.dispose();
      _physics = null;
      return const Center(child: Text('No Nodes in this graph view.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();
        final baseExtent =
            (math.sqrt(width * height / widget.graph.nodes.length) * 0.55)
                .clamp(32.0, 88.0);
        final diameters = <String, double>{
          for (final node in widget.graph.nodes)
            node.slug: (baseExtent * (_sizeScales[node.slug] ?? 1)).clamp(
              16.0,
              176.0,
            ),
        };
        final layout = _ensureLayout(Size(width, height), diameters);
        _ensurePhysics(layout, diameters);
        final displayPositions = _physics!.positions;
        final visible = Rect.fromPoints(
          _transformation.toScene(Offset.zero),
          _transformation.toScene(Offset(width, height)),
        ).inflate(190);
        return InteractiveViewer(
          transformationController: _transformation,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          minScale: 0.15,
          maxScale: 8,
          child: SizedBox(
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConnectionPainter(
                      layout: layout,
                      connections: widget.graph.connections,
                      positions: displayPositions,
                      selectedNodeSlug: widget.selectedNodeSlug,
                    ),
                  ),
                ),
                for (final node in widget.graph.nodes)
                  if (displayPositions[node.slug] case final position?)
                    if (visible.contains(position))
                      Positioned(
                        left: position.dx - diameters[node.slug]! / 2,
                        top: position.dy - diameters[node.slug]! / 2,
                        width: diameters[node.slug]!,
                        height: diameters[node.slug]!,
                        child: _GraphNode(
                          node: node,
                          colorRule: _matchedRules[node.slug],
                          ruleColor: _ruleColors[node.slug],
                          selected: node.slug == widget.selectedNodeSlug,
                          onTap: (anchor) =>
                              widget.onNodeSelected(node, anchor),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  GraphWorldLayout _ensureLayout(Size viewport, Map<String, double> diameters) {
    final current = _layout;
    if (current != null &&
        _layoutGraph == widget.graph &&
        current.viewport == viewport &&
        _sameValues(_layoutDiameters, diameters)) {
      return current;
    }
    final next = GraphWorldLayout.compute(
      nodes: widget.graph.nodes,
      viewport: viewport,
      diameters: diameters,
    );
    _layout = next;
    _layoutGraph = widget.graph;
    _layoutDiameters = Map.of(diameters);
    final previousOrigin = current?.origin;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final matrix = _transformation.value.clone();
      if (!_cameraInitialized) {
        matrix.setTranslationRaw(
          viewport.width * (next.timeIntervals.isEmpty ? 0.5 : 0.74) -
              next.origin.dx,
          viewport.height / 2 - next.origin.dy,
          0,
        );
        _cameraInitialized = true;
      } else if (previousOrigin != null) {
        final scale = matrix.getMaxScaleOnAxis();
        matrix.setTranslationRaw(
          matrix.entry(0, 3) - (next.origin.dx - previousOrigin.dx) * scale,
          matrix.entry(1, 3) - (next.origin.dy - previousOrigin.dy) * scale,
          0,
        );
      }
      _transformation.value = matrix;
    });
    return next;
  }

  void _ensurePhysics(GraphWorldLayout layout, Map<String, double> diameters) {
    final current = _physics;
    if (current != null &&
        current.worldSize == layout.size &&
        _sameValues(current.nodeDiameters, diameters) &&
        _sameValues(current.gravityScales, _gravityScales) &&
        _sameOffsets(current.anchors, layout.anchors)) {
      return;
    }
    final oldPositions = current?.positions ?? const <String, Offset>{};
    final oldOrigin = current == null ? null : _previousPhysicsOrigin;
    final shift = oldOrigin == null ? Offset.zero : layout.origin - oldOrigin;
    final previousPositions = {
      for (final entry in oldPositions.entries) entry.key: entry.value + shift,
    };
    current?.dispose();
    _physics = NodeGraphPhysics(
      worldSize: layout.size,
      anchors: layout.anchors,
      planes: layout.planes,
      nodeDiameters: diameters,
      gravityScales: _gravityScales,
      initialPositions: previousPositions,
    );
    _previousPhysicsOrigin = layout.origin;
    _accumulator = 0;
  }

  Offset? _previousPhysicsOrigin;

  bool _sameValues(Map<String, double> a, Map<String, double> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  bool _sameOffsets(Map<String, Offset> a, Map<String, Offset> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  void _onCameraChanged() {
    if (mounted) setState(() {});
  }

  void _onFrame(Duration elapsed) {
    final previous = _lastFrame;
    _lastFrame = elapsed;
    if (previous == null ||
        _physics == null ||
        !TickerMode.valuesOf(context).enabled ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      _accumulator = 0;
      return;
    }
    const step = 1 / 30;
    _accumulator = math.min(
      _accumulator + (elapsed - previous).inMicroseconds / 1000000,
      step * 2,
    );
    var changed = false;
    while (_accumulator >= step) {
      _simulationTime += step;
      _physics!.step(step, _simulationTime);
      _accumulator -= step;
      changed = true;
    }
    if (changed) setState(() {});
  }
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.node,
    required this.colorRule,
    required this.ruleColor,
    required this.selected,
    required this.onTap,
  });

  final Node node;
  final NodeColorRule? colorRule;
  final Color? ruleColor;
  final bool selected;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final label = node.slug.trim().isEmpty ? node.displayLabel : node.slug;
    final emoji = node.primaryEmojiCharacter;
    final scheme = Theme.of(context).colorScheme;
    final fill = ruleColor ?? const Color(0xFF203849);
    final textColor = ruleColor == null
        ? const Color(0xFFFFD54F)
        : ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Tooltip(
      message: [
        node.title.trim().isEmpty ? label : node.title,
        if (colorRule != null) 'Appearance rule: ${colorRule!.name}',
      ].join('\n'),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Node $label',
        child: Material(
          color: fill,
          shape: CircleBorder(
            side: BorderSide(
              color: selected ? scheme.primary : const Color(0xFF7694A9),
              width: selected ? 3 : 1,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              onTap(
                box?.localToGlobal(box.size.center(Offset.zero)) ?? Offset.zero,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 23)),
                    Text(
                      '[[$label]]',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  const _ConnectionPainter({
    required this.layout,
    required this.connections,
    required this.positions,
    required this.selectedNodeSlug,
  });

  final GraphWorldLayout layout;
  final List<NodeConnection> connections;
  final Map<String, Offset> positions;
  final String? selectedNodeSlug;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTimePlane(canvas);
    for (final link in layout.calendarLinks) {
      final child = positions[link.childSlug];
      final parent = positions[link.parentSlug];
      if (child == null || parent == null) continue;
      canvas.drawLine(
        child,
        parent,
        Paint()
          ..color = const Color(0x665AB69B)
          ..strokeWidth = 1.3,
      );
    }
    final seen = <String>{};
    for (final connection in connections) {
      if (!connection.hasTargetNodeSlug()) continue;
      final source = positions[connection.sourceNodeSlug];
      final target = positions[connection.targetNodeSlug];
      if (source == null || target == null) continue;
      if (!seen.add(
        _edgeKey(connection.sourceNodeSlug, connection.targetNodeSlug),
      )) {
        continue;
      }
      final active =
          connection.sourceNodeSlug == selectedNodeSlug ||
          connection.targetNodeSlug == selectedNodeSlug;
      canvas.drawLine(
        source,
        target,
        Paint()
          ..color = active ? const Color(0xFFADD8F1) : const Color(0x337A92A3)
          ..strokeWidth = active ? 2 : 1,
      );
    }
  }

  void _paintTimePlane(Canvas canvas) {
    if (layout.timeIntervals.isEmpty) return;
    final bounds = layout.timeBounds;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
      Paint()..color = const Color(0x181C6680),
    );
    for (final guide in layout.timeGuides) {
      canvas.drawLine(
        Offset(bounds.left + 12, guide.y),
        Offset(bounds.right - 12, guide.y),
        Paint()
          ..color = const Color(0x3378A7B8)
          ..strokeWidth = 1,
      );
      _paintText(
        canvas,
        guide.label,
        Offset(bounds.left + 12, guide.y - 22),
        const Color(0xFF9DB7C3),
        12,
      );
    }
    canvas.drawLine(
      Offset(bounds.left + 12, layout.todayY),
      Offset(bounds.right - 12, layout.todayY),
      Paint()
        ..color = const Color(0xAA74C9B1)
        ..strokeWidth = 1.5,
    );
    _paintText(
      canvas,
      'NOW · ${layout.todayLabel}',
      Offset(bounds.left + 12, layout.todayY - 23),
      const Color(0xFFB6E8D8),
      13,
    );
    for (final band in layout.timeBandX.entries) {
      canvas.drawLine(
        Offset(band.value, bounds.top + 12),
        Offset(band.value, bounds.bottom - 12),
        Paint()
          ..color = const Color(0x2278A7B8)
          ..strokeWidth = 1,
      );
      _paintText(
        canvas,
        _bandLabel(band.key),
        Offset(band.value - 28, layout.timeHeaderY),
        const Color(0xFF9DB7C3),
        11,
      );
    }
    _paintText(
      canvas,
      '↑ FUTURE',
      Offset(bounds.left + 12, layout.todayY - 55),
      const Color(0xFFAAD6DC),
      13,
    );
    _paintText(
      canvas,
      '↓ PAST',
      Offset(bounds.left + 12, layout.timeHeaderY),
      const Color(0xFFAAD6DC),
      13,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  String _bandLabel(TemporalGranularity granularity) => switch (granularity) {
    TemporalGranularity.TEMPORAL_GRANULARITY_YEAR => 'YEARS',
    TemporalGranularity.TEMPORAL_GRANULARITY_SEASON => 'SEASONS',
    TemporalGranularity.TEMPORAL_GRANULARITY_MONTH => 'MONTHS',
    TemporalGranularity.TEMPORAL_GRANULARITY_WEEK => 'WEEKS',
    TemporalGranularity.TEMPORAL_GRANULARITY_DAY => 'DAYS',
    _ => '',
  };

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.connections != connections ||
      oldDelegate.positions != positions ||
      oldDelegate.selectedNodeSlug != selectedNodeSlug;
}

String _edgeKey(String source, String target) =>
    source.compareTo(target) <= 0 ? '$source|$target' : '$target|$source';
