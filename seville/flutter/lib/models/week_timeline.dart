import 'layout.dart';

class WeekTimeline extends TrackLayout {
  WeekTimeline({
    required List<double> columnRatio,
    super.attributes,
    required super.elements,
  }) : super.fromAxes(axes: [columnRatio.length], columnFractions: columnRatio);

  static const leadingEtc = 'leading-etc';
  static const trailingEtc = 'trailing-etc';

  static String slotId(int month, int weekOfMonth) =>
      'month-$month-week-$weekOfMonth';
}
