class LayoutGrid {
  const LayoutGrid({required this.columns, required this.rows});

  final int columns;
  final int rows;
}

abstract final class DefaultGrid {
  static const g9x9 = LayoutGrid(columns: 9, rows: 9);
  static const g36x36 = LayoutGrid(columns: 36, rows: 36);
  static const g32x6 = LayoutGrid(columns: 32, rows: 6);
  static const g36x6 = LayoutGrid(columns: 36, rows: 6);
}

class LayoutGridArea {
  const LayoutGridArea({
    required this.column,
    required this.row,
    this.columnSpan = 1,
    this.rowSpan = 1,
  });

  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;
}
