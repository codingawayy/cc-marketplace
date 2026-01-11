<#
.SYNOPSIS
    Builds an index of repository files for spec generation.

.DESCRIPTION
    Scans the repository, excludes patterns from .specs/config.json and .gitignore,
    and outputs a CSV index to .specs/index.csv.

.OUTPUTS
    Creates .specs/index.csv with columns: path, last_modified
#>

# Read config exclusions
$ConfigPath = Join-Path (Get-Location) ".specs/config.json"
$ConfigJson = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$ExcludePatterns = @($ConfigJson.exclude)

# Read .gitignore patterns if exists
$GitignorePath = Join-Path (Get-Location) ".gitignore"
if (Test-Path $GitignorePath) {
    $GitignorePatterns = Get-Content $GitignorePath | Where-Object {
        $_ -and -not $_.StartsWith('#')
    }
    $ExcludePatterns += $GitignorePatterns
}

# Get all files recursively
$AllFiles = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue

# Filter out excluded files
$IncludedFiles = $AllFiles | Where-Object {
    $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
    $excluded = $false
    foreach ($pattern in $ExcludePatterns) {
        if (-not $pattern) { continue }
        # Normalize pattern - remove trailing slash
        $cleanPattern = $pattern.TrimEnd('/')
        # Convert glob pattern to regex that matches anywhere in path
        $escaped = $cleanPattern -replace '\.', '\.' -replace '\*\*', '.*' -replace '\*', '[^/]*' -replace '\?', '.'
        # Match at start of path or after a /
        $regex = '(^|/)' + $escaped + '(/|$)'
        if ($relativePath -match $regex) {
            $excluded = $true
            break
        }
    }
    -not $excluded
}

# Ensure .specs directory exists
$IndexDir = Join-Path (Get-Location) ".specs"
if (-not (Test-Path $IndexDir)) {
    New-Item -ItemType Directory -Path $IndexDir -Force | Out-Null
}

# Build CSV
$IndexPath = Join-Path $IndexDir "index.csv"
$CsvData = $IncludedFiles | ForEach-Object {
    [PSCustomObject]@{
        path = $_.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
        last_modified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

$CsvData | Export-Csv -Path $IndexPath -NoTypeInformation -Encoding UTF8

Write-Output "Indexed $($CsvData.Count) files to .specs/index.csv"
