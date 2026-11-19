import 'dart:math' as math;
import 'dart:ui';

import 'package:forge2d/forge2d.dart';

import 'graph_world_layout.dart';

/// Forge2D animates Nodes around semantic anchors in a virtual world.
/// Calendar and LINK_TO connections are visual, never physical constraints.
class NodeGraphPhysics {
  NodeGraphPhysics({
    required this.worldSize,
    required Map<String, Offset> anchors,
    required Map<String, GraphPlane> planes,
    required Map<String, double> nodeDiameters,
    required Map<String, double> gravityScales,
    Map<String, Offset> initialPositions = const {},
  }) : anchors = Map.unmodifiable(anchors),
       planes = Map.unmodifiable(planes),
       nodeDiameters = Map.unmodifiable(nodeDiameters),
       gravityScales = Map.unmodifiable(gravityScales),
       _world = World(gravity: Vector2.zero()) {
    final slugs = nodeDiameters.keys.toList()..sort();
    for (final slug in slugs) {
      final diameter = nodeDiameters[slug]!;
      final anchor = anchors[slug]!;
      final position = initialPositions[slug] ?? anchor;
      final phase = _stablePhase(slug);
      final body = _world.createBody(
        BodyDef(
          type: BodyType.dynamic,
          position: _worldPoint(position),
          linearVelocity: Vector2(math.cos(phase), math.sin(phase)) * 0.02,
          linearDamping: 2.2,
          fixedRotation: true,
          enableSleep: false,
        ),
      );
      body.createShape(
        Circle(radius: diameter / (2 * _pixelsPerMeter)),
        ShapeDef(material: SurfaceMaterial(friction: 0, restitution: 0.2)),
      );
      _bodies[slug] = body;
      _masses[slug] = body.mass;
      _targets[slug] = _worldPoint(anchor);
      _phases[slug] = phase;
    }
  }

  static const _pixelsPerMeter = 40.0;

  final Size worldSize;
  final Map<String, Offset> anchors;
  final Map<String, GraphPlane> planes;
  final Map<String, double> nodeDiameters;
  final Map<String, double> gravityScales;
  final World _world;
  final Map<String, Body> _bodies = {};
  final Map<String, double> _masses = {};
  final Map<String, Vector2> _targets = {};
  final Map<String, double> _phases = {};

  Map<String, Offset> get positions => {
    for (final entry in _bodies.entries)
      entry.key: Offset(
        entry.value.position.x * _pixelsPerMeter,
        entry.value.position.y * _pixelsPerMeter,
      ),
  };

  void step(double seconds, double elapsedSeconds) {
    for (final entry in _bodies.entries) {
      final slug = entry.key;
      final body = entry.value;
      final target = _targets[slug]!;
      final position = body.position;
      final phase = _phases[slug]!;
      final isTime = planes[slug] == GraphPlane.time;
      final strength = isTime ? 4.0 : 2.0;
      final motion = isTime ? 0.16 : 1.0;
      body.applyForce(
        Vector2(
              (target.x - position.x) * strength * (gravityScales[slug] ?? 1) +
                  math.cos(elapsedSeconds * 0.7 + phase) * motion,
              (target.y - position.y) * strength * (gravityScales[slug] ?? 1) +
                  math.sin(elapsedSeconds * 0.9 + phase * 1.2) * motion,
            ) *
            _masses[slug]!,
      );
    }
    _world.step(seconds);
  }

  void dispose() => _world.destroy();

  Vector2 _worldPoint(Offset position) =>
      Vector2(position.dx / _pixelsPerMeter, position.dy / _pixelsPerMeter);
}

double _stablePhase(String slug) {
  var hash = 2166136261;
  for (final codeUnit in slug.codeUnits) {
    hash = ((hash ^ codeUnit) * 16777619) & 0xffffffff;
  }
  return hash / 0xffffffff * 2 * math.pi;
}
