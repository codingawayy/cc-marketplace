<#
.SYNOPSIS
    Summarizes generated specification files.

.DESCRIPTION
    Scans docs.specs/ and returns statistics about generated specs by category.

.OUTPUTS
    JSON object with counts by category
#>

$SpecsDir = Join-Path (Get-Location) "docs.specs"

if (-not (Test-Path $SpecsDir)) {
    @{
        error = "docs.specs/ directory not found"
    } | ConvertTo-Json
    exit 1
}

# Count specs by category
$Stats = @{
    system = 0
    entities = 0
    actions = 0
    tasks = 0
    services = 0
    apps = 0
    total = 0
}

# System spec
if (Test-Path (Join-Path $SpecsDir "system.yaml")) {
    $Stats.system = 1
}

# Entities and actions
$DomainDir = Join-Path $SpecsDir "domain"
if (Test-Path $DomainDir) {
    $EntityDirs = Get-ChildItem -Path $DomainDir -Directory -ErrorAction SilentlyContinue
    foreach ($EntityDir in $EntityDirs) {
        # Count entity yaml
        $EntityYaml = Join-Path $EntityDir.FullName "$($EntityDir.Name).yaml"
        if (Test-Path $EntityYaml) {
            $Stats.entities++
        }
        # Count actions
        $ActionsDir = Join-Path $EntityDir.FullName "actions"
        if (Test-Path $ActionsDir) {
            $Stats.actions += (Get-ChildItem -Path $ActionsDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue).Count
        }
    }
}

# Tasks
$TasksDir = Join-Path $SpecsDir "tasks"
if (Test-Path $TasksDir) {
    $Stats.tasks = (Get-ChildItem -Path $TasksDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue).Count
}

# Services
$ServicesDir = Join-Path $SpecsDir "external-services"
if (Test-Path $ServicesDir) {
    $Stats.services = (Get-ChildItem -Path $ServicesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue).Count
}

# Apps
$AppsDir = Join-Path $SpecsDir "apps"
if (Test-Path $AppsDir) {
    $AppDirs = Get-ChildItem -Path $AppsDir -Directory -ErrorAction SilentlyContinue
    foreach ($AppDir in $AppDirs) {
        $AppYaml = Join-Path $AppDir.FullName "$($AppDir.Name).yaml"
        if (Test-Path $AppYaml) {
            $Stats.apps++
        }
    }
}

# Calculate total
$Stats.total = $Stats.system + $Stats.entities + $Stats.actions + $Stats.tasks + $Stats.services + $Stats.apps

$Stats | ConvertTo-Json
