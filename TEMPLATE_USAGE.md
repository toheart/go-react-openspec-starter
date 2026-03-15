# Template Usage

This repository is intended to be published as a reusable Go + React + OpenSpec starter.

## 1. Create A New Repository

Use your Git hosting template feature or copy the repository into a new project repository.

Recommended repository naming pattern:

- repository slug: `your-project`
- frontend package: `your-project-frontend`
- backend module: `github.com/your-org/your-project/backend`

## 2. Initialize Starter Metadata

Run the bootstrap script from the repository root:

```powershell
.\scripts\init.ps1 `
  -ProjectSlug your-project `
  -ModuleBase github.com/your-org/your-project
```

Optional inputs:

- `-AppName`: override the default CLI and backend app name
- `-DisplayName`: override the UI title and backend short description
- `-FrontendPackageName`: override the default `your-project-frontend`
- `-EnvPrefix`: override the default uppercase `YOUR_PROJECT`
- `-SkipGoModTidy`: skip `go mod tidy`
- `-SkipVerification`: skip the post-init verification script

## 3. Managed Metadata Files

The bootstrap workflow updates these starter-owned metadata files:

- `backend/go.mod`
- `backend/Makefile`
- `backend/cmd/main.go`
- `backend/conf/conf.go`
- `backend/etc/config.dev.yaml`
- `backend/etc/config.prod.yaml`
- `frontend/package.json`
- `frontend/package-lock.json`
- `frontend/index.html`

See [starter-metadata.md](./docs/starter-metadata.md) for the exact ownership and replacement
targets.

## 4. Verify The Result

The init script runs verification automatically unless `-SkipVerification` is used. You can also
run it directly:

```powershell
.\scripts\verify-template.ps1 `
  -ModuleBase github.com/your-org/your-project `
  -AppName your-project `
  -DisplayName "Your Project" `
  -FrontendPackageName your-project-frontend `
  -EnvPrefix YOUR_PROJECT
```

## 5. Start A Fresh OpenSpec Change

The starter should ship only reusable engineering specs under `openspec/specs/`.

When publishing a dedicated starter repository or template branch:

- keep `openspec/config.yaml`
- keep `openspec/specs/`
- exclude `openspec/changes/`

After your new repository is initialized, begin product work with a fresh change:

```text
/opsx:propose describe the first feature or fix
```

Then implement it with:

```text
/opsx:apply <change-name>
```
