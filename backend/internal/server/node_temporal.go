package server

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/Matey2010/seville/backend/internal/store"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
)

func (s *Server) replaceNodeTemporalSpan(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.NodeTemporalUpdateRequest{}
	if err := readRequiredProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_temporal_span", err.Error())
		return
	}
	slug := strings.TrimSpace(r.PathValue("slug"))
	if slug == "" {
		s.writeError(w, http.StatusBadRequest, "invalid_node_slug", "Node slug is required.")
		return
	}
	node, err := s.store.ReplaceNodeTemporalSpan(
		r.Context(), slug, request.Span, request.GetExpectedUpdateCount(),
	)
	switch {
	case errors.Is(err, store.ErrInvalidTemporalSpan):
		s.writeError(w, http.StatusBadRequest, "invalid_temporal_span", err.Error())
	case errors.Is(err, store.ErrNodeNotFound):
		s.writeError(w, http.StatusNotFound, "node_not_found", "The Node does not exist.")
	case errors.Is(err, store.ErrNodeConflict):
		s.writeError(w, http.StatusConflict, "node_conflict", "The Node changed since it was opened.")
	case errors.Is(err, store.ErrAmbiguousNodeSlug):
		s.writeError(w, http.StatusConflict, "ambiguous_node_slug", "More than one Node has this slug.")
	case err != nil:
		slog.Error("replace Node temporal span failed", "error", err, "node_slug", slug)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The Node temporal span could not be saved.")
	default:
		s.writeProto(w, http.StatusOK, node)
	}
}
