# BOB'S AUTO-SAVE SYSTEM
# Automatically saves session state periodically
# Prevents data loss on crash/freeze/reboot

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [int]$IntervalMinutes = 5
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$BOB_DIR = "C:\Users\clayt\opencode-bob"
$AUTO_SAVE_JOB = "OpencodeBobAutoSave"
$STATE_FILE = "$BOB_DIR\memory\sessions\bob-state.json"

# ============================================================================
# FUNCTIONS
# ============================================================================

function Start-AutoSave {
    # Stop existing job if any
    Stop-AutoSave
    
    $scriptPath = "$BOB_DIR\session-tracker.ps1"
    
    # Create a simple trigger - every $IntervalMinutes minutes
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration ([TimeSpan]::MaxValue)
    
    # Task action - save current session state
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Write-Host 'Auto-save triggered at:' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); & '$scriptPath' -Operation save -Task 'Auto-save' -Status 'working' -Details 'Background auto-save'" -WorkingDirectory $BOB_DIR
    
    # Settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    
    # Register task
    Register-ScheduledTask -TaskName $AUTO_SAVE_JOB -Trigger $trigger -Action $action -Settings $settings -Description "Opencode Bob auto-save session state" -Force | Out-Null
    
    Write-Host "Auto-save started (every $IntervalMinutes minutes)" -ForegroundColor Green
    Write-Host "Job name: $AUTO_SAVE_JOB" -ForegroundColor Cyan
}

function Stop-AutoSave {
    try {
        Unregister-ScheduledTask -TaskName $AUTO_SAVE_JOB -Confirm:$false -ErrorAction Stop
        Write-Host "Auto-save stopped" -ForegroundColor Yellow
    } catch {
        # Job doesn't exist, that's fine
    }
}

function Get-AutoSaveStatus {
    $task = Get-ScheduledTask -TaskName $AUTO_SAVE_JOB -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-Host "Auto-save: RUNNING" -ForegroundColor Green
        Write-Host "Task State: $($task.State)" -ForegroundColor Cyan
        Write-Host "Last Run: $($task.LastRunTime)" -ForegroundColor Gray
        Write-Host "Next Run: $($task.NextRunTime)" -ForegroundColor Gray
    } else {
        Write-Host "Auto-save: NOT RUNNING" -ForegroundColor Yellow
        Write-Host "Use -Start to enable auto-save" -ForegroundColor Gray
    }
}

function Update-BobState {
    # Update last_seen timestamp
    if (Test-Path $STATE_FILE) {
        $state = Get-Content $STATE_FILE -Raw | ConvertFrom-Json
        $state.last_seen = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        $state | ConvertTo-Json -Depth 3 | Set-Content $STATE_FILE
    }
}

# ============================================================================
# MAIN
# ============================================================================

if ($Start) {
    Start-AutoSave
} elseif ($Stop) {
    Stop-AutoSave
} elseif ($Status) {
    Get-AutoSaveStatus
} else {
    # Default: just update state timestamp
    Update-BobState
    Write-Host "Bob state updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
}