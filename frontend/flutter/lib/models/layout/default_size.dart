part of 'layout.dart';

abstract final class LayoutDefaultSize {
  /// Applies [override] to [defaults] without discarding an inherited
  /// secondary dimension when the override configures only the primary size.
  static LayoutSize mergeWith(LayoutSize defaults, LayoutSize? override) {
    if (override == null) return defaults;

    final secondary = override.secondary ?? defaults.secondary;
    if (secondary == null) return override.primary;

    return LayoutSize.twoDimensional(
      primary: override.primary,
      secondary: secondary,
    );
  }

  static const LayoutSize panoramicHeader = LayoutSize.rem(6);
  static const LayoutSize crossAxisRibbonWidth = LayoutSize.rem(6);
  static const LayoutSize panoramicFooter = LayoutSize.rem(2);
  static const LayoutSize panoramicRightWidth = LayoutSize.rem(8);
}
