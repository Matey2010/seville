import 'dart:ui';

import 'layout.dart';

enum NodePropertyTableDataSource { baseNodeInfo }

enum TableFieldOrdering { asConfigured, keyAlphabetical, valueAlphabetical }

class TableFieldBuilder {
  const TableFieldBuilder({this.groups = const {}, required this.fields});

  final Set<TableGroup> groups;
  final List<TableField> fields;
}

class TableGroup {
  const TableGroup({
    required this.id,
    this.label,
    this.ordering = TableFieldOrdering.asConfigured,
  });

  final String? id;
  final String? label;
  final TableFieldOrdering ordering;
}

class TableField {
  const TableField({
    required this.key,
    required this.size,
    this.label,
    this.groupId,
  });

  final String key;
  final GridAxisVariable size;
  final String? label;
  final String? groupId;
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

class NodePropertyTable extends Layout {
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
  }) : super.fromAxes();

  final List<MapEntry<String, GridAxisVariable>> columns;
  final NodePropertyTableDataSource dataSource;
  final GuideStyle guideStyle;
  final TableFieldBuilder? fieldBuilder;
  final double padding;
  final TableCellHighlightConfig? cellHighlight;
  final Color labelColor;
  final Color valueColor;
  final double labelSize;
  final double valueSize;
}
