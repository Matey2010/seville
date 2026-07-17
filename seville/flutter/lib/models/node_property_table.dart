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

enum NodePropertyTableDataSource { nodeInfo, systemInfo }

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

class NodePropertyTable extends Layout
    with TableLayoutMixin
    implements TableDefinition<GridAxisVariable> {
  const NodePropertyTable({
    required this.columns,
    required this.dataSource,
    required this.guideStyle,
    this.fieldBuilder,
    this.padding = 12,
    this.cellHighlight,
    this.labelColor = const Color(0xFFE5E7EB),
    this.valueColor = const Color(0xFFFFFFFF),
    this.labelSize = 11,
    this.valueSize = 11,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.visibility,
    super.inputSources,
  }) : super.fromAxes();

  @override
  final List<MapEntry<String, GridAxisVariable>> columns;
  final NodePropertyTableDataSource dataSource;
  final GuideStyle guideStyle;
  @override
  final TableFieldBuilder<GridAxisVariable>? fieldBuilder;
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
