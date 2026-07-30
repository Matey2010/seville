part of 'layout.dart';

class SearchLayout extends Layout {
  const SearchLayout({
    this.padding = 12,
    this.maxWidth = 520,
    this.inputHeight = 52,
    this.inputToSuggestionsGap = 6,
    super.size,
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
    super.nodeHoverBorderStyle,
    super.children = const {
      searchResultsLayoutKey: TableLayout(
        guideStyle: GuideStyle(color: Color(0xFF3F51B5)),
        tableConfig: TableConfig(
          panels: {'search_results': PanelConfig(size: LayoutSize.fr(1))},
          rowConfig: TableRowConfig(
            rows: {
              'search_results': TableRow(
                label: 'Results',
                panelId: 'search_results',
                size: LayoutSize.fr(1),
              ),
            },
          ),
          columnConfig: TableColumnConfig(
            columns: {
              'key': TableColumn(size: LayoutSize.fr(1)),
              'value': TableColumn(size: LayoutSize.fr(3)),
            },
          ),
        ),
        children: {
          'search_results': NodeListLayout(
            dataSource: NodeListDataSource.searchResults,
            style: GuideStyle(color: Color(0xFF3F51B5)),
          ),
        },
      ),
    },
    super.visibility,
    super.inputSources,
  }) : assert(padding >= 0),
       assert(maxWidth > 0),
       assert(inputHeight > 0),
       assert(inputToSuggestionsGap >= 0),
       super(attributes: const [LayoutAttribute.rectangular]);

  final double padding;
  final double maxWidth;
  final double inputHeight;
  final double inputToSuggestionsGap;

  static const searchResultsLayoutKey = 'search-results';

  TableLayout? get searchResultsLayout {
    final configured = children[searchResultsLayoutKey];
    return configured is TableLayout ? configured : null;
  }
}
