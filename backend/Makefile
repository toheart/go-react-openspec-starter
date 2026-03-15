APP_NAME := go-react-openspec-starter
GO ?= go
GOLANGCI_LINT_VERSION ?= v2.11.3
GOLANGCI_LINT := $(GO) run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

.PHONY: run test fmt lint lint-fix tidy build check

run:
	$(GO) run ./cmd server

test:
	$(GO) test ./...

fmt:
	$(GOLANGCI_LINT) fmt -c .golangci.yml ./...

lint:
	$(GOLANGCI_LINT) run -c .golangci.yml ./...

lint-fix:
	$(GOLANGCI_LINT) fmt -c .golangci.yml ./...
	$(GOLANGCI_LINT) run -c .golangci.yml --fix ./...

tidy:
	$(GO) mod tidy

build:
	$(GO) build -o bin/$(APP_NAME) ./cmd

check: fmt lint test build
