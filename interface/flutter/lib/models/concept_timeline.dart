import 'layout.dart';

class ConceptTimeline extends TrackLayout {
  const ConceptTimeline({
    required List<double> columnRatio,
    super.attributes,
    super.innerCircle,
    super.outerCircle,
    required super.elements,
  }) : super.fromAxes(axes: const [3], columnFractions: columnRatio);

  static const past = 'past';
  static const now = 'now';
  static const future = 'future';
}
