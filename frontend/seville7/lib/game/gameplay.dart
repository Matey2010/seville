import 'package:flame/components.dart';

/// Owns independently extensible gameplay systems and their event boundary.
class GameplayKernel extends Component {
  GameplayKernel({Iterable<GameplaySystem> systems = const []}) {
    for (final system in systems) {
      registerSystem(system);
    }
  }

  final Map<String, GameplaySystem> _systems = {};
  final List<GameplayEvent> _pendingEvents = [];

  Iterable<GameplaySystem> get systems => _systems.values;

  T? system<T extends GameplaySystem>() {
    for (final system in _systems.values) {
      if (system is T) return system;
    }
    return null;
  }

  void registerSystem(GameplaySystem system) {
    final existing = _systems[system.systemId];
    if (existing != null && !identical(existing, system)) {
      throw StateError('Gameplay system "${system.systemId}" is registered.');
    }
    if (existing != null) return;
    _systems[system.systemId] = system;
    add(system);
  }

  GameplaySystem? unregisterSystem(String systemId) {
    final system = _systems.remove(systemId);
    system?.removeFromParent();
    return system;
  }

  void publish(GameplayEvent event) => _pendingEvents.add(event);

  @override
  void update(double dt) {
    if (_pendingEvents.isNotEmpty) {
      final events = List<GameplayEvent>.of(_pendingEvents);
      _pendingEvents.clear();
      final orderedSystems = _systems.values.toList()
        ..sort((left, right) => left.priority.compareTo(right.priority));
      for (final event in events) {
        for (final system in orderedSystems) {
          system.onGameplayEvent(event);
        }
      }
    }
    super.update(dt);
  }
}

/// One replaceable simulation concern, such as collisions, RPG rules, or sync.
abstract class GameplaySystem extends Component {
  GameplaySystem({required this.systemId, int updateOrder = 0}) {
    priority = updateOrder;
  }

  final String systemId;

  GameplayKernel get kernel => parent! as GameplayKernel;

  void onGameplayEvent(GameplayEvent event) {}
}

/// Marker protocol for messages exchanged between gameplay systems.
abstract interface class GameplayEvent {}
