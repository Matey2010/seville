import 'layout.dart';

class MillenniumTimeline extends TrackLayout {
  const MillenniumTimeline({
    required List<double> columnRatio,
    required List<double> fractionSpans,
    super.attributes,
    required super.elements,
  }) : super.fromAxes(
         axes: const [9],
         columnFractions: columnRatio,
         fractionSpans: fractionSpans,
       );

  static const leadingEtc = 'leading-etc';
  static const ivBce = 'iv-bce';
  static const iiiBce = 'iii-bce';
  static const iiBce = 'ii-bce';
  static const iBce = 'i-bce';
  static const iCe = 'i-ce';
  static const iiCe = 'ii-ce';
  static const iiiCe = 'iii-ce';
  static const trailingEtc = 'trailing-etc';
}
