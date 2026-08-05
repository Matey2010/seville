part of 'layout.dart';

class LandscapeXlLayout extends Layout {
  const LandscapeXlLayout({
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.children,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.inputSources,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
  }) : super();
}

class SafeAreaLayout extends LandscapeXlLayout {
  const SafeAreaLayout({
    super.slot,
    super.aliases,
    super.attributes = const [
      LayoutAttribute.safeArea,
      LayoutAttribute.rectangular,
    ],
    super.background,
    super.children,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.inputSources,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
  });
}
