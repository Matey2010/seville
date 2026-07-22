package store

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	systemv1 "github.com/Matey2010/seville/proto/gen/go/seville/system/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type Neo4jStore struct {
	driver        neo4j.Driver
	database      string
	queryLog      bool
	queryLogMutex sync.Mutex
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
		driver.Close(ctx)
		return nil, fmt.Errorf("connect neo4j: %w", err)
	}
	store := &Neo4jStore{driver: driver, database: database, queryLog: queryLog}
	if err := store.migrate(ctx); err != nil {
		driver.Close(ctx)
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
	defer session.Close(ctx)
	statements := []string{
		`CREATE CONSTRAINT seville_tag_id IF NOT EXISTS FOR (tag:Tag) REQUIRE tag.id IS UNIQUE`,
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
	return nil
}

func (s *Neo4jStore) SystemInfo(ctx context.Context) (*systemv1.SystemInfo, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
	result, err := session.Run(ctx, `CALL {
  CALL db.labels() YIELD label
  WITH label ORDER BY label
  RETURN collect(label) AS neo4j_labels
}
CALL {
  CALL dbms.components() YIELD name, versions
  WHERE name CONTAINS 'Neo4j'
  RETURN head(collect(head(versions))) AS neo4j_version
}
CALL {
MATCH (node)
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> ''
  AND NOT node:Tag
  AND NOT node:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(node) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(node) }
RETURN count(node) AS node_count,
       sum(size(keys(node))) AS node_property_count
}
RETURN node_count, node_property_count, neo4j_labels, neo4j_version`, nil)
	if err != nil {
		return nil, fmt.Errorf("query neo4j system info: %w", err)
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			return nil, fmt.Errorf("read neo4j system info: %w", err)
		}
		return nil, fmt.Errorf("read neo4j system info: empty result")
	}
	record := result.Record()
	nodeCount, ok := recordInt64(record, "node_count")
	if !ok || nodeCount < 0 {
		return nil, fmt.Errorf("read neo4j system info: invalid node_count")
	}
	nodePropertyCount, ok := recordInt64(record, "node_property_count")
	if !ok || nodePropertyCount < 0 {
		return nil, fmt.Errorf("read neo4j system info: invalid node_property_count")
	}
	neo4jVersion, ok := recordString(record, "neo4j_version")
	if !ok || strings.TrimSpace(neo4jVersion) == "" {
		return nil, fmt.Errorf("read neo4j system info: invalid neo4j_version")
	}
	return &systemv1.SystemInfo{
		NodeCount:         uint64(nodeCount),
		NodePropertyCount: uint64(nodePropertyCount),
		Neo4JLabels:       recordStrings(record, "neo4j_labels"),
		GoVersion:         runtime.Version(),
		Neo4JVersion:      neo4jVersion,
	}, nil
}

func (s *Neo4jStore) NodeTree(
	ctx context.Context,
	rootNodeID string,
	rootNodeFilter *nodesv1.NodeSearchFilter,
	relationshipType nodesv1.NodeRelationshipType,
	nodeFilter *nodesv1.NodeSearchFilter,
	depth uint32,
) (*nodesv1.NodeTree, error) {
	relationshipName, err := neo4jRelationshipName(relationshipType)
	if err != nil {
		return nil, err
	}
	compiledRootFilter, err := compileNodeSearchFilter(rootNodeFilter)
	if err != nil {
		return nil, fmt.Errorf("root_node_filter: %w", err)
	}
	compiledFilter, err := compileNodeSearchFilter(nodeFilter)
	if err != nil {
		return nil, err
	}
	childQuery := `MATCH (child)-[relationship]->(parent)
WHERE elementId(parent) IN $parent_element_ids
  AND type(relationship) = $relationship_type
OPTIONAL MATCH (child)-[:TAGGED_WITH]->(tag:Tag)
WITH parent, child, relationship,
     [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
WITH parent, child, relationship, graphTags,
     CASE WHEN size(graphTags) > 0 THEN graphTags ELSE coalesce(child.tags, []) END AS effectiveTags` +
		compiledFilter.whereClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH parent, child, relationship, graphTags, emoji
ORDER BY elementId(parent), child.slug, child.path, elementId(relationship), emoji.id
WITH parent, child, relationship, graphTags,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN elementId(parent) AS parent_element_id,
       elementId(child) AS child_element_id,
       child.id AS id, child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE child.tags END AS tags,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis,
       elementId(relationship) AS relationship_id
ORDER BY parent_element_id, child.slug, child.path, relationship_id`
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)

	rootMatch := "MATCH (child)"
	rootParameters := make(map[string]any, len(compiledRootFilter.parameters))
	rootFilterClause := compiledRootFilter.whereClause
	for name, value := range compiledRootFilter.parameters {
		rootParameters[name] = value
	}
	if rootNodeID != "" {
		rootMatch = "MATCH (child {id: $root_node_id})"
		rootParameters = map[string]any{"root_node_id": rootNodeID}
		rootFilterClause = ""
	}
	rootQuery := rootMatch + `
WHERE NOT child:Tag
  AND NOT child:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(child) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(child) }
