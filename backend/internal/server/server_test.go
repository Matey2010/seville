package server

import (
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"

	"github.com/Matey2010/seville/backend/internal/store"
	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
	"google.golang.org/protobuf/proto"
)

func TestAuthenticatedSnapshot(t *testing.T) {
	database, err := store.Open(filepath.Join(t.TempDir(), "seville.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()

	app := New(database, filepath.Join("..", "..", "testdata", "vault"), "secret")
	if err := app.InitialScan(); err != nil {
		t.Fatal(err)
	}

	unauthorized := httptest.NewRecorder()
	app.Handler().ServeHTTP(unauthorized, httptest.NewRequest(http.MethodGet, "/v1/snapshot", nil))
	if unauthorized.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d", unauthorized.Code)
	}

	request := httptest.NewRequest(http.MethodGet, "/v1/snapshot", nil)
	request.Header.Set("Authorization", "Bearer secret")
	response := httptest.NewRecorder()
	app.Handler().ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("snapshot status = %d", response.Code)
	}
	var snapshot knowledgev1.KnowledgeSnapshot
	if err := proto.Unmarshal(response.Body.Bytes(), &snapshot); err != nil {
		t.Fatal(err)
	}
	if len(snapshot.Notes) != 2 {
		t.Fatalf("notes = %d", len(snapshot.Notes))
	}

	cachedRequest := httptest.NewRequest(http.MethodGet, "/v1/snapshot", nil)
	cachedRequest.Header.Set("Authorization", "Bearer secret")
	cachedRequest.Header.Set("If-None-Match", response.Header().Get("ETag"))
	cachedResponse := httptest.NewRecorder()
	app.Handler().ServeHTTP(cachedResponse, cachedRequest)
	if cachedResponse.Code != http.StatusNotModified {
		t.Fatalf("cached status = %d", cachedResponse.Code)
	}
}

func TestLocalBrowserPreflight(t *testing.T) {
	app := New(nil, "", "secret")
	request := httptest.NewRequest(http.MethodOptions, "/v1/status", nil)
	request.Header.Set("Origin", "http://localhost:54321")
	response := httptest.NewRecorder()

	app.Handler().ServeHTTP(response, request)

	if response.Code != http.StatusNoContent {
		t.Fatalf("preflight status = %d, want %d", response.Code, http.StatusNoContent)
	}
	if got := response.Header().Get("Access-Control-Allow-Origin"); got != "http://localhost:54321" {
		t.Fatalf("allow origin = %q", got)
	}
}
