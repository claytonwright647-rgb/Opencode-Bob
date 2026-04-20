# =============================================================================
# BOB'S AUTO-SYNC - GitHub Automatic Sync
# =============================================================================
# Monitors local files and automatically pushes changes to GitHub
# Run this in background: Start-Job -FilePath auto-sync.ps1
# =============================================================================

param(
    [string]$WatchPath = "C:\Users\clayt\opencode-bob",
    [int]$DebounceSeconds = 5,
    [switch]$OneTime
)

$ErrorActionPreference = "Continue"

# GitHub repo info
$RepoUrl = "https://github.com/claytonwright647-rgb/Opencode-Bob.git"
$Branch = "main"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "     BOB'S AUTO-SYNC - GitHub Sync Service" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Watching: $WatchPath" -ForegroundColor White
Write-Host "  Repo: $RepoUrl" -ForegroundColor Gray
Write-Host "  Branch: $Branch" -ForegroundColor Gray
Write-Host ""

# Track last sync time
$lastSync = Get-Date

# Get list of files to ignore
$ignorePatterns = @(
    "*.log",
    "*.tmp",
    "*.temp",
    "memory",
    "memory-*",
    "parallel-results",
    "screenshots",
    "time-machine",
    ".git"
)

function Test-Ignored {
    param([string]$Path)
    foreach ($pattern in $ignorePatterns) {
        if ($Path -match [regex]::Escape($pattern)) {
            return $true
        }
    }
    return $false
}

function Sync-ToGitHub {
    Write-Host ""
    Write-Host "[SYNC] Checking for changes..." -ForegroundColor Cyan

    Set-Location $WatchPath

    # Check git status
    $status = git status --porcelain 2>$null

    if ($status) {
        Write-Host "[SYNC] Changes detected!" -ForegroundColor Yellow

        # Stage all changes
        git add -A

        # Create commit with timestamp
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $commitMsg = "Auto-sync: $timestamp"

        git commit -m $commitMsg 2>$null

        # Push to GitHub
        Write-Host "[SYNC] Pushing to GitHub..." -ForegroundColor Green
        $result = git push origin $Branch 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SYNC] ✅ Pushed successfully!" -ForegroundColor Green
        } else {
            Write-Host "[SYNC] ❌ Push failed: $result" -ForegroundColor Red
        }

        $script:lastSync = Get-Date
    } else {
        Write-Host "[SYNC] No changes" -ForegroundColor Gray
    }
}

# Initial sync
Write-Host "[SYNC] Initial sync..." -ForegroundColor Cyan
Sync-ToGitHub

if ($OneTime) {
    Write-Host "[SYNC] One-time mode complete!" -ForegroundColor Green
    exit 0
}

# Continuous monitoring using FileSystemWatcher
Write-Host "[SYNC] Starting continuous monitoring..." -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Debounce mechanism
$lastChange = Get-Date
$pendingSync = $false

$action = {
    $script:lastChange = Get-Date
    $script:pendingSync = $true
}

Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action

# Main loop
try {
    while ($true) {
        Start-Sleep -Seconds 1

        if ($pendingSync) {
            $elapsed = (Get-Date) - $lastChange

            if ($elapsed.TotalSeconds -ge $DebounceSeconds) {
                Sync-ToGitHub
                $pendingSync = $false
            }
        }
    }
}
finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Host ""
    Write-Host "[SYNC] Stopped monitoring" -ForegroundColor Yellow
}