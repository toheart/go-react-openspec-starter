param(
    [ValidateSet("all", "cursor", "claude")]
    [string[]]$Target = @("all"),

    [ValidateSet("auto", "junction", "symlink", "copy")]
    [string]$Mode = "auto"
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceRoot = Join-Path $repoRoot ".agents\skills"

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "Source skills directory not found: $sourceRoot"
}

$targetMap = @{
    cursor = Join-Path $repoRoot ".cursor\skills"
    claude = Join-Path $repoRoot ".claude\skills"
}

if ($Target -contains "all") {
    $resolvedTargets = @("cursor", "claude")
}
else {
    $resolvedTargets = $Target
}

function Assert-WithinPath {
    param(
        [string]$ChildPath,
        [string]$ParentPath
    )

    $parent = [System.IO.Path]::GetFullPath($ParentPath)
    $child = [System.IO.Path]::GetFullPath($ChildPath)
    if (-not $child.StartsWith($parent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside target root: $child"
    }
}

function Reset-TargetDirectory {
    param(
        [string]$PathToReset,
        [string]$TargetRoot
    )

    Assert-WithinPath -ChildPath $PathToReset -ParentPath $TargetRoot
    if (Test-Path -LiteralPath $PathToReset) {
        Remove-Item -LiteralPath $PathToReset -Recurse -Force
    }
}

function New-SkillProjection {
    param(
        [string]$SkillSource,
        [string]$SkillTarget,
        [string]$ProjectionMode
    )

    switch ($ProjectionMode) {
        "junction" {
            New-Item -ItemType Junction -Path $SkillTarget -Target $SkillSource | Out-Null
            return "junction"
        }
        "symlink" {
            New-Item -ItemType SymbolicLink -Path $SkillTarget -Target $SkillSource | Out-Null
            return "symlink"
        }
        "copy" {
            Copy-Item -LiteralPath $SkillSource -Destination $SkillTarget -Recurse -Force
            return "copy"
        }
        "auto" {
            foreach ($candidate in @("junction", "symlink", "copy")) {
                try {
                    return New-SkillProjection -SkillSource $SkillSource -SkillTarget $SkillTarget -ProjectionMode $candidate
                }
                catch {
                    if (Test-Path -LiteralPath $SkillTarget) {
                        Remove-Item -LiteralPath $SkillTarget -Recurse -Force
                    }
                }
            }
            throw "Unable to sync skill '$SkillSource' with any projection mode."
        }
        default {
            throw "Unsupported mode: $ProjectionMode"
        }
    }
}

$skillDirs = Get-ChildItem -LiteralPath $sourceRoot -Directory | Sort-Object Name
if ($skillDirs.Count -eq 0) {
    Write-Host "No skills found under $sourceRoot"
    exit 0
}

foreach ($targetName in $resolvedTargets) {
    $targetRoot = $targetMap[$targetName]
    if (-not $targetRoot) {
        throw "Unknown target: $targetName"
    }

    New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null
    Write-Host "Sync target: $targetName -> $targetRoot"

    foreach ($skillDir in $skillDirs) {
        $skillTarget = Join-Path $targetRoot $skillDir.Name
        Reset-TargetDirectory -PathToReset $skillTarget -TargetRoot $targetRoot
        $usedMode = New-SkillProjection -SkillSource $skillDir.FullName -SkillTarget $skillTarget -ProjectionMode $Mode
        Write-Host ("  [{0}] {1}" -f $usedMode, $skillDir.Name)
    }
}

Write-Host ""
Write-Host "Done. Source of truth remains .agents/skills/."
Write-Host "Examples:"
Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/sync-ide-skills.ps1 -Target all -Mode auto"
Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/sync-ide-skills.ps1 -Target cursor -Mode copy"
