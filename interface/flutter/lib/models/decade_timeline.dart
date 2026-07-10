import 'layout.dart';

class DecadeTimeline extends TrackLayout {
  const DecadeTimeline({
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
  static const previousNineties = 'previous-nineties';
  static const zeroes = 'zeroes';
  static const tens = 'tens';
  static const twenties = 'twenties';
  static const thirties = 'thirties';
  static const forties = 'forties';
  static const fifties = 'fifties';
  static const sixties = 'sixties';
  static const seventies = 'seventies';
  static const eighties = 'eighties';
  static const nineties = 'nineties';
  static const nextZeroes = 'next-zeroes';
  static const trailingEtc = 'trailing-etc';
}
