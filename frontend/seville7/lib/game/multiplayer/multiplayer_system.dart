import 'dart:async';

import 'package:flutter/foundation.dart';

import '../gameplay.dart';

/// Tracks one client session and admits only server-authored world messages.
class MultiplayerSystem extends GameplaySystem {
  MultiplayerSystem({required this.transport})
    : state = ValueNotifier(const MultiplayerSessionState()),
      super(systemId: 'multiplayer', updateOrder: 100);

  final MultiplayerTransport transport;
  final ValueNotifier<MultiplayerSessionState> state;
  StreamSubscription<ServerGameMessage>? _subscription;
  MultiplayerEndpoint? _endpoint;
  int _nextCommandId = 1;

  MultiplayerEndpoint? get endpoint => _endpoint;

  Future<void> connect(MultiplayerEndpoint endpoint) async {
    await disconnect();
    _endpoint = endpoint;
    state.value = state.value.copyWith(
      status: MultiplayerConnectionStatus.connecting,
      playerIds: const {},
      serverTick: 0,
    );
    _subscription = transport.messages.listen(
      _receive,
      onError: (Object error, StackTrace stackTrace) {
        state.value = state.value.copyWith(
          status: MultiplayerConnectionStatus.failed,
          error: error,
        );
      },
      onDone: () {
        if (state.value.status != MultiplayerConnectionStatus.disconnected) {
          state.value = state.value.copyWith(
            status: MultiplayerConnectionStatus.disconnected,
          );
        }
      },
    );
    try {
      await transport.connect(endpoint);
      state.value = state.value.copyWith(
        status: MultiplayerConnectionStatus.connected,
        clearError: true,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        status: MultiplayerConnectionStatus.failed,
        error: error,
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await transport.disconnect();
    await _subscription?.cancel();
    _subscription = null;
    _endpoint = null;
    state.value = const MultiplayerSessionState();
  }

  Future<void> sendCommand(
    String type, {
    Map<String, Object?> payload = const {},
  }) async {
    final endpoint = _endpoint;
    if (endpoint == null ||
        state.value.status != MultiplayerConnectionStatus.connected) {
      throw StateError('The multiplayer session is not connected.');
    }
    final command = ClientGameCommand(
      id: '${endpoint.playerId}:${_nextCommandId++}',
      playerId: endpoint.playerId,
      worldId: endpoint.worldId,
      type: type,
      payload: payload,
    );
    await transport.send(command);
  }

  void _receive(ServerGameMessage message) {
    final endpoint = _endpoint;
    if (endpoint == null || message.worldId != endpoint.worldId) return;
    if (message is WorldSnapshotMessage) {
      if (message.serverTick < state.value.serverTick) return;
      state.value = state.value.copyWith(
        serverTick: message.serverTick,
        worldState: message.worldState,
      );
    } else if (message is WorldDeltaMessage) {
      if (message.serverTick <= state.value.serverTick) return;
      state.value = state.value.copyWith(serverTick: message.serverTick);
    } else if (message is PlayerPresenceMessage) {
      state.value = state.value.copyWith(playerIds: message.playerIds);
    }
    kernel.publish(MultiplayerMessageReceived(message));
  }

  @override
  void onRemove() {
    unawaited(disconnect().whenComplete(state.dispose));
    super.onRemove();
  }
}

@immutable
class MultiplayerSessionState {
  const MultiplayerSessionState({
    this.status = MultiplayerConnectionStatus.disconnected,
    this.serverTick = 0,
    this.playerIds = const {},
    this.worldState = const {},
    this.error,
  });

  final MultiplayerConnectionStatus status;
  final int serverTick;
  final Set<String> playerIds;
  final Map<String, Object?> worldState;
  final Object? error;

  MultiplayerSessionState copyWith({
    MultiplayerConnectionStatus? status,
    int? serverTick,
    Set<String>? playerIds,
    Map<String, Object?>? worldState,
    Object? error,
    bool clearError = false,
  }) => MultiplayerSessionState(
    status: status ?? this.status,
    serverTick: serverTick ?? this.serverTick,
    playerIds: Set.unmodifiable(playerIds ?? this.playerIds),
    worldState: Map.unmodifiable(worldState ?? this.worldState),
    error: clearError ? null : error ?? this.error,
  );
}

enum MultiplayerConnectionStatus { disconnected, connecting, connected, failed }

@immutable
class MultiplayerEndpoint {
  const MultiplayerEndpoint({required this.worldId, required this.playerId});

  final String worldId;
  final String playerId;
}

@immutable
class ClientGameCommand {
  ClientGameCommand({
    required this.id,
    required this.playerId,
    required this.worldId,
    required this.type,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  final String id;
  final String playerId;
  final String worldId;
  final String type;
  final Map<String, Object?> payload;
}

sealed class ServerGameMessage {
  const ServerGameMessage({required this.worldId, required this.serverTick});

  final String worldId;
  final int serverTick;
}

final class WorldSnapshotMessage extends ServerGameMessage {
  WorldSnapshotMessage({
    required super.worldId,
    required super.serverTick,
    Map<String, Object?> worldState = const {},
  }) : worldState = Map.unmodifiable(worldState);

  final Map<String, Object?> worldState;
}

final class WorldDeltaMessage extends ServerGameMessage {
  WorldDeltaMessage({
    required super.worldId,
    required super.serverTick,
    required this.commandId,
    required this.actorId,
    required this.type,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  final String commandId;
  final String actorId;
  final String type;
  final Map<String, Object?> payload;
}

final class PlayerPresenceMessage extends ServerGameMessage {
  PlayerPresenceMessage({
    required super.worldId,
    required super.serverTick,
    required Set<String> playerIds,
  }) : playerIds = Set.unmodifiable(playerIds);

  final Set<String> playerIds;
}

final class MultiplayerMessageReceived implements GameplayEvent {
  const MultiplayerMessageReceived(this.message);

  final ServerGameMessage message;
}

abstract interface class MultiplayerTransport {
  Stream<ServerGameMessage> get messages;

  Future<void> connect(MultiplayerEndpoint endpoint);

  Future<void> send(ClientGameCommand command);

  Future<void> disconnect();
}

/// A deterministic local authority usable by multiple in-process clients.
class InMemoryMultiplayerServer {
  InMemoryMultiplayerServer({InMemoryWorldReducer? reducer})
    : _reducer = reducer ?? _defaultReducer;

  final InMemoryWorldReducer _reducer;
  final Map<String, _InMemoryWorld> _worlds = {};

  void connect(
    MultiplayerEndpoint endpoint,
    StreamController<ServerGameMessage> client,
  ) {
    final world = _worlds.putIfAbsent(endpoint.worldId, _InMemoryWorld.new);
    if (world.clients.containsKey(endpoint.playerId)) {
      throw StateError(
        'Player "${endpoint.playerId}" is already in "${endpoint.worldId}".',
      );
    }
    world.clients[endpoint.playerId] = client;
    client.add(
      WorldSnapshotMessage(
        worldId: endpoint.worldId,
        serverTick: world.serverTick,
        worldState: world.state,
      ),
    );
    _broadcastPresence(endpoint.worldId, world);
  }

  void accept(ClientGameCommand command) {
    final world = _worlds[command.worldId];
    if (world == null || !world.clients.containsKey(command.playerId)) {
      throw StateError('The command sender is not connected to the world.');
    }
    world.serverTick += 1;
    final nextState = _reducer(Map.unmodifiable(world.state), command);
    world.state
      ..clear()
      ..addAll(nextState);
    final delta = WorldDeltaMessage(
      worldId: command.worldId,
      serverTick: world.serverTick,
      commandId: command.id,
      actorId: command.playerId,
      type: command.type,
      payload: command.payload,
    );
    for (final client in world.clients.values) {
      client.add(delta);
    }
  }

  void disconnect(MultiplayerEndpoint endpoint) {
    final world = _worlds[endpoint.worldId];
    if (world == null) return;
    world.clients.remove(endpoint.playerId);
    if (world.clients.isEmpty) {
      _worlds.remove(endpoint.worldId);
      return;
    }
    _broadcastPresence(endpoint.worldId, world);
  }

  void _broadcastPresence(String worldId, _InMemoryWorld world) {
    final message = PlayerPresenceMessage(
      worldId: worldId,
      serverTick: world.serverTick,
      playerIds: world.clients.keys.toSet(),
    );
    for (final client in world.clients.values) {
      client.add(message);
    }
  }

  static Map<String, Object?> _defaultReducer(
    Map<String, Object?> state,
    ClientGameCommand command,
  ) => {
    ...state,
    command.type: <String, Object?>{
      'actorId': command.playerId,
      'commandId': command.id,
      ...command.payload,
    },
  };
}

typedef InMemoryWorldReducer =
    Map<String, Object?> Function(
      Map<String, Object?> currentState,
      ClientGameCommand command,
    );

/// Client transport for the local authority; a socket adapter can replace it.
class InMemoryMultiplayerTransport implements MultiplayerTransport {
  InMemoryMultiplayerTransport(this.server);

  final InMemoryMultiplayerServer server;
  final StreamController<ServerGameMessage> _messages =
      StreamController.broadcast();
  MultiplayerEndpoint? _endpoint;

  @override
  Stream<ServerGameMessage> get messages => _messages.stream;

  @override
  Future<void> connect(MultiplayerEndpoint endpoint) async {
    if (_endpoint != null) {
      throw StateError('The multiplayer transport is already connected.');
    }
    server.connect(endpoint, _messages);
    _endpoint = endpoint;
  }

  @override
  Future<void> send(ClientGameCommand command) async {
    final endpoint = _endpoint;
    if (endpoint == null ||
        endpoint.playerId != command.playerId ||
        endpoint.worldId != command.worldId) {
      throw StateError('The command does not belong to this connection.');
    }
    server.accept(command);
  }

  @override
  Future<void> disconnect() async {
    final endpoint = _endpoint;
    if (endpoint == null) return;
    server.disconnect(endpoint);
    _endpoint = null;
  }
}

class _InMemoryWorld {
  int serverTick = 0;
  final Map<String, Object?> state = {};
  final Map<String, StreamController<ServerGameMessage>> clients = {};
}