OPTIONAL MATCH (child)-[:TAGGED_WITH]->(tag:Tag)
WITH child, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
WITH child, graphTags,
     CASE WHEN size(graphTags) > 0 THEN graphTags ELSE coalesce(child.tags, []) END AS effectiveTags` +
		rootFilterClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH child, graphTags, emoji
ORDER BY emoji.id
WITH child, graphTags,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN elementId(child) AS node_element_id,
       child.id AS id, child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE child.tags END AS tags,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis
ORDER BY size(coalesce(toString(child.slug), '')), child.slug, child.path,
         child.id, node_element_id`
	rootTraceStarted := s.startQueryTrace("node_tree.root", rootQuery, rootParameters)
	rootResult, err := session.Run(ctx, rootQuery, rootParameters)
	rootDispatchDuration := queryTraceDuration(rootTraceStarted)
	if err != nil {
		s.logQueryRunError("node_tree.root", rootTraceStarted, err)
		return nil, fmt.Errorf("query radial tree root: %w", err)
	}
	type storedOccurrence struct {
		occurrence *nodesv1.NodeTreeOccurrence
		elementID  string
	}
	type storedChild struct {
		node      *nodev2.Node
		elementID string
	}
	tree := &nodesv1.NodeTree{
		Relationship: relationshipType,
		Depth:        depth,
	}
	current := make([]storedOccurrence, 0)
	for rootResult.Next(ctx) {
		rootRecord := rootResult.Record()
		root := nodeFromRecord(rootRecord)
		rootElementID, ok := recordString(rootRecord, "node_element_id")
		if !ok || rootElementID == "" {
			return nil, fmt.Errorf("read node tree root: invalid internal locator")
		}
		rootOccurrence := &nodesv1.NodeTreeOccurrence{
			OccurrenceId: strconv.Itoa(len(current)),
			Depth:        0,
			Node:         root,
		}
		tree.Occurrences = append(tree.Occurrences, rootOccurrence)
		current = append(current, storedOccurrence{
			occurrence: rootOccurrence,
			elementID:  rootElementID,
		})
		if s.queryLog {
			slog.Info(
				"neo4j node tree root selected",
				"slug", root.GetSlug(),
				"labels", root.GetLabels(),
				"element_id", rootElementID,
			)
		}
	}
	if err := rootResult.Err(); err != nil {
		s.logQueryRunError("node_tree.root", rootTraceStarted, err)
		return nil, fmt.Errorf("read radial tree root: %w", err)
	}
	if err := s.finishQueryTrace(
		ctx,
		"node_tree.root",
		rootTraceStarted,
		rootDispatchDuration,
		len(current),
		rootResult,
	); err != nil {
		return nil, fmt.Errorf("read radial tree root summary: %w", err)
	}
	if len(current) == 0 {
		return nil, ErrNodeNotFound
	}
	if len(current) == 1 {
		tree.RootNodeId = current[0].occurrence.GetNode().GetId()
	}

	for level := uint32(1); level != 0 && level <= depth && len(current) > 0; level++ {
		parentElementIDs := make([]string, 0, len(current))
		seenParentElementIDs := make(map[string]struct{}, len(current))
		for _, stored := range current {
			if _, seen := seenParentElementIDs[stored.elementID]; seen {
				continue
			}
			seenParentElementIDs[stored.elementID] = struct{}{}
			parentElementIDs = append(parentElementIDs, stored.elementID)
		}

		parameters := map[string]any{
			"parent_element_ids": parentElementIDs,
			"relationship_type":  relationshipName,
		}
		for name, value := range compiledFilter.parameters {
			parameters[name] = value
		}
		operation := fmt.Sprintf("node_tree.depth_%d", level)
		traceStarted := s.startQueryTrace(operation, childQuery, parameters)
		result, err := session.Run(ctx, childQuery, parameters)
		dispatchDuration := queryTraceDuration(traceStarted)
		if err != nil {
			s.logQueryRunError(operation, traceStarted, err)
			return nil, fmt.Errorf("query radial tree depth %d: %w", level, err)
		}
		childrenByParent := make(map[string][]storedChild)
		recordCount := 0
		for result.Next(ctx) {
			recordCount++
			record := result.Record()
			parentElementID, _ := recordString(record, "parent_element_id")
			childElementID, _ := recordString(record, "child_element_id")
			childrenByParent[parentElementID] = append(
				childrenByParent[parentElementID],
				storedChild{node: nodeFromRecord(record), elementID: childElementID},
			)
		}
		if err := result.Err(); err != nil {
			s.logQueryRunError(operation, traceStarted, err)
			return nil, fmt.Errorf("read radial tree depth %d: %w", level, err)
		}
		if err := s.finishQueryTrace(
			ctx,
			operation,
			traceStarted,
			dispatchDuration,
			recordCount,
			result,
		); err != nil {
			return nil, fmt.Errorf("read radial tree depth %d summary: %w", level, err)
		}

		next := make([]storedOccurrence, 0)
		for _, storedParent := range current {
			for childIndex, child := range childrenByParent[storedParent.elementID] {
				parentOccurrenceID := storedParent.occurrence.OccurrenceId
				occurrence := &nodesv1.NodeTreeOccurrence{
					OccurrenceId:       fmt.Sprintf("%s/%d", parentOccurrenceID, childIndex),
					ParentOccurrenceId: &parentOccurrenceID,
					Depth:              level,
					Node:               child.node,
				}
				tree.Occurrences = append(tree.Occurrences, occurrence)
				next = append(next, storedOccurrence{occurrence: occurrence, elementID: child.elementID})
			}
		}
		current = next
	}

	return tree, nil
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
	query := `MATCH (child)
WHERE child.slug IS NOT NULL AND trim(toString(child.slug)) <> ''
  AND NOT child:Tag
  AND NOT child:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(child) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(child) }
OPTIONAL MATCH (child)-[:TAGGED_WITH]->(tag:Tag)
WITH child, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
WITH child, graphTags,
     CASE WHEN size(graphTags) > 0 THEN graphTags ELSE coalesce(child.tags, []) END AS effectiveTags` +
		compiledFilter.whereClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH child, graphTags, emoji
