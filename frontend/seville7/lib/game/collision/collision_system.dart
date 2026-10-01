import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';

import '../gameplay.dart';

/// Counts distinct collision contacts while retaining the active contact set.
class CollisionSystem extends GameplaySystem {
  CollisionSystem({this.onCollisionStarted})
    : snapshot = ValueNotifier(const CollisionSnapshot()),
      super(systemId: 'collision', updateOrder: -100);

  final ValueChanged<CollisionStarted>? onCollisionStarted;
  final ValueNotifier<CollisionSnapshot> snapshot;
  final Map<CollisionPair, int> _contactCounts = {};

  int get total => snapshot.value.total;

  @override
  void onGameplayEvent(GameplayEvent event) {
    switch (event) {
      case _CollisionContactStarted():
        final contactCount = _contactCounts[event.pair] ?? 0;
        _contactCounts[event.pair] = contactCount + 1;
        if (contactCount == 0) {
          final collision = CollisionStarted(
            event.pair.firstActorId,
            event.pair.secondActorId,
          );
          snapshot.value = CollisionSnapshot(
            total: snapshot.value.total + 1,
            active: Set.unmodifiable(_contactCounts.keys),
          );
          onCollisionStarted?.call(collision);
          kernel.publish(collision);
        }
      case _CollisionContactEnded():
        final contactCount = _contactCounts[event.pair];
        if (contactCount == null) return;
        if (contactCount > 1) {
          _contactCounts[event.pair] = contactCount - 1;
          return;
        }
        _contactCounts.remove(event.pair);
        snapshot.value = CollisionSnapshot(
          total: snapshot.value.total,
          active: Set.unmodifiable(_contactCounts.keys),
        );
        kernel.publish(
          CollisionEnded(event.pair.firstActorId, event.pair.secondActorId),
        );
      default:
        break;
    }
  }

  void reset() {
    _contactCounts.clear();
    snapshot.value = const CollisionSnapshot();
  }

  @override
  void onRemove() {
    snapshot.dispose();
    super.onRemove();
  }
}

@immutable
class CollisionSnapshot {
  const CollisionSnapshot({this.total = 0, this.active = const {}});

  final int total;
  final Set<CollisionPair> active;
}

@immutable
class CollisionPair {
  CollisionPair(String firstActorId, String secondActorId)
    : firstActorId = firstActorId.compareTo(secondActorId) <= 0
          ? firstActorId
          : secondActorId,
      secondActorId = firstActorId.compareTo(secondActorId) <= 0
          ? secondActorId
          : firstActorId {
    if (firstActorId.trim().isEmpty || secondActorId.trim().isEmpty) {
      throw ArgumentError('Collision actor IDs must not be empty.');
    }
    if (firstActorId == secondActorId) {
      throw ArgumentError('A collision pair requires two different actors.');
    }
  }

  final String firstActorId;
  final String secondActorId;

  @override
  bool operator ==(Object other) =>
      other is CollisionPair &&
      firstActorId == other.firstActorId &&
      secondActorId == other.secondActorId;

  @override
  int get hashCode => Object.hash(firstActorId, secondActorId);
}

sealed class CollisionEvent implements GameplayEvent {
  CollisionEvent(String firstActorId, String secondActorId)
    : pair = CollisionPair(firstActorId, secondActorId);

  final CollisionPair pair;
}

final class CollisionStarted extends CollisionEvent {
  CollisionStarted(super.firstActorId, super.secondActorId);
}

final class CollisionEnded extends CollisionEvent {
  CollisionEnded(super.firstActorId, super.secondActorId);
}

final class _CollisionContactStarted extends CollisionEvent {
  _CollisionContactStarted(super.firstActorId, super.secondActorId);
}

final class _CollisionContactEnded extends CollisionEvent {
  _CollisionContactEnded(super.firstActorId, super.secondActorId);
}

/// Base for collidable actors; subclasses add the appropriate Flame hitboxes.
abstract class CollisionBodyComponent extends PositionComponent
    with CollisionCallbacks {
  CollisionBodyComponent({
    required this.actorId,
    required this.gameplay,
    super.position,
    super.size,
    super.anchor,
    super.priority,
  }) {
    if (actorId.trim().isEmpty) {
      throw ArgumentError.value(actorId, 'actorId', 'must not be empty');
    }
  }

  final String actorId;
  final GameplayKernel gameplay;

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    final otherBody = other.findParent<CollisionBodyComponent>(
      includeSelf: true,
    );
    if (otherBody == null || otherBody.actorId == actorId) return;
    gameplay.publish(_CollisionContactStarted(actorId, otherBody.actorId));
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    final otherBody = other.findParent<CollisionBodyComponent>(
      includeSelf: true,
    );
    if (otherBody == null || otherBody.actorId == actorId) return;
    gameplay.publish(_CollisionContactEnded(actorId, otherBody.actorId));
  }
}
