package main

import (
	"context"
	"errors"
	"fmt"
	nethttp "net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/spf13/cobra"

	"github.com/toheart/go-react-openspec-starter/backend/conf"
	"github.com/toheart/go-react-openspec-starter/backend/internal/logging"
	"github.com/toheart/go-react-openspec-starter/backend/internal/wire"
)

func newServerCmd() *cobra.Command {
	var (
		runMode    string
		configPath string
	)

	cmd := &cobra.Command{
		Use:   "server",
		Short: "Start the HTTP server",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := conf.Load(configPath, runMode)
			if err != nil {
				return fmt.Errorf("load config: %w", err)
			}

			logger := logging.New(cfg.Log, cfg.App.Name)
			httpServer := wire.BuildHTTPServer(cfg, logger)

			errCh := make(chan error, 1)
			go func() {
				if err := httpServer.Start(); err != nil && !errors.Is(err, nethttp.ErrServerClosed) {
					errCh <- err
				}
			}()

			logger.Info("server started", "addr", cfg.HTTP.Address(), "runMode", cfg.App.RunMode)

			ctx, stop := signal.NotifyContext(cmd.Context(), syscall.SIGINT, syscall.SIGTERM)
			defer stop()

			select {
			case <-ctx.Done():
				logger.Info("shutdown signal received")
			case err := <-errCh:
				return fmt.Errorf("http server exited: %w", err)
			}

			shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			if err := httpServer.Shutdown(shutdownCtx); err != nil {
				return fmt.Errorf("shutdown http server: %w", err)
			}

			logger.Info("server stopped")
			return nil
		},
	}

	cmd.Flags().StringVar(&runMode, "run-mode", "dev", "Run mode: dev or prod")
	cmd.Flags().StringVar(&configPath, "configs", "", "Path to the YAML config file")

	return cmd
}
