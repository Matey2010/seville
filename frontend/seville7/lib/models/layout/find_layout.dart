part of 'layout.dart';

/// Projected Node finder with a native editable Flutter input.
///
/// The owning Flame renderer resolves this layout through the same path and
/// grid geometry as every other [Layout]. The editable control is then mapped
/// onto the resolved input surface; its result list remains ordinary child
/// layout content.
class FindLayout extends GridLayout {
  FindLayout({
    this.padding = 12,
    this.maxWidth = 520,
    this.inputHeight = 52,
    this.inputToSuggestionsGap = 6,
    this.hint = const LayoutText.value('Find Nodes'),
    this.inputBackgroundColor = const Color(0xEEFFFFFF),
    this.inputBorderStyle = const GuideStyle(
      color: Color(0xFF3F51B5),
      strokeWidth: 2,
    ),
    this.inputBorderRadius = 8,
    super.size,
    super.slot,
    super.aliases,
    super.background,
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
    super.attributes = const [LayoutAttribute.rectangular],
    super.children = const {
      resultsLayoutKey: ColumnLayout(
        slot: resultsLayoutKey,
        children: {
          'find_results': NodeListLayout(
            dataSource: NodeListDataSource.searchResults,
            style: GuideStyle(color: Color(0xFF3F51B5)),
          ),
        },
      ),
    },
    super.inputSources,
    super.guideStyle,
  }) : assert(padding >= 0),
       assert(maxWidth > 0),
       assert(inputHeight > 0),
       assert(inputToSuggestionsGap >= 0),
       assert(inputBorderRadius >= 0),
       assert(inputBorderStyle.strokeWidth >= 0),
       assert(inputBorderStyle.pattern == GuideLinePattern.solid),
       super(
         rowsConfig: {
           'input': LayoutSize.px(
             padding + inputHeight + inputToSuggestionsGap,
           ),
           resultsLayoutKey: const LayoutSize.fr(1),
         },
         columnsConfig: const {'content': LayoutSize.fr(1)},
         slots: const {
           resultsLayoutKey: GridSlot(row: resultsLayoutKey, column: 'content'),
         },
       );

  final double padding;
  final double maxWidth;
  final double inputHeight;
  final double inputToSuggestionsGap;
  final LayoutText hint;
  final Color inputBackgroundColor;
  final GuideStyle inputBorderStyle;
  final double inputBorderRadius;

  static const resultsLayoutKey = 'find-results';
}
