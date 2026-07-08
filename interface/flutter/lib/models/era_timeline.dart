import 'layout.dart';

class EraTimeline extends TrackLayout {
  const EraTimeline({
    required List<double> columnRatio,
    super.attributes,
    super.innerCircle,
    super.outerCircle,
    required super.elements,
  }) : super.fromAxes(axes: const [2], columnFractions: columnRatio);

  static const bce = 'bce';
  static const ce = 'ce';
}
