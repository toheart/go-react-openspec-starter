package memory

import (
	"context"
	"sync"
	"time"

	domainsample "github.com/toheart/go-react-openspec-starter/backend/internal/domain/sample"
)

var _ domainsample.Repository = (*SampleRepository)(nil)

type SampleRepository struct {
	mu      sync.RWMutex
	samples []domainsample.Sample
}

func NewSampleRepository() *SampleRepository {
	now := time.Now().UTC()

	return &SampleRepository{
		samples: []domainsample.Sample{
			{
				ID:        "sample-001",
				Name:      "Backend module",
				Summary:   "Shows how the Go service layers domain, application, and HTTP delivery.",
				Category:  domainsample.CategoryBackend,
				Status:    domainsample.StatusReady,
				UpdatedAt: now.Add(-15 * time.Minute),
			},
			{
				ID:        "sample-002",
				Name:      "Frontend module",
				Summary:   "Demonstrates typed API access, async UI state, and reusable page components.",
				Category:  domainsample.CategoryFrontend,
				Status:    domainsample.StatusInProgress,
				UpdatedAt: now.Add(-45 * time.Minute),
			},
			{
				ID:        "sample-003",
				Name:      "OpenSpec workflow",
				Summary:   "Captures repository rules and the expected change proposal lifecycle.",
				Category:  domainsample.CategoryWorkflow,
				Status:    domainsample.StatusDone,
				UpdatedAt: now.Add(-2 * time.Hour),
			},
		},
	}
}

func (r *SampleRepository) List(ctx context.Context) ([]domainsample.Sample, error) {
	_ = ctx

	r.mu.RLock()
	defer r.mu.RUnlock()

	items := make([]domainsample.Sample, len(r.samples))
	copy(items, r.samples)

	return items, nil
}
