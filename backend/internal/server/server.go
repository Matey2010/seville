package server

import (
	"crypto/subtle"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/Matey2010/seville/backend/internal/store"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	"google.golang.org/protobuf/proto"
)

type Server struct {
	store store.NodeService
	token string
}

func New(store store.NodeService, token string) *Server {
	return &Server{store: store, token: token}
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok\n"))
	})
	mux.Handle("GET /v2/status", s.auth(http.HandlerFunc(s.status)))
	mux.Handle("GET /v2/snapshot", s.auth(http.HandlerFunc(s.snapshot)))
	mux.Handle("GET /system/v1/info", s.auth(http.HandlerFunc(s.systemInfo)))
	mux.Handle("QUERY /api/v1/node/search", s.auth(http.HandlerFunc(s.nodeSearch)))
	mux.Handle("POST /api/v1/node/{$}", s.auth(http.HandlerFunc(s.createNode)))
	mux.Handle("PATCH /api/v1/node/{$}", s.auth(http.HandlerFunc(s.mutateNodes)))
	nodeTreeHandler := s.auth(http.HandlerFunc(s.nodeTree))
	mux.Handle("QUERY /api/v1/node/tree", nodeTreeHandler)
	mux.Handle("GET /api/v1/node/tree", nodeTreeHandler)
	return localCORS(mux)
}

func (s *Server) createNode(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.NodeCreateRequest{}
	if err := readProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_node_create", err.Error())
		return
	}
	node, err := s.store.CreateNode(r.Context(), store.NodeCreate{
		Slug:   request.GetSlug(),
		Labels: request.GetLabels(),
	})
	if errors.Is(err, store.ErrInvalidNodeCreate) {
		s.writeError(w, http.StatusBadRequest, "invalid_node_create", err.Error())
		return
	}
	if errors.Is(err, store.ErrNodeAlreadyExists) {
		s.writeError(w, http.StatusConflict, "node_already_exists", err.Error())
		return
	}
	if err != nil {
		slog.Error("create Node failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The Node could not be created.")
		return
	}
	s.writeProto(w, http.StatusCreated, node)
}

func (s *Server) mutateNodes(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.NodeMutationRequest{}
	if err := readProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_mutation", err.Error())
		return
	}
	if nodeSearchFilterEmpty(request.GetNodeFilter()) {
		s.writeError(w, http.StatusBadRequest, "node_filter_required", "node_filter is required.")
		return
	}
	mutation, err := nodeMutation(request)
	if err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_mutation", err.Error())
		return
	}
	mutatedNodeCount, err := s.store.MutateNodes(
		r.Context(),
		request.GetNodeFilter(),
		mutation,
	)
	if errors.Is(err, store.ErrInvalidNodeSearchParameter) ||
		errors.Is(err, store.ErrInvalidNodeMutation) {
		s.writeError(w, http.StatusBadRequest, "invalid_mutation", err.Error())
		return
	}
	if err != nil {
		slog.Error("mutate Nodes failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "Nodes could not be mutated.")
		return
	}
	s.writeProto(w, http.StatusOK, &nodesv1.NodeMutationResult{
		MutatedNodeCount: mutatedNodeCount,
	})
}

func nodeMutation(request *nodesv1.NodeMutationRequest) (store.NodeMutation, error) {
	properties := make(map[string]any, len(request.GetSetProperties())+len(request.GetRemoveProperties()))
	for property, value := range request.GetSetProperties() {
		if value == nil {
			return store.NodeMutation{}, fmt.Errorf("set_properties[%q] requires a value", property)
		}
		switch typed := value.GetValue().(type) {
		case *nodesv1.NodePropertyValue_StringValue:
			properties[property] = typed.StringValue
		case *nodesv1.NodePropertyValue_IntegerValue:
			properties[property] = typed.IntegerValue
		case *nodesv1.NodePropertyValue_DoubleValue:
			properties[property] = typed.DoubleValue
		case *nodesv1.NodePropertyValue_BooleanValue:
			properties[property] = typed.BooleanValue
		default:
			return store.NodeMutation{}, fmt.Errorf("set_properties[%q] requires a supported scalar value", property)
		}
	}
	for _, property := range request.GetRemoveProperties() {
		property = strings.TrimSpace(property)
		if property == "" {
			return store.NodeMutation{}, fmt.Errorf("remove_properties must not contain empty names")
		}
		if _, exists := properties[property]; exists {
			return store.NodeMutation{}, fmt.Errorf("property %q cannot be set and removed together", property)
		}
		properties[property] = nil
	}
	if len(properties) == 0 {
		return store.NodeMutation{}, fmt.Errorf("at least one property change is required")
	}
	return store.NodeMutation{SetProperties: properties}, nil
}

