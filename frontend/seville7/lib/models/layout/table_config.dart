part of 'layout.dart';

/// Values supplied to a [TableLayout] independently of Flame rendering.
class TableData {
  const TableData(this.values);

  static const empty = TableData({});

  final Map<String, Object?> values;

  Object? operator [](String key) => values[key];
}

enum TableRowOrdering { asConfigured, keyAlphabetical, valueAlphabetical }

class TableAction {
  const TableAction.copy() : name = 'copy';
  const TableAction.copyToClipboard() : name = 'copyToClipboard';
  const TableAction.delete() : name = 'delete';

  final String name;

  bool get copiesToClipboard => name == 'copyToClipboard';
}

/// Native Seville table structure.
///
/// Table definitions use [LayoutSize] directly and expose the owning Layout's
/// [NodeConfig], so Node-backed table content follows the same conditional
/// configuration protocol as every other Node-rendering Layout.
abstract interface class TableDefinition {
  TableConfig? get tableConfig;
  NodeConfig get node;
  PanelConfig get panel;
}

class TableConfig {
  const TableConfig({
    this.panel = const PanelConfig(),
    this.panels = const {},
    required this.rowConfig,
    required this.columnConfig,
  });

  final PanelConfig panel;
  final Map<String, PanelConfig> panels;
  final TableRowConfig rowConfig;
  final TableColumnConfig columnConfig;

  List<MapEntry<String, PanelConfig>> get orderedPanels =>
      _orderedTableEntries(panels, (panel) => panel.resolvedOrderPosition);
}

class TableRowConfig {
  const TableRowConfig({this.rows = const {}});

  final Map<String, TableRow> rows;

  List<MapEntry<String, TableRow>> get orderedRows =>
      _orderedTableEntries(rows, (row) => row.orderPosition);
}

class TableColumnConfig {
  const TableColumnConfig({this.columns = const {}});

  final Map<String, TableColumn> columns;

  List<MapEntry<String, TableColumn>> get orderedColumns =>
      _orderedTableEntries(columns, (column) => column.orderPosition);
}

class TableRow {
  const TableRow({
    required this.size,
    this.orderPosition = 0,
    this.label,
    this.panelId,
    this.includeWhenEmpty = false,
    this.actions = const [],
  });

  final LayoutSize size;
  final int orderPosition;
  final String? label;
  final String? panelId;
  final bool includeWhenEmpty;
  final List<TableAction> actions;
}

class TableColumn {
  const TableColumn({required this.size, this.orderPosition = 0, this.label});

  final LayoutSize size;
  final int orderPosition;
  final String? label;
}

List<MapEntry<String, TValue>> _orderedTableEntries<TValue>(
  Map<String, TValue> values,
  int Function(TValue value) orderPosition,
) {
  final indexed = values.entries.indexed
      .map((entry) => (index: entry.$1, entry: entry.$2))
      .toList();
  indexed.sort((left, right) {
    final order = orderPosition(
      left.entry.value,
    ).compareTo(orderPosition(right.entry.value));
    return order != 0 ? order : left.index.compareTo(right.index);
  });
  return [for (final item in indexed) item.entry];
}
