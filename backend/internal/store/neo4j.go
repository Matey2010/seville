package store

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var neo4jNodeLabelPattern = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)

type Neo4jStore struct {
	driver          neo4j.Driver
	database        string
	queryLog        bool
	queryLogMutex   sync.Mutex
	createNodeMutex sync.Mutex
}

func OpenNeo4j(
	ctx context.Context,
	uri string,
	username string,
	password string,
	database string,
	queryLog bool,
) (*Neo4jStore, error) {
	driver, err := neo4j.NewDriver(uri, neo4j.BasicAuth(username, password, ""))
	if err != nil {
		return nil, fmt.Errorf("create neo4j driver: %w", err)
	}
	if err := waitForConnectivity(ctx, driver, 30*time.Second); err != nil {
		_ = driver.Close(ctx) // the open error matters more
		return nil, fmt.Errorf("connect neo4j: %w", err)
	}
	store := &Neo4jStore{driver: driver, database: database, queryLog: queryLog}
	if err := store.migrate(ctx); err != nil {
		_ = driver.Close(ctx) // the open error matters more
		return nil, err
	}
	return store, nil
}

func waitForConnectivity(ctx context.Context, driver neo4j.Driver, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	var lastErr error
	for {
		if err := driver.VerifyConnectivity(ctx); err == nil {
			return nil
		} else {
			lastErr = err
		}
		if time.Now().After(deadline) {
			return lastErr
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(time.Second):
		}
	}
}

func (s *Neo4jStore) Close() error {
	return s.driver.Close(context.Background())
}

// closeSession closes a session from a defer. A close error comes after the
// work's own result, so it is logged rather than returned.
func closeSession(ctx context.Context, session neo4j.Session) {
	if err := session.Close(ctx); err != nil {
		slog.Warn("close Neo4j session failed", "error", err)
	}
}

func (s *Neo4jStore) session(ctx context.Context, mode neo4j.AccessMode) neo4j.Session {
	return s.driver.NewSession(ctx, neo4j.SessionConfig{
		AccessMode:   mode,
		DatabaseName: s.database,
	})
}

func (s *Neo4jStore) startQueryTrace(
	operation string,
	cypher string,
	parameters map[string]any,
) time.Time {
	if !s.queryLog {
		return time.Time{}
	}
	s.queryLogMutex.Lock()
	_, _ = fmt.Fprintf(
		os.Stderr,
		"\n--- NEO4J CYPHER %s ---\n%s%s\n--- END NEO4J CYPHER ---\n",
		operation,
		neo4jBrowserParameters(parameters),
		cypher,
	)
	s.queryLogMutex.Unlock()
	return time.Now()
}

