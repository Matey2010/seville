part of 'layout.dart';

class SearchLayout extends GridLayout {
  SearchLayout({
    this.padding = 12,
    this.maxWidth = 520,
    this.inputHeight = 52,
    this.inputToSuggestionsGap = 6,
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
      searchResultsLayoutKey: ColumnLayout(
        slot: searchResultsLayoutKey,
        children: {
          'search_results': NodeListLayout(
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
       super(
         rowsConfig: {
           'input': LayoutSize.px(
             padding + inputHeight + inputToSuggestionsGap,
           ),
           searchResultsLayoutKey: const LayoutSize.fr(1),
         },
         columnsConfig: const {'content': LayoutSize.fr(1)},
         slots: const {
           searchResultsLayoutKey: GridSlot(
             row: searchResultsLayoutKey,
             column: 'content',
           ),
         },
       );

  final double padding;
  final double maxWidth;
  final double inputHeight;
  final double inputToSuggestionsGap;

  static const searchResultsLayoutKey = 'search-results';
}
