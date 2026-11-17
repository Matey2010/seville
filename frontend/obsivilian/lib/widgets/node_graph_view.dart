import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';
import 'node_graph_physics.dart';

/// Native Flutter view of one bounded NodeGraph response.
class NodeGraphView extends StatefulWidget {
  const NodeGraphView({
    required this.graph,
    required this.selectedNodeId,
    required this.onNodeSelected,
    super.key,
  });

  final NodeGraph graph;
  final String? selectedNodeId;
  final ValueChanged<Node> onNodeSelected;

  @override
  State<NodeGraphView> createState() => _NodeGraphViewState();
}

class _NodeGraphViewState extends State<NodeGraphView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformation = TransformationController();
  late final Ticker _ticker;
  NodeGraphPhysics? _physics;
  Duration? _lastFrame;
  double _accumulator = 0;
  double _simulationTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _physics?.dispose();
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
        final extent =
            (math.sqrt(width * height / widget.graph.nodes.length) * 0.55)
                .clamp(32.0, 88.0);
        _ensurePhysics(Size(width, height), extent);
        final displayPositions = _physics!.positions;
        return InteractiveViewer(
          transformationController: _transformation,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 5,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConnectionPainter(
                      connections: widget.graph.connections,
                      positions: displayPositions,
                      selectedNodeId: widget.selectedNodeId,
                    ),
                  ),
                ),
                for (final node in widget.graph.nodes)
                  if (displayPositions[node.id] case final position?)
                    Positioned(
                      left: position.dx * width - extent / 2,
                      top: position.dy * height - extent / 2,
                      width: extent,
                      height: extent,
                      child: _GraphNode(
                        node: node,
                        selected: node.id == widget.selectedNodeId,
                        onTap: () => widget.onNodeSelected(node),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ensurePhysics(Size viewport, double extent) {
    final ids = {for (final node in widget.graph.nodes) node.id};
    final current = _physics;
    if (current != null &&
        current.viewport == viewport &&
        current.nodeDiameter == extent &&
        current.nodeIds.length == ids.length &&
        current.nodeIds.containsAll(ids)) {
      return;
    }
    final previousPositions = current?.positions ?? const <String, Offset>{};
    current?.dispose();
    _physics = NodeGraphPhysics(
      viewport: viewport,
      nodeDiameter: extent,
      nodeIds: ids,
      initialPositions: previousPositions,
    );
    _accumulator = 0;
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
    required this.selected,
    required this.onTap,
  });

  final Node node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = node.slug.trim().isEmpty ? node.displayLabel : node.slug;
    final emoji = node.primaryEmojiCharacter;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: node.title.trim().isEmpty ? label : node.title,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Node $label',
        child: Material(
          color: selected ? scheme.primaryContainer : const Color(0xFF203849),
          shape: CircleBorder(
            side: BorderSide(
              color: selected ? scheme.primary : const Color(0xFF7694A9),
              width: selected ? 3 : 1,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
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
                        color: selected
                            ? scheme.onPrimaryContainer
                            : const Color(0xFFFFD54F),
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
    required this.connections,
    required this.positions,
    required this.selectedNodeId,
  });

  final List<NodeConnection> connections;
  final Map<String, Offset> positions;
  final String? selectedNodeId;

  @override
  void paint(Canvas canvas, Size size) {
    final seen = <String>{};
    for (final connection in connections) {
      if (!connection.hasTargetNodeId()) continue;
      final source = positions[connection.sourceNodeId];
      final target = positions[connection.targetNodeId];
      if (source == null || target == null) continue;
      if (!seen.add(
        _edgeKey(connection.sourceNodeId, connection.targetNodeId),
      )) {
        continue;
      }
      final active =
          connection.sourceNodeId == selectedNodeId ||
          connection.targetNodeId == selectedNodeId;
      canvas.drawLine(
        Offset(source.dx * size.width, source.dy * size.height),
        Offset(target.dx * size.width, target.dy * size.height),
        Paint()
          ..color = active ? const Color(0xFFADD8F1) : const Color(0x997A92A3)
          ..strokeWidth = active ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.connections != connections ||
      oldDelegate.positions != positions ||
      oldDelegate.selectedNodeId != selectedNodeId;
}

String _edgeKey(String source, String target) =>
    source.compareTo(target) <= 0 ? '$source|$target' : '$target|$source';
