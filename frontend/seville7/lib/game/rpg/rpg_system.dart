import 'package:flutter/foundation.dart';

import '../gameplay.dart';

/// Owns RPG actors and composes independent rules over shared actor state.
class RpgSystem extends GameplaySystem {
  RpgSystem({Iterable<RpgRule> rules = const []})
    : super(systemId: 'rpg', updateOrder: 0) {
    for (final rule in rules) {
      registerRule(rule);
    }
  }

  final Map<String, RpgActor> _actors = {};
  final Map<String, RpgRule> _rules = {};

  Iterable<RpgActor> get actors => _actors.values;
  Iterable<RpgRule> get rules => _rules.values;

  RpgActor? actor(String actorId) => _actors[actorId];

  void addActor(RpgActor actor) {
    if (_actors.containsKey(actor.actorId)) {
      throw StateError('RPG actor "${actor.actorId}" already exists.');
    }
    _actors[actor.actorId] = actor;
    for (final rule in _orderedRules) {
      rule.onActorAdded(actor, this);
    }
  }

  RpgActor? removeActor(String actorId) {
    final actor = _actors.remove(actorId);
    if (actor == null) return null;
    for (final rule in _orderedRules) {
      rule.onActorRemoved(actor, this);
    }
    return actor;
  }

  void registerRule(RpgRule rule) {
    final existing = _rules[rule.id];
    if (existing != null && !identical(existing, rule)) {
      throw StateError('RPG rule "${rule.id}" is registered.');
    }
    _rules[rule.id] = rule;
    for (final actor in _actors.values) {
      rule.onActorAdded(actor, this);
    }
  }

  void unregisterRule(String ruleId) => _rules.remove(ruleId);

  List<RpgRule> get _orderedRules =>
      _rules.values.toList()
        ..sort((left, right) => left.order.compareTo(right.order));

  @override
  void onGameplayEvent(GameplayEvent event) {
    for (final rule in _orderedRules) {
      rule.onEvent(event, this);
    }
  }

  @override
  void update(double dt) {
    for (final rule in _orderedRules) {
      rule.update(dt, this);
    }
  }
}

/// Mutable simulation state for one RPG actor with open-ended stats and tags.
class RpgActor {
  RpgActor({
    required this.actorId,
    Map<RpgStatKey, RpgStat>? stats,
    Set<String>? tags,
  }) : stats = stats ?? {},
       tags = tags ?? {} {
    if (actorId.trim().isEmpty) {
      throw ArgumentError.value(actorId, 'actorId', 'must not be empty');
    }
  }

  final String actorId;
  final Map<RpgStatKey, RpgStat> stats;
  final Set<String> tags;

  double statValue(RpgStatKey key, {double fallback = 0}) =>
      stats[key]?.value ?? fallback;
}

/// One extensible numeric RPG value with source-addressable modifiers.
class RpgStat {
  RpgStat({required this.baseValue, Map<String, double>? modifiers})
    : modifiers = modifiers ?? {};

  double baseValue;
  final Map<String, double> modifiers;

  double get value =>
      baseValue + modifiers.values.fold(0, (total, value) => total + value);
}

@immutable
class RpgStatKey {
  const RpgStatKey(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is RpgStatKey && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Extension point for combat, needs, skills, crafting, progression, and AI.
abstract class RpgRule {
  String get id;

  int get order => 0;

  void onActorAdded(RpgActor actor, RpgSystem system) {}

  void onActorRemoved(RpgActor actor, RpgSystem system) {}

  void onEvent(GameplayEvent event, RpgSystem system) {}

  void update(double dt, RpgSystem system) {}
}
