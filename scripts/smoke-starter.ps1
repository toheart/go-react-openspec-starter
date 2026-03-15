param(
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$ProjectSlug = 'starter-smoke-app',

    [string]$ModuleBase = 'github.com/example/starter-smoke-app',

    [string]$DisplayName = 'Starter Smoke App',

    [switch]$SkipGoModTidy,

    [switch]$SkipOpenSpecList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Copy-StarterPath {
    param(
        [string]$SourceRoot,
        [string]$TargetRoot,
        [string]$RelativePath
    )

    $sourcePath = Join-Path $SourceRoot $RelativePath
    if (-not (Test-Path -Path $sourcePath)) {
        throw "Starter path not found: $RelativePath"
    }

    $targetPath = Join-Path $TargetRoot $RelativePath
    $parentPath = Split-Path -Parent $targetPath
    if (-not [string]::IsNullOrWhiteSpace($parentPath)) {
        New-Item -ItemType Directory -Force -Path $parentPath | Out-Null
    }

    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tmpRoot = Join-Path $repoRoot '.tmpbin'
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$smokeRoot = Join-Path $tmpRoot "starter-smoke-$stamp"

New-Item -ItemType Directory -Force -Path $smokeRoot | Out-Null

$pathsToCopy = @(
    'backend',
    'frontend',
    'scripts',
    'docs',
    'openspec',
    'README.md',
    'TEMPLATE_USAGE.md',
    '.gitignore',
    'AGENTS.md'
)

foreach ($pathToCopy in $pathsToCopy) {
    Copy-StarterPath -SourceRoot $repoRoot -TargetRoot $smokeRoot -RelativePath $pathToCopy
}

$pathsToRemove = @(
    (Join-Path $smokeRoot 'frontend\node_modules'),
    (Join-Path $smokeRoot 'frontend\dist'),
    (Join-Path $smokeRoot 'backend\bin'),
    (Join-Path $smokeRoot 'backend\cmd.exe'),
    (Join-Path $smokeRoot '.tmpbin'),
    (Join-Path $smokeRoot 'openspec\changes')
)

foreach ($pathToRemove in $pathsToRemove) {
    if (Test-Path -Path $pathToRemove) {
        Remove-Item -Path $pathToRemove -Recurse -Force
    }
}

$initScript = Join-Path $smokeRoot 'scripts\init.ps1'
& $initScript `
    -ProjectSlug $ProjectSlug `
    -ModuleBase $ModuleBase `
    -DisplayName $DisplayName `
    -SkipGoModTidy:$SkipGoModTidy

$openSpecConfigPath = Join-Path $smokeRoot 'openspec\config.yaml'
$openSpecSpecsPath = Join-Path $smokeRoot 'openspec\specs'
$openSpecChangesPath = Join-Path $smokeRoot 'openspec\changes'

if (-not (Test-Path -Path $openSpecConfigPath)) {
    throw 'OpenSpec smoke check failed: missing openspec/config.yaml in smoke copy.'
}

if (-not (Test-Path -Path $openSpecSpecsPath)) {
    throw 'OpenSpec smoke check failed: missing openspec/specs in smoke copy.'
}

$specFiles = Get-ChildItem -Path $openSpecSpecsPath -Recurse -Filter 'spec.md'
if ($specFiles.Count -eq 0) {
    throw 'OpenSpec smoke check failed: no baseline spec files found in smoke copy.'
}

if (-not $SkipOpenSpecList) {
    New-Item -ItemType Directory -Force -Path $openSpecChangesPath | Out-Null

    $openSpecCommand = Get-Command 'openspec' -ErrorAction SilentlyContinue
    if ($null -eq $openSpecCommand) {
        Write-Host 'SKIP OpenSpec CLI list check (openspec command not found).'
    }
    else {
        Push-Location $smokeRoot
        try {
            $openSpecList = openspec list --json
        }
        finally {
            Pop-Location
        }

        Write-Host ''
        Write-Host 'OpenSpec list output'
        Write-Host '--------------------'
        Write-Host $openSpecList
    }
}

Write-Host ''
Write-Host 'Starter smoke directory'
Write-Host '-----------------------'
Write-Host $smokeRoot
Write-Host "OpenSpec config: $openSpecConfigPath"
Write-Host "OpenSpec specs:  $($specFiles.Count) files"
