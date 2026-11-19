import 'package:seville_proto/seville_proto.dart';

const millisecondsPerDay = 86400000;

class CalendarDay {
  const CalendarDay(this.date, this.epochDay);

  final DateTime date;
  final int epochDay;

  static final _pattern = RegExp(r'^(-?\d{4,6})-(\d{2})-(\d{2})$');

  static CalendarDay? parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (year < -9999 || year > 9999) return null;
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return CalendarDay(date, date.millisecondsSinceEpoch ~/ millisecondsPerDay);
  }
}

class TemporalInterval {
  const TemporalInterval({
    required this.start,
    required this.endExclusive,
    required this.granularity,
  });

  final CalendarDay start;
  final CalendarDay endExclusive;
  final TemporalGranularity granularity;

  static TemporalInterval? fromNode(Node node) {
    if (!node.hasTemporalSpan()) return null;
    final span = node.temporalSpan;
    final start = CalendarDay.parse(span.startDate);
    final end = CalendarDay.parse(span.endDateExclusive);
    if (start == null || end == null || end.epochDay <= start.epochDay) {
      return null;
    }
    return TemporalInterval(
      start: start,
      endExclusive: end,
      granularity: span.granularity,
    );
  }
}
