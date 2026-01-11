<#
.SYNOPSIS
    Gets statistics about changes since the last overview generation.

.DESCRIPTION
    Reads the overviewCommit from .specs/config.json and reports:
    - Whether this is a first run or incremental update
    - List of commits since last overview (hash and message)
    - List of all changed files across those commits

    Claude can then use:
    - git show <hash> to see changes in a specific commit
    - git diff <previousCommit>..<currentCommit> -- <file> for accumulated diff per file
    - git diff <previousCommit>..<currentCommit> for full accumulated diff

.OUTPUTS
    JSON object with stats
#>

$ConfigPath = Join-Path (Get-Location) ".specs/config.json"

# Check if config exists
if (-not (Test-Path $ConfigPath)) {
    @{
        type = "first-run"
        message = "No previous overview found"
    } | ConvertTo-Json
    exit 0
}

# Read config
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$OverviewCommit = $Config.overviewCommit

# Check if overviewCommit exists
if (-not $OverviewCommit) {
    @{
        type = "first-run"
        message = "No previous overview commit recorded"
    } | ConvertTo-Json
    exit 0
}

# Check if the commit exists in the repo
$CommitExists = git cat-file -t $OverviewCommit 2>$null
if (-not $CommitExists) {
    @{
        type = "first-run"
        message = "Previous commit $OverviewCommit not found in repository"
        previousCommit = $OverviewCommit
    } | ConvertTo-Json
    exit 0
}

# Get current commit
$CurrentCommit = git rev-parse HEAD

# Check if we're on the same commit
if ($OverviewCommit -eq $CurrentCommit) {
    @{
        type = "no-changes"
        message = "Overview is up to date"
        commit = $CurrentCommit
    } | ConvertTo-Json
    exit 0
}

# Get commits since last overview (hash and message)
$CommitLines = git log --format="%H|%s" "$OverviewCommit..HEAD" | Where-Object { $_ }
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

# Get all changed files since last overview
$ChangedFiles = git diff --name-only "$OverviewCommit..HEAD" | Where-Object { $_ }

# Build result object
$Result = @{
    type = "incremental"
    message = "Changes detected since last overview"
    previousCommit = $OverviewCommit
    currentCommit = $CurrentCommit
    commits = $Commits
    changedFiles = @($ChangedFiles)
}

# Save to .specs/temp/<commit_hash>.md
$TempDir = Join-Path (Get-Location) ".specs/temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

$ShortPrev = $OverviewCommit.Substring(0, 7)
$ShortCurr = $CurrentCommit.Substring(0, 7)
$StatsFile = Join-Path $TempDir "$ShortPrev-to-$ShortCurr.json"

$JsonContent = $Result | ConvertTo-Json -Depth 4
$JsonContent | Out-File -FilePath $StatsFile -Encoding UTF8

# Output JSON to console
$JsonContent
