import 'layout.dart';

class QuarterTimeline extends TrackLayout {
  const QuarterTimeline({
    required List<double> columnRatio,
    super.attributes,
    super.innerCircle,
    super.outerCircle,
    required super.elements,
  }) : super.fromAxes(axes: const [6], columnFractions: columnRatio);

  static const leadingEtc = 'leading-etc';
  static const q1 = 'q1';
  static const q2 = 'q2';
  static const q3 = 'q3';
  static const q4 = 'q4';
  static const trailingEtc = 'trailing-etc';
}
