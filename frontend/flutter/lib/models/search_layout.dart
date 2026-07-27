import 'dart:ui';

import 'layout.dart';
import 'table_layout.dart';

class SearchLayout extends Layout {
  const SearchLayout({
    this.padding = 12,
    this.maxWidth = 520,
    this.inputHeight = 52,
    this.inputToSuggestionsGap = 6,
    super.size,
    super.aliases,
    super.backgrounds,
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
    super.layouts = const {
      searchResultsLayoutKey: TableLayout(
        guideStyle: GuideStyle(color: Color(0xFF3F51B5)),
        tableConfig: TableConfig(
          groups: {
            'search_results': TableGroup(
              size: GridAxisVariable(size: LayoutSize.fr(1)),
            ),
          },
          rows: {
            'search_results': TableRow(
              label: 'Results',
              groupId: 'search_results',
              size: GridAxisVariable(size: LayoutSize.fr(1)),
            ),
          },
        ),
        columns: [
          MapEntry('key', GridAxisVariable(size: LayoutSize.fr(1))),
          MapEntry('value', GridAxisVariable(size: LayoutSize.fr(3))),
        ],
        layouts: {
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
       super.fromAxes(attributes: const [LayoutAttribute.rectangular]);

  final double padding;
  final double maxWidth;
  final double inputHeight;
  final double inputToSuggestionsGap;

  static const searchResultsLayoutKey = 'search-results';

  TableLayout? get searchResultsLayout {
    final configured = layouts[searchResultsLayoutKey];
    return configured is TableLayout ? configured : null;
  }
}
