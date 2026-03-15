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
- Run `.\scripts\verify-template.ps1` with the expected starter or project metadata values.
- Smoke-test `.\scripts\init.ps1` in a fresh copy when changing managed metadata targets.

## Handoff

- The README explains how to initialize the starter.
- `TEMPLATE_USAGE.md` explains how to begin a fresh OpenSpec proposal/design/tasks flow in the
  generated project.
