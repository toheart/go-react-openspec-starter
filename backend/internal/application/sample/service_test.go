package sample

import (
	"context"
	"testing"

	"github.com/toheart/go-react-openspec-starter/backend/internal/infrastructure/storage/memory"
)

func TestServiceList(t *testing.T) {
	t.Parallel()

	service := NewService(memory.NewSampleRepository())

	items, err := service.List(context.Background())
	if err != nil {
		t.Fatalf("List() error = %v", err)
	}

	if len(items) != 3 {
		t.Fatalf("expected 3 sample items, got %d", len(items))
	}
}
