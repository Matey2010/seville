import 'layout.dart';

class LandscapeXlLayout extends Layout {
  const LandscapeXlLayout({
    this.initialHighlightedNode,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.backgrounds,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.visibility,
    super.inputSources,
    super.layoutDefaults,
  }) : super.fromAxes();

  /// Configured initial highlight until persisted user state is loaded.
  final VaultNodeUiComponent? initialHighlightedNode;
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
    super.visibility,
    super.inputSources,
    super.layoutDefaults,
  });
}
