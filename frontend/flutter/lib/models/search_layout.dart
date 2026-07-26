import 'layout.dart';

class SearchLayout extends Layout {
  const SearchLayout({
    this.padding = 12,
    this.maxWidth = 520,
    this.inputHeight = 52,
    this.optionHeight = 44,
    this.maxVisibleOptions = 8,
    this.inputToOptionsGap = 6,
    super.size,
    super.aliases,
    super.backgrounds,
    super.layoutDefaults,
    super.visibility,
    super.inputSources,
  }) : assert(padding >= 0),
       assert(maxWidth > 0),
       assert(inputHeight > 0),
       assert(optionHeight > 0),
       assert(maxVisibleOptions > 0),
       assert(inputToOptionsGap >= 0),
       super.fromAxes(attributes: const [LayoutAttribute.rectangular]);

  final double padding;
  final double maxWidth;
  final double inputHeight;
  final double optionHeight;
  final int maxVisibleOptions;
  final double inputToOptionsGap;
}