func (s *Server) nodeSearch(w http.ResponseWriter, r *http.Request) {
	query := &nodesv1.NodeSearchQuery{}
	if err := readProtoBody(r, query); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_query", err.Error())
		return
	}
	if nodeSearchFilterEmpty(query.GetNodeFilter()) {
		s.writeError(w, http.StatusBadRequest, "node_filter_required", "node_filter is required.")
		return
	}
	limit := uint32(20)
	if query.Limit != nil {
		limit = query.GetLimit()
	}
	if limit == 0 || limit > 100 {
		s.writeError(w, http.StatusBadRequest, "invalid_limit", "limit must be between 1 and 100.")
		return
	}
	result, err := s.store.NodeSearch(r.Context(), query.GetNodeFilter(), limit)
	if errors.Is(err, store.ErrInvalidNodeSearchParameter) {
		s.writeError(w, http.StatusBadRequest, "invalid_node_search_parameter", err.Error())
		return
	}
	if err != nil {
		slog.Error("search Nodes failed", "error", err, "limit", limit)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "Nodes could not be searched.")
		return
	}
	s.writeProto(w, http.StatusOK, result)
}

func (s *Server) nodeTree(w http.ResponseWriter, r *http.Request) {
	query, err := readNodeTreeQuery(r)
	if err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_query", err.Error())
		return
	}

	rootNodeID := strings.TrimSpace(query.GetRootNodeId())
	if query.RootNodeId == nil {
		rootNodeID = strings.TrimSpace(r.URL.Query().Get("root_node_id"))
	}
	relationshipType := query.GetTraverseBy()
	ok := supportedNodeTreeRelationshipType(relationshipType)
	if relationshipType == nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_UNSPECIFIED {
		relationshipType, ok = nodeTreeRelationshipType(r.URL.Query().Get("traverse_by"))
	}
	if !ok {
		s.writeError(
			w,
			http.StatusBadRequest,
			"invalid_traverse_by",
			"traverse_by must be one of: part_of, family.",
		)
		return
	}
	rootNodeFilter := query.GetRootNodeFilter()
	if rootNodeID == "" && nodeSearchFilterEmpty(rootNodeFilter) {
		s.writeError(w, http.StatusBadRequest, "root_node_selector_required", "root_node_id or root_node_filter is required.")
		return
	}

	depth := uint64(3)
	if query.Depth != nil {
		depth = uint64(query.GetDepth())
	} else if rawDepth := strings.TrimSpace(r.URL.Query().Get("depth")); rawDepth != "" {
		parsedDepth, err := strconv.ParseUint(rawDepth, 10, 32)
		if err != nil {
			s.writeError(w, http.StatusBadRequest, "invalid_depth", "depth must be an unsigned integer.")
			return
		}
		depth = parsedDepth
	}
	tree, err := s.store.NodeTree(
		r.Context(),
		rootNodeID,
		rootNodeFilter,
		relationshipType,
		query.GetNodeFilter(),
		uint32(depth),
	)
	if errors.Is(err, store.ErrNodeNotFound) {
		s.writeError(w, http.StatusNotFound, "root_node_not_found", "The requested root Node does not exist.")
		return
	}
	if errors.Is(err, store.ErrInvalidNodeSearchParameter) {
		s.writeError(w, http.StatusBadRequest, "invalid_node_search_parameter", err.Error())
		return
	}
	if err != nil {
		slog.Error(
			"read node tree failed",
			"error", err,
			"root_node_id", rootNodeID,
			"root_filter_parameter_count", len(rootNodeFilter.GetIncludeNodesMatching())+len(rootNodeFilter.GetExcludeNodesMatching()),
			"traverse_by", relationshipType,
			"included_parameter_count", len(query.GetNodeFilter().GetIncludeNodesMatching()),
			"excluded_parameter_count", len(query.GetNodeFilter().GetExcludeNodesMatching()),
			"depth", depth,
		)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The Node tree could not be read.")
		return
	}
	s.writeProto(w, http.StatusOK, tree)
}

