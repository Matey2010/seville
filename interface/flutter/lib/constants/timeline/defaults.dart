import '../../models/century_timeline.dart';
import '../../models/concept_timeline.dart';
import '../../models/decade_timeline.dart';
import '../../models/era_timeline.dart';
import '../../models/layout.dart';
import '../../models/millennium_timeline.dart';
import '../../models/month_timeline.dart';
import '../../models/quarter_timeline.dart';
import '../../models/timeline_grid.dart';
import '../../models/week_timeline.dart';
import '../../models/year_timeline.dart';
import '../interface_colors.dart';
import '../layout_axes.dart';
import '../layout_guides.dart';
import '../paths/default_vault_paths.dart';

const defaultTimelineSlotStyle = LayoutSlotStyle(
  borderColor: bottomWallTimeAxisColor,
  strokeWidth: 2,
);

const defaultTimelineYear = 2026;
const _daysInDefaultTimelineYear = 365.0;
const _currentYearLeadingSpan = 8.0;
const _currentYearSpan = 23.0;
const _currentYearTrailingSpan = 5.0;
const _daySpan = _currentYearSpan / _daysInDefaultTimelineYear;
const _monthNames = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

final defaultTimelineLayout = TimelineGrid.fromAxes(
  axes: CommonRatio.twoDimension.grid36x13,
  rowFractions: [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  layouts: const {'timeline-grid': timelineGuideGrid},
  subLayouts: {
    TimelineGrid.conceptTimeline: (
      layout: defaultConceptTimeline,
      area: LayoutArea(column: 0, row: 12, columnSpan: 36, rowSpan: 1),
    ),

    TimelineGrid.eraTimeline: (
      layout: defaultEraTimeline,
      area: LayoutArea(column: 0, row: 11, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.millenniumTimeline: (
      layout: defaultMillenniumTimeline,
      area: LayoutArea(column: 0, row: 10, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.centuryTimeline: (
      layout: defaultCenturyTimeline,
      area: LayoutArea(column: 0, row: 9, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.decadeTimeline: (
      layout: defaultDecadeTimeline,
      area: LayoutArea(column: 0, row: 8, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.yearTimeline: (
      layout: defaultYearTimeline,
      area: LayoutArea(column: 0, row: 7, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.quarterTimeline: (
      layout: defaultQuarterTimeline,
      area: LayoutArea(column: 0, row: 6, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.monthTimeline: (
      layout: defaultMonthTimeline,
      area: LayoutArea(column: 0, row: 5, columnSpan: 36, rowSpan: 1),
    ),
    TimelineGrid.weekTimeline: (
      layout: defaultWeekTimeline,
      area: LayoutArea(column: 0, row: 4, columnSpan: 36, rowSpan: 1),
    ),
  },
  elements: {
    TimelineGrid.timeAxis: LayoutElement(
      area: LayoutArea(column: 0, row: 2, columnSpan: 36, rowSpan: 0),
    ),
    TimelineGrid.nowPointer: LayoutElement(
      area: LayoutArea(column: 0, row: 0, columnSpan: 36, rowSpan: 13),
    ),
    "asdasdasd": LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.today,
      area: LayoutArea(column: 6, row: 3, columnSpan: 24, rowSpan: 1),
      borderRadius: 8,
    ),
  },
);

const defaultConceptTimeline = ConceptTimeline(
  columnRatio: [1, 4, 1],
  elements: {
    ConceptTimeline.past: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.past,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    ConceptTimeline.now: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.now,
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    ConceptTimeline.future: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.future,
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultEraTimeline = EraTimeline(
  columnRatio: [5, 31],
  elements: {
    EraTimeline.bce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.bce,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    EraTimeline.ce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.ce,
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultMillenniumTimeline = MillenniumTimeline(
  fractionSpans: [36],
  columnRatio: [1, 1, 1, 1, 1, 1, 1, LayoutFraction.fullSpan, 1],
  elements: {
    MillenniumTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.ivBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.ivBceMillennium,
      defaultLabel: 'IV BCE',
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iiiBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iiiBceMillennium,
      defaultLabel: 'III BCE',
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iiBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iiBceMillennium,
      defaultLabel: 'II BCE',
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iBceMillennium,
      defaultLabel: 'I BCE',
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iMillennium,
      defaultLabel: 'I CE',
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iiCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iiMillennium,
      defaultLabel: 'II CE',
      area: LayoutArea(column: 6, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.iiiCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iiiMillennium,
      defaultLabel: 'III CE',
      area: LayoutArea(column: 7, row: 0),
      borderRadius: 8,
    ),
    MillenniumTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 8, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultCenturyTimeline = CenturyTimeline(
  fractionSpans: [36],
  columnRatio: [1, 1, 1, 1, 1, 1, 1, LayoutFraction.fullSpan, 1, 1],
  elements: {
    CenturyTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.xxvBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.xxvBceCentury,
      defaultLabel: 'XXV BCE',
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.bceEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.iBce: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iBceCentury,
      defaultLabel: 'I BCE',
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.iCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.iCentury,
      defaultLabel: 'I CE',
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.ceEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.xxCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.xxCentury,
      defaultLabel: 'XX CE',
      area: LayoutArea(column: 6, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.xxiCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.xxiCentury,
      defaultLabel: 'XXI CE',
      area: LayoutArea(column: 7, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.xxiiCe: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.xxiiCentury,
      defaultLabel: 'XXII CE',
      area: LayoutArea(column: 8, row: 0),
      borderRadius: 8,
    ),
    CenturyTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 9, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultDecadeTimeline = DecadeTimeline(
  fractionSpans: [36],
  columnRatio: [1, 1, 1, 1, LayoutFraction.fullSpan, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  elements: {
    DecadeTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.previousNineties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.nineties,
      defaultLabel: 'Nineties',
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.zeroes: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.zeroes,
      defaultLabel: 'Zeroes',
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.tens: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.tens,
      defaultLabel: 'Tens',
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.twenties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.twenties,
      defaultLabel: 'Twenties',
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.thirties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.thirties,
      defaultLabel: 'Thirties',
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.forties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.forties,
      defaultLabel: 'Forties',
      area: LayoutArea(column: 6, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.fifties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.fifties,
      defaultLabel: 'Fifties',
      area: LayoutArea(column: 7, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.sixties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.sixties,
      defaultLabel: 'Sixties',
      area: LayoutArea(column: 8, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.seventies: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.seventies,
      defaultLabel: 'Seventies',
      area: LayoutArea(column: 9, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.eighties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.eighties,
      defaultLabel: 'Eighties',
      area: LayoutArea(column: 10, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.nineties: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.nineties,
      defaultLabel: 'Nineties',
      area: LayoutArea(column: 11, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.nextZeroes: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.zeroes,
      defaultLabel: 'Zeroes',
      area: LayoutArea(column: 12, row: 0),
      borderRadius: 8,
    ),
    DecadeTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      area: LayoutArea(column: 13, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultYearTimeline = YearTimeline(
  fractionSpans: [36],
  columnRatio: [1, 1, 1, 1, 1, 1, 1, 1, LayoutFraction.fullSpan, 1, 1, 1, 1, 1],
  elements: {
    YearTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2019: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2019,
      defaultLabel: '2019',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2020: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2020,
      defaultLabel: '2020',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2021: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2021,
      defaultLabel: '2021',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2022: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2022,
      defaultLabel: '2022',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2023: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2023,
      defaultLabel: '2023',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2024: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2024,
      defaultLabel: '2024',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 6, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2025: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2025,
      defaultLabel: '2025',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 7, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2026: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2026,
      defaultLabel: '2026',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 8, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2027: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2027,
      defaultLabel: '2027',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 9, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2028: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2028,
      defaultLabel: '2028',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 10, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2029: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2029,
      defaultLabel: '2029',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 11, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.year2030: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.year2030,
      defaultLabel: '2030',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 12, row: 0),
      borderRadius: 8,
    ),
    YearTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 13, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultQuarterTimeline = QuarterTimeline(
  columnRatio: [
    _currentYearLeadingSpan,
    90 * _daySpan,
    91 * _daySpan,
    92 * _daySpan,
    92 * _daySpan,
    _currentYearTrailingSpan,
  ],
  elements: {
    QuarterTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    QuarterTimeline.q1: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.q1,
      defaultLabel: 'Q1',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    QuarterTimeline.q2: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.q2,
      defaultLabel: 'Q2',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    QuarterTimeline.q3: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.q3,
      defaultLabel: 'Q3',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    QuarterTimeline.q4: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.q4,
      defaultLabel: 'Q4',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    QuarterTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
  },
);

const defaultMonthTimeline = MonthTimeline(
  columnRatio: [
    _currentYearLeadingSpan,
    31 * _daySpan,
    28 * _daySpan,
    31 * _daySpan,
    30 * _daySpan,
    31 * _daySpan,
    30 * _daySpan,
    31 * _daySpan,
    31 * _daySpan,
    30 * _daySpan,
    31 * _daySpan,
    30 * _daySpan,
    31 * _daySpan,
    _currentYearTrailingSpan,
  ],
  elements: {
    MonthTimeline.leadingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.january: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.january,
      defaultLabel: 'January',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 1, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.february: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.february,
      defaultLabel: 'February',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 2, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.march: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.march,
      defaultLabel: 'March',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 3, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.april: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.april,
      defaultLabel: 'April',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 4, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.may: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.may,
      defaultLabel: 'May',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 5, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.june: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.june,
      defaultLabel: 'June',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 6, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.july: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.july,
      defaultLabel: 'July',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 7, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.august: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.august,
      defaultLabel: 'August',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 8, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.september: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.september,
      defaultLabel: 'September',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 9, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.october: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.october,
      defaultLabel: 'October',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 10, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.november: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.november,
      defaultLabel: 'November',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 11, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.december: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.december,
      defaultLabel: 'December',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 12, row: 0),
      borderRadius: 8,
    ),
    MonthTimeline.trailingEtc: LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 13, row: 0),
      borderRadius: 8,
    ),
  },
);

final defaultWeekTimeline = _buildDefaultWeekTimeline();

WeekTimeline _buildDefaultWeekTimeline() {
  final fractions = <double>[_currentYearLeadingSpan];
  final elements = <String, LayoutElement>{
    WeekTimeline.leadingEtc: const LayoutElement(
      defaultPath: DefaultTimelineVaultPaths.etc,
      defaultLabel: 'Etc',
      slotStyle: defaultTimelineSlotStyle,
      area: LayoutArea(column: 0, row: 0),
      borderRadius: 8,
    ),
  };
  var column = 1;

  for (var month = 1; month <= 12; month += 1) {
    final daysInMonth = DateTime(defaultTimelineYear, month + 1, 0).day;
    var day = 1;
    var weekOfMonth = 1;
    while (day <= daysInMonth) {
      final weekday = DateTime(defaultTimelineYear, month, day).weekday;
      final daysThroughSunday = 8 - weekday;
      final remainingDays = daysInMonth - day + 1;
      final daysInSlot = remainingDays < daysThroughSunday
          ? remainingDays
          : daysThroughSunday;
      fractions.add(daysInSlot * _daySpan);
      elements[WeekTimeline.slotId(month, weekOfMonth)] = LayoutElement(
        defaultPath: DefaultTimelineVaultPaths.week(
          defaultTimelineYear,
          _monthNames[month - 1],
          weekOfMonth,
        ),
        defaultLabel: '$weekOfMonth',
        slotStyle: defaultTimelineSlotStyle,
        area: LayoutArea(column: column, row: 0),
        borderRadius: 8,
      );
      day += daysInSlot;
      weekOfMonth += 1;
      column += 1;
    }
  }

  fractions.add(_currentYearTrailingSpan);
  elements[WeekTimeline.trailingEtc] = LayoutElement(
    defaultPath: DefaultTimelineVaultPaths.etc,
    defaultLabel: 'Etc',
    slotStyle: defaultTimelineSlotStyle,
    area: LayoutArea(column: column, row: 0),
    borderRadius: 8,
  );

  return WeekTimeline(
    columnRatio: List.unmodifiable(fractions),
    elements: Map.unmodifiable(elements),
  );
}
