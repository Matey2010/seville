package server

import (
	"crypto/subtle"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"

	"github.com/Matey2010/seville/backend/internal/store"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	presentationv1 "github.com/Matey2010/seville/proto/gen/go/seville/presentation/v1"
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
	mux.Handle("QUERY /api/v1/node/search", s.auth(http.HandlerFunc(s.nodeSearch)))
	mux.Handle("QUERY /api/v1/node/graph", s.auth(http.HandlerFunc(s.nodeGraph)))
	mux.Handle("QUERY /api/v1/label/search", s.auth(http.HandlerFunc(s.searchLabels)))
	mux.Handle("PUT /api/v1/node/{slug}/labels", s.auth(http.HandlerFunc(s.replaceNodeLabels)))
	mux.Handle("PUT /api/v1/node/{slug}/temporal", s.auth(http.HandlerFunc(s.replaceNodeTemporalSpan)))
	mux.Handle("PATCH /api/v1/label/{name}", s.auth(http.HandlerFunc(s.renameLabel)))
	mux.Handle("DELETE /api/v1/label/{name}", s.auth(http.HandlerFunc(s.deleteLabel)))
	mux.Handle("GET /api/v1/graph/color-rules", s.auth(http.HandlerFunc(s.nodeColorRules)))
	mux.Handle("PUT /api/v1/graph/color-rules", s.auth(http.HandlerFunc(s.replaceNodeColorRules)))
	mux.Handle("POST /api/v1/node/{$}", s.auth(http.HandlerFunc(s.createNode)))
	mux.Handle("PATCH /api/v1/node/{slug}", s.auth(http.HandlerFunc(s.updateNodeBody)))
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
		Body:   request.GetBody(),
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

func (s *Server) updateNodeBody(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.NodeBodyUpdateRequest{}
	if err := readProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_node_body", err.Error())
		return
	}
	slug := strings.TrimSpace(r.PathValue("slug"))
	if slug == "" {
		s.writeError(w, http.StatusBadRequest, "invalid_node_slug", "Node slug is required.")
		return
	}
	node, err := s.store.UpdateNodeBody(r.Context(), slug, request.GetBody(), request.GetExpectedUpdateCount())
	if errors.Is(err, store.ErrNodeNotFound) {
		s.writeError(w, http.StatusNotFound, "node_not_found", "The Node does not exist.")
		return
	}
	if errors.Is(err, store.ErrNodeConflict) {
		s.writeError(w, http.StatusConflict, "node_conflict", "The Node changed since it was opened.")
		return
	}
	if errors.Is(err, store.ErrAmbiguousNodeSlug) {
		s.writeError(w, http.StatusConflict, "ambiguous_node_slug", "More than one Node has this slug.")
		return
	}
	if err != nil {
		slog.Error("update Node body failed", "error", err, "node_slug", slug)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The Node body could not be saved.")
		return
	}
	s.writeProto(w, http.StatusOK, node)
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

func (s *Server) nodeGraph(w http.ResponseWriter, r *http.Request) {
	query := &nodesv1.NodeGraphQuery{}
	if err := readProtoBody(r, query); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_query", err.Error())
		return
	}
	if query.GetDepth() > 2 || query.GetLimit() < 1 || query.GetLimit() > 200 {
		s.writeError(w, http.StatusBadRequest, "invalid_graph_bounds", "depth must be at most 2 and limit between 1 and 200.")
		return
	}
	if len(query.GetSearch()) > 256 {
		s.writeError(w, http.StatusBadRequest, "invalid_graph_search", "search must be at most 256 bytes.")
		return
	}
	graph, err := s.store.NodeGraph(
		r.Context(), strings.TrimSpace(query.GetRootNodeSlug()),
		strings.TrimSpace(query.GetSearch()), query.GetDepth(), query.GetLimit(),
	)
	if errors.Is(err, store.ErrNodeNotFound) {
		s.writeError(w, http.StatusNotFound, "root_node_not_found", "The requested root Node does not exist.")
		return
	}
	if errors.Is(err, store.ErrAmbiguousNodeSlug) {
		s.writeError(w, http.StatusConflict, "ambiguous_node_slug", "More than one Node has this slug.")
		return
	}
	if err != nil {
		slog.Error("read Node graph failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The Node graph could not be read.")
		return
	}
	s.writeProto(w, http.StatusOK, graph)
}

func (s *Server) nodeColorRules(w http.ResponseWriter, r *http.Request) {
	rules, err := s.store.NodeColorRules(r.Context())
	if err != nil {
		slog.Error("read Node color rules failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "Node color rules could not be read.")
		return
	}
	etag := fmt.Sprintf(`"%d"`, rules.GetRevision())
	if r.Header.Get("If-None-Match") == etag {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	w.Header().Set("ETag", etag)
	s.writeProto(w, http.StatusOK, rules)
}

func (s *Server) replaceNodeColorRules(w http.ResponseWriter, r *http.Request) {
	request := &presentationv1.NodeColorRuleSet{}
	if err := readRequiredProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_color_rules", err.Error())
		return
	}
	rules, err := s.store.ReplaceNodeColorRules(r.Context(), request)
	if errors.Is(err, store.ErrInvalidColorRules) {
		s.writeError(w, http.StatusBadRequest, "invalid_color_rules", err.Error())
		return
	}
	if errors.Is(err, store.ErrColorRulesConflict) {
		s.writeError(w, http.StatusConflict, "color_rules_conflict", "Node color rules changed on another device. Reload before saving.")
		return
	}
	if err != nil {
		slog.Error("replace Node color rules failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "Node color rules could not be saved.")
		return
	}
	w.Header().Set("ETag", fmt.Sprintf(`"%d"`, rules.GetRevision()))
	s.writeProto(w, http.StatusOK, rules)
}

func nodeSearchFilterEmpty(filter *nodesv1.NodeSearchFilter) bool {
	return filter == nil ||
		(!filter.GetNegated() &&
			len(filter.GetIncludeNodesMatching()) == 0 &&
			len(filter.GetExcludeNodesMatching()) == 0)
}

const maxProtoQueryBytes = 1 << 20

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

func readRequiredProtoBody(r *http.Request, message proto.Message) error {
	if r.Body == nil {
		return fmt.Errorf("protobuf request body is required")
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, maxProtoQueryBytes+1))
	if err != nil {
		return fmt.Errorf("read protobuf request: %w", err)
	}
	if len(body) == 0 || len(body) > maxProtoQueryBytes {
		return fmt.Errorf("protobuf request body must contain 1 to %d bytes", maxProtoQueryBytes)
	}
	if err := proto.Unmarshal(body, message); err != nil {
		return fmt.Errorf("decode protobuf request: %w", err)
	}
	return nil
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