ORDER BY child.slug, child.path, emoji.id
WITH child, graphTags,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN child.id AS id, child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE child.tags END AS tags,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis
ORDER BY child.slug, child.path
LIMIT $limit`
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
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

// MutateNodes is the single store boundary for canonical Node updates. The
// selection and mutation are compiled together so update_count changes in the
// same transaction and cannot be accidentally added to a read query.
func (s *Neo4jStore) MutateNodes(
	ctx context.Context,
	filter *nodesv1.NodeSearchFilter,
	mutation NodeMutation,
) (uint64, error) {
	query, parameters, err := compileNodeMutation(filter, mutation)
	if err != nil {
		return 0, err
	}
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	result, err := session.Run(ctx, query, parameters)
	if err != nil {
		return 0, fmt.Errorf("mutate Nodes: %w", err)
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			return 0, fmt.Errorf("read Node mutation result: %w", err)
		}
		return 0, fmt.Errorf("read Node mutation result: empty result")
	}
	mutatedNodeCount, ok := recordInt64(result.Record(), "mutated_node_count")
	if !ok || mutatedNodeCount < 0 {
		return 0, fmt.Errorf("read Node mutation result: invalid mutated_node_count")
	}
	if _, err := result.Consume(ctx); err != nil {
		return 0, fmt.Errorf("consume Node mutation result: %w", err)
	}
	return uint64(mutatedNodeCount), nil
}

func compileNodeMutation(
	filter *nodesv1.NodeSearchFilter,
	mutation NodeMutation,
) (string, map[string]any, error) {
	if filter == nil ||
		(len(filter.GetIncludeNodesMatching()) == 0 &&
			len(filter.GetExcludeNodesMatching()) == 0) {
		return "", nil, fmt.Errorf("%w: node_filter is required", ErrInvalidNodeMutation)
	}
	if len(mutation.SetProperties) == 0 {
		return "", nil, fmt.Errorf("%w: set properties are required", ErrInvalidNodeMutation)
	}
	for property := range mutation.SetProperties {
		if strings.TrimSpace(property) == "" {
			return "", nil, fmt.Errorf("%w: property names must not be empty", ErrInvalidNodeMutation)
		}
		if property == "update_count" {
			return "", nil, fmt.Errorf("%w: update_count is managed by the store", ErrInvalidNodeMutation)
		}
	}
	compiledFilter, err := compileNodeSearchFilter(filter)
	if err != nil {
		return "", nil, err
	}
	parameters := make(map[string]any, len(compiledFilter.parameters)+1)
	for name, value := range compiledFilter.parameters {
		parameters[name] = value
	}
	parameters["set_properties"] = mutation.SetProperties
	query := `MATCH (child)
