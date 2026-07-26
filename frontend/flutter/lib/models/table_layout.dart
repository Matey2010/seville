import 'dart:ui';

import 'package:table_data/table_data.dart';

import 'layout.dart';

export 'package:table_data/table_data.dart'
    show
        TableData,
        TableDefinition,
        TableField,
        TableFieldBuilder,
        TableFieldOrdering,
        TableGroup,
        TableRow;

class TableLayout extends Layout
    with TableLayoutMixin
    implements TableDefinition<GridAxisVariable> {
  const TableLayout({
    required this.columns,
    required this.guideStyle,
    this.fieldBuilder,
    this.includeUnconfiguredFields = false,
    this.unconfiguredFieldGroupId,
    this.unconfiguredFieldSize = const GridAxisVariable(size: LayoutSize.fr(1)),
    this.groupGap = 12,
    this.groupBorderStyle,
    this.groupFoldDuration = 0.22,
    this.padding = 12,
    this.cellHighlight,
    this.labelColor = const Color(0xFFFFF8E7),
    this.valueColor = const Color(0xFFFFF8E7),
    this.labelSize = 11,
    this.valueSize = 11,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.backgrounds,
    super.layouts,
    super.layoutDefaults,
    super.visibility,
    super.inputSources,
  }) : assert(groupGap >= 0),
       assert(groupFoldDuration > 0),
       super.fromAxes();

  @override
  final List<MapEntry<String, GridAxisVariable>> columns;
  final GuideStyle guideStyle;
  @override
  final TableFieldBuilder<GridAxisVariable>? fieldBuilder;
  final bool includeUnconfiguredFields;
  final String? unconfiguredFieldGroupId;
  final GridAxisVariable unconfiguredFieldSize;
  final double groupGap;
  final GuideStyle? groupBorderStyle;
  final double groupFoldDuration;
  final double padding;
  final TableCellHighlightConfig? cellHighlight;
  final Color labelColor;
  final Color valueColor;
  final double labelSize;
  final double valueSize;

  @override
  Map<String, GridAxisVariable> get tableRowsConfig => {
    for (final field
        in fieldBuilder?.fields ?? const <TableField<GridAxisVariable>>[])
      field.key: field.size,
  };

  @override
  Map<String, GridAxisVariable> get tableColumnsConfig =>
      Map.fromEntries(columns);

  @override
  GuideStyle get tableGuideStyle => guideStyle;
}

class TableCellHighlightConfig {
  const TableCellHighlightConfig({
    this.rows = false,
    this.columns = false,
    this.color = const Color(0x33FFF7D6),
  });

  final bool rows;
  final bool columns;
  final Color color;
}
