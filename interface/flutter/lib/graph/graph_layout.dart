import 'dart:math';

import 'package:flutter/material.dart';

import '../models/knowledge_graph.dart';

/// Small deterministic force layout intended for the first useful prototype.
///
/// The quadratic simulation is capped; large vaults keep deterministic seeded
/// positions until a spatial-indexed layout is introduced.
Map<String, Offset> layoutGraph(KnowledgeGraph graph) {
  if (graph.nodes.isEmpty) return const {};

  final positions = <String, Offset>{
    for (final node in graph.nodes) node.id: _seededPosition(node.id),
  };
  if (graph.nodes.length > 250) return positions;

  final velocity = {for (final node in graph.nodes) node.id: Offset.zero};

  for (var iteration = 0; iteration < 140; iteration++) {
    final forces = {for (final node in graph.nodes) node.id: Offset.zero};

    for (var i = 0; i < graph.nodes.length; i++) {
      for (var j = i + 1; j < graph.nodes.length; j++) {
        final a = graph.nodes[i].id;
        final b = graph.nodes[j].id;
        var delta = positions[a]! - positions[b]!;
        var distanceSquared = delta.dx * delta.dx + delta.dy * delta.dy;
        if (distanceSquared < 0.0001) {
          delta = const Offset(0.01, 0.01);
          distanceSquared = 0.0002;
        }
        final push = 0.000035 / distanceSquared;
        final direction = delta / sqrt(distanceSquared);
        forces[a] = forces[a]! + direction * push;
        forces[b] = forces[b]! - direction * push;
      }
    }

    for (final edge in graph.edges) {
      final delta = positions[edge.targetId]! - positions[edge.sourceId]!;
      final distance = max(0.001, delta.distance);
      final pull = (distance - 0.18) * 0.012 * edge.weight;
      final force = delta / distance * pull;
      forces[edge.sourceId] = forces[edge.sourceId]! + force;
      forces[edge.targetId] = forces[edge.targetId]! - force;
    }

    final cooling = 1 - iteration / 170;
    for (final node in graph.nodes) {
      final id = node.id;
      final centerPull = (const Offset(0.5, 0.5) - positions[id]!) * 0.002;
      final nextVelocity =
          (velocity[id]! * 0.72 + forces[id]! + centerPull) * cooling;
      velocity[id] = nextVelocity;
      final next = positions[id]! + nextVelocity;
      positions[id] = Offset(
        next.dx.clamp(0.04, 0.96),
        // Keep the lower wall area visually separate from the graph cloud.
        next.dy.clamp(0.04, 0.82),
      );
    }
  }
  return positions;
}

Offset _seededPosition(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0x7FFFFFFF;
  }
  final random = Random(hash);
  return Offset(
    0.04 + random.nextDouble() * 0.92,
    0.04 + random.nextDouble() * 0.78,
  );
}