func nodeSearchFilterEmpty(filter *nodesv1.NodeSearchFilter) bool {
	return filter == nil ||
		(!filter.GetNegated() &&
			len(filter.GetIncludeNodesMatching()) == 0 &&
			len(filter.GetExcludeNodesMatching()) == 0)
}

const maxProtoQueryBytes = 1 << 20

func readNodeTreeQuery(r *http.Request) (*nodesv1.NodeTreeQuery, error) {
	query := &nodesv1.NodeTreeQuery{}
	if err := readProtoBody(r, query); err != nil {
		return nil, err
	}
	return query, nil
}

func readProtoBody(r *http.Request, query proto.Message) error {
	if r.Body == nil {
		return nil
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, maxProtoQueryBytes+1))
	if err != nil {
		return fmt.Errorf("read protobuf query: %w", err)
	}
	if len(body) > maxProtoQueryBytes {
		return fmt.Errorf("protobuf request exceeds %d bytes", maxProtoQueryBytes)
	}
	if len(body) == 0 {
		return nil
	}
	if err := proto.Unmarshal(body, query); err != nil {
		return fmt.Errorf("decode protobuf query: %w", err)
	}
	return nil
}

func supportedNodeTreeRelationshipType(value nodesv1.NodeRelationshipType) bool {
	switch value {
	case nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_PART_OF,
		nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_FAMILY:
		return true
	default:
		return false
	}
}

func nodeTreeRelationshipType(value string) (nodesv1.NodeRelationshipType, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "part_of":
		return nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_PART_OF, true
	case "family":
		return nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_FAMILY, true
	default:
		return nodesv1.NodeRelationshipType_NODE_RELATIONSHIP_TYPE_UNSPECIFIED, false
	}
}

func (s *Server) systemInfo(w http.ResponseWriter, r *http.Request) {
	info, err := s.store.SystemInfo(r.Context())
	if err != nil {
		slog.Error("read system info failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "System information could not be read.")
		return
	}
	s.writeProto(w, http.StatusOK, info)
}

func localCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if strings.HasPrefix(origin, "http://localhost:") || strings.HasPrefix(origin, "http://127.0.0.1:") {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, If-None-Match")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, QUERY, PATCH, DELETE, OPTIONS")
			w.Header().Add("Vary", "Origin")
		}
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) status(w http.ResponseWriter, r *http.Request) {
	snapshot, err := s.store.Snapshot(r.Context())
	if err != nil {
		s.writeStoreError(w, err)
		return
	}
	s.writeProto(w, http.StatusOK, &nodev2.ImportStatus{
		Revision:        snapshot.Revision,
		ImportedAt:      snapshot.GeneratedAt,
		NodeCount:       uint32(len(snapshot.Nodes)),
		ConnectionCount: uint32(len(snapshot.Connections)),
		WarningCount:    uint32(len(snapshot.Warnings)),
	})
}

func (s *Server) snapshot(w http.ResponseWriter, r *http.Request) {
	snapshot, err := s.store.Snapshot(r.Context())
	if err != nil {
		s.writeStoreError(w, err)
		return
	}
	etag := `"` + snapshot.Revision + `"`
	if r.Header.Get("If-None-Match") == etag {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	w.Header().Set("ETag", etag)
	s.writeProto(w, http.StatusOK, snapshot)
}

func (s *Server) auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		const prefix = "Bearer "
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, prefix) ||
			subtle.ConstantTimeCompare([]byte(strings.TrimPrefix(header, prefix)), []byte(s.token)) != 1 {
			w.Header().Set("WWW-Authenticate", "Bearer")
			s.writeError(w, http.StatusUnauthorized, "unauthorized", "A valid bearer token is required.")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) writeStoreError(w http.ResponseWriter, err error) {
	if errors.Is(err, store.ErrSnapshotUnavailable) {
		s.writeError(w, http.StatusServiceUnavailable, "snapshot_unavailable", "No graph snapshot is available.")
		return
	}
	slog.Error("read snapshot failed", "error", err)
	s.writeError(w, http.StatusInternalServerError, "storage_error", "The snapshot could not be read.")
}

func (s *Server) writeError(w http.ResponseWriter, status int, code, message string) {
	s.writeProto(w, status, &nodev2.ApiError{Code: code, Message: message})
}

func (s *Server) writeProto(w http.ResponseWriter, status int, message proto.Message) {
	data, err := proto.Marshal(message)
	if err != nil {
		http.Error(w, "encode response", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/x-protobuf")
	w.WriteHeader(status)
	_, _ = w.Write(data)
}
