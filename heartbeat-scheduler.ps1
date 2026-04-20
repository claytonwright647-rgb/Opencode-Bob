# BOB'S HEARTBEAT SCHEDULER
# Proactive background task execution
# Inspired by OpenClaw's heartbeat system

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "schedule",  # schedule, list, run, status
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Interval = "30min",  # 1min, 5min, 15min, 30min, 1hour, daily
    
    [Parameter(Mandatory=$false)]
    [string]$Command = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$SCHEDULER_DIR = "C:\Users\clayt\opencode-bob\memory\scheduler"
$TASKS_FILE = "$SCHEDULER_DIR\tasks.json"
$RUNS_FILE = "$SCHEDULER_DIR\runs.json"

if (-not (Test-Path $SCHEDULER_DIR)) {
    New-Item -ItemType Directory -Force -Path $SCHEDULER_DIR | Out-Null
}

# ============================================================================
# INTERVAL CONVERSIONS
# ============================================================================

$INTERVALS = @{
    "1min" = 60
    "5min" = 300
    "15min" = 900
    "30min" = 1800
    "1hour" = 3600
    "daily" = 86400
}

# ============================================================================
# STATE
# ============================================================================

function Get-SchedulerState {
    if (Test-Path $TASKS_FILE) {
        return Get-Content $TASKS_FILE -Raw | ConvertFrom-Json
    }
    return @{ tasks = @(); running = $false }
}

function Save-SchedulerState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $TASKS_FILE
}

# ============================================================================
# SCHEDULE TASK
# ============================================================================

function New-ScheduledTask {
    param([string]$Name, [string]$Interval, [string]$Cmd)
    
    $state = Get-SchedulerState
    
    # Check exists
    foreach ($task in $state.tasks) {
        if ($task.name -eq $Name) {
            return @{ success = $false; reason = "exists" }
        }
    }
    
    $task = @{
        name = $Name
        interval = $Interval
        intervalSeconds = $INTERVALS[$Interval]
        command = $Cmd
        enabled = $true
        scheduled = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        lastRun = $null
        nextRun = (Get-Date).AddSeconds($INTERVALS[$Interval]).ToString("yyyy-MM-dd HH:mm:ss")
        runCount = 0
    }
    
    $state.tasks += $task
    Save-SchedulerState -State $state
    
    return @{
        success = $true
        name = $Name
        interval = $Interval
        nextRun = $task.nextRun
    }
}

# ============================================================================
# LIST TASKS
# ============================================================================

function Get-TaskList {
    $state = Get-SchedulerState
    
    $tasks = @()
    foreach ($task in $state.tasks) {
        $tasks += @{
            name = $task.name
            interval = $task.interval
            enabled = $task.enabled
            lastRun = $task.lastRun
            nextRun = $task.nextRun
            runCount = $task.runCount
        }
    }
    
    return @{
        tasks = $tasks
        count = $tasks.Count
        running = $state.running
    }
}

# ============================================================================
# RUN TASK NOW
# ============================================================================

function Run-TaskNow {
    param([string]$Name)
    
    $state = Get-SchedulerState
    $task = $null
    
    foreach ($t in $state.tasks) {
        if ($t.name -eq $Name) {
            $task = $t
            break
        }
    }
    
    if (-not $task) {
        return @{ success = $false; reason = "not_found" }
    }
    
    # Log run
    $runs = @()
    if (Test-Path $RUNS_FILE) {
        $runs = Get-Content $RUNS_FILE -Raw | ConvertFrom-Json
        if (-not ($runs -is [array])) { $runs = @($runs) }
    }
    
    $run = @{
        task = $Name
        startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "running"
    }
    
    $runs += $run
    $runs | ConvertTo-Json -Depth 10 | Set-Content $RUNS_FILE
    
    # Execute command (simplified - just log for now)
    Write-Output "Would execute: $($task.command)"
    
    # Update task
    $task.lastRun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $task.runCount++
    $task.nextRun = (Get-Date).AddSeconds($task.intervalSeconds).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Mark run complete
    $runs[-1].endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $runs[-1].status = "completed"
    $runs | ConvertTo-Json -Depth 10 | Set-Content $RUNS_FILE
    
    Save-SchedulerState -State $state
    
    return @{
        success = $true
        name = $Name
        completed = $task.lastRun
    }
}

# ============================================================================
# CHECK DUE TASKS
# ============================================================================

function Get-DueTasks {
    $state = Get-SchedulerState
    $now = Get-Date
    
    $due = @()
    foreach ($task in $state.tasks) {
        if (-not $task.enabled) { continue }
        
        $nextRun = [DateTime]::Parse($task.nextRun)
        if ($now -ge $nextRun) {
            $due += $task.name
        }
    }
    
    return @{
        due = $due
        count = $due.Count
        now = $now.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# ============================================================================
# ENABLE/DISABLE
# ============================================================================

function Set-TaskEnabled {
    param([string]$Name, [bool]$Enabled)
    
    $state = Get-SchedulerState
    $found = $false
    
    foreach ($task in $state.tasks) {
        if ($task.name -eq $Name) {
            $task.enabled = $Enabled
            $found = $true
        }
    }
    
    if ($found) {
        Save-SchedulerState -State $state
    }
    
    return @{
        success = $found
        name = $Name
        enabled = $Enabled
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "schedule" {
        if ($TaskName -eq "" -or $Command -eq "") {
            Write-Error "TaskName and Command required"
        }
        New-ScheduledTask -Name $TaskName -Interval $Interval -Cmd $Command
    }
    "list" {
        Get-TaskList
    }
    "run" {
        if ($TaskName -eq "") {
            Write-Error "TaskName required"
        }
        Run-TaskNow -Name $TaskName
    }
    "due" {
        Get-DueTasks
    }
    "enable" {
        if ($TaskName -eq "") {
            Write-Error "TaskName required"
        }
        Set-TaskEnabled -Name $TaskName -Enabled $true
    }
    "disable" {
        if ($TaskName -eq "") {
            Write-Error "TaskName required"
        }
        Set-TaskEnabled -Name $TaskName -Enabled $false
    }
    "status" {
        $state = Get-SchedulerState
        @{running=$state.running; totalTasks=$state.tasks.Count}
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}