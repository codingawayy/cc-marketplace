<#
.SYNOPSIS
    Initializes the specs plugin for the current user.

.DESCRIPTION
    - Adds the plugin path to ~/.claude/plugins/cache/settings.json
    - Creates .specs/config.json in the current project if it doesn't exist

    This script is called automatically via the SessionStart hook.
#>

$ErrorActionPreference = "SilentlyContinue"

# Determine plugin root from script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir

# Determine user home directory (cross-platform)
$UserHome = $HOME
if (-not $UserHome -and $env:USERPROFILE) {
    $UserHome = $env:USERPROFILE
}

# ============================================================================
# 1. Cache plugin path in ~/.claude/plugins/cache/settings.json
#
#    This is a temporary workaround for claude-code#9354, where
#    ${CLAUDE_PLUGIN_ROOT} doesn't expand in command markdown files.
#    https://github.com/anthropics/claude-code/issues/9354
# ============================================================================

$SettingsDir = Join-Path $UserHome ".claude" |
Join-Path -ChildPath "plugins" |
Join-Path -ChildPath "cache"
$SettingsPath = Join-Path $SettingsDir "settings.json"

if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir -Force | Out-Null
}

if (Test-Path $SettingsPath) {
    $settings = Get-Content -Path $SettingsPath -Raw | ConvertFrom-Json
}
else {
    $settings = @{}
}

$settings | Add-Member -NotePropertyName "cc-specs-plugin" -NotePropertyValue @{
    pluginPath = $PluginRoot
} -Force

$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8

# ============================================================================
# 2. Create .specs/config.json in current project if it doesn't exist
# ============================================================================

$SpecsDir = Join-Path (Get-Location) ".specs"
$ConfigPath = Join-Path $SpecsDir "config.json"

if (-not (Test-Path $ConfigPath)) {
    if (-not (Test-Path $SpecsDir)) {
        New-Item -ItemType Directory -Path $SpecsDir -Force | Out-Null
    }

    $DefaultConfig = @{
        exclude = @(
            "docs.specs/"
            ".specs/"
            ".claude/"
            ".git/"
            ".github/"
            ".rider/"
            ".idea/"
            ".vscode/"
            "node_modules/"
            "dist/"
            "build/"
            ".svelte-kit/"
        )
    }

    $DefaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
}

# ============================================================================
# 3. Create .specs/.gitignore if it doesn't exist
# ============================================================================

$GitignorePath = Join-Path $SpecsDir ".gitignore"

if (-not (Test-Path $GitignorePath)) {
    @"
temp/
"@ | Set-Content -Path $GitignorePath -Encoding UTF8 -NoNewline
}
