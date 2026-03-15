param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleBase,

    [Parameter(Mandatory = $true)]
    [string]$AppName,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$FrontendPackageName,

    [Parameter(Mandatory = $true)]
    [string]$EnvPrefix
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Pattern {
    param(
        [string]$Path,
        [string]$Pattern
    )

    return Select-String -Path $Path -Pattern $Pattern -Quiet
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendModule = "$ModuleBase/backend"
$starterSlug = 'go-react-openspec-starter'
$starterBackendModule = 'github.com/toheart/go-react-openspec-starter/backend'
$starterFrontendPackage = 'go-react-openspec-starter-frontend'
$starterEnvPrefix = 'GO_REACT_OPENSPEC_STARTER'

$checks = @(
    @{
        Description = 'backend module path'
        Path = Join-Path $repoRoot 'backend/go.mod'
        Pattern = [regex]::Escape("module $backendModule")
    }
    @{
        Description = 'backend app name'
        Path = Join-Path $repoRoot 'backend/Makefile'
        Pattern = [regex]::Escape("APP_NAME := $AppName")
    }
    @{
        Description = 'backend env prefix'
        Path = Join-Path $repoRoot 'backend/conf/conf.go'
        Pattern = [regex]::Escape("v.SetEnvPrefix(""$EnvPrefix"")")
    }
    @{
        Description = 'backend config default'
        Path = Join-Path $repoRoot 'backend/conf/conf.go'
        Pattern = [regex]::Escape("v.SetDefault(""app.name"", ""$AppName"")")
    }
    @{
        Description = 'frontend package name'
        Path = Join-Path $repoRoot 'frontend/package.json'
        Pattern = [regex]::Escape("""name"": ""$FrontendPackageName""")
    }
    @{
        Description = 'frontend title'
        Path = Join-Path $repoRoot 'frontend/index.html'
        Pattern = [regex]::Escape("<title>$DisplayName</title>")
    }
)

$backendSourceFiles = Get-ChildItem -Path (Join-Path $repoRoot 'backend') -Recurse -File |
    Where-Object { $_.Extension -eq '.go' -or $_.Name -eq 'go.mod' } |
    ForEach-Object { $_.FullName }

$legacyChecks = @(
    @{
        Description = 'legacy backend module path'
        Pattern = $starterBackendModule
        Paths = $backendSourceFiles
        ShouldCheck = $backendModule -ne $starterBackendModule
    }
    @{
        Description = 'legacy frontend package'
        Pattern = $starterFrontendPackage
        Paths = @(
            Join-Path $repoRoot 'frontend/package.json'
            Join-Path $repoRoot 'frontend/package-lock.json'
        )
        ShouldCheck = $FrontendPackageName -ne $starterFrontendPackage
    }
    @{
        Description = 'legacy env prefix'
        Pattern = $starterEnvPrefix
        Paths = @(
            Join-Path $repoRoot 'backend/conf/conf.go'
        )
        ShouldCheck = $EnvPrefix -ne $starterEnvPrefix
    }
)

$failures = New-Object System.Collections.Generic.List[string]

foreach ($check in $checks) {
    if (Test-Pattern -Path $check.Path -Pattern $check.Pattern) {
        Write-Host "PASS $($check.Description)"
    }
    else {
        $failures.Add("Missing expected $($check.Description) in $($check.Path)")
        Write-Host "FAIL $($check.Description)"
    }
}

$metadataFiles = @(
    Join-Path $repoRoot 'backend/go.mod'
    Join-Path $repoRoot 'backend/Makefile'
    Join-Path $repoRoot 'backend/cmd/main.go'
    Join-Path $repoRoot 'backend/conf/conf.go'
    Join-Path $repoRoot 'backend/etc/config.dev.yaml'
    Join-Path $repoRoot 'backend/etc/config.prod.yaml'
    Join-Path $repoRoot 'frontend/package.json'
    Join-Path $repoRoot 'frontend/package-lock.json'
    Join-Path $repoRoot 'frontend/index.html'
)

foreach ($legacy in $legacyChecks) {
    if (-not $legacy.ShouldCheck) {
        Write-Host "PASS $($legacy.Description) (baseline value retained intentionally)"
        continue
    }

    $matches = Select-String -Path $legacy.Paths -Pattern ([regex]::Escape($legacy.Pattern))
    if ($matches) {
        $failures.Add("Found remaining $($legacy.Description) in managed metadata files")
        Write-Host "FAIL $($legacy.Description)"
    }
    else {
        Write-Host "PASS $($legacy.Description)"
    }
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'Verification failed:'
    foreach ($failure in $failures) {
        Write-Host " - $failure"
    }

    exit 1
}

Write-Host ''
Write-Host 'Starter metadata verification passed.'
