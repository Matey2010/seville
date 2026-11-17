import 'dart:math' as math;
import 'dart:ui';

import 'package:forge2d/forge2d.dart';

/// A viewport-sized physics world shared by either graph presentation.
/// Connections are intentionally visual only until their behavior is defined.
class NodeGraphPhysics {
  NodeGraphPhysics({
    required this.viewport,
    required this.nodeDiameter,
    required Iterable<String> nodeIds,
    Map<String, Offset> initialPositions = const {},
  }) : nodeIds = nodeIds.toSet(),
       _world = World(gravity: Vector2.zero()) {
    _addWalls();
    final ids = this.nodeIds.toList()..sort();
    for (var index = 0; index < ids.length; index++) {
      final id = ids[index];
      final phase = (id.hashCode & 0xffff) / 0xffff * 2 * math.pi;
      final target = _targetFor(index, ids.length);
      final position = _inside(initialPositions[id] ?? target);
      final body = _world.createBody(
        BodyDef(
          type: BodyType.dynamic,
          position: _worldPoint(position),
          linearVelocity: Vector2(math.cos(phase), math.sin(phase)) * 0.05,
          linearDamping: 1.8,
          fixedRotation: true,
          enableSleep: false,
        ),
      );
      body.createShape(
        Circle(radius: nodeDiameter / (2 * _pixelsPerMeter)),
        ShapeDef(material: SurfaceMaterial(friction: 0, restitution: 0.35)),
      );
      _bodies[id] = body;
      _masses[id] = body.mass;
      _targets[id] = _worldPoint(target);
      _phases[id] = phase;
    }
  }

  static const _pixelsPerMeter = 40.0;
  static const _wallThickness = 0.5;
  static const _wallInset = 6.0;

  final Size viewport;
  final double nodeDiameter;
  final Set<String> nodeIds;
  final World _world;
  final Map<String, Body> _bodies = {};
  final Map<String, double> _masses = {};
  final Map<String, Vector2> _targets = {};
  final Map<String, double> _phases = {};

  Map<String, Offset> get positions => {
    for (final entry in _bodies.entries)
      entry.key: Offset(
        entry.value.position.x * _pixelsPerMeter / viewport.width,
        entry.value.position.y * _pixelsPerMeter / viewport.height,
      ),
  };

  void step(double seconds, double elapsedSeconds) {
    for (final entry in _bodies.entries) {
      final id = entry.key;
      final body = entry.value;
      final target = _targets[id]!;
      final position = body.position;
      final phase = _phases[id]!;
      body.applyForce(
        Vector2(
              (target.x - position.x) * 2 +
                  math.cos(elapsedSeconds * 0.7 + phase) * 1.1,
              (target.y - position.y) * 2 +
                  math.sin(elapsedSeconds * 0.9 + phase * 1.2) * 1.1,
            ) *
            _masses[id]!,
      );
    }
    _world.step(seconds);
  }

  void dispose() => _world.destroy();

  Offset _targetFor(int index, int count) {
    if (count == 1) return const Offset(0.5, 0.5);
    final angle = index * math.pi * (3 - math.sqrt(5));
    final spread = math.sqrt((index + 0.5) / count) * 0.92;
    final halfX = math.max(0, (viewport.width - nodeDiameter) / 2 - 14);
    final halfY = math.max(0, (viewport.height - nodeDiameter) / 2 - 14);
    return Offset(
      0.5 + math.cos(angle) * spread * halfX / viewport.width,
      0.5 + math.sin(angle) * spread * halfY / viewport.height,
    );
  }

  Offset _inside(Offset position) {
    final insetX = math.min(
      0.5,
      (nodeDiameter / 2 + _wallInset) / viewport.width,
    );
    final insetY = math.min(
      0.5,
      (nodeDiameter / 2 + _wallInset) / viewport.height,
    );
    return Offset(
      position.dx.clamp(insetX, 1 - insetX),
      position.dy.clamp(insetY, 1 - insetY),
    );
  }

  Vector2 _worldPoint(Offset position) => Vector2(
    position.dx * viewport.width / _pixelsPerMeter,
    position.dy * viewport.height / _pixelsPerMeter,
  );

  void _addWalls() {
    final width = viewport.width / _pixelsPerMeter;
    final height = viewport.height / _pixelsPerMeter;
    final inset = _wallInset / _pixelsPerMeter;
    final half = _wallThickness / 2;
    void wall(Vector2 center, double halfWidth, double halfHeight) {
      _world
          .createBody(BodyDef(position: center))
          .createShape(Polygon.box(halfWidth, halfHeight));
    }

    wall(Vector2(inset - half, height / 2), half, height / 2 + 1);
    wall(Vector2(width - inset + half, height / 2), half, height / 2 + 1);
    wall(Vector2(width / 2, inset - half), width / 2 + 1, half);
    wall(Vector2(width / 2, height - inset + half), width / 2 + 1, half);
  }
}
