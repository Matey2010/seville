import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/layout/layout.dart';

class LayoutDerivativeChange {
  const LayoutDerivativeChange({
    required this.observable,
    required this.derivative,
    required this.previous,
    required this.current,
  });

  final String observable;
  final String derivative;
  final Offset previous;
  final Offset current;
}

class LayoutDerivativeObserver extends ChangeNotifier {
  LayoutDerivativeObserver(this.layout);

  final Layout layout;

  Map<String, Offset> _previous = const {};
  List<LayoutDerivativeChange> _changes = const [];

  List<LayoutDerivativeChange> get changes => _changes;

  void evaluate(Size size, [String? snapshot]) {
    final current = layout.resolveDerivatives(size, snapshot);
    if (_previous.isEmpty) {
      _previous = current;
      return;
    }

    final changes = <LayoutDerivativeChange>[];
    for (final observableEntry in layout.observables.entries) {
      final observable = observableEntry.value;
      for (final derivative in observable.derivatives) {
        final previous = _previous[derivative];
        final next = current[derivative];
        if (previous == null || next == null) continue;
        if ((next - previous).distance <= observable.epsilon) continue;
        changes.add(
          LayoutDerivativeChange(
            observable: observableEntry.key,
            derivative: derivative,
            previous: previous,
            current: next,
          ),
        );
      }
    }

    _previous = current;
    _changes = List.unmodifiable(changes);
    if (changes.isNotEmpty) notifyListeners();
  }
}
