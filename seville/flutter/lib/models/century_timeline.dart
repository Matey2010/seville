import 'layout.dart';

class CenturyTimeline extends TrackLayout {
  const CenturyTimeline({
    required List<double> columnRatio,
    required List<double> fractionSpans,
    super.attributes,
    super.inputSources,
    required super.elements,
  }) : super.fromAxes(
         axes: const [10],
         columnFractions: columnRatio,
         fractionSpans: fractionSpans,
       );

  static const leadingEtc = 'leading-etc';
  static const xxvBce = 'xxv-bce';
  static const bceEtc = 'bce-etc';
  static const iBce = 'i-bce';
  static const iCe = 'i-ce';
  static const ceEtc = 'ce-etc';
  static const xxCe = 'xx-ce';
  static const xxiCe = 'xxi-ce';
  static const xxiiCe = 'xxii-ce';
  static const trailingEtc = 'trailing-etc';
}
