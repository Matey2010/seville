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
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	systemv1 "github.com/Matey2010/seville/proto/gen/go/seville/system/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var neo4jNodeLabelPattern = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)

const systemInfoLabelLimit = 12

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

func (s *Neo4jStore) SystemInfo(ctx context.Context) (*systemv1.SystemInfo, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
	result, err := session.Run(ctx, `CALL {
  MATCH (candidate:Node)
  WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
  WITH candidate.slug AS slug, collect(candidate) AS matches
  WHERE size(matches) = 1
  WITH matches[0] AS labelled_node
  UNWIND labels(labelled_node) AS label
  WITH label WHERE label <> 'Node'
  WITH label, count(*) AS frequency
  ORDER BY frequency DESC, label
  LIMIT $label_limit
  RETURN collect(label) AS neo4j_labels
}
CALL {
  CALL dbms.components() YIELD name, versions
  WHERE name CONTAINS 'Neo4j'
  RETURN head(collect(head(versions))) AS neo4j_version
}
CALL {
MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
RETURN count(node) AS node_count,
       coalesce(sum(size(keys(node))), 0) AS node_property_count
}
RETURN node_count, node_property_count, neo4j_labels, neo4j_version`, map[string]any{
		"label_limit": systemInfoLabelLimit,
	})
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
	rootNodeSlug string,
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
	childQuery := `MATCH (child:Node)-[relationship]->(parent:Node)
WHERE elementId(parent) IN $parent_element_ids
  AND type(relationship) = $relationship_type
  AND child.slug IS NOT NULL
  AND NOT EXISTS {
    MATCH (duplicate:Node {slug: child.slug})
    WHERE elementId(duplicate) <> elementId(child)
  }
WITH parent, child, relationship` +
		compiledFilter.whereClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH parent, child, relationship, emoji
ORDER BY elementId(parent), child.slug, child.path, elementId(relationship), emoji.id
WITH parent, child, relationship,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN elementId(parent) AS parent_element_id,
       elementId(child) AS child_element_id,
       child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis,
       elementId(relationship) AS relationship_id
ORDER BY parent_element_id, child.slug, child.path, relationship_id`
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)

	rootMatch := "MATCH (candidate:Node)"
	rootParameters := make(map[string]any, len(compiledRootFilter.parameters))
	rootFilterClause := compiledRootFilter.whereClause
	for name, value := range compiledRootFilter.parameters {
		rootParameters[name] = value
	}
	if rootNodeSlug != "" {
		rootMatch = "MATCH (candidate:Node {slug: $root_node_slug})"
		rootParameters = map[string]any{"root_node_slug": rootNodeSlug}
		rootFilterClause = ""
	}
	rootQuery := rootMatch + `
WHERE candidate.slug IS NOT NULL
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS child` +
		rootFilterClause + `
OPTIONAL MATCH (child)-[:HAS_EMOJI]->(emoji)
WITH child, emoji
ORDER BY emoji.id
WITH child,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN elementId(child) AS node_element_id,
       child.slug AS slug, child.path AS path,
       child.title AS title, child.body AS body,
       labels(child) AS labels,
       child.frontmatter_json AS frontmatter_json,
       child.modified_at AS modified_at, properties(child) AS properties,
       emojis
ORDER BY size(coalesce(toString(child.slug), '')), child.slug, child.path,
         node_element_id`
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
		if rootNodeSlug != "" {
			result, err := session.Run(ctx, `MATCH (node:Node {slug: $slug}) RETURN count(node) AS matches`, map[string]any{"slug": rootNodeSlug})
			if err != nil {
				return nil, err
			}
			if !result.Next(ctx) {
				if err := result.Err(); err != nil {
					return nil, fmt.Errorf("read duplicate root slugs: %w", err)
				}
				return nil, ErrNodeNotFound
			}
			matches, _ := recordInt64(result.Record(), "matches")
			if _, err := result.Consume(ctx); err != nil {
				return nil, err
			}
			if matches > 1 {
				return nil, ErrAmbiguousNodeSlug
			}
		}
		return nil, ErrNodeNotFound
	}
	if len(current) == 1 {
		tree.RootNodeSlug = current[0].occurrence.GetNode().GetSlug()
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
	traceStarted := s.startQueryTrace("node_mutation", query, parameters)
	result, err := session.Run(ctx, query, parameters)
	dispatchDuration := queryTraceDuration(traceStarted)
	if err != nil {
		s.logQueryRunError("node_mutation", traceStarted, err)
		return 0, fmt.Errorf("mutate Nodes: %w", err)
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			s.logQueryRunError("node_mutation", traceStarted, err)
			return 0, fmt.Errorf("read Node mutation result: %w", err)
		}
		return 0, fmt.Errorf("read Node mutation result: empty result")
	}
	mutatedNodeCount, ok := recordInt64(result.Record(), "mutated_node_count")
	if !ok || mutatedNodeCount < 0 {
		return 0, fmt.Errorf("read Node mutation result: invalid mutated_node_count")
	}
	if s.queryLog {
		if err := s.finishQueryTrace(
			ctx,
			"node_mutation",
			traceStarted,
			dispatchDuration,
			1,
			result,
		); err != nil {
			return 0, fmt.Errorf("read Node mutation summary: %w", err)
		}
	} else if _, err := result.Consume(ctx); err != nil {
		return 0, fmt.Errorf("consume Node mutation result: %w", err)
	}
	return uint64(mutatedNodeCount), nil
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
	defer session.Close(ctx)
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
		createdValue, ok := record.Get("created")
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
		if property == "body" {
			return "", nil, fmt.Errorf("%w: edit body through the Node resource so connections stay synchronized", ErrInvalidNodeMutation)
		}
		if property == "temporal_start" || property == "temporal_end_exclusive" || property == "temporal_granularity" || property == "temporal_placement_disabled" {
			return "", nil, fmt.Errorf("%w: edit temporal data through the Node temporal resource", ErrInvalidNodeMutation)
		}
		if property == "tags" || property == "tags_json" {
			return "", nil, fmt.Errorf("%w: labels are the Node classification system", ErrInvalidNodeMutation)
		}
		if property == "id" || property == "slug" {
			return "", nil, fmt.Errorf("%w: Node identity cannot be changed through a filter mutation", ErrInvalidNodeMutation)
		}
		if property == "counter" {
			return "", nil, fmt.Errorf("%w: legacy counter is not mutable", ErrInvalidNodeMutation)
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
	query := `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS child` +
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
	result, err := session.Run(ctx, `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
OPTIONAL MATCH (node)-[:HAS_EMOJI]->(emoji)
WITH node, emoji
ORDER BY node.path, emoji.id
WITH node,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body,
       labels(node) AS labels,
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

func (s *Neo4jStore) readLinks(ctx context.Context, session neo4j.Session, snapshot *nodev2.NodeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (source:Node)-[connection:LINKS_TO]->(target:Node)
RETURN source.slug AS source, target.slug AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
UNION ALL
MATCH (source:Node)-[:HAS_UNRESOLVED_LINK]->(connection:SevilleUnresolvedLink)
RETURN source.slug AS source, null AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
ORDER BY source, index`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j connections: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		targetText, _ := recordString(record, "target_text")
		connection := &nodev2.NodeConnection{SourceNodeSlug: source, TargetText: targetText}
		if value, ok := record.Get("target"); ok {
			if target, ok := value.(string); ok {
				connection.TargetNodeSlug = &target
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
