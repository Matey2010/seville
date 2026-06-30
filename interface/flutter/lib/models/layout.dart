abstract class Layout {
  const Layout({required this.dimensions, this.subLayouts = const {}});

  final LayoutDimensions dimensions;
  final Map<String, Layout> subLayouts;

  int get dimensionCount => dimensions.dimensionCount;
}

class SceneLayout extends Layout {
  const SceneLayout({required super.dimensions, super.subLayouts});
}

class GridLayout extends Layout {
  const GridLayout({required super.dimensions, super.subLayouts});
}

class LayoutDimensions {
  const LayoutDimensions({
    required this.dimensionCount,
    required this.axes,
    this.horizontalFractions,
    this.verticalFractions,
    this.depthFractions,
  });

  final int dimensionCount;
  final List<int> axes;
  final List<double>? horizontalFractions;
  final List<double>? verticalFractions;
  final List<double>? depthFractions;

  int axis(int dimension) => axes[dimension];

  int get horizontal => axis(0);

  int get vertical => axis(1);

  int get depth => axis(2);

  double normalizedHorizontalPosition(num track) {
    return normalizedAxisPosition(0, track);
  }

  double normalizedVerticalPosition(num track) {
    return normalizedAxisPosition(1, track);
  }

  double normalizedAxisPosition(int dimension, num track) {
    final trackCount = axis(dimension);
    if (trackCount <= 0) return 0;
    final clampedTrack = track.clamp(0, trackCount);
    final fractions = _fractionsFor(dimension);

    if (fractions == null || fractions.length != trackCount) {
      return clampedTrack / trackCount;
    }

    final total = fractions.fold<double>(
      0,
      (sum, fraction) => sum + fraction.clamp(0, double.infinity).toDouble(),
    );
    if (total <= 0) return clampedTrack / trackCount;

    final wholeTracks = clampedTrack.floor();
    final partialTrack = clampedTrack - wholeTracks;
    var weightedPosition = 0.0;

    for (var index = 0; index < wholeTracks; index += 1) {
      weightedPosition += fractions[index].clamp(0, double.infinity).toDouble();
    }
    if (wholeTracks < fractions.length && partialTrack > 0) {
      weightedPosition +=
          fractions[wholeTracks].clamp(0, double.infinity).toDouble() *
          partialTrack;
    }

    return (weightedPosition / total).clamp(0.0, 1.0);
  }

  List<double>? _fractionsFor(int dimension) {
    return switch (dimension) {
      0 => horizontalFractions,
      1 => verticalFractions,
      2 => depthFractions,
      _ => null,
    };
  }
}

class LayoutArea {
  const LayoutArea({
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

class LayoutPoint {
  const LayoutPoint({required this.column, required this.row, this.depth = 0});

  final num column;
  final num row;
  final num depth;
}
