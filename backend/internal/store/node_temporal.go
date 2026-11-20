package store

import (
	"context"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

func temporalSpanFromProperties(properties map[string]any) *nodev2.NodeTemporalSpan {
	start, ok := nativeCalendarDate(properties["temporal_start"])
	if !ok {
		return nil
	}
	end, ok := nativeCalendarDate(properties["temporal_end_exclusive"])
	if !ok || !start.Before(end) {
		return nil
	}
	granularity, ok := temporalGranularity(properties["temporal_granularity"])
	if !ok {
		granularity = nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_RANGE
	}
	return &nodev2.NodeTemporalSpan{
		StartDate:        formatCalendarDate(start),
		EndDateExclusive: formatCalendarDate(end),
		Granularity:      granularity,
	}
}

func nativeCalendarDate(value any) (time.Time, bool) {
	var date time.Time
	switch typed := value.(type) {
	case neo4j.Date:
		date = typed.Time()
	case time.Time:
		date = typed
	default:
		return time.Time{}, false
	}
	if date.Hour() != 0 || date.Minute() != 0 || date.Second() != 0 || date.Nanosecond() != 0 {
		return time.Time{}, false
	}
	return time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC), true
}

var isoCalendarDatePattern = regexp.MustCompile(`^(-?[0-9]{4,6})-([0-9]{2})-([0-9]{2})$`)
var dayMonthYearSlugPattern = regexp.MustCompile(`^([0-9]{2})-([0-9]{2})-([0-9]{4})$`)
var yearSlugPattern = regexp.MustCompile(`^[0-9]{4}$`)
var monthSlugPattern = regexp.MustCompile(`^([0-9]{4})-([0-9]{2})$`)
var weekSlugPattern = regexp.MustCompile(`^([0-9]{4})-W([0-9]{2})$`)
var calendarTimeSlugPattern = regexp.MustCompile(`^cortex-time-calendar-([0-9]{4})-([0-9]{2})-[a-z0-9]+$`)
var calendarTimeTitlePattern = regexp.MustCompile(`^([0-9]{4}) ([0-9]{2}) ([0-9]{2}): ([0-9]{2})$`)
var datedEventSlugPattern = regexp.MustCompile(`^event-([0-9]{8})[0-9]{6}-[a-z0-9]+$`)
var datedEventTitlePattern = regexp.MustCompile(`^Event ([0-9]{4})-([0-9]{2})-([0-9]{2})$`)
var bceYearTitlePattern = regexp.MustCompile(`(?i)^([1-9][0-9]{0,3})\s+(?:bce|bc)(?::.*)?$`)
var beforeEraTitlePattern = regexp.MustCompile(`(?i)^([1-9][0-9]{0,3})\s+year before our era$`)

func parseCalendarDate(value string) (time.Time, bool) {
	match := isoCalendarDatePattern.FindStringSubmatch(value)
	if match == nil {
		return time.Time{}, false
	}
	year, yearErr := strconv.Atoi(match[1])
	month, monthErr := strconv.Atoi(match[2])
	day, dayErr := strconv.Atoi(match[3])
	if yearErr != nil || monthErr != nil || dayErr != nil || year < -9999 || year > 9999 {
		return time.Time{}, false
	}
	date := time.Date(year, time.Month(month), day, 0, 0, 0, 0, time.UTC)
	if date.Year() != year || int(date.Month()) != month || date.Day() != day || formatCalendarDate(date) != value {
		return time.Time{}, false
	}
	return date, true
}

func formatCalendarDate(date time.Time) string {
	year := date.Year()
	if year < 0 {
		return fmt.Sprintf("-%04d-%02d-%02d", -year, date.Month(), date.Day())
	}
	return fmt.Sprintf("%04d-%02d-%02d", year, date.Month(), date.Day())
}

