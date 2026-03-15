package httpserver

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/toheart/go-react-openspec-starter/backend/conf"
	"github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http/handler"
	"github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http/response"
)

type Server struct {
	logger *slog.Logger
	server *http.Server
}

func New(cfg conf.Config, logger *slog.Logger, sampleHandler *handler.SampleHandler) *Server {
	if cfg.App.RunMode == "prod" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.GET("/healthz", func(c *gin.Context) {
		response.Success(c, gin.H{"status": "ok"})
	})

	api := router.Group("/api/v1")
	sampleHandler.RegisterRoutes(api)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      router,
		ReadTimeout:  cfg.HTTP.ReadTimeoutDuration(),
		WriteTimeout: cfg.HTTP.WriteTimeoutDuration(),
		IdleTimeout:  cfg.HTTP.IdleTimeoutDuration(),
	}

	return &Server{
		logger: logger,
		server: server,
	}
}

func (s *Server) Start() error {
	if err := s.server.ListenAndServe(); err != nil {
		return fmt.Errorf("listen and serve: %w", err)
	}

	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	s.logger.InfoContext(ctx, "shutting down http server")

	if err := s.server.Shutdown(ctx); err != nil {
		return fmt.Errorf("shutdown http server: %w", err)
	}

	return nil
}
