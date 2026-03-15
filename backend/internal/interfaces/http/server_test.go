package httpserver

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	appsample "github.com/toheart/go-react-openspec-starter/backend/internal/application/sample"
	"github.com/toheart/go-react-openspec-starter/backend/internal/infrastructure/storage/memory"
	"github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http/handler"

	"github.com/toheart/go-react-openspec-starter/backend/conf"
)

type envelope[T any] struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    T      `json:"data"`
}

type samplePayload struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Summary  string `json:"summary"`
	Category string `json:"category"`
	Status   string `json:"status"`
	Updated  string `json:"updatedAt"`
}

func TestServerSampleRoutes(t *testing.T) {
	t.Parallel()

	server := buildTestServer()

	t.Run("healthz uses the shared response envelope", func(t *testing.T) {
		t.Parallel()

		request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
		recorder := httptest.NewRecorder()

		server.server.Handler.ServeHTTP(recorder, request)

		if recorder.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", recorder.Code)
		}

		var payload envelope[map[string]string]
		if err := json.Unmarshal(recorder.Body.Bytes(), &payload); err != nil {
			t.Fatalf("unmarshal healthz response: %v", err)
		}

		if payload.Code != 0 {
			t.Fatalf("expected business code 0, got %d", payload.Code)
		}

		if payload.Message != "success" {
			t.Fatalf("expected message success, got %q", payload.Message)
		}

		if payload.Data["status"] != "ok" {
			t.Fatalf("expected health status ok, got %q", payload.Data["status"])
		}
	})

	t.Run("sample route returns starter sample items", func(t *testing.T) {
		t.Parallel()

		request := httptest.NewRequest(http.MethodGet, "/api/v1/samples", nil)
		recorder := httptest.NewRecorder()

		server.server.Handler.ServeHTTP(recorder, request)

		if recorder.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", recorder.Code)
		}

		var payload envelope[[]samplePayload]
		if err := json.Unmarshal(recorder.Body.Bytes(), &payload); err != nil {
			t.Fatalf("unmarshal sample response: %v", err)
		}

		if payload.Code != 0 {
			t.Fatalf("expected business code 0, got %d", payload.Code)
		}

		if payload.Message != "success" {
			t.Fatalf("expected message success, got %q", payload.Message)
		}

		if len(payload.Data) != 3 {
			t.Fatalf("expected 3 sample items, got %d", len(payload.Data))
		}

		if payload.Data[0].ID == "" || payload.Data[0].Name == "" {
			t.Fatalf("expected first sample item to contain id and name")
		}
	})
}

func buildTestServer() *Server {
	cfg := conf.Config{
		App: conf.AppConfig{
			Name:    "go-react-openspec-starter",
			RunMode: "test",
		},
		HTTP: conf.HTTPConfig{
			Host: "127.0.0.1",
			Port: 8080,
		},
	}

	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := memory.NewSampleRepository()
	service := appsample.NewService(repo)
	sampleHandler := handler.NewSampleHandler(service)

	return New(cfg, logger, sampleHandler)
}
