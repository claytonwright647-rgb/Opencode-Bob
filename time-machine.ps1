# OPENCODE BOB Time Machine - Complete Backup System
# Organizes by Day\Time-Label | 6-month retention | Infinite daily snapshots
# SAFETY: History is READ ONLY. Bob must never edit files inside time-machine.

param(
    [string]$Label    = "Auto",
    [string]$Type     = "Scheduled",   # PreTask | PostTask | Scheduled | Manual
    [string]$Project  = ""             # Optional: single project path. Empty = all projects.
)

$TM_ROOT    = "C:\Users\clayt\opencode-bob\time-machine"
$PROTECTED  = "C:\Users\clayt\OneDrive\Documents\02_VA"
$LOG_FILE   = "$TM_ROOT\time-machine.log"

# ONLY for scheduled snapshots: Exit if Opencode is not running
if ($Type -eq "Scheduled") {
    $running = $false
    Get-Process | ForEach-Object { if ($_.ProcessName -like "*opencode*") { $running = $true } }
    if (-not $running) { exit 0 }
}

# Source folders to back up when no specific project given
# For Opencode Bob, we back up his working directories
$SOURCE_ROOTS = @(
    "C:\Users\clayt\opencode-bob"
)

# Always exclude these patterns
$EXCLUDE_PATTERNS = @(
    "BobTimeMachine", "node_modules", "\bin\", "\obj\", "\.git",
    "\out\build\", "\.next", "\dist\", "\build\", "__pycache__",
    "AppData", ".vscode\extensions", "02_VA",
    "\.ai\time-machine", "\.ai\logs", "time-machine\",
    "Attachments", "drop-zone"  # Exclude temporary folders
)

function Should-Exclude($path) {
    foreach ($pat in $EXCLUDE_PATTERNS) {
        if ($path -like "*$pat*") { return $true }
    }
    if ($path.ToLower().StartsWith($PROTECTED.ToLower())) { return $true }
    return $false
}

function Copy-Snapshot($source, $dest) {
    if (!(Test-Path $source)) { return 0 }
    $copied = 0
    Get-ChildItem $source -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        if (Should-Exclude $_.FullName) { return }
        $rel   = $_.FullName.Substring($source.Length).TrimStart('\')
        $tDir  = Join-Path $dest (Split-Path $rel -Parent)
        if (!(Test-Path $tDir)) { New-Item -ItemType Directory -Force -Path $tDir | Out-Null }
        Copy-Item $_.FullName -Destination (Join-Path $dest $rel) -Force -ErrorAction SilentlyContinue
        $copied++
    }
    return $copied
}

# Build destination path
$dayFolder   = Get-Date -Format "yyyy-MM-dd"
$timeStamp   = Get-Date -Format "HH-mm-ss"
$safeLabel  = ($Label -replace '[^a-zA-Z0-9_\-]', '-').Substring(0, [Math]::Min($Label.Length, 40))
$snapshotName = "$timeStamp-$Type-$safeLabel"
$dayPath     = Join-Path $TM_ROOT $dayFolder
$snapPath    = Join-Path $dayPath $snapshotName

New-Item -ItemType Directory -Force -Path $snapPath | Out-Null

# Determine what to back up
if ($Project -ne "" -and (Test-Path $Project)) {
    $sources = @($Project)
} else {
    $sources = $SOURCE_ROOTS | Where-Object { Test-Path $_ }
}

# Copy files
$totalCopied = 0
foreach ($src in $sources) {
    $srcName   = Split-Path $src -Leaf
    $srcDest   = Join-Path $snapPath $srcName
    New-Item -ItemType Directory -Force -Path $srcDest | Out-Null
    $totalCopied += Copy-Snapshot $src $srcDest
}

# Write a manifest file so Bob knows exactly what this snapshot contains
$manifest = @{
    timestamp  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    label      = $Label
    type       = $Type
    sources    = $sources
    files      = $totalCopied
    snapshot   = $snapPath
    readonly   = $true
    rule       = "BOB MUST NEVER EDIT FILES IN THIS FOLDER. Copy to staging area first."
} | ConvertTo-Json -Depth 3
Set-Content -Path (Join-Path $snapPath "_BOB_MANIFEST.json") -Value $manifest

# Log entry
$entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Type] SNAPSHOT: $snapshotName | Files: $totalCopied | Sources: $($sources.Count)"
if (!(Test-Path (Split-Path $LOG_FILE))) { New-Item -ItemType Directory -Force -Path (Split-Path $LOG_FILE) | Out-Null }
Add-Content $LOG_FILE $entry -ErrorAction SilentlyContinue
Write-Host $entry

# 6-Month Retention: delete day-folders older than 180 days
$cutoff = (Get-Date).AddDays(-180)
Get-ChildItem $TM_ROOT -Directory -ErrorAction SilentlyContinue | Where-Object {
    try {
        $folderDate = [datetime]::ParseExact($_.Name, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
        return $folderDate -lt $cutoff
    } catch { return $false }
} | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    $delEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] PURGED (6mo): $($_.Name)"
    Add-Content $LOG_FILE $delEntry -ErrorAction SilentlyContinue
    Write-Host $delEntry
}

Write-Host "Opencode Bob Time Machine: Snapshot complete - $snapPath ($totalCopied files)"
Write-Output $snapPath