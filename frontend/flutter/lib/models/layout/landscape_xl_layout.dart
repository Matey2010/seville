part of 'layout.dart';

class LandscapeXlLayout extends Layout {
  const LandscapeXlLayout({
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.backgrounds,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.visibility,
    super.inputSources,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.backgroundDefaults,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.nodeHoverBorderStyle,
    super.nodeSlugPrefix,
    super.nodeSlugTransform,
    super.nodeSlugSuffix,
    super.slugColor,
  }) : super();
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
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.backgroundDefaults,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.nodeHoverBorderStyle,
    super.nodeSlugPrefix,
    super.nodeSlugTransform,
    super.nodeSlugSuffix,
    super.slugColor,
  });
}
