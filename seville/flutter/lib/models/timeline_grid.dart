import 'layout.dart';

class TimelineGrid extends GridLayout {
  const TimelineGrid.fromAxes({
    required super.axes,
    super.attributes = const [LayoutAttribute.rectangular],
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.columnFractions,
    super.rowFractions,
    super.subLayouts,
    required super.elements,
  }) : super.fromAxes();

  static const timeAxis = 'time-axis';
  static const nowPointer = 'now-pointer';
  static const conceptTimeline = 'concept-timeline';
  static const eraTimeline = 'era-timeline';
  static const millenniumTimeline = 'millennium-timeline';
  static const centuryTimeline = 'century-timeline';
  static const decadeTimeline = 'decade-timeline';
  static const yearTimeline = 'year-timeline';
  static const quarterTimeline = 'quarter-timeline';
  static const monthTimeline = 'month-timeline';
  static const weekTimeline = 'week-timeline';

  LayoutElement element(String id) => elements[id]!;
}
