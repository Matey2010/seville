import 'dart:math' as math;
import 'dart:ui';

import 'package:seville_proto/seville_proto.dart';

import '../domain/node_temporal.dart';

/// Independent regions of one virtual graph. Location, top, and right are
/// reserved so their future layouts can contribute anchors without changing
/// the physics or camera contract.
enum GraphPlane { core, time, location, top, right }

class TimeGuide {
  const TimeGuide({required this.y, required this.label});

  final double y;
  final String label;
}

class CalendarLink {
  const CalendarLink({required this.childSlug, required this.parentSlug});

  final String childSlug;
  final String parentSlug;
}

class GraphWorldLayout {
  const GraphWorldLayout({
    required this.viewport,
    required this.size,
    required this.origin,
    required this.anchors,
    required this.planes,
    required this.timeGuides,
    required this.calendarLinks,
    required this.timeIntervals,
    required this.timeRowY,
    required this.timeBandX,
    required this.todayY,
    required this.todayLabel,
    required this.timeHeaderY,
    required this.homeHours,
  });

  final Size viewport;
  final Size size;
  final Offset origin;
  final Map<String, Offset> anchors;
  final Map<String, GraphPlane> planes;
  final List<TimeGuide> timeGuides;
  final List<CalendarLink> calendarLinks;
  final Map<String, TemporalInterval> timeIntervals;

  /// Virtual Y coordinate for each dated start-day slot. Other graph regions
  /// can align their own Nodes to the same HUD guide.
  final Map<int, double> timeRowY;
  final Map<TemporalGranularity, double> timeBandX;
  final double todayY;
  final String todayLabel;
  final double timeHeaderY;
  final double homeHours;

  static GraphWorldLayout compute({
    required Iterable<Node> nodes,
    required Size viewport,
    required Map<String, double> diameters,
  }) {
    final ordered = nodes.toList()..sort((a, b) => a.slug.compareTo(b.slug));
    final intervals = <String, TemporalInterval>{};
    final core = <Node>[];
    for (final node in ordered) {
      final interval = TemporalInterval.fromNode(node);
      if (interval == null || !_bandOrder.contains(interval.granularity)) {
        core.add(node);
      } else {
        intervals[node.slug] = interval;
      }
    }

    final largestDiameter = diameters.values.fold<double>(48, math.max);
    final coreRadius = math.max(
      viewport.width * 0.34,
      math.sqrt(math.max(1, core.length)) * largestDiameter * 0.72,
    );
    final local = <String, Offset>{};
    final planes = <String, GraphPlane>{};
    for (var index = 0; index < core.length; index++) {
      final node = core[index];
      final angle = index * math.pi * (3 - math.sqrt(5));
      final radius = math.sqrt((index + 0.5) / core.length) * coreRadius;
      local[node.slug] = Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      planes[node.slug] = GraphPlane.core;
    }

    final timeSlugs = intervals.keys.toList()
      ..sort((a, b) {
        final byDate = intervals[b]!.start.epochDay.compareTo(
          intervals[a]!.start.epochDay,
        );
        return byDate != 0 ? byDate : a.compareTo(b);
      });
    final now = DateTime.now();
    final todayDay =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        millisecondsPerDay;
    // A date owns one horizontal guide across the graph world.
    final rows = <int, List<String>>{};
    for (final slug in timeSlugs) {
      rows.putIfAbsent(intervals[slug]!.start.epochDay, () => []).add(slug);
    }
    final rowLanes = <int, Map<TemporalGranularity, List<String>>>{};
    for (final row in rows.entries) {
      final byLane = <TemporalGranularity, List<String>>{};
      for (final slug in row.value) {
        byLane.putIfAbsent(intervals[slug]!.granularity, () => []).add(slug);
      }
      rowLanes[row.key] = byLane;
    }
    final rowLocalY = <int, double>{};
    void placeRow(int day, double y) {
      rowLocalY[day] = y;
      for (final lane in rowLanes[day]!.entries) {
        final laneSlugs = lane.value..sort();
        for (var index = 0; index < laneSlugs.length; index++) {
          final slug = laneSlugs[index];
          final offset =
              (index - (laneSlugs.length - 1) / 2) * (largestDiameter * 0.42);
          local[slug] = Offset(_timeNodeX(slug, coreRadius) + offset, y);
          planes[slug] = GraphPlane.time;
        }
      }
    }

    final nowDay =
        todayDay +
        (now.hour * 3600 + now.minute * 60 + now.second) / (24 * 3600);
    for (final day in rows.keys) {
      placeRow(day, _timeY(day - nowDay, viewport.height));
    }

    var minX = -math.max(viewport.width / 2, coreRadius + 140);
    var maxX = math.max(viewport.width / 2, coreRadius + 140);
    var minY = -math.max(viewport.height / 2, coreRadius + 140);
    var maxY = math.max(viewport.height / 2, coreRadius + 140);
    for (final position in local.values) {
      minX = math.min(minX, position.dx - largestDiameter / 2 - 110);
      maxX = math.max(maxX, position.dx + largestDiameter / 2 + 110);
      minY = math.min(minY, position.dy - largestDiameter / 2 - 110);
      maxY = math.max(maxY, position.dy + largestDiameter / 2 + 110);
    }
    final shift = Offset(-minX, -minY);
    final anchors = <String, Offset>{
      for (final entry in local.entries) entry.key: entry.value + shift,
    };
    final guides = <TimeGuide>[];
    final seenYears = <int>{};
    final step = math.max(1, (timeSlugs.length / 18).ceil());
    for (var index = 0; index < timeSlugs.length; index += step) {
      final slug = timeSlugs[index];
      final year = intervals[slug]!.start.date.year;
      if (seenYears.add(year)) {
        guides.add(TimeGuide(y: anchors[slug]!.dy, label: _yearLabel(year)));
      }
    }

    return GraphWorldLayout(
      viewport: viewport,
      size: Size(maxX - minX, maxY - minY),
      origin: shift,
      anchors: Map.unmodifiable(anchors),
      planes: Map.unmodifiable(planes),
      timeGuides: List.unmodifiable(guides),
      calendarLinks: List.unmodifiable(_calendarLinks(intervals)),
      timeIntervals: Map.unmodifiable(intervals),
      timeRowY: Map.unmodifiable({
        for (final row in rowLocalY.entries) row.key: shift.dy + row.value,
      }),
      timeBandX: Map.unmodifiable({
        for (final granularity in _bandOrder)
          granularity: shift.dx + _laneX(granularity, coreRadius),
      }),
      todayY: shift.dy,
      todayLabel:
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}',
      timeHeaderY: shift.dy + 44,
      homeHours: 24,
    );
  }
}

