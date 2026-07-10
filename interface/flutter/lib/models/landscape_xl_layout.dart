import 'layout.dart';

class LandscapeXlLayout extends Layout {
  const LandscapeXlLayout({
    this.initialActiveNode,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.backgrounds,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.layoutDefaults,
  }) : super.fromAxes();

  /// Configured initial selection until a persisted user selection is loaded.
  final VaultNodeUiComponent? initialActiveNode;
}

class SafeAreaLayout extends LandscapeXlLayout {
  const SafeAreaLayout({
    super.aliases,
    super.attributes = const [
      LayoutAttribute.safeArea,
      LayoutAttribute.rectangular,
    ],
    super.backgrounds,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.layoutDefaults,
  });
}
