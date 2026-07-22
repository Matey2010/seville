import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_layers/overlay_layers.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/hud_store.dart';

class HudToastLayer extends ConsumerStatefulWidget {
  const HudToastLayer({super.key});

  @override
  ConsumerState<HudToastLayer> createState() => _HudToastLayerState();
}

class _HudToastLayerState extends ConsumerState<HudToastLayer> {
  static const _visibleDuration = Duration(seconds: 3);

  final Map<int, Timer> _dismissTimers = {};
  late final ProviderSubscription<List<HudToastEvent>> _toastSubscription;
  List<HudToastEvent> _pendingToasts = const [];
  bool _syncScheduled = false;
  String? _overlayId;

  @override
  void initState() {
    super.initState();
    _toastSubscription = ref.listenManual(
      hudToastProvider,
      (_, toasts) => _scheduleSync(toasts),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _toastSubscription.close();
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    final overlayId = _overlayId;
    if (overlayId != null) {
      OverlayManager.instance.removeOverlay(overlayId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  void _scheduleSync(List<HudToastEvent> toasts) {
    _pendingToasts = toasts;
    for (final toast in toasts) {
      _dismissTimers.putIfAbsent(
        toast.id,
        () => Timer(
          _visibleDuration,
          () => ref.read(hudToastProvider.notifier).dismiss(toast.id),
        ),
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
      if (mounted) _syncOverlay(_pendingToasts);
    });
  }

  void _syncOverlay(List<HudToastEvent> toasts) {
    final overlayId = _overlayId;
    if (toasts.isEmpty) {
      if (overlayId != null) {
        OverlayManager.instance.removeOverlay(overlayId);
        _overlayId = null;
      }
      return;
    }

    final data = List<HudToastEvent>.unmodifiable(toasts);
    if (overlayId == null) {
      _overlayId = OverlayManager.instance.createOverlay<List<HudToastEvent>>(
        context: context,
        type: OverlayType.toast,
        builder: (_) => const _HudToastStack(),
        options: OverlayCreateOptions(initialData: data),
      );
      return;
    }
    OverlayManager.instance.updateOverlayData<List<HudToastEvent>>(
      overlayId,
      data,
    );
  }
}

class _HudToastStack extends StatelessWidget {
  const _HudToastStack();

  @override
  Widget build(BuildContext context) {
    final toasts = OverlayDataContext.of<List<HudToastEvent>>(context).data;
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
                      child: HudNotification(
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

class HudNotification extends StatelessWidget {
  const HudNotification({required this.type, required this.child, super.key});

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
