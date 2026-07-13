import 'layout.dart';

class MonthTimeline extends TrackLayout {
  const MonthTimeline({
    required List<double> columnRatio,
    super.attributes,
    required super.elements,
  }) : super.fromAxes(axes: const [14], columnFractions: columnRatio);

  static const leadingEtc = 'leading-etc';
  static const january = 'january';
  static const february = 'february';
  static const march = 'march';
  static const april = 'april';
  static const may = 'may';
  static const june = 'june';
  static const july = 'july';
  static const august = 'august';
  static const september = 'september';
  static const october = 'october';
  static const november = 'november';
  static const december = 'december';
  static const trailingEtc = 'trailing-etc';
}
