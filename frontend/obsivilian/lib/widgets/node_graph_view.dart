import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';
import '../domain/node_color_rules.dart';
import '../domain/node_temporal.dart';
import '../state/node_store.dart';
import 'graph_world_layout.dart';
import 'node_graph_physics.dart';

/// Native Flutter view of one bounded NodeGraph response.
class NodeGraphView extends StatefulWidget {
  const NodeGraphView({
    required this.graph,
    required this.selectedNodeSlug,
    required this.onNodeSelected,
    required this.onCalendarDateSelected,
    required this.colorRules,
    super.key,
  });

  final NodeGraph graph;
  final String? selectedNodeSlug;
  final void Function(Node node, Offset globalAnchor) onNodeSelected;
  final ValueChanged<DateTime> onCalendarDateSelected;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();
        final graphNodes = widget.graph.nodes
            .where((node) => !_isCalendarDateNode(node))
            .toList(growable: false);
        final baseExtent =
            (math.sqrt(width * height / math.max(1, graphNodes.length)) * 0.55)
                .clamp(32.0, 88.0);
        final diameters = <String, double>{
          for (final node in graphNodes)
            node.slug: (baseExtent * (_sizeScales[node.slug] ?? 1)).clamp(
              16.0,
              176.0,
            ),
        };
        final layout = _ensureLayout(
          Size(width, height),
          diameters,
          graphNodes,
        );
        _ensurePhysics(layout, diameters);
        final displayPositions = _physics!.positions;
        final visible = Rect.fromPoints(
          _transformation.toScene(Offset.zero),
          _transformation.toScene(Offset(width, height)),
        ).inflate(190);
        final todayScreenY =
            layout.todayY * _cameraScale + _transformation.value.entry(1, 3);
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NowLinePainter(nowY: todayScreenY),
                ),
              ),
            ),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformation,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false,
                minScale: 0.05,
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
                      for (final node in graphNodes)
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
              ),
            ),
            Positioned.fill(
              child: _CalendarHud(
                scale: _cameraScale,
                todayScreenY: todayScreenY,
                nodes: widget.graph.nodes,
                onDateSelected: widget.onCalendarDateSelected,
              ),
            ),
          ],
        );
      },
    );
  }

  GraphWorldLayout _ensureLayout(
    Size viewport,
    Map<String, double> diameters,
    List<Node> graphNodes,
  ) {
    final current = _layout;
    if (current != null &&
        _layoutGraph == widget.graph &&
        current.viewport == viewport &&
        _sameValues(_layoutDiameters, diameters)) {
      return current;
    }
    final next = GraphWorldLayout.compute(
      nodes: graphNodes,
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
          viewport.width / 2 - next.origin.dx,
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
      for (final entry in oldPositions.entries)
        if (current?.planes[entry.key] == layout.planes[entry.key])
          entry.key: entry.value + shift,
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

  double get _cameraScale => _transformation.value.getMaxScaleOnAxis();

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

bool _isCalendarDateNode(Node node) =>
    node.labels.contains('Date') && TemporalInterval.fromNode(node) != null;

class _CalendarHud extends ConsumerWidget {
  const _CalendarHud({
    required this.scale,
    required this.todayScreenY,
    required this.nodes,
    required this.onDateSelected,
  });

  final double scale;
  final double todayScreenY;
  final List<Node> nodes;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final now = DateTime.now();
      final safeScale = scale.clamp(0.05, 8.0);
      final topTime = _timeAtHudY(0, now, todayScreenY, size.height, safeScale);
      final bottomTime = _timeAtHudY(
        size.height,
        now,
        todayScreenY,
        size.height,
        safeScale,
      );
      final windowStart = bottomTime.isBefore(topTime) ? bottomTime : topTime;
      final windowEnd = topTime.isAfter(bottomTime) ? topTime : bottomTime;
      final visibleHours =
          windowEnd.difference(windowStart).inMinutes.abs() / 60;
      final hourStep = switch (visibleHours) {
        <= 36 => 1,
        <= 96 => 3,
        <= 240 => 6,
        _ => 24,
      };
      final hourTicks = <({double y, String label})>[];
      if (visibleHours <= 24 * 31) {
        final firstHour = windowStart;
        var tick = DateTime(
          firstHour.year,
          firstHour.month,
          firstHour.day,
          firstHour.hour - firstHour.hour % hourStep,
        );
        while (!tick.isAfter(windowEnd) && hourTicks.length < 240) {
          hourTicks.add((
            y: _hudY(tick, now, todayScreenY, size.height, safeScale),
            label: '${tick.hour.toString().padLeft(2, '0')}:00',
          ));
          tick = tick.add(Duration(hours: hourStep));
        }
      }

      final firstDay = DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day,
      );
      final lastDay = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
      final visibleDayCount = lastDay.difference(firstDay).inDays + 1;
      final dayStep = math.max(1, (visibleDayCount / 32).ceil());
      final loadedDateNodes = <String, Node>{
        for (final node in nodes)
          if (_isCalendarDateNode(node)) node.slug: node,
      };
      final visibleDates =
          <({DateTime date, double lineY, double centerY, String slug})>[];
      var day = firstDay;
      while (!day.isAfter(lastDay) && visibleDates.length < 40) {
        final slug = _dateSlug(day);
        final lineY = _hudY(day, now, todayScreenY, size.height, safeScale);
        final nextLineY = _hudY(
          day.add(const Duration(days: 1)),
          now,
          todayScreenY,
          size.height,
          safeScale,
        );
        visibleDates.add((
          date: day,
          lineY: lineY,
          centerY: (lineY + nextLineY) / 2,
          slug: slug,
        ));
        day = day.add(Duration(days: dayStep));
      }
      final exactState = ref.watch(
        nodesByExactSlugsProvider(
          visibleDates.map((item) => item.slug).join('\n'),
        ),
      );
      final exactDateNodes = switch (exactState) {
        AsyncData(:final value) => value,
        _ => const <String, Node>{},
      };
      final days = [
        for (final item in visibleDates)
          _HudDay(
            date: item.date,
            lineY: item.lineY,
            centerY: item.centerY,
            exists:
                loadedDateNodes.containsKey(item.slug) ||
                exactDateNodes.containsKey(item.slug),
            checking:
                exactState is AsyncLoading &&
                !loadedDateNodes.containsKey(item.slug),
          ),
      ];

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CalendarHudPainter(
                  hourLines: hourTicks
                      .map((tick) => tick.y)
                      .toList(growable: false),
                  dayLines: days
                      .map((day) => day.lineY)
                      .toList(growable: false),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: _TimeWindowLabel(
                  start: windowStart,
                  end: windowEnd,
                  now: now,
                  nowVisible: todayScreenY >= 0 && todayScreenY <= size.height,
                ),
              ),
            ),
          ),
          for (final tick in hourTicks)
            if (visibleHours <= 96 && tick.y > 16 && tick.y < size.height - 16)
              Positioned(
                left: 52,
                top: tick.y - 8,
                child: IgnorePointer(
                  child: Text(
                    tick.label,
                    style: const TextStyle(
                      color: Color(0x887FA3AF),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          if (todayScreenY > 16 && todayScreenY < size.height - 16)
            Positioned(
              left: 52,
              top: todayScreenY - 22,
              child: const IgnorePointer(
                child: Text(
                  'NOW',
                  style: TextStyle(
                    color: Color(0xFFE45656),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          for (final day in days)
            if (day.centerY > 72 && day.centerY < size.height - 28)
              Positioned(
                left: 12,
                top: day.centerY - 54,
                width: 28,
                height: 108,
                child: Center(
                  child: _CalendarDateButton(
                    day: day,
                    onPressed: () => onDateSelected(day.date),
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class _HudDay {
  const _HudDay({
    required this.date,
    required this.lineY,
    required this.centerY,
    required this.exists,
    required this.checking,
  });

  final DateTime date;
  final double lineY;
  final double centerY;
  final bool exists;
  final bool checking;
}

class _CalendarDateButton extends StatelessWidget {
  const _CalendarDateButton({required this.day, required this.onPressed});

  final _HudDay day;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = day.exists
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150);
    return Tooltip(
      message: day.checking
          ? 'Checking Date Node'
          : day.exists
          ? 'Edit Date Node'
          : 'Create Date Node',
      child: RotatedBox(
        quarterTurns: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: day.checking ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: day.exists
                  ? color.withAlpha(45)
                  : Theme.of(context).colorScheme.surface.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: day.exists ? 1.4 : 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  day.checking
                      ? Icons.more_horiz
                      : day.exists
                      ? Icons.event
                      : Icons.add,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  _dateSlug(day.date),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: day.exists ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarHudPainter extends CustomPainter {
  const _CalendarHudPainter({required this.hourLines, required this.dayLines});

  final List<double> hourLines;
  final List<double> dayLines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final y in hourLines) {
      _dottedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0x287FA3AF)
          ..strokeWidth = 1,
        dash: 2,
        gap: 7,
      );
    }
    for (final y in dayLines) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0x467FA3AF)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_CalendarHudPainter oldDelegate) =>
      oldDelegate.hourLines != hourLines || oldDelegate.dayLines != dayLines;
}

class _NowLinePainter extends CustomPainter {
  const _NowLinePainter({required this.nowY});

  final double nowY;

  @override
  void paint(Canvas canvas, Size size) {
    _dottedLine(
      canvas,
      Offset(0, nowY),
      Offset(size.width, nowY),
      Paint()
        ..color = const Color(0xFFE45656)
        ..strokeWidth = 2,
      dash: 12,
      gap: 7,
    );
  }

  @override
  bool shouldRepaint(_NowLinePainter oldDelegate) => oldDelegate.nowY != nowY;
}

void _dottedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  var x = start.dx;
  while (x < end.dx) {
    canvas.drawLine(
      Offset(x, start.dy),
      Offset(math.min(x + dash, end.dx), end.dy),
      paint,
    );
    x += dash + gap;
  }
}

double _hudY(
  DateTime value,
  DateTime now,
  double todayScreenY,
  double height,
  double scale,
) {
  final hours = value.difference(now).inMinutes / 60;
  if (hours == 0) return todayScreenY;
  final distance = height / 2 * (math.log(1 + hours.abs() / 12) / math.ln2);
  return todayScreenY + (hours > 0 ? -distance : distance) * scale;
}

DateTime _timeAtHudY(
  double y,
  DateTime now,
  double todayScreenY,
  double height,
  double scale,
) {
  final virtualDistance = (y - todayScreenY) / scale;
  final hours = 12 * (math.pow(2, virtualDistance.abs() / (height / 2)) - 1);
  final signedHours = virtualDistance < 0 ? hours : -hours;
  return now.add(Duration(minutes: (signedHours * 60).round()));
}

String _dateSlug(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.year.toString().padLeft(4, '0')}';

class _TimeWindowLabel extends StatelessWidget {
  const _TimeWindowLabel({
    required this.start,
    required this.end,
    required this.now,
    required this.nowVisible,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final bool nowVisible;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(220),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        _timeWindowLabel(start, end, now, nowVisible),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
  );
}

String _timeWindowLabel(
  DateTime start,
  DateTime end,
  DateTime now,
  bool nowVisible,
) {
  if (nowVisible) {
    final past = now.difference(start);
    final future = end.difference(now);
    final larger = math.max(past.inMinutes.abs(), future.inMinutes.abs());
    final difference = (past.inMinutes - future.inMinutes).abs();
    if (larger > 0 && difference / larger < 0.08) {
      return 'TIME · NOW ±${_compactDuration(Duration(minutes: ((past.inMinutes + future.inMinutes) / 2).round()))}';
    }
    return 'TIME · NOW −${_compactDuration(past)} / +${_compactDuration(future)}';
  }
  final span = end.difference(start);
  return 'TIME · ${_compactMoment(start, span)} → ${_compactMoment(end, span)}';
}

String _compactDuration(Duration duration) {
  final minutes = duration.inMinutes.abs();
  if (minutes < 120) return '${math.max(1, minutes)}m';
  final hours = minutes / 60;
  if (hours < 48) return '${hours.round()}h';
  final days = hours / 24;
  if (days < 730) return '${days.round()}d';
  final years = days / 365.2425;
  return years < 10 ? '${years.toStringAsFixed(1)}y' : '${years.round()}y';
}

String _compactMoment(DateTime value, Duration span) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = value.day.toString().padLeft(2, '0');
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  if (span.inHours.abs() <= 48) {
    return '$day ${months[value.month - 1]} $time';
  }
  if (span.inDays.abs() <= 730) {
    return '$day ${months[value.month - 1]} ${value.year}';
  }
  return value.year.toString();
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

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.connections != connections ||
      oldDelegate.positions != positions ||
      oldDelegate.selectedNodeSlug != selectedNodeSlug;
}

String _edgeKey(String source, String target) =>
    source.compareTo(target) <= 0 ? '$source|$target' : '$target|$source';
