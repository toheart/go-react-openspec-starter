# Go React OpenSpec Starter

A reusable Go + React full-stack starter that pairs a typed frontend, a layered Go backend,
and OpenSpec-managed engineering rules.

## What You Get

- A Go backend with Cobra entrypoints, Gin HTTP delivery, Viper config loading, and `log/slog`
  logging.
- A React + TypeScript frontend with a shared API service layer and a simple starter home page.
- A neutral `sample` vertical slice that demonstrates backend domain/application/interface wiring
  and frontend API consumption without locking the template to a business domain.
- Shared OpenSpec specs for backend style, frontend style, API conventions, and testing rules.
- Bootstrap scripts for initializing metadata in a new repository created from the starter.

## Structure

```text
go-react-openspec-starter/
├── backend/
│   ├── cmd/
│   ├── conf/
│   ├── docs/
│   ├── etc/
│   └── internal/
│       ├── application/sample/
│       ├── domain/sample/
│       ├── infrastructure/storage/memory/
│       ├── interfaces/http/
│       ├── logging/
│       └── wire/
├── docs/
├── frontend/
├── openspec/
│   ├── config.yaml
│   └── specs/
└── scripts/
```

## Quick Start

### Backend

```bash
cd backend
go mod tidy
make run
```

The backend serves:

- `GET /healthz`
- `GET /api/v1/samples`

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend dev server is available at `http://localhost:3000`.

## Using This As A Starter

1. Create a new repository from this baseline or copy it into a dedicated template repository.
2. Run the initialization script:

```powershell
.\scripts\init.ps1 `
  -ProjectSlug order-center `
  -ModuleBase github.com/acme/order-center
```

3. Review the generated metadata summary and rerun verification if needed:

```powershell
.\scripts\verify-template.ps1 `
  -ModuleBase github.com/acme/order-center `
  -AppName order-center `
  -DisplayName "Order Center" `
  -FrontendPackageName order-center-frontend `
  -EnvPrefix ORDER_CENTER
```

See [TEMPLATE_USAGE.md](./TEMPLATE_USAGE.md) for the full template workflow and managed
metadata files.

## OpenSpec Baseline

The starter keeps only reusable engineering rules under `openspec/specs/`.

When you publish a dedicated starter repository or template branch:

- keep `openspec/config.yaml`
- keep `openspec/specs/`
- do not carry `openspec/changes/` history into the published starter baseline

After creating a new project, start product-specific work with a fresh proposal rather than
reusing source-repository planning artifacts.