WHERE child.slug IS NOT NULL AND trim(toString(child.slug)) <> ''
  AND NOT child:Tag
  AND NOT child:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(child) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(child) }
OPTIONAL MATCH (child)-[:TAGGED_WITH]->(tag:Tag)
WITH child, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
WITH child,
     CASE WHEN size(graphTags) > 0 THEN graphTags ELSE coalesce(child.tags, []) END AS effectiveTags` +
		compiledFilter.whereClause + `
WITH DISTINCT child
SET child += $set_properties,
    child.update_count = coalesce(toInteger(child.update_count), 0) + 1
RETURN count(child) AS mutated_node_count`
	return query, parameters, nil
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
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_ID,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_PATH,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TITLE,
		nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TAG,
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
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_ID:
		valueExpression = "coalesce(toString(child.id), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_PATH:
		valueExpression = "coalesce(toString(child.path), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TITLE:
		valueExpression = "coalesce(toString(child.title), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_SLUG:
		valueExpression = "coalesce(toString(child.slug), '')"
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_TAG:
		valueExpression = "effectiveTags"
		isList = true
	case nodesv1.NodeParameterType_NODE_PARAMETER_TYPE_LABEL:
		valueExpression = "labels(child)"
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

func neo4jRelationshipName(relationshipType nodesv1.NodeRelationshipType) (string, error) {
	switch relationshipType {
	case nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_PART_OF:
		return "PART_OF", nil
	case nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_FAMILY:
		return "FAMILY", nil
	default:
		return "", fmt.Errorf("unsupported Node tree relationship type: %s", relationshipType)
	}
}

func (s *Neo4jStore) ImportNew(ctx context.Context, snapshot *nodev2.NodeSnapshot) error {
	nodes := make([]map[string]any, 0, len(snapshot.Nodes))
	for _, node := range snapshot.Nodes {
		tags, _ := json.Marshal(node.Tags)
		frontmatter, _ := json.Marshal(node.Frontmatter)
		row := map[string]any{
			"id": node.Id, "path": node.Path, "title": node.Title,
			"body": node.Body, "tags": node.Tags, "tags_json": string(tags),
			"frontmatter_json": string(frontmatter),
			"modified_at":      node.ModifiedAt.AsTime().UnixNano(),
		}
		for key, value := range node.Frontmatter {
			if _, protected := row[key]; !protected {
				row[key] = value
			}
		}
		nodes = append(nodes, row)
	}
	warningsJSON, _ := json.Marshal(snapshot.Warnings)
	taggings := make([]map[string]any, 0)
	for _, node := range snapshot.Nodes {
		for _, tag := range node.Tags {
			taggings = append(taggings, map[string]any{
				"note_id": node.Id,
				"tag_id":  tag,
				"weight":  1.0,
			})
		}
	}
	resolvedConnections := make([]map[string]any, 0, len(snapshot.Connections))
	unresolvedConnections := make([]map[string]any, 0)
	for index, connection := range snapshot.Connections {
		row := map[string]any{
			"index": int64(index), "source": connection.SourceNodeId,
			"target_text": connection.TargetText, "display_text": stringValue(connection.DisplayText),
			"kind": int64(connection.Kind), "fragment": stringValue(connection.Fragment),
		}
		if connection.TargetNodeId == nil {
			unresolvedConnections = append(unresolvedConnections, row)
			continue
		}
		row["target"] = *connection.TargetNodeId
		resolvedConnections = append(resolvedConnections, row)
	}

	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	_, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		queries := []struct {
			cypher string
			params map[string]any
		}{
			{`UNWIND $nodes AS row
