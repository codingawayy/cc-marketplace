<#
.SYNOPSIS
    Gets statistics about changes since a previous generation.

.DESCRIPTION
    Reads a commit hash from .specs/config.json and reports:
    - Whether this is a first run or incremental update
    - List of commits since last generation (hash and message)
    - List of all changed files across those commits

    Claude can then use:
    - git show <hash> to see changes in a specific commit
    - git diff <previousCommit>..<currentCommit> -- <file> for accumulated diff per file
    - git diff <previousCommit>..<currentCommit> for full accumulated diff

.PARAMETER For
    What to check changes for.
    Valid values: "overview", "specs"
    Default: "overview"

.OUTPUTS
    JSON object with stats
#>

param(
    [ValidateSet("overview", "specs")]
    [string]$For = "overview"
)

$ConfigPath = Join-Path (Get-Location) ".specs/config.json"

# Map parameter to config key
$ConfigKeys = @{
    "overview" = "overviewCommit"
    "specs" = "specsCommit"
}
$CommitKey = $ConfigKeys[$For]

# Check if config exists
if (-not (Test-Path $ConfigPath)) {
    @{
        type = "first-run"
        message = "No previous $For found"
    } | ConvertTo-Json
    exit 0
}

# Read config
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$PreviousCommit = $Config.$CommitKey

# Check if commit key exists
if (-not $PreviousCommit) {
    @{
        type = "first-run"
        message = "No previous $For commit recorded"
    } | ConvertTo-Json
    exit 0
}

# Check if the commit exists in the repo
$CommitExists = git cat-file -t $PreviousCommit 2>$null
if (-not $CommitExists) {
    @{
        type = "first-run"
        message = "Previous commit $PreviousCommit not found in repository"
        previousCommit = $PreviousCommit
    } | ConvertTo-Json
    exit 0
}

# Get current commit
$CurrentCommit = git rev-parse HEAD

# Check if we're on the same commit
if ($PreviousCommit -eq $CurrentCommit) {
    @{
        type = "no-changes"
        message = "$($For.Substring(0,1).ToUpper() + $For.Substring(1)) is up to date"
        commit = $CurrentCommit
    } | ConvertTo-Json
    exit 0
}

# Get commits since last generation (hash and message)
$CommitLines = git log --format="%H|%s" "$PreviousCommit..HEAD" | Where-Object { $_ }
$Commits = @()
if ($CommitLines) {
    foreach ($line in $CommitLines) {
        $parts = $line -split '\|', 2
        $Commits += @{
            hash = $parts[0]
            message = $parts[1]
        }
    }
}

# Get all changed files since last generation
$ChangedFiles = git diff --name-only "$PreviousCommit..HEAD" | Where-Object { $_ }

# Build result object
$Result = @{
    type = "incremental"
    message = "Changes detected since last $For"
    previousCommit = $PreviousCommit
    currentCommit = $CurrentCommit
    commits = $Commits
    changedFiles = @($ChangedFiles)
}

# Save to .specs/temp/<prev>-to-<curr>.json
$TempDir = Join-Path (Get-Location) ".specs/temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

$ShortPrev = $PreviousCommit.Substring(0, 7)
$ShortCurr = $CurrentCommit.Substring(0, 7)
$StatsFile = Join-Path $TempDir "$ShortPrev-to-$ShortCurr.json"

$JsonContent = $Result | ConvertTo-Json -Depth 4
$JsonContent | Out-File -FilePath $StatsFile -Encoding UTF8

# Output JSON to console
$JsonContent
