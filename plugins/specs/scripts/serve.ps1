<#
.SYNOPSIS
    Starts a Hugo dev server to browse generated specs as a website.

.DESCRIPTION
    This script mounts YAML spec files from the project into Hugo's asset pipeline
    and starts a local Hugo server. Hugo's content adapter dynamically converts
    the YAML specs into browseable pages.

.PARAMETER SpecsDir
    Directory containing YAML spec files. Defaults to "docs.specs" in the current working directory.

.PARAMETER Port
    Port for the Hugo server. Defaults to 1313.

.EXAMPLE
    powershell.exe -NoProfile -File "/path/to/scripts/serve.ps1"

.EXAMPLE
    powershell.exe -NoProfile -File "/path/to/scripts/serve.ps1" -SpecsDir "my-specs" -Port 8080
#>

param(
    [string]$SpecsDir = "docs.specs",
    [int]$Port = 1313
)

$ErrorActionPreference = "Stop"

# Plugin paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginDir = Split-Path -Parent $ScriptDir
$PluginSiteDir = Join-Path $PluginDir "site"

# Project paths
$ProjectDir = Get-Location

# Resolve specs directory relative to project
if (-not [System.IO.Path]::IsPathRooted($SpecsDir)) {
    $ProjectSpecsDir = Join-Path $ProjectDir $SpecsDir
} else {
    $ProjectSpecsDir = $SpecsDir
}

# Check if Hugo is installed
function Test-HugoInstalled {
    try {
        $null = Get-Command hugo -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Main execution
Write-Host "Specs Site Server" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""

# Check Hugo installation
if (-not (Test-HugoInstalled)) {
    Write-Host "Hugo is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Hugo using one of these methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Windows (winget):" -ForegroundColor White
    Write-Host "    winget install Hugo.Hugo.Extended" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Windows (chocolatey):" -ForegroundColor White
    Write-Host "    choco install hugo-extended" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Windows (scoop):" -ForegroundColor White
    Write-Host "    scoop install hugo-extended" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Download from: https://gohugo.io/installation/" -ForegroundColor White
    Write-Host ""
    exit 1
}

$hugoVersion = hugo version
Write-Host "Found: $hugoVersion" -ForegroundColor Green
Write-Host ""

# Check npm dependencies
$nodeModulesPath = Join-Path $PluginSiteDir "node_modules"
if (-not (Test-Path $nodeModulesPath)) {
    Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
    Push-Location $PluginSiteDir
    npm install
    Pop-Location
    Write-Host "Dependencies installed" -ForegroundColor Green
    Write-Host ""
}

# Check if specs directory exists
if (-not (Test-Path $ProjectSpecsDir)) {
    Write-Host "Specs directory not found: $ProjectSpecsDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run /specs:generate first to create specification files." -ForegroundColor Yellow
    exit 1
}

$specCount = (Get-ChildItem -Path $ProjectSpecsDir -Filter "*.yaml" -Recurse).Count
Write-Host "Found $specCount spec files in: $ProjectSpecsDir" -ForegroundColor Green
Write-Host ""

# Generate temporary mount config
# This mounts the project's specs directory into Hugo's assets/specs/
$mountConfigPath = Join-Path $PluginSiteDir "mount.toml"
$specsPathEscaped = $ProjectSpecsDir.Replace('\', '/')

$mountConfig = @"
# Auto-generated mount configuration
# Maps project specs into Hugo's asset pipeline

[module]
[[module.mounts]]
  source = "assets"
  target = "assets"

[[module.mounts]]
  source = "layouts"
  target = "layouts"

[[module.mounts]]
  source = "content"
  target = "content"

[[module.mounts]]
  source = "$specsPathEscaped"
  target = "assets/specs"
"@

[System.IO.File]::WriteAllText($mountConfigPath, $mountConfig)

# Start Hugo server
Write-Host "Starting Hugo server on http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

try {
    Set-Location $PluginSiteDir
    hugo server --port $Port --bind "127.0.0.1" --config "hugo.toml,$mountConfigPath"
}
finally {
    # Clean up mount config
    if (Test-Path $mountConfigPath) {
        Remove-Item $mountConfigPath -Force
    }
}
