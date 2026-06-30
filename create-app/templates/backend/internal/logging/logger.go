package logging

import (
	"log/slog"
	"os"
	"strings"

	"github.com/toheart/go-react-openspec-starter/backend/conf"
)

func New(cfg conf.LogConfig, appName string) *slog.Logger {
	opts := &slog.HandlerOptions{
		AddSource: cfg.AddSource,
		Level:     parseLevel(cfg.Level),
	}

	var handler slog.Handler
	if strings.EqualFold(cfg.Format, "text") {
		handler = slog.NewTextHandler(os.Stdout, opts)
	} else {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	}

	return slog.New(handler).With("app", appName)
}

func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
