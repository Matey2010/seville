import 'layout.dart';

class LandscapeXlLayout extends Layout {
  const LandscapeXlLayout({
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.backgrounds,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.layoutDefaults,
    super.innerCircle,
    super.outerCircle,
  }) : super.fromAxes();
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
    super.innerCircle,
    super.outerCircle,
  });
}
