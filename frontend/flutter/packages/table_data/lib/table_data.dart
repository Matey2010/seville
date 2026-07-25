/// Values supplied to a table definition independently of its renderer.
class TableData {
  const TableData(this.values);

  static const empty = TableData({});

  final Map<String, Object?> values;

  Object? operator [](String key) => values[key];
}

enum TableFieldOrdering { asConfigured, keyAlphabetical, valueAlphabetical }

/// Renderer-independent table structure.
///
/// [TSize] belongs to the consumer. It may be a Flutter layout track, an SVG
/// measurement, a CSS value, or another renderer-specific size description.
abstract interface class TableDefinition<TSize> {
  List<MapEntry<String, TSize>> get columns;
  TableFieldBuilder<TSize>? get fieldBuilder;
}

class TableFieldBuilder<TSize> {
  const TableFieldBuilder({this.groups = const [], required this.fields});

  final List<TableGroup> groups;
  final List<TableField<TSize>> fields;
}

class TableGroup {
  const TableGroup({
    required this.id,
    this.title,
    this.ordering = TableFieldOrdering.asConfigured,
    this.foldable = false,
    this.initiallyFolded = false,
  }) : assert(!initiallyFolded || foldable);

  final String? id;
  final String? title;
  final TableFieldOrdering ordering;
  final bool foldable;
  final bool initiallyFolded;
}

class TableField<TSize> {
  const TableField({
    required this.key,
    required this.size,
    this.label,
    this.groupId,
  });

  final String key;
  final TSize size;
  final String? label;
  final String? groupId;
}

class TableRow<TSize> {
  const TableRow({
    this.key,
    this.groupId,
    required this.label,
    required this.value,
    required this.size,
    this.section = false,
    this.spacer = false,
  });

  final String? key;
  final String? groupId;
  final String label;
  final Object? value;
  final TSize size;
  final bool section;
  final bool spacer;
}

/// Resolves configured fields into deterministic rows without painting them.
List<TableRow<TSize>> buildTableRows<TSize>(
  TableDefinition<TSize> definition,
  TableData data, {
  required TSize Function(TSize fieldSize) sectionSize,
  required String Function(Object? value) formatValue,
  bool Function(Object? value)? includeValue,
}) {
  final builder = definition.fieldBuilder;
  if (builder == null) return const [];

  final fields = builder.fields;
  final groups = builder.groups;
  final groupIds = {for (final group in groups) group.id};

  Iterable<TableRow<TSize>> rowsForGroup(TableGroup group) sync* {
    final groupFields = [
      for (final field in fields)
        if ((groupIds.contains(field.groupId) ? field.groupId : null) ==
                group.id &&
            (includeValue?.call(data[field.key]) ?? true))
          field,
    ];
    _sortFields(groupFields, group.ordering, data, formatValue);
    if (groupFields.isEmpty) return;

    final groupTitle = group.title?.trim();
    if (groupTitle != null && groupTitle.isNotEmpty) {
      yield TableRow(
        groupId: group.id,
        label: groupTitle,
        value: null,
        size: sectionSize(groupFields.first.size),
        section: true,
      );
    }
    for (final field in groupFields) {
      yield TableRow(
        key: field.key,
        groupId: group.id,
        label: field.label ?? field.key,
        value: data[field.key],
        size: field.size,
      );
    }
  }

  return [for (final group in groups) ...rowsForGroup(group)];
}

void _sortFields<TSize>(
  List<TableField<TSize>> fields,
  TableFieldOrdering ordering,
  TableData data,
  String Function(Object? value) formatValue,
) {
  switch (ordering) {
    case TableFieldOrdering.asConfigured:
      return;
    case TableFieldOrdering.keyAlphabetical:
      fields.sort((left, right) => left.key.compareTo(right.key));
    case TableFieldOrdering.valueAlphabetical:
      fields.sort(
        (left, right) =>
            formatValue(data[left.key]).compareTo(formatValue(data[right.key])),
      );
  }
}
