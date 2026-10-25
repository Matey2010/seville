import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';

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

class _NodeGraphViewState extends State<NodeGraphView> {
  final TransformationController _transformation = TransformationController();
  final Map<String, Offset> _positions = {};
  String _graphKey = '';

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _settlePositions();
    if (widget.graph.nodes.isEmpty) {
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
        final insetX = math.min(0.45, extent / (2 * width) + 0.01);
        final insetY = math.min(0.45, extent / (2 * height) + 0.01);
        final displayPositions = {
          for (final entry in _positions.entries)
            entry.key: Offset(
              insetX + entry.value.dx * (1 - 2 * insetX),
              insetY + entry.value.dy * (1 - 2 * insetY),
            ),
        };
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

  void _settlePositions() {
    final nodes = widget.graph.nodes;
    final keys = [for (final node in nodes) node.id];
    final edges = <String>{
      for (final edge in widget.graph.connections)
        if (edge.hasTargetNodeId())
          _edgeKey(edge.sourceNodeId, edge.targetNodeId),
    }.toList()..sort();
    final fingerprint = '${keys.join('|')}#${edges.join('|')}';
    if (fingerprint == _graphKey) return;
    _graphKey = fingerprint;
    final keySet = keys.toSet();
    _positions.removeWhere((key, _) => !keySet.contains(key));
    for (var index = 0; index < keys.length; index++) {
      final angle = index * math.pi * (3 - math.sqrt(5));
      final radius = 0.08 + 0.36 * math.sqrt((index + 1) / keys.length);
      _positions.putIfAbsent(
        keys[index],
        () => Offset(
          0.5 + math.cos(angle) * radius,
          0.5 + math.sin(angle) * radius,
        ),
      );
    }
    final linked = <String, (String, String)>{
      for (final edge in widget.graph.connections)
        if (edge.hasTargetNodeId() &&
            _positions.containsKey(edge.sourceNodeId) &&
            _positions.containsKey(edge.targetNodeId))
          _edgeKey(edge.sourceNodeId, edge.targetNodeId): (
            edge.sourceNodeId,
            edge.targetNodeId,
          ),
    }.values;
    for (var step = 0; step < 60; step++) {
      final forces = {for (final key in keys) key: Offset.zero};
      for (var i = 0; i < keys.length; i++) {
        for (var j = i + 1; j < keys.length; j++) {
          final delta = _positions[keys[i]]! - _positions[keys[j]]!;
          final distanceSquared = math.max(0.0004, delta.distanceSquared);
          final force =
              delta / math.sqrt(distanceSquared) * (0.00018 / distanceSquared);
          forces[keys[i]] = forces[keys[i]]! + force;
          forces[keys[j]] = forces[keys[j]]! - force;
        }
      }
      for (final (source, target) in linked) {
        final force = (_positions[target]! - _positions[source]!) * 0.018;
        forces[source] = forces[source]! + force;
        forces[target] = forces[target]! - force;
      }
      for (final key in keys) {
        final current = _positions[key]!;
        final movement =
            forces[key]! + (const Offset(0.5, 0.5) - current) * 0.012;
        final bounded = movement.distance > 0.025
            ? movement / movement.distance * 0.025
            : movement;
        _positions[key] = Offset(
          (current.dx + bounded.dx).clamp(0.06, 0.94),
          (current.dy + bounded.dy).clamp(0.06, 0.94),
        );
      }
    }
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
