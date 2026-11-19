package server

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/Matey2010/seville/backend/internal/store"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
)

func (s *Server) searchLabels(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.LabelSearchQuery{}
	if err := readProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_label_search", err.Error())
		return
	}
	limit := request.GetLimit()
	if limit == 0 {
		limit = 100
	}
	result, err := s.store.SearchLabels(r.Context(), request.GetPrefix(), limit)
	if errors.Is(err, store.ErrInvalidLabel) {
		s.writeError(w, http.StatusBadRequest, "invalid_label_search", err.Error())
		return
	}
	if err != nil {
		slog.Error("search labels failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "Labels could not be loaded.")
		return
	}
	s.writeProto(w, http.StatusOK, result)
}

func (s *Server) replaceNodeLabels(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.NodeLabelsUpdateRequest{}
	if err := readProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_labels", err.Error())
		return
	}
	slug := strings.TrimSpace(r.PathValue("slug"))
	node, err := s.store.ReplaceNodeLabels(r.Context(), slug, request.GetLabels(), request.GetExpectedUpdateCount())
	if s.writeLabelError(w, err) {
		return
	}
	s.writeProto(w, http.StatusOK, node)
}

func (s *Server) renameLabel(w http.ResponseWriter, r *http.Request) {
	request := &nodesv1.LabelRenameRequest{}
	if err := readRequiredProtoBody(r, request); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid_label", err.Error())
		return
	}
	count, err := s.store.RenameLabel(r.Context(), r.PathValue("name"), request.GetNewName())
	if s.writeLabelError(w, err) {
		return
	}
	s.writeProto(w, http.StatusOK, &nodesv1.LabelMutationResult{ChangedNodeCount: count})
}

func (s *Server) deleteLabel(w http.ResponseWriter, r *http.Request) {
	count, err := s.store.DeleteLabel(r.Context(), r.PathValue("name"))
	if s.writeLabelError(w, err) {
		return
	}
	s.writeProto(w, http.StatusOK, &nodesv1.LabelMutationResult{ChangedNodeCount: count})
}

func (s *Server) writeLabelError(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}
	switch {
	case errors.Is(err, store.ErrInvalidLabel):
		s.writeError(w, http.StatusBadRequest, "invalid_label", err.Error())
	case errors.Is(err, store.ErrNodeNotFound), errors.Is(err, store.ErrLabelNotFound):
		s.writeError(w, http.StatusNotFound, "not_found", err.Error())
	case errors.Is(err, store.ErrNodeConflict), errors.Is(err, store.ErrLabelConflict), errors.Is(err, store.ErrAmbiguousNodeSlug):
		s.writeError(w, http.StatusConflict, "conflict", err.Error())
	default:
		slog.Error("label operation failed", "error", err)
		s.writeError(w, http.StatusInternalServerError, "storage_error", "The label change could not be saved.")
	}
	return true
}
