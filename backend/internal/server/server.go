package server

import (
	"crypto/subtle"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/Matey2010/seville/backend/internal/store"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"google.golang.org/protobuf/proto"
)

type Server struct {
	store store.SnapshotReader
	token string
}

func New(store store.SnapshotReader, token string) *Server {
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
	return localCORS(mux)
}

func localCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if strings.HasPrefix(origin, "http://localhost:") || strings.HasPrefix(origin, "http://127.0.0.1:") {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, If-None-Match")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
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
