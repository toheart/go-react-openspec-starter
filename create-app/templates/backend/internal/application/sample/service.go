package sample

import (
	"context"
	"fmt"
	"time"

	domainsample "github.com/toheart/go-react-openspec-starter/backend/internal/domain/sample"
)

type SampleDTO struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Summary   string `json:"summary"`
	Category  string `json:"category"`
	Status    string `json:"status"`
	UpdatedAt string `json:"updatedAt"`
}

type Service struct {
	repo domainsample.Repository
}

func NewService(repo domainsample.Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) List(ctx context.Context) ([]SampleDTO, error) {
	samples, err := s.repo.List(ctx)
	if err != nil {
		return nil, fmt.Errorf("list sample items: %w", err)
	}

	items := make([]SampleDTO, 0, len(samples))
	for _, item := range samples {
		items = append(items, toDTO(item))
	}

	return items, nil
}

func toDTO(item domainsample.Sample) SampleDTO {
	return SampleDTO{
		ID:        item.ID,
		Name:      item.Name,
		Summary:   item.Summary,
		Category:  string(item.Category),
		Status:    string(item.Status),
		UpdatedAt: item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}