MERGE (node {id: row.id})
ON CREATE SET node = row, node.import_revision = $revision`, map[string]any{"nodes": nodes, "revision": snapshot.Revision}},
			{`UNWIND $taggings AS row
MATCH (node {id: row.note_id})
MERGE (tag:Tag {id: row.tag_id})
ON CREATE SET tag.name = row.tag_id
MERGE (node)-[tagging:TAGGED_WITH]->(tag)
			ON CREATE SET tagging.weight = row.weight, tagging.source = 'markdown'`, map[string]any{"taggings": taggings}},
			{`UNWIND $connections AS row
MATCH (source {id: row.source})
MATCH (target {id: row.target})
WHERE source.import_revision = $revision
MERGE (source)-[connection:LINKS_TO {index: row.index}]->(target)
			SET connection = row`, map[string]any{"connections": resolvedConnections, "revision": snapshot.Revision}},
			{`UNWIND $connections AS row
MATCH (source {id: row.source})
WHERE source.import_revision = $revision
MERGE (connection:SevilleUnresolvedLink {source: row.source, index: row.index})
SET connection = row
MERGE (source)-[:HAS_UNRESOLVED_LINK]->(connection)`, map[string]any{"connections": unresolvedConnections, "revision": snapshot.Revision}},
			{`MERGE (state:SevilleScanState {singleton: true})
SET state.revision = $revision, state.generated_at = $generated_at,
    state.warnings_json = $warnings_json`, map[string]any{
				"revision":      snapshot.Revision,
				"generated_at":  snapshot.GeneratedAt.AsTime().UnixNano(),
				"warnings_json": string(warningsJSON),
			}},
		}
		for _, query := range queries {
			result, err := tx.Run(ctx, query.cypher, query.params)
			if err != nil {
				return nil, err
			}
			if _, err := result.Consume(ctx); err != nil {
				return nil, err
			}
		}
		return nil, nil
	})
	if err != nil {
		return fmt.Errorf("import vault into neo4j: %w", err)
	}
	return nil
}

func (s *Neo4jStore) Snapshot(ctx context.Context) (*nodev2.NodeSnapshot, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
	result, err := session.Run(ctx, `MATCH (state:SevilleScanState {singleton: true})