const _bandOrder = <TemporalGranularity>[
  TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
  TemporalGranularity.TEMPORAL_GRANULARITY_SEASON,
  TemporalGranularity.TEMPORAL_GRANULARITY_MONTH,
  TemporalGranularity.TEMPORAL_GRANULARITY_WEEK,
  TemporalGranularity.TEMPORAL_GRANULARITY_DAY,
];

double _laneX(TemporalGranularity granularity, double coreRadius) {
  final index = _bandOrder.indexOf(granularity);
  return -coreRadius - 250 - (_bandOrder.length - 1 - index) * 132;
}

double _timeNodeX(String slug, double coreRadius) {
  var hash = 2166136261;
  for (final codeUnit in slug.codeUnits) {
    hash = ((hash ^ codeUnit) * 16777619) & 0xffffffff;
  }
  final normalized = hash / 0xffffffff;
  return (normalized * 2 - 1) * coreRadius * 0.9;
}

/// Twelve hours from now occupy half of the Home viewport. Greater distances
/// are compressed so zooming out can reveal days, years, and ancient dates in
/// the same virtual world.
double _timeY(double daysFromNow, double viewportHeight) {
  final hours = daysFromNow * 24;
  if (hours == 0) return 0;
  final distance =
      viewportHeight / 2 * (math.log(1 + hours.abs() / 12) / math.ln2);
  return hours > 0 ? -distance : distance;
}

String _yearLabel(int astronomicalYear) =>
    astronomicalYear <= 0 ? '${1 - astronomicalYear} BCE' : '$astronomicalYear';

List<CalendarLink> _calendarLinks(Map<String, TemporalInterval> intervals) {
  final links = <CalendarLink>[];
  for (final entry in intervals.entries) {
    final child = entry.value;
    final parentKinds = switch (child.granularity) {
      TemporalGranularity.TEMPORAL_GRANULARITY_DAY => [
        TemporalGranularity.TEMPORAL_GRANULARITY_WEEK,
        TemporalGranularity.TEMPORAL_GRANULARITY_MONTH,
        TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
      ],
      TemporalGranularity.TEMPORAL_GRANULARITY_WEEK => [
        TemporalGranularity.TEMPORAL_GRANULARITY_MONTH,
        TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
      ],
      TemporalGranularity.TEMPORAL_GRANULARITY_MONTH => [
        TemporalGranularity.TEMPORAL_GRANULARITY_SEASON,
        TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
      ],
      TemporalGranularity.TEMPORAL_GRANULARITY_SEASON => [
        TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
      ],
      _ => <TemporalGranularity>[],
    };
    for (final kind in parentKinds) {
      String? best;
      var bestOverlap = 0;
      for (final candidate in intervals.entries) {
        if (candidate.key == entry.key || candidate.value.granularity != kind) {
          continue;
        }
        final overlap =
            math
                .min(
                  child.endExclusive.epochDay,
                  candidate.value.endExclusive.epochDay,
                )
                .toInt() -
            math
                .max(child.start.epochDay, candidate.value.start.epochDay)
                .toInt();
        if (overlap > bestOverlap ||
            (overlap == bestOverlap &&
                overlap > 0 &&
                (best == null || candidate.key.compareTo(best) < 0))) {
          best = candidate.key;
          bestOverlap = overlap;
        }
      }
      if (best != null && bestOverlap > 0) {
        links.add(CalendarLink(childSlug: entry.key, parentSlug: best));
        break;
      }
    }
  }
  return links;
}