func neo4jBrowserParameters(parameters map[string]any) string {
	if len(parameters) == 0 {
		return ""
	}
	keys := make([]string, 0, len(parameters))
	for key := range parameters {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	var commands strings.Builder
	for _, key := range keys {
		encoded, err := json.Marshal(parameters[key])
		if err != nil {
			encoded = []byte("null")
		}
		fmt.Fprintf(&commands, ":param %s => %s;\n", key, encoded)
	}
	return commands.String()
}

func (s *Neo4jStore) logQueryRunError(
	operation string,
	started time.Time,
	err error,
) {
	if !s.queryLog {
		return
	}
	slog.Error(
		"neo4j query failed",
		"operation", operation,
		"elapsed", time.Since(started),
		"error", err,
	)
}

func queryTraceDuration(started time.Time) time.Duration {
	if started.IsZero() {
		return 0
	}
	return time.Since(started)
}

func (s *Neo4jStore) finishQueryTrace(
	ctx context.Context,
	operation string,
	started time.Time,
	dispatchDuration time.Duration,
	recordCount int,
	result neo4j.Result,
) error {
	if !s.queryLog {
		return nil
	}
	summary, err := result.Consume(ctx)
	if err != nil {
		s.logQueryRunError(operation, started, err)
		return err
	}
	slog.Info(
		"neo4j query complete",
		"operation", operation,
		"records", recordCount,
		"dispatch_duration", dispatchDuration,
		"total_duration", time.Since(started),
		"server_available_after", summary.ResultAvailableAfter(),
		"server_consumed_after", summary.ResultConsumedAfter(),
	)
	return nil
}

func (s *Neo4jStore) migrate(ctx context.Context) error {
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer closeSession(ctx, session)
	statements := []string{
		`DROP CONSTRAINT seville_tag_id IF EXISTS`,
		`CREATE CONSTRAINT obsivilian_color_rule_set_key IF NOT EXISTS FOR (settings:ObsivilianColorRuleSet) REQUIRE settings.key IS UNIQUE`,
		`MATCH ()-[assignment:TAGGED_WITH]->() DELETE assignment`,
		`MATCH (tag:Tag) WHERE tag.slug IS NULL DETACH DELETE tag`,
		`MATCH (node) WHERE node.slug IS NOT NULL REMOVE node.tags, node.tags_json`,
		`MATCH (settings:ObsivilianColorRuleSet {key: 'global'})-[:HAS_COLOR_RULE]->(rule:ObsivilianColorRule)
WHERE rule.field = 3 SET settings.revision = coalesce(settings.revision, 0) + 1 DETACH DELETE rule`,
	}
	for _, statement := range statements {
		result, err := session.Run(ctx, statement, nil)
		if err != nil {
			return fmt.Errorf("migrate neo4j: %w", err)
		}
		if _, err := result.Consume(ctx); err != nil {
			return fmt.Errorf("migrate neo4j: %w", err)
		}
	}
	if err := discardLegacyTagFrontmatter(ctx, session); err != nil {
		return err
	}
	if err := s.migrateCanonicalNodeLabels(ctx, session); err != nil {
		return err
	}
	return s.migrateTemporalNodes(ctx, session)
}

// migrateCanonicalNodeLabels makes the existing :Node(slug) uniqueness
// constraint cover every canonical Node. The five legacy counter-only shells
// were inspected by the owner before this narrowly guarded cleanup.
func (s *Neo4jStore) migrateCanonicalNodeLabels(ctx context.Context, session neo4j.Session) error {
	_, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `UNWIND ['armor', 'career', 'game', 'science', 'weapon'] AS slug
MATCH (shell {slug: slug, counter: 1})
WHERE size(keys(shell)) = 2 AND size(labels(shell)) = 0
  AND NOT EXISTS { MATCH (shell)--() }
MATCH (keeper {slug: slug})
WHERE keeper <> shell AND keeper.title IS NOT NULL
WITH slug, shell, count(keeper) AS keepers
WHERE keepers = 1
DELETE shell
RETURN slug`, nil)
		if err != nil {
			return nil, err
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		result, err = tx.Run(ctx, `MATCH (node)
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> ''
WITH node.slug AS slug, count(node) AS copies
WHERE copies > 1
RETURN slug ORDER BY slug LIMIT 1`, nil)
		if err != nil {
			return nil, err
		}
		if result.Next(ctx) {
			slug, _ := recordString(result.Record(), "slug")
			return nil, fmt.Errorf("%w: %s; resolve duplicate slugs before applying :Node", ErrAmbiguousNodeSlug, slug)
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		result, err = tx.Run(ctx, `MATCH (node)
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> '' AND NOT node:Node
SET node:Node
RETURN count(node) AS count`, nil)
		if err != nil {
			return nil, err
		}
		_, err = result.Consume(ctx)
		return nil, err
	})
	if err != nil {
		return fmt.Errorf("migrate canonical Node labels: %w", err)
	}
	result, err := session.Run(ctx, `CREATE CONSTRAINT slug_unique IF NOT EXISTS
FOR (node:Node) REQUIRE node.slug IS UNIQUE`, nil)
	if err != nil {
		return fmt.Errorf("create Node slug constraint: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return fmt.Errorf("create Node slug constraint: %w", err)
	}
	return nil
}

func discardLegacyTagFrontmatter(ctx context.Context, session neo4j.Session) error {
	result, err := session.Run(ctx, `MATCH (node)
WHERE node.slug IS NOT NULL
  AND node.frontmatter_json IS NOT NULL
  AND (toLower(node.frontmatter_json) CONTAINS '"tags"'
       OR toLower(node.frontmatter_json) CONTAINS '"tags_json"')
RETURN elementId(node) AS element_id, node.frontmatter_json AS frontmatter_json`, nil)
	if err != nil {
		return fmt.Errorf("find legacy tag frontmatter: %w", err)
	}
	type update struct {
		elementID string
		json      string
	}
	var updates []update
	for result.Next(ctx) {
		elementID, _ := recordString(result.Record(), "element_id")
		raw, _ := recordString(result.Record(), "frontmatter_json")
		fields := make(map[string]json.RawMessage)
		if err := json.Unmarshal([]byte(raw), &fields); err != nil {
			continue
		}
		changed := false
		for key := range fields {
			if strings.EqualFold(key, "tags") || strings.EqualFold(key, "tags_json") {
				delete(fields, key)
				changed = true
			}
		}
		if !changed {
			continue
		}
		encoded, err := json.Marshal(fields)
		if err != nil {
			return err
		}
		updates = append(updates, update{elementID: elementID, json: string(encoded)})
	}
	if err := result.Err(); err != nil {
		return err
	}
	if _, err := result.Consume(ctx); err != nil {
		return err
	}
	for _, item := range updates {
		result, err := session.Run(ctx, `MATCH (node) WHERE elementId(node) = $element_id
SET node.frontmatter_json = $frontmatter_json,
    node.update_count = coalesce(toInteger(node.update_count), 0) + 1`,
			map[string]any{"element_id": item.elementID, "frontmatter_json": item.json})
		if err != nil {
			return err
		}
		if _, err := result.Consume(ctx); err != nil {
			return err
		}
	}
	return nil
}

func (s *Neo4jStore) NodeSearch(
	ctx context.Context,
	filter *nodesv1.NodeSearchFilter,
	limit uint32,
) (*nodesv1.NodeSearchResult, error) {
	compiledFilter, err := compileNodeSearchFilter(filter)
	if err != nil {
		return nil, err
	}
	parameters := make(map[string]any, len(compiledFilter.parameters)+1)
	for name, value := range compiledFilter.parameters {
		parameters[name] = value
	}
	parameters["limit"] = int64(limit)
	query := `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS child` +
		compiledFilter.whereClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH child, emoji
ORDER BY child.slug, child.path, emoji.id
WITH child,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis
ORDER BY child.slug, child.path
LIMIT $limit`
	session := s.session(ctx, neo4j.AccessModeRead)
	defer closeSession(ctx, session)
	traceStarted := s.startQueryTrace("node_search", query, parameters)
	result, err := session.Run(ctx, query, parameters)
	dispatchDuration := queryTraceDuration(traceStarted)
	if err != nil {
		s.logQueryRunError("node_search", traceStarted, err)
		return nil, fmt.Errorf("query Nodes: %w", err)
	}
	response := &nodesv1.NodeSearchResult{}
	for result.Next(ctx) {
		response.Nodes = append(response.Nodes, nodeFromRecord(result.Record()))
	}
	if err := result.Err(); err != nil {
		s.logQueryRunError("node_search", traceStarted, err)
		return nil, fmt.Errorf("read queried Nodes: %w", err)
	}
	if err := s.finishQueryTrace(
		ctx,
		"node_search",
		traceStarted,
		dispatchDuration,
		len(response.Nodes),
		result,
	); err != nil {
		return nil, fmt.Errorf("read Node search summary: %w", err)
	}
	return response, nil
}

// CreateNode creates one canonical Node identified by slug. Labels are
// validated before becoming Cypher syntax; all ordinary values stay query
// parameters.
func (s *Neo4jStore) CreateNode(
	ctx context.Context,
	create NodeCreate,
) (*nodev2.Node, error) {
	s.createNodeMutex.Lock()
	defer s.createNodeMutex.Unlock()
	query, parameters, slug, err := compileNodeCreate(create)
	if err != nil {
		return nil, err
	}
	tokenBytes := make([]byte, 16)
	if _, err := rand.Read(tokenBytes); err != nil {
		return nil, fmt.Errorf("create Node token: %w", err)
	}
	parameters["create_token"] = hex.EncodeToString(tokenBytes)

	session := s.session(ctx, neo4j.AccessModeWrite)
	defer closeSession(ctx, session)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		traceStarted := s.startQueryTrace("node_create", query, parameters)
		result, err := tx.Run(ctx, query, parameters)
		dispatchDuration := queryTraceDuration(traceStarted)
		if err != nil {
			s.logQueryRunError("node_create", traceStarted, err)
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, fmt.Errorf("read created Node: empty result")
		}
		record := result.Record()
		createdValue, _ := record.Get("created")
		created, ok := createdValue.(bool)
		if !ok {
			return nil, fmt.Errorf("read created Node: invalid created flag")
		}
		node := nodeFromRecord(record)
		if s.queryLog {
			if err := s.finishQueryTrace(ctx, "node_create", traceStarted, dispatchDuration, 1, result); err != nil {
				return nil, err
			}
		} else if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if !created {
			return nil, fmt.Errorf("%w: slug %q", ErrNodeAlreadyExists, slug)
		}
		if err := replaceOutgoingConnections(ctx, tx, node.Slug, node.Path, create.Body); err != nil {
			return nil, err
		}
		if err := resolveInboundUnresolvedForNode(ctx, tx, node.Slug); err != nil {
			return nil, err
		}
		return nodeBySlugInTransaction(ctx, tx, node.Slug)
	})
	if err != nil {
		return nil, fmt.Errorf("create Node: %w", err)
	}
	return value.(*nodev2.Node), nil
}

func compileNodeCreate(create NodeCreate) (string, map[string]any, string, error) {
	slug := strings.TrimSpace(create.Slug)
	if slug == "" {
		return "", nil, "", fmt.Errorf("%w: slug is required", ErrInvalidNodeCreate)
	}
	if len(slug) > 512 {
		return "", nil, "", fmt.Errorf("%w: slug exceeds 512 bytes", ErrInvalidNodeCreate)
	}
	if strings.IndexFunc(slug, unicode.IsControl) >= 0 {
		return "", nil, "", fmt.Errorf("%w: slug must not contain control characters", ErrInvalidNodeCreate)
	}
	labels, err := normalizeLabels(create.Labels)
	if err != nil {
		return "", nil, "", fmt.Errorf("%w: %v", ErrInvalidNodeCreate, err)
	}

	labelMutation := ""
	if len(labels) > 0 {
		quotedLabels := make([]string, len(labels))
		for index, label := range labels {
			quotedLabels[index] = "`" + label + "`"
		}
		labelMutation = `
FOREACH (_ IN CASE WHEN created THEN [1] ELSE [] END |
  SET node:` + strings.Join(quotedLabels, ":") + `
)`
	}
	query := `MERGE (node:Node {slug: $slug})
ON CREATE SET node.update_count = 0,
              node.body = $body,
              node.modified_at = $modified_at,
              node.__seville_create_token = $create_token
WITH node, coalesce(node.__seville_create_token = $create_token, false) AS created` + labelMutation + `
FOREACH (_ IN CASE WHEN created THEN [1] ELSE [] END |
  REMOVE node.__seville_create_token
)
RETURN created,
       node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body,
       labels(node) AS labels,
       node.frontmatter_json AS frontmatter_json,
       node.modified_at AS modified_at, properties(node) AS properties,
       [] AS emojis`
	return query, map[string]any{
		"slug":        slug,
		"body":        create.Body,
		"modified_at": time.Now().UTC().UnixNano(),
	}, slug, nil
}

type compiledNodeSearchFilter struct {
	whereClause string
	parameters  map[string]any
}

func compileNodeSearchFilter(filter *nodesv1.NodeSearchFilter) (compiledNodeSearchFilter, error) {
	if filter == nil {
		return compiledNodeSearchFilter{parameters: map[string]any{}}, nil
	}
	parameters := make(map[string]any)
	include, err := compileNodeSearchPredicates(
		filter.GetIncludeNodesMatching(),
		"node_filter_include",
		parameters,
	)
	if err != nil {
		return compiledNodeSearchFilter{}, fmt.Errorf("include_nodes_matching: %w", err)
	}
	exclude, err := compileNodeSearchPredicates(
		filter.GetExcludeNodesMatching(),
		"node_filter_exclude",
		parameters,
	)
	if err != nil {
		return compiledNodeSearchFilter{}, fmt.Errorf("exclude_nodes_matching: %w", err)
	}
	clauses := make([]string, 0, 2)
	if len(include) > 0 {
		includeJoiner, err := nodeSearchIncludeJoiner(filter.GetIncludeMatchMode())
		if err != nil {
			return compiledNodeSearchFilter{}, err
		}
		clauses = append(clauses, "("+strings.Join(include, includeJoiner)+")")
	}
	if len(exclude) > 0 {
		clauses = append(clauses, "NOT ("+strings.Join(exclude, " OR ")+")")
	}
	whereClause := ""
	if len(clauses) > 0 {
		predicate := strings.Join(clauses, " AND ")
		if filter.GetNegated() {
			predicate = "NOT (" + predicate + ")"
		}
		whereClause = "\nWHERE " + predicate
	} else if filter.GetNegated() {
		whereClause = "\nWHERE false"
	}
	return compiledNodeSearchFilter{
		whereClause: whereClause,
		parameters:  parameters,
	}, nil
}

func nodeSearchIncludeJoiner(mode nodesv1.NodeSearchMatchMode) (string, error) {
	switch mode {
	case nodesv1.NodeSearchMatchMode_NODE_SEARCH_MATCH_MODE_UNSPECIFIED,
		nodesv1.NodeSearchMatchMode_NODE_SEARCH_MATCH_MODE_ANY:
		return " OR ", nil
	case nodesv1.NodeSearchMatchMode_NODE_SEARCH_MATCH_MODE_ALL:
		return " AND ", nil
	default:
		return "", fmt.Errorf("%w: unsupported include_match_mode", ErrInvalidNodeSearchParameter)
	}
}

func compileNodeSearchPredicates(
	searchParameters []*nodesv1.NodeSearchParameter,
	parameterPrefix string,
	queryParameters map[string]any,
) ([]string, error) {
	predicates := make([]string, 0, len(searchParameters))
	for index, parameter := range searchParameters {
		if parameter == nil || !supportedNodeParameter(parameter.GetParameter()) {
			return nil, fmt.Errorf("%w at index %d: unsupported parameter", ErrInvalidNodeSearchParameter, index)
		}
		if _, ok := parameter.GetValue().(*nodesv1.NodeSearchParameter_StringValue); !ok {
			return nil, fmt.Errorf("%w at index %d: string_value is required", ErrInvalidNodeSearchParameter, index)
		}
		if parameter.GetOperator() == nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION {
			if _, err := regexp.Compile(parameter.GetStringValue()); err != nil {
				return nil, fmt.Errorf("%w at index %d: invalid regular expression: %v", ErrInvalidNodeSearchParameter, index, err)
			}
		}
		parameterName := fmt.Sprintf("%s_%d", parameterPrefix, index)
		predicate, err := nodeSearchPredicate(parameter, parameterName)
		if err != nil {
			return nil, fmt.Errorf("%w at index %d: %v", ErrInvalidNodeSearchParameter, index, err)
		}
		queryParameters[parameterName] = parameter.GetStringValue()
		predicates = append(predicates, predicate)
	}
	return predicates, nil
}

func supportedNodeParameter(parameter nodesv1.NodeParameterType) bool {
	switch parameter {
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_NAME,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_PATH,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TITLE,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_LABEL,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_SLUG:
		return true
	default:
		return false
	}
}

func nodeSearchPredicate(parameter *nodesv1.NodeSearchParameter, parameterName string) (string, error) {
	valueExpression := ""
	isList := false
	switch parameter.GetParameter() {
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_NAME:
		valueExpression = "coalesce(toString(child.name), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_PATH:
		valueExpression = "coalesce(toString(child.path), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TITLE:
		valueExpression = "coalesce(toString(child.title), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_SLUG:
		valueExpression = "coalesce(toString(child.slug), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_LABEL:
		valueExpression = "[label IN labels(child) WHERE label <> 'Node']"
		isList = true
	default:
		return "", fmt.Errorf("unsupported parameter")
	}
	if isList {
		predicate, err := nodeSearchOperatorPredicate(
			"toString(nodeSearchValue)",
			parameterName,
			parameter.GetOperator(),
		)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("any(nodeSearchValue IN %s WHERE %s)", valueExpression, predicate), nil
	}
	return nodeSearchOperatorPredicate(valueExpression, parameterName, parameter.GetOperator())
}

func nodeSearchOperatorPredicate(
	valueExpression string,
	parameterName string,
	operator nodesv1.NodeSearchMatchOperator,
) (string, error) {
	switch operator {
	case nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_EXACT:
		return fmt.Sprintf("%s = $%s", valueExpression, parameterName), nil
	case nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH:
		return fmt.Sprintf("%s STARTS WITH $%s", valueExpression, parameterName), nil
	case nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH:
		return fmt.Sprintf("%s ENDS WITH $%s", valueExpression, parameterName), nil
	case nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_CONTAINS:
		return fmt.Sprintf("%s CONTAINS $%s", valueExpression, parameterName), nil
	case nodesv1.NodeSearchMatchOperator_NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION:
		return fmt.Sprintf("%s =~ $%s", valueExpression, parameterName), nil
	default:
		return "", fmt.Errorf("unsupported operator")
	}
}

func nodeFromRecord(record *neo4j.Record) *nodev2.Node {
	node := &nodev2.Node{}
	node.Slug, _ = recordString(record, "slug")
	node.Slug = strings.TrimSpace(node.Slug)
	node.Path, _ = recordString(record, "path")
	node.Title, _ = recordString(record, "title")
	node.Body, _ = recordString(record, "body")
	for _, label := range recordStrings(record, "labels") {
		if label != "Node" {
			node.Labels = append(node.Labels, label)
		}
	}
	if raw, ok := recordString(record, "frontmatter_json"); ok {
		_ = json.Unmarshal([]byte(raw), &node.Frontmatter)
	}
	for key := range node.Frontmatter {
		if strings.EqualFold(key, "tags") || strings.EqualFold(key, "tags_json") ||
			strings.EqualFold(key, "temporal_start") || strings.EqualFold(key, "temporal_end_exclusive") ||
			strings.EqualFold(key, "temporal_granularity") || strings.EqualFold(key, "temporal_placement_disabled") {
			delete(node.Frontmatter, key)
		}
	}
	if node.Frontmatter == nil {
		node.Frontmatter = make(map[string]string)
	}
	if properties, ok := record.Get("properties"); ok {
		if values, ok := properties.(map[string]any); ok {
			if updateCount, ok := mapInt64(values, "update_count"); ok && updateCount >= 0 {
				node.UpdateCount = uint64(updateCount)
			}
			node.TemporalSpan = temporalSpanFromProperties(values)
			for key, value := range values {
				if isStoredNodeField(key) {
					continue
				}
				if text, ok := value.(string); ok {
					node.Frontmatter[key] = text
				}
			}
		}
	}
	if value, ok := record.Get("modified_at"); ok {
		if nanos, ok := value.(int64); ok {
			node.ModifiedAt = timestamppb.New(time.Unix(0, nanos).UTC())
		}
	}
	if values, ok := record.Get("emojis"); ok {
		if items, ok := values.([]any); ok {
			for _, item := range items {
				if properties, ok := item.(map[string]any); ok {
					node.Emojis = append(node.Emojis, emojiFromProperties(properties))
				}
			}
		}
	}
	return node
}

func emojiFromProperties(properties map[string]any) *nodev2.Emoji {
	emoji := &nodev2.Emoji{}
	emoji.Id, _ = mapString(properties, "id")
	emoji.Character, _ = mapString(properties, "character")
	emoji.Title, _ = mapString(properties, "title")
	emoji.Codes, _ = mapString(properties, "codes")
	emoji.GroupName, _ = mapString(properties, "groupName")
	emoji.Subgroup, _ = mapString(properties, "subgroup")
	emoji.Category, _ = mapString(properties, "category")
	emoji.Source, _ = mapString(properties, "source")
	if counter, ok := properties["counter"].(int64); ok && counter >= 0 {
		emoji.Counter = uint64(counter)
	}
	emoji.CreatedAt = protoTimestamp(properties["createdAt"])
	emoji.UpdatedAt = protoTimestamp(properties["updatedAt"])
	return emoji
}

func mapString(values map[string]any, key string) (string, bool) {
	value, ok := values[key]
	if !ok {
		return "", false
	}
	text, ok := value.(string)
	return text, ok
}

func mapInt64(values map[string]any, key string) (int64, bool) {
	value, ok := values[key]
	if !ok {
		return 0, false
	}
	integer, ok := value.(int64)
	return integer, ok
}

func protoTimestamp(value any) *timestamppb.Timestamp {
	var timestamp time.Time
	switch typed := value.(type) {
	case time.Time:
		timestamp = typed
	case interface{ Time() time.Time }:
		timestamp = typed.Time()
	default:
		return nil
	}
	result := timestamppb.New(timestamp.UTC())
	if result.CheckValid() != nil {
		return nil
	}
	return result
}

func isStoredNodeField(key string) bool {
	switch key {
	case "id", "slug", "path", "title", "body", "tags", "tags_json", "frontmatter_json", "modified_at", "import_revision", "update_count", "temporal_start", "temporal_end_exclusive", "temporal_granularity", "temporal_placement_disabled":
		return true
	default:
		return false
	}
}

func recordString(record *neo4j.Record, key string) (string, bool) {
	value, ok := record.Get(key)
	if !ok {
		return "", false
	}
	text, ok := value.(string)
	return text, ok
}

func recordStrings(record *neo4j.Record, key string) []string {
	value, ok := record.Get(key)
	if !ok {
		return nil
	}
	switch values := value.(type) {
	case []string:
		return append([]string(nil), values...)
	case []any:
		result := make([]string, 0, len(values))
		for _, value := range values {
			if text, ok := value.(string); ok {
				result = append(result, text)
			}
		}
		return result
	default:
		return nil
	}
}

func recordInt64(record *neo4j.Record, key string) (int64, bool) {
	value, ok := record.Get(key)
	if !ok {
		return 0, false
	}
	integer, ok := value.(int64)
	return integer, ok
}

func stringValue(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}
