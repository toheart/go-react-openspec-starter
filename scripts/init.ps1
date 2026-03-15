param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$ProjectSlug,

    [Parameter(Mandatory = $true)]
    [string]$ModuleBase,

    [string]$AppName,

    [string]$DisplayName,

    [string]$FrontendPackageName,

    [string]$EnvPrefix,

    [switch]$SkipGoModTidy,

    [switch]$SkipVerification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DisplayName {
    param([string]$Slug)

    $segments = $Slug -split '-'
    $words = foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment)) {
            continue
        }

        $lower = $segment.ToLowerInvariant()
        $lower.Substring(0, 1).ToUpperInvariant() + $lower.Substring(1)
    }

    return ($words -join ' ')
}

function Update-FileContent {
    param(
        [string]$Path,
        [scriptblock]$Transform
    )

    $rawContent = Get-Content -Path $Path -Raw
    $updatedContent = & $Transform $rawContent

    if ($updatedContent -ne $rawContent) {
        Set-Content -Path $Path -Value $updatedContent -NoNewline
        return $true
    }

    return $false
}

if ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = $ProjectSlug
}

if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    $DisplayName = Get-DisplayName -Slug $ProjectSlug
}

if ([string]::IsNullOrWhiteSpace($FrontendPackageName)) {
    $FrontendPackageName = "$ProjectSlug-frontend"
}

if ([string]::IsNullOrWhiteSpace($EnvPrefix)) {
    $EnvPrefix = ($ProjectSlug -replace '-', '_').ToUpperInvariant()
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendModule = "$ModuleBase/backend"
$shortDescription = "$DisplayName backend service"

$managedFiles = @(
    'backend/go.mod',
    'backend/Makefile',
    'backend/cmd/main.go',
    'backend/conf/conf.go',
    'backend/etc/config.dev.yaml',
    'backend/etc/config.prod.yaml',
    'frontend/package.json',
    'frontend/package-lock.json',
    'frontend/index.html'
)

$updatedFiles = New-Object System.Collections.Generic.List[string]

$transformMap = @{
    'backend/go.mod' = {
        param($content)
        [regex]::Replace($content, '(?m)^module\s+.+$', "module $backendModule")
    }
    'backend/Makefile' = {
        param($content)
        [regex]::Replace($content, '(?m)^APP_NAME := .+$', "APP_NAME := $AppName")
    }
    'backend/cmd/main.go' = {
        param($content)
        $result = [regex]::Replace($content, '(?m)(Use:\s+")([^"]+)(")', "`${1}$AppName`${3}")
        [regex]::Replace($result, '(?m)(Short:\s+")([^"]+)(")', "`${1}$shortDescription`${3}")
    }
    'backend/conf/conf.go' = {
        param($content)
        $result = [regex]::Replace(
            $content,
            '(?m)(v\.SetEnvPrefix\(")([^"]+)("\))',
            "`${1}$EnvPrefix`${3}"
        )
        [regex]::Replace(
            $result,
            '(?m)(v\.SetDefault\("app\.name", ")([^"]+)("\))',
            "`${1}$AppName`${3}"
        )
    }
    'backend/etc/config.dev.yaml' = {
        param($content)
        [regex]::Replace($content, '(?m)^  name: .+$', "  name: $AppName")
    }
    'backend/etc/config.prod.yaml' = {
        param($content)
        [regex]::Replace($content, '(?m)^  name: .+$', "  name: $AppName")
    }
    'frontend/package.json' = {
        param($content)
        [regex]::Replace($content, '(?m)("name":\s+")([^"]+)(")', "`${1}$FrontendPackageName`${3}", 1)
    }
    'frontend/package-lock.json' = {
        param($content)
        $result = [regex]::Replace($content, '("name":\s+")([^"]+)(")', "`${1}$FrontendPackageName`${3}", 1)
        [regex]::Replace($result, '("name":\s+")([^"]+)(")', "`${1}$FrontendPackageName`${3}", 1)
    }
    'frontend/index.html' = {
        param($content)
        [regex]::Replace($content, '(?m)(<title>)(.*?)(</title>)', "`${1}$DisplayName`${3}")
    }
}

foreach ($relativePath in $managedFiles) {
    $absolutePath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -Path $absolutePath)) {
        throw "Managed metadata file not found: $relativePath"
    }

    if (Update-FileContent -Path $absolutePath -Transform $transformMap[$relativePath]) {
        $updatedFiles.Add($relativePath)
    }
}

if (-not $SkipGoModTidy) {
    Push-Location (Join-Path $repoRoot 'backend')
    try {
        go mod tidy
    }
    finally {
        Pop-Location
    }
}

Write-Host ''
Write-Host 'Starter initialization summary'
Write-Host '------------------------------'
Write-Host "Project slug:           $ProjectSlug"
Write-Host "Module base:            $ModuleBase"
Write-Host "Backend module:         $backendModule"
Write-Host "App name:               $AppName"
Write-Host "Display name:           $DisplayName"
Write-Host "Frontend package name:  $FrontendPackageName"
Write-Host "Environment prefix:     $EnvPrefix"
Write-Host 'Updated files:'

foreach ($updatedFile in $updatedFiles) {
    Write-Host " - $updatedFile"
}

if (-not $SkipVerification) {
    & (Join-Path $PSScriptRoot 'verify-template.ps1') `
        -ModuleBase $ModuleBase `
        -AppName $AppName `
        -DisplayName $DisplayName `
        -FrontendPackageName $FrontendPackageName `
        -EnvPrefix $EnvPrefix
}
