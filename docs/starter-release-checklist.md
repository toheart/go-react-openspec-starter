# Starter Release Checklist

Use this checklist before publishing the baseline as a dedicated starter repository or template
branch.

## Repository Identity

- Backend module path uses the starter baseline module.
- Backend CLI name, config defaults, frontend package name, and page title all use starter
  metadata.
- The sample feature remains neutral and does not use product-specific business naming.

## OpenSpec Scope

- `openspec/config.yaml` is included.
- `openspec/specs/` is included.
- `openspec/changes/` is excluded from the published starter baseline.

## Verification

- Run `go test ./...` under `backend/`.
- Run `npm run build` under `frontend/`.
- Run `.\scripts\verify-template.ps1` or `./scripts/verify-template.sh` with the expected starter or project metadata values.
- Run `.\scripts\smoke-starter.ps1` or `./scripts/smoke-starter.sh` to validate the publishable starter copy, including OpenSpec baseline files.

## Handoff

- The README explains how to initialize the starter.
- `TEMPLATE_USAGE.md` explains how to begin a fresh OpenSpec proposal/design/tasks flow in the
  generated project.
