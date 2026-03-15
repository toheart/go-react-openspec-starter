package sample

import (
	"context"
	"time"
)

type Category string

const (
	CategoryBackend  Category = "backend"
	CategoryFrontend Category = "frontend"
	CategoryWorkflow Category = "workflow"
)

type Status string

const (
	StatusReady      Status = "ready"
	StatusInProgress Status = "in-progress"
	StatusDone       Status = "done"
)

type Sample struct {
	ID        string
	Name      string
	Summary   string
	Category  Category
	Status    Status
	UpdatedAt time.Time
}

type Repository interface {
	List(ctx context.Context) ([]Sample, error)
}
