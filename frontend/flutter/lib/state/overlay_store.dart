import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

class ToastEvent {
  const ToastEvent({
    required this.id,
    required this.message,
    required this.type,
  });

  final int id;
  final String message;
  final NotificationType type;
}

final toastProvider = NotifierProvider<ToastNotifier, List<ToastEvent>>(
  ToastNotifier.new,
);

class ToastNotifier extends Notifier<List<ToastEvent>> {
  var _nextId = 0;

  @override
  List<ToastEvent> build() => const [];

  void show(
    String message, {
    NotificationType type = NotificationType.NOTIFICATION_TYPE_INFO,
  }) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;
    state = [
      ...state,
      ToastEvent(id: _nextId++, message: normalizedMessage, type: type),
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

class InterfaceOverlayState {
  const InterfaceOverlayState({this.searchValue = ''});

  final String searchValue;

  InterfaceOverlayState copyWith({String? searchValue}) =>
      InterfaceOverlayState(searchValue: searchValue ?? this.searchValue);
}

final interfaceOverlayStateProvider =
    NotifierProvider<InterfaceOverlayNotifier, InterfaceOverlayState>(
      InterfaceOverlayNotifier.new,
    );

class InterfaceOverlayNotifier extends Notifier<InterfaceOverlayState> {
  @override
  InterfaceOverlayState build() => const InterfaceOverlayState();

  void submitSearch(String value) {
    final normalizedValue = value.trim();
    state = state.copyWith(searchValue: normalizedValue);
  }

  void cancel() {
    state = const InterfaceOverlayState();
  }
}
