part of 'layout.dart';

class TableLayout extends Layout
    with TableLayoutMixin
    implements TableDefinition {
  const TableLayout({
    required this.guideStyle,
    this.tableConfig,
    this.includeUnconfiguredFields = false,
    this.unconfiguredFieldPanelId,
    this.unconfiguredFieldSize = const LayoutSize.fr(1),
    this.panelGap = 12,
    this.panelBorderStyle,
    this.panelFoldDuration = 0.22,
    this.padding = 12,
    this.cellHighlight,
    this.labelSize = 11,
    this.valueSize = 11,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.children,
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
    super.inputSources,
  }) : assert(panelGap >= 0),
       assert(panelFoldDuration > 0),
       super();

  final GuideStyle guideStyle;
  @override
  final TableConfig? tableConfig;
  final bool includeUnconfiguredFields;
  final String? unconfiguredFieldPanelId;
  final LayoutSize unconfiguredFieldSize;
  final double panelGap;
  final GuideStyle? panelBorderStyle;
  final double panelFoldDuration;
  final double padding;
  final TableCellHighlightConfig? cellHighlight;
  final double labelSize;
  final double valueSize;

  @override
  Map<String, LayoutSize> get tableRowsConfig => {
    for (final row
        in tableConfig?.rowConfig.orderedRows ??
            const <MapEntry<String, TableRow>>[])
      row.key: row.value.size,
  };

  @override
  Map<String, LayoutSize> get tableColumnsConfig => {
    for (final column
        in tableConfig?.columnConfig.orderedColumns ??
            const <MapEntry<String, TableColumn>>[])
      column.key: column.value.size,
  };

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
