import 'layout.dart';

class YearTimeline extends TrackLayout {
  const YearTimeline({
    required List<double> columnRatio,
    required List<double> fractionSpans,
    super.attributes,
    required super.elements,
  }) : super.fromAxes(
         axes: const [14],
         columnFractions: columnRatio,
         fractionSpans: fractionSpans,
       );

  static const leadingEtc = 'leading-etc';
  static const year2019 = '2019';
  static const year2020 = '2020';
  static const year2021 = '2021';
  static const year2022 = '2022';
  static const year2023 = '2023';
  static const year2024 = '2024';
  static const year2025 = '2025';
  static const year2026 = '2026';
  static const year2027 = '2027';
  static const year2028 = '2028';
  static const year2029 = '2029';
  static const year2030 = '2030';
  static const trailingEtc = 'trailing-etc';
}
