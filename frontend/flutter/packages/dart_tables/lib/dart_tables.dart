/// Values supplied to a customizable table definition independently of its
/// renderer.
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

/// Renderer-independent table structure.
///
/// [TSize] belongs to the consumer. It may be a Flutter layout track, an SVG
/// measurement, a CSS value, or another renderer-specific size description.
abstract interface class TableDefinition<TSize> {
  List<MapEntry<String, TSize>> get columns;
  TableConfig<TSize>? get tableConfig;
}

class TableConfig<TSize> {
  const TableConfig({this.groups = const {}, required this.rows});

  final Map<String, TableGroup<TSize>> groups;
  final Map<String, TableRow<TSize>> rows;
}

class TableGroup<TSize> {
  const TableGroup({
    required this.size,
    this.orderPosition = 0,
    this.title,
    this.ordering = TableRowOrdering.asConfigured,
    this.foldable = false,
    this.initiallyFolded = false,
  }) : assert(!initiallyFolded || foldable);

  final TSize size;
  final int orderPosition;
  final String? title;
  final TableRowOrdering ordering;
  final bool foldable;
  final bool initiallyFolded;
}

class TableRow<TSize> {
  const TableRow({
    required this.size,
    this.orderPosition = 0,
    this.label,
    this.groupId,
    this.includeWhenEmpty = false,
    this.actions = const [],
  });

  final TSize size;
  final int orderPosition;
  final String? label;
  final String? groupId;
  final bool includeWhenEmpty;
  final List<TableAction> actions;
}
