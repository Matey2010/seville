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
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.backgroundDefaults,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.nodeHoverBorderStyle,
    super.nodeSlugPrefix,
    super.nodeSlugTransform,
    super.nodeSlugSuffix,
    super.slugColor,
    super.classificationLabelColors,
    super.classificationLabelBorderColor,
    super.classificationLabelHoleColor,
    super.classificationLabelTextColor,
    super.classificationLabelBorderWidth,
    super.classificationLabelHoverBorderStyle,
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
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.backgroundDefaults,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.nodeHoverBorderStyle,
    super.nodeSlugPrefix,
    super.nodeSlugTransform,
    super.nodeSlugSuffix,
    super.slugColor,
    super.classificationLabelColors,
    super.classificationLabelBorderColor,
    super.classificationLabelHoleColor,
    super.classificationLabelTextColor,
    super.classificationLabelBorderWidth,
    super.classificationLabelHoverBorderStyle,
  });
}
