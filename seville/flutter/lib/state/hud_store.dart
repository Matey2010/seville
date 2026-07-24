import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

class HudToastEvent {
  const HudToastEvent({
    required this.id,
    required this.message,
    required this.type,
  });

  final int id;
  final String message;
  final NotificationType type;
}

final hudToastProvider =
    NotifierProvider<HudToastNotifier, List<HudToastEvent>>(
      HudToastNotifier.new,
    );

class HudToastNotifier extends Notifier<List<HudToastEvent>> {
  var _nextId = 0;

  @override
  List<HudToastEvent> build() => const [];

  void show(
    String message, {
    NotificationType type = NotificationType.NOTIFICATION_TYPE_INFO,
  }) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;
    state = [
      ...state,
      HudToastEvent(id: _nextId++, message: normalizedMessage, type: type),
    ];
  }

  void dismiss(int id) {
    state = [
      for (final toast in state)
        if (toast.id != id) toast,
    ];
  }

  void showCopiedText(String text) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;
    show(
      'Copied: $normalizedText',
      type: NotificationType.NOTIFICATION_TYPE_SUCCESS,
    );
  }
}

class HudState {
  const HudState({this.searchEnabled = false, this.searchValue = ''});

  final bool searchEnabled;
  final String searchValue;

  bool get isSearchEnabled => searchEnabled;

  HudState copyWith({bool? searchEnabled, String? searchValue}) => HudState(
    searchEnabled: searchEnabled ?? this.searchEnabled,
    searchValue: searchValue ?? this.searchValue,
  );
}

final hudStateProvider = NotifierProvider<HudNotifier, HudState>(
  HudNotifier.new,
);

class HudNotifier extends Notifier<HudState> {
  @override
  HudState build() => const HudState();

  void showSearch() {
    state = state.copyWith(searchEnabled: true);
  }

  void hideSearch() {
    state = state.copyWith(searchEnabled: false);
  }

  void submitSearch(String value) {
    state = state.copyWith(searchEnabled: false, searchValue: value.trim());
  }

  void cancel() {
    state = const HudState();
  }
}
