package wire

import (
	"log/slog"

	appsample "github.com/toheart/go-react-openspec-starter/backend/internal/application/sample"
	"github.com/toheart/go-react-openspec-starter/backend/internal/infrastructure/storage/memory"
	httpserver "github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http"
	"github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http/handler"

	"github.com/toheart/go-react-openspec-starter/backend/conf"
)

func BuildHTTPServer(cfg conf.Config, logger *slog.Logger) *httpserver.Server {
	repo := memory.NewSampleRepository()
	service := appsample.NewService(repo)
	sampleHandler := handler.NewSampleHandler(service)

	return httpserver.New(cfg, logger, sampleHandler)
}
