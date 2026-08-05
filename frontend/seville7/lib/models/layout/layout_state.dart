part of 'layout.dart';

/// Ordered conditional values shared by Layout and its configuration models.
class LayoutState<T> {
  const LayoutState([this.values = const {}]);

  final Map<LayoutCondition, T> values;

  LayoutState<T> merge(LayoutState<T> overlay) =>
      LayoutState({...values, ...overlay.values});

  T resolve(
    LayoutContext context, {
    required T base,
    required T Function(T current, T overlay) merge,
    T Function(T value, LayoutContext context)? resolveValue,
  }) {
    var resolved = base;
    for (final entry in values.entries) {
      if (!entry.key.isActive(context)) continue;
      final value = resolveValue?.call(entry.value, context) ?? entry.value;
      resolved = merge(resolved, value);
    }
    return resolved;
  }
}
