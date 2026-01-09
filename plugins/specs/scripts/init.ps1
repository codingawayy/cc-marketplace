<#
.SYNOPSIS
    Initializes the specs plugin for the current user.

.DESCRIPTION
    Adds the plugin path to ~/.claude/plugins/cache/settings.json.
    This script is called automatically via the SessionStart hook.

    This is a temporary workaround for claude-code#9354, where ${CLAUDE_PLUGIN_ROOT}
    doesn't expand in command markdown files. Once the bug is fixed, this file will
    no longer be needed.

    https://github.com/anthropics/claude-code/issues/9354

.NOTES
    The ~/.claude/plugins/cache/settings.json file structure:

    {
      "cc-specs-plugin": {
        "pluginPath": "/path/to/cc-specs-plugin"
      }
    }
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

# Build settings directory path: ~/.claude/plugins/cache/
$SettingsDir = Join-Path $UserHome ".claude" |
               Join-Path -ChildPath "plugins" |
               Join-Path -ChildPath "cache"
$SettingsPath = Join-Path $SettingsDir "settings.json"

# Ensure settings directory exists
if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir -Force | Out-Null
}

# Load existing settings.json or create new object
if (Test-Path $SettingsPath) {
    $settings = Get-Content -Path $SettingsPath -Raw | ConvertFrom-Json
} else {
    $settings = @{}
}

# Add/update cc-specs-plugin entry
$settings | Add-Member -NotePropertyName "cc-specs-plugin" -NotePropertyValue @{
    pluginPath = $PluginRoot
} -Force

# Write back to file
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
