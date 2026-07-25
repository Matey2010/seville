import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlay_layers/overlay_layers.dart';
import 'package:seville_proto/seville_proto.dart';

import '../constants/typography.dart';
import '../state/overlay_store.dart';

class ToastOverlayPresenter {
  static const _visibleDuration = Duration(seconds: 3);

  final Map<int, Timer> _dismissTimers = {};
  List<ToastEvent> _pendingToasts = const [];
  bool _syncScheduled = false;
  bool _disposed = false;
  String? _overlayId;

  void sync(
    BuildContext context,
    List<ToastEvent> toasts, {
    required void Function(int id) dismiss,
  }) {
    if (_disposed) return;
    _pendingToasts = toasts;
    for (final toast in toasts) {
      _dismissTimers.putIfAbsent(
        toast.id,
        () => Timer(_visibleDuration, () => dismiss(toast.id)),
      );
    }
    final activeIds = toasts.map((toast) => toast.id).toSet();
    for (final id in _dismissTimers.keys.toList()) {
      if (activeIds.contains(id)) continue;
      _dismissTimers.remove(id)?.cancel();
    }
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!_disposed && context.mounted) {
        _syncOverlay(context, _pendingToasts);
      }
    });
  }

  void dispose() {
    _disposed = true;
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    _dismissTimers.clear();
    final overlayId = _overlayId;
    if (overlayId != null) {
      OverlayManager.instance.removeOverlay(overlayId);
      _overlayId = null;
    }
  }

  void _syncOverlay(BuildContext context, List<ToastEvent> toasts) {
    final overlayId = _overlayId;
    if (toasts.isEmpty) {
      if (overlayId != null) {
        OverlayManager.instance.removeOverlay(overlayId);
        _overlayId = null;
      }
      return;
    }

    final data = List<ToastEvent>.unmodifiable(toasts);
    if (overlayId == null) {
      _overlayId = OverlayManager.instance.createOverlay<List<ToastEvent>>(
        context: context,
        type: OverlayType.toast,
        builder: (_) => const ToastWidgets(),
        options: OverlayCreateOptions(initialData: data),
      );
      return;
    }
    OverlayManager.instance.updateOverlayData<List<ToastEvent>>(
      overlayId,
      data,
    );
  }
}

class ToastWidgets extends StatelessWidget {
  const ToastWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    final toasts = OverlayDataContext.of<List<ToastEvent>>(context).data;
    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.topRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final toast in toasts)
                  Padding(
                    key: ValueKey(toast.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedOverlay(
                      duration: const Duration(milliseconds: 180),
                      slideFrom: const Offset(-0.08, 0),
                      scale: false,
                      child: ToastWidget(
                        type: toast.type,
                        child: Text(toast.message),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToastWidget extends StatelessWidget {
  const ToastWidget({required this.type, required this.child, super.key});

  final NotificationType type;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color: _backgroundColor,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: SevilleTypography.fontFamily,
          color: _foregroundColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    ),
  );

  Color get _backgroundColor => switch (type.value) {
    0 => const Color(0xFF1976D2),
    1 => const Color(0xFFD32F2F),
    2 => const Color(0xFFF9A825),
    3 => const Color(0xFF388E3C),
    _ => const Color(0xFF1976D2),
  };

  Color get _foregroundColor =>
      type.value == NotificationType.NOTIFICATION_TYPE_WARNING.value
      ? const Color(0xFF1A1A1A)
      : const Color(0xFFFFFFFF);
}