RETURN state.revision AS revision, state.generated_at AS generated_at,
       state.warnings_json AS warnings_json`, nil)
	if err != nil {
		return nil, fmt.Errorf("query neo4j snapshot: %w", err)
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			return nil, fmt.Errorf("read neo4j snapshot: %w", err)
		}
		return nil, ErrSnapshotUnavailable
	}
	record := result.Record()
	revision, _ := record.Get("revision")
	generatedAt, _ := record.Get("generated_at")
	warningsJSON, _ := record.Get("warnings_json")
	snapshot := &nodev2.NodeSnapshot{Revision: revision.(string)}
	if nanos, ok := generatedAt.(int64); ok {
		snapshot.GeneratedAt = timestamppb.New(time.Unix(0, nanos).UTC())
	}
	if raw, ok := warningsJSON.(string); ok {
		_ = json.Unmarshal([]byte(raw), &snapshot.Warnings)
	}
	if err := s.readNodes(ctx, session, snapshot); err != nil {
		return nil, err
	}
	if err := s.readLinks(ctx, session, snapshot); err != nil {
		return nil, err
	}
	return snapshot, nil
}

func (s *Neo4jStore) readNodes(ctx context.Context, session neo4j.Session, snapshot *nodev2.NodeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (node)
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> ''
  AND NOT node:Tag
  AND NOT node:Emoji
  AND NOT EXISTS { MATCH ()-[:TAGGED_WITH]->(node) }
  AND NOT EXISTS { MATCH ()-[:HAS_EMOJI]->(node) }
OPTIONAL MATCH (node)-[:TAGGED_WITH]->(tag:Tag)
WITH node, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
OPTIONAL MATCH (node)-[:HAS_EMOJI]->(emoji)
WITH node, graphTags, emoji
ORDER BY node.path, emoji.id
WITH node, graphTags,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN node.id AS id, node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body,
       labels(node) AS labels,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE node.tags END AS tags,
       node.frontmatter_json AS frontmatter_json,
       node.modified_at AS modified_at, properties(node) AS properties,
       emojis
ORDER BY node.path`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j nodes: %w", err)
	}
	for result.Next(ctx) {
		snapshot.Nodes = append(snapshot.Nodes, nodeFromRecord(result.Record()))
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j nodes: %w", err)
	}
	return nil
}

func nodeFromRecord(record *neo4j.Record) *nodev2.Node {
	node := &nodev2.Node{}
	node.Id, _ = recordString(record, "id")
	node.Slug, _ = recordString(record, "slug")
	node.Slug = strings.TrimSpace(node.Slug)
	node.Path, _ = recordString(record, "path")
	node.Title, _ = recordString(record, "title")
	node.Body, _ = recordString(record, "body")
	node.Labels = recordStrings(record, "labels")
	if values, ok := record.Get("tags"); ok {
		if items, ok := values.([]any); ok {
			for _, item := range items {
				if value, ok := item.(string); ok {
					node.Tags = append(node.Tags, value)
				}
			}
		}
	}
	if raw, ok := recordString(record, "frontmatter_json"); ok {
		_ = json.Unmarshal([]byte(raw), &node.Frontmatter)
	}
	if node.Frontmatter == nil {
		node.Frontmatter = make(map[string]string)
	}
	if properties, ok := record.Get("properties"); ok {
		if values, ok := properties.(map[string]any); ok {
			if updateCount, ok := mapInt64(values, "update_count"); ok && updateCount >= 0 {
				node.UpdateCount = uint64(updateCount)
			}
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
	case "id", "slug", "path", "title", "body", "tags", "tags_json", "frontmatter_json", "modified_at", "import_revision", "update_count":
		return true
	default:
		return false
	}
}

func (s *Neo4jStore) readLinks(ctx context.Context, session neo4j.Session, snapshot *nodev2.NodeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (source)-[connection:LINKS_TO]->(target)
RETURN source.id AS source, target.id AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
UNION ALL
MATCH (source)-[:HAS_UNRESOLVED_LINK]->(connection:SevilleUnresolvedLink)
RETURN source.id AS source, null AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
ORDER BY source, index`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j connections: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		targetText, _ := recordString(record, "target_text")
		connection := &nodev2.NodeConnection{SourceNodeId: source, TargetText: targetText}
		if value, ok := record.Get("target"); ok {
			if target, ok := value.(string); ok {
				connection.TargetNodeId = &target
			}
		}
		if value, ok := record.Get("display_text"); ok {
			if text, ok := value.(string); ok {
				connection.DisplayText = &text
			}
		}
		if value, ok := record.Get("fragment"); ok {
			if text, ok := value.(string); ok {
				connection.Fragment = &text
			}
		}
		if value, ok := record.Get("kind"); ok {
			if kind, ok := value.(int64); ok {
				connection.Kind = nodev2.NodeConnectionKind(kind)
			}
		}
		snapshot.Connections = append(snapshot.Connections, connection)
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j connections: %w", err)
	}
	return nil
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
