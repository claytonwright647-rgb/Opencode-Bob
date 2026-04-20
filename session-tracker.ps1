# BOB'S SESSION TRACKER
# Tracks current work context for recovery after reboot/freeze
# Part of the persistent identity system

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "save",  # save, load, list, current, clear
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Status = "working",  # working, paused, completed, blocked
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Files = @(),
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Context = @{}
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$SESSION_DIR = "C:\Users\clayt\opencode-bob\memory\sessions"
$CURRENT_SESSION_FILE = Join-Path $SESSION_DIR "current-session.json"
$SESSION_HISTORY_FILE = Join-Path $SESSION_DIR "history.json"
$BOB_STATE_FILE = Join-Path $SESSION_DIR "bob-state.json"

# Ensure directory exists
New-Item -ItemType Directory -Force -Path $SESSION_DIR | Out-Null

# ============================================================================
# FUNCTIONS
# ============================================================================

function Save-CurrentSession {
    param(
        [string]$Task,
        [string]$Status,
        [string]$Details,
        [string[]]$Files,
        [hashtable]$Context
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    
    $session = @{
        "task" = $Task
        "status" = $Status
        "details" = $Details
        "files" = $Files
        "context" = $Context
        "started_at" = $timestamp
        "last_updated" = $timestamp
        "update_count" = 0
    }
    
    # Load existing session
    $current = $null
    if (Test-Path $CURRENT_SESSION_FILE) {
        $current = Get-Content $CURRENT_SESSION_FILE -Raw | ConvertFrom-Json
        if ($current.started_at) {
            $session.started_at = $current.started_at
            $session.update_count = ($current.update_count + 1)
        }
    }
    
    # Save current session
    $session | ConvertTo-Json -Depth 5 | Set-Content $CURRENT_SESSION_FILE
    
    # Add to history
    Add-SessionToHistory $session
    
    Write-Host "SESSION SAVED: $Task" -ForegroundColor Green
    Write-Host "  Status: $Status" -ForegroundColor Cyan
    if ($Details) { Write-Host "  Details: $Details" -ForegroundColor Gray }
    if ($Files.Count -gt 0) { Write-Host "  Files: $($Files.Count)" -ForegroundColor Gray }
    
    return $session
}

function Add-SessionToHistory {
    param([hashtable]$Session)
    
    $history = @()
    if (Test-Path $SESSION_HISTORY_FILE) {
        $history = Get-Content $SESSION_HISTORY_FILE -Raw | ConvertFrom-Json
        if ($history -isnot [System.Array]) { $history = @($history) }
    }
    
    # Add to beginning
    $history = @($Session) + $history
    
    # Keep last 50 sessions
    if ($history.Count -gt 50) {
        $history = $history[0..49]
    }
    
    $history | ConvertTo-Json -Depth 5 | Set-Content $SESSION_HISTORY_FILE
}

function Load-CurrentSession {
    if (Test-Path $CURRENT_SESSION_FILE) {
        $session = Get-Content $CURRENT_SESSION_FILE -Raw | ConvertFrom-Json
        Write-Host "CURRENT SESSION:" -ForegroundColor Yellow
        Write-Host "  Task: $($session.task)" -ForegroundColor White
        Write-Host "  Status: $($session.status)" -ForegroundColor Cyan
        if ($session.details) { Write-Host "  Details: $($session.details)" -ForegroundColor Gray }
        if ($session.files) { Write-Host "  Files: $($session.files -join ', ')" -ForegroundColor Gray }
        Write-Host "  Started: $($session.started_at)" -ForegroundColor Gray
        Write-Host "  Updates: $($session.update_count)" -ForegroundColor Gray
        return $session
    } else {
        Write-Host "No current session found" -ForegroundColor Yellow
        return $null
    }
}

function Get-SessionHistory {
    if (Test-Path $SESSION_HISTORY_FILE) {
        $history = Get-Content $SESSION_HISTORY_FILE -Raw | ConvertFrom-Json
        if ($history -isnot [System.Array]) { $history = @($history) }
        
        Write-Host "SESSION HISTORY:" -ForegroundColor Yellow
        $i = 0
        foreach ($sess in $history) {
            $i++
            if ($i -gt 10) { break }  # Show last 10
            $color = if ($sess.status -eq "completed") { "Green" } elseif ($sess.status -eq "blocked") { "Red" } else { "White" }
            Write-Host "  [$($sess.status)] $($sess.task)" -ForegroundColor $color
            Write-Host "      $($sess.started_at) - $($sess.details)" -ForegroundColor Gray
        }
        return $history
    }
    return @()
}

function Save-BobState {
    param([Parameter(ValueFromPipeline=$true)][object]$State)
    
    # Convert PSCustomObject to hashtable if needed
    $stateHash = @{}
    $State.PSObject.Properties | ForEach-Object { $stateHash[$_.Name] = $_.Value }
    
    $stateHash.last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    $stateHash | ConvertTo-Json -Depth 5 | Set-Content $BOB_STATE_FILE
    return $stateHash
}

function Get-BobState {
    if (Test-Path $BOB_STATE_FILE) {
        return Get-Content $BOB_STATE_FILE -Raw | ConvertFrom-Json
    }
    
    # Default state
    return @{
        "name" = "Opencode Bob"
        "version" = "1.0"
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "last_updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "boot_count" = 1
        "total_sessions" = 0
        "total_tasks_completed" = 0
        "first_boot" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "last_seen" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
}

function Clear-CurrentSession {
    if (Test-Path $CURRENT_SESSION_FILE) {
        Remove-Item $CURRENT_SESSION_FILE -Force
        Write-Host "Current session cleared" -ForegroundColor Yellow
    }
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "save" {
        if (-not $Task) {
            Write-Host "Error: Task is required for save operation" -ForegroundColor Red
            exit 1
        }
        Save-CurrentSession -Task $Task -Status $Status -Details $Details -Files $Files -Context $Context
    }
    
    "load" {
        Load-CurrentSession
    }
    
    "current" {
        Load-CurrentSession
    }
    
    "list" {
        Get-SessionHistory
    }
    
    "history" {
        Get-SessionHistory
    }
    
    "state" {
        Get-BobState
    }
    
    "clear" {
        Clear-CurrentSession
    }
    
    "complete" {
        # Mark current task as completed
        $sessionObj = Load-CurrentSession
        if ($sessionObj) {
            # Convert PSCustomObject to hashtable for modification
            $session = @{}
            $sessionObj.PSObject.Properties | ForEach-Object { $session[$_.Name] = $_.Value }
            $session.status = "completed"
            $session.last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            $session | ConvertTo-Json -Depth 5 | Set-Content $CURRENT_SESSION_FILE
            Add-SessionToHistory $session
            
            # Update bob state
            $stateObj = Get-BobState
            $state = @{}
            $stateObj.PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value }
            $state.total_tasks_completed++
            $state.last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            Save-BobState $state
            
            Write-Host "Task marked as completed: $($session.task)" -ForegroundColor Green
        }
    }
    
    "startup" {
        # Called on Bob's startup - loads context
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "   OPENCODE BOB - INITIALIZING..." -ForegroundColor Yellow
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        # Get Bob's state
        $state = Get-BobState
        $state.last_seen = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        $state | ConvertTo-Json -Depth 5 | Set-Content $BOB_STATE_FILE
        
        Write-Host "Identity: $($state.name) v$($state.version)" -ForegroundColor White
        Write-Host "Boot count: $($state.boot_count)" -ForegroundColor Cyan
        Write-Host "Tasks completed: $($state.total_tasks_completed)" -ForegroundColor Green
        Write-Host "First boot: $($state.first_boot)" -ForegroundColor Gray
        
        # Load current session if exists
        $session = Load-CurrentSession
        if ($session -and $session.status -eq "working") {
            Write-Host "`nRESUMING WORK:" -ForegroundColor Yellow
            Write-Host "  Task: $($session.task)" -ForegroundColor White
            Write-Host "  Details: $($session.details)" -ForegroundColor Gray
            if ($session.files) {
                Write-Host "  Files: $($session.files -join ', ')" -ForegroundColor Gray
            }
            Write-Host "  Started: $($session.started_at)" -ForegroundColor Gray
            Write-Host "`nSay 'resume' to continue this work.`n" -ForegroundColor Cyan
        }
        
        # Load recent learnings
        $learningFile = "C:\Users\clayt\opencode-bob\memory\learning\stats.json"
        if (Test-Path $learningFile) {
            $learning = Get-Content $learningFile -Raw | ConvertFrom-Json
            if ($learning.total_patterns) {
                Write-Host "Learned patterns: $($learning.total_patterns)" -ForegroundColor Green
            }
        }
        
        Write-Host "`n========================================`n" -ForegroundColor Cyan
        
        return $state
    }
    
    default {
        Write-Host "Usage: session-tracker.ps1 -Operation <save|load|current|list|state|clear|complete|startup>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\session-tracker.ps1 -Operation save -Task 'Build feature X' -Status working -Details 'Implementing API'"
        Write-Host "  .\session-tracker.ps1 -Operation load"
        Write-Host "  .\session-tracker.ps1 -Operation list"
        Write-Host "  .\session-tracker.ps1 -Operation startup"
    }
}