func inferredTemporalSpan(slug, title string, labels []string) *nodev2.NodeTemporalSpan {
	has := func(label string) bool {
		for _, candidate := range labels {
			if candidate == label {
				return true
			}
		}
		return false
	}
	span := func(start, end time.Time, granularity nodev2.TemporalGranularity) *nodev2.NodeTemporalSpan {
		return &nodev2.NodeTemporalSpan{
			StartDate: formatCalendarDate(start), EndDateExclusive: formatCalendarDate(end),
			Granularity: granularity,
		}
	}
	if has("Date") || has("Time") {
		if match := dayMonthYearSlugPattern.FindStringSubmatch(slug); match != nil {
			iso := match[3] + "-" + match[2] + "-" + match[1]
			if date, ok := parseCalendarDate(iso); ok {
				return span(date, date.AddDate(0, 0, 1), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY)
			}
		}
		if date, ok := parseCalendarDate(slug); ok {
			return span(date, date.AddDate(0, 0, 1), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY)
		}
		if has("Time") {
			fromSlug := calendarTimeSlugPattern.FindStringSubmatch(slug)
			fromTitle := calendarTimeTitlePattern.FindStringSubmatch(strings.TrimSpace(title))
			if fromSlug != nil && fromTitle != nil &&
				fromSlug[1] == fromTitle[1] && fromSlug[2] == fromTitle[2] &&
				fromTitle[2] == fromTitle[4] {
				if date, ok := parseCalendarDate(fromTitle[1] + "-" + fromTitle[2] + "-" + fromTitle[3]); ok {
					return span(date, date.AddDate(0, 0, 1), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY)
				}
			}
		}
		if has("Date") {
			fromSlug := datedEventSlugPattern.FindStringSubmatch(slug)
			fromTitle := datedEventTitlePattern.FindStringSubmatch(strings.TrimSpace(title))
			if fromSlug != nil && fromTitle != nil &&
				fromSlug[1] == fromTitle[1]+fromTitle[2]+fromTitle[3] {
				if date, ok := parseCalendarDate(fromTitle[1] + "-" + fromTitle[2] + "-" + fromTitle[3]); ok {
					return span(date, date.AddDate(0, 0, 1), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY)
				}
			}
		}
	}
	if has("Year") {
		if yearSlugPattern.MatchString(slug) {
			year, _ := strconv.Atoi(slug)
			start := time.Date(year, time.January, 1, 0, 0, 0, 0, time.UTC)
			return span(start, start.AddDate(1, 0, 0), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_YEAR)
		}
		for _, pattern := range []*regexp.Regexp{bceYearTitlePattern, beforeEraTitlePattern} {
			if match := pattern.FindStringSubmatch(strings.TrimSpace(title)); match != nil {
				bceYear, _ := strconv.Atoi(match[1])
				start := time.Date(1-bceYear, time.January, 1, 0, 0, 0, 0, time.UTC)
				return span(start, start.AddDate(1, 0, 0), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_YEAR)
			}
		}
	}
	if has("Month") {
		if match := monthSlugPattern.FindStringSubmatch(slug); match != nil {
			date, ok := parseCalendarDate(match[1] + "-" + match[2] + "-01")
			if ok {
				return span(date, date.AddDate(0, 1, 0), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_MONTH)
			}
		}
	}
	if has("Week") {
		if match := weekSlugPattern.FindStringSubmatch(slug); match != nil {
			year, _ := strconv.Atoi(match[1])
			week, _ := strconv.Atoi(match[2])
			jan4 := time.Date(year, time.January, 4, 0, 0, 0, 0, time.UTC)
			weekday := (int(jan4.Weekday()) + 6) % 7
			start := jan4.AddDate(0, 0, -weekday+(week-1)*7)
			actualYear, actualWeek := start.ISOWeek()
			if actualYear == year && actualWeek == week {
				return span(start, start.AddDate(0, 0, 7), nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_WEEK)
			}
		}
	}
	// Recurring months and seasons have no unique calendar date.
	return nil
}

// migrateTemporalNodes adds native DATE values only where an existing calendar
// slug or BCE Year title is unambiguous. It never guesses from generic Time.
func (s *Neo4jStore) migrateTemporalNodes(ctx context.Context, session neo4j.Session) error {
	result, err := session.Run(ctx, `MATCH (node:Node)
WHERE node.temporal_start IS NULL AND node.temporal_end_exclusive IS NULL
  AND coalesce(node.temporal_placement_disabled, false) = false
  AND any(label IN labels(node) WHERE label IN ['Date', 'Time', 'Year', 'Month', 'Week'])
RETURN node.slug AS slug, node.title AS title, labels(node) AS labels,
       node.date AS legacy_date`, nil)
	if err != nil {
		return fmt.Errorf("find calendar Nodes: %w", err)
	}
	rows := make([]map[string]any, 0)
	for result.Next(ctx) {
		slug, _ := recordString(result.Record(), "slug")
		title, _ := recordString(result.Record(), "title")
		span := inferredTemporalSpan(slug, title, recordStrings(result.Record(), "labels"))
		if legacy, found := result.Record().Get("legacy_date"); found {
			if day, native := nativeCalendarDate(legacy); native {
				span = &nodev2.NodeTemporalSpan{
					StartDate:        formatCalendarDate(day),
					EndDateExclusive: formatCalendarDate(day.AddDate(0, 0, 1)),
					Granularity:      nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY,
				}
			}
		}
		if span == nil {
			continue
		}
		if _, _, _, err := validateTemporalSpan(span); err != nil {
			continue
		}
		granularity, _ := temporalGranularityName(span.Granularity)
		rows = append(rows, map[string]any{
			"slug": slug, "start": span.StartDate,
			"end": span.EndDateExclusive, "granularity": granularity,
		})
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read calendar Nodes: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return fmt.Errorf("consume calendar Nodes: %w", err)
	}
	for offset := 0; offset < len(rows); offset += 500 {
		end := offset + 500
		if end > len(rows) {
			end = len(rows)
		}
		batch := rows[offset:end]
		_, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
			result, err := tx.Run(ctx, `UNWIND $rows AS row
MATCH (node:Node {slug: row.slug})
WHERE node.temporal_start IS NULL AND node.temporal_end_exclusive IS NULL
SET node.temporal_start = date(row.start),
    node.temporal_end_exclusive = date(row.end),
    node.temporal_granularity = row.granularity,
    node.update_count = coalesce(toInteger(node.update_count), 0) + 1,
    node.modified_at = $modified_at
RETURN count(node) AS changed`, map[string]any{
				"rows": batch, "modified_at": time.Now().UTC().UnixNano(),
			})
			if err != nil {
				return nil, err
			}
			_, err = result.Consume(ctx)
			return nil, err
		})
		if err != nil {
			return fmt.Errorf("backfill native calendar dates: %w", err)
		}
	}
	return nil
}

func temporalGranularity(value any) (nodev2.TemporalGranularity, bool) {
	switch value {
	case "year":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_YEAR, true
	case "season":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_SEASON, true
	case "month":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_MONTH, true
	case "week":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_WEEK, true
	case "day":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY, true
	case "range":
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_RANGE, true
	default:
		return nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_UNSPECIFIED, false
	}
}

func temporalGranularityName(value nodev2.TemporalGranularity) (string, bool) {
	switch value {
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_YEAR:
		return "year", true
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_SEASON:
		return "season", true
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_MONTH:
		return "month", true
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_WEEK:
		return "week", true
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_DAY:
		return "day", true
	case nodev2.TemporalGranularity_TEMPORAL_GRANULARITY_RANGE:
		return "range", true
	default:
		return "", false
	}
}

func validateTemporalSpan(span *nodev2.NodeTemporalSpan) (string, string, string, error) {
	if span == nil {
		return "", "", "", nil
	}
	startText := strings.TrimSpace(span.GetStartDate())
	endText := strings.TrimSpace(span.GetEndDateExclusive())
	start, ok := parseCalendarDate(startText)
	if !ok {
		return "", "", "", fmt.Errorf("%w: start_date must be an ISO calendar date", ErrInvalidTemporalSpan)
	}
	end, ok := parseCalendarDate(endText)
	if !ok || !start.Before(end) {
		return "", "", "", fmt.Errorf("%w: end_date_exclusive must follow start_date", ErrInvalidTemporalSpan)
	}
	granularity, ok := temporalGranularityName(span.GetGranularity())
	if !ok {
		return "", "", "", fmt.Errorf("%w: granularity is required", ErrInvalidTemporalSpan)
	}
	switch granularity {
	case "day":
		if !end.Equal(start.AddDate(0, 0, 1)) {
			return "", "", "", fmt.Errorf("%w: a day must span one calendar day", ErrInvalidTemporalSpan)
		}
	case "week":
		if start.Weekday() != time.Monday || !end.Equal(start.AddDate(0, 0, 7)) {
			return "", "", "", fmt.Errorf("%w: a week must run Monday to Monday", ErrInvalidTemporalSpan)
		}
	case "month":
		if start.Day() != 1 || !end.Equal(start.AddDate(0, 1, 0)) {
			return "", "", "", fmt.Errorf("%w: a month must cover one calendar month", ErrInvalidTemporalSpan)
		}
	case "year":
		if start.Month() != time.January || start.Day() != 1 || !end.Equal(start.AddDate(1, 0, 0)) {
			return "", "", "", fmt.Errorf("%w: a year must cover one calendar year", ErrInvalidTemporalSpan)
		}
	}
	return startText, endText, granularity, nil
}

// ReplaceNodeTemporalSpan stores a calendar interval as native Neo4j DATE
// properties. An absent span clears all temporal placement metadata.
func (s *Neo4jStore) ReplaceNodeTemporalSpan(ctx context.Context, slug string, span *nodev2.NodeTemporalSpan, expected uint64) (*nodev2.Node, error) {
	if strings.TrimSpace(slug) == "" || expected > 1<<63-2 {
		return nil, ErrInvalidTemporalSpan
	}
	start, end, granularity, err := validateTemporalSpan(span)
	if err != nil {
		return nil, err
	}
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer closeSession(ctx, session)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `MATCH (node:Node {slug: $slug})
RETURN coalesce(toInteger(node.update_count), 0) AS update_count`, map[string]any{"slug": slug})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrNodeNotFound
		}
		count, _ := recordInt64(result.Record(), "update_count")
		if result.Next(ctx) {
			return nil, ErrAmbiguousNodeSlug
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if count < 0 || uint64(count) != expected {
			return nil, ErrNodeConflict
		}
		query := `MATCH (node:Node {slug: $slug})
WHERE coalesce(toInteger(node.update_count), 0) = $expected
SET node.temporal_start = date($start),
    node.temporal_end_exclusive = date($end),
    node.temporal_granularity = $granularity,
    node.temporal_placement_disabled = false,
    node.update_count = $expected + 1,
    node.modified_at = $modified_at
RETURN node.slug AS slug`
		if span == nil {
			query = `MATCH (node:Node {slug: $slug})
WHERE coalesce(toInteger(node.update_count), 0) = $expected
REMOVE node.temporal_start, node.temporal_end_exclusive, node.temporal_granularity
SET node.temporal_placement_disabled = true,
    node.update_count = $expected + 1, node.modified_at = $modified_at
RETURN node.slug AS slug`
		}
		result, err = tx.Run(ctx, query, map[string]any{
			"slug": slug, "expected": int64(expected), "start": start,
			"end": end, "granularity": granularity,
			"modified_at": time.Now().UTC().UnixNano(),
		})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrNodeConflict
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		return nodeBySlugInTransaction(ctx, tx, slug)
	})
	if err != nil {
		return nil, fmt.Errorf("replace Node temporal span: %w", err)
	}
	return value.(*nodev2.Node), nil
}
