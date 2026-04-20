# BOB'S PROGRESS TRACKER
# Track progress on multi-step tasks
# For long-running workflows

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "init",  # init, update, status, complete, list
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Milestone = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Status = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Notes = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$PROGRESS_DIR = "C:\Users\clayt\opencode-bob\memory\progress"
$TASKS_FILE = "$PROGRESS_DIR\tasks.json"

if (-not (Test-Path $PROGRESS_DIR)) {
    New-Item -ItemType Directory -Force -Path $PROGRESS_DIR | Out-Null
}

# ============================================================================
# STATE
# ============================================================================

function Get-TaskState {
    if (Test-Path $TASKS_FILE) {
        return Get-Content $TASKS_FILE -Raw | ConvertFrom-Json
    }
    return @{ tasks = @() }
}

function Save-TaskState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $TASKS_FILE
}

# ============================================================================
# INITIALIZE TASK
# ============================================================================

function Initialize-Task {
    param([string]$Name, [string]$InitialMilestone)
    
    $state = Get-TaskState
    
    # Check exists
    foreach ($task in $state.tasks) {
        if ($task.name -eq $Name) {
            return @{ success = $false; reason = "exists" }
        }
    }
    
    $task = @{
        name = $Name
        status = "in_progress"
        started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        milestones = @()
        completed = 0
        total = 0
    }
    
    # Add initial milestone if provided
    if ($InitialMilestone -ne "") {
        $task.milestones += @{
            name = $InitialMilestone
            status = "in_progress"
            started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $task.total = 1
    }
    
    $state.tasks += $task
    Save-TaskState -State $state
    
    return @{
        success = $true
        task = $Name
        status = "in_progress"
    }
}

# ============================================================================
# UPDATE MILESTONE
# ============================================================================

function Update-Milestone {
    param([string]$Task, [string]$MilestoneName, [string]$NewStatus, [string]$Note)
    
    $state = Get-TaskState
    $found = $false
    
    foreach ($task in $state.tasks) {
        if ($task.name -eq $Task) {
            $found = $true
            
            # Check if milestone exists
            $ms = $null
            foreach ($m in $task.milestones) {
                if ($m.name -eq $MilestoneName) {
                    $ms = $m
                    break
                }
            }
            
            if ($ms) {
                # Update existing
                if ($NewStatus) { $ms.status = $NewStatus }
                if ($NewStatus -eq "completed") {
                    $ms.completed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $task.completed++
                }
                if ($Note) { $ms.notes = $Note }
            } else {
                # Add new
                $task.milestones += @{
                    name = $MilestoneName
                    status = if ($NewStatus) { $NewStatus } else { "in_progress" }
                    started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    notes = $Note
                }
                $task.total++
            }
            
            # Update task status
            if ($task.completed -eq $task.total -and $task.total -gt 0) {
                $task.status = "completed"
                $task.completedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    
    if (-not $found) {
        return @{ success = $false; reason = "not_found" }
    }
    
    Save-TaskState -State $state
    
    return @{
        success = $true
        task = $Task
        milestone = $MilestoneName
        status = $NewStatus
    }
}

# ============================================================================
# GET TASK STATUS
# ============================================================================

function Get-TaskStatus {
    param([string]$Task)
    
    $state = Get-TaskState
    
    if ($Task) {
        foreach ($t in $state.tasks) {
            if ($t.name -eq $Task) {
                $pct = 0
                if ($t.total -gt 0) {
                    $pct = [math]::Round(($t.completed / $t.total) * 100)
                }
                return @{
                    name = $t.name
                    status = $t.status
                    completed = $t.completed
                    total = $t.total
                    progress = $pct
                    started = $t.started
                    milestones = $t.milestones
                }
            }
        }
        return @{ error = "not_found" }
    }
    
    # All tasks
    $tasks = @()
    foreach ($t in $state.tasks) {
        $pct = 0
        if ($t.total -gt 0) {
            $pct = [math]::Round(($t.completed / $t.total) * 100)
        }
        $tasks += @{
            name = $t.name
            status = $t.status
            progress = $pct
            completed = $t.completed
            total = $t.total
        }
    }
    
    return @{ tasks = $tasks }
}

# ============================================================================
# COMPLETE TASK
# ============================================================================

function Complete-Task {
    param([string]$Task)
    
    $state = Get-TaskState
    
    foreach ($t in $state.tasks) {
        if ($t.name -eq $Task) {
            $t.status = "completed"
            $t.completedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $t.completed = $t.total
            break
        }
    }
    
    Save-TaskState -State $state
    
    return @{
        success = $true
        task = $Task
        status = "completed"
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "init" {
        if ($TaskName -eq "") {
            Write-Error "TaskName required"
        }
        Initialize-Task -Name $TaskName -InitialMilestone $Milestone
    }
    "update" {
        if ($TaskName -eq "" -or $Milestone -eq "") {
            Write-Error "TaskName and Milestone required"
        }
        Update-Milestone -Task $TaskName -MilestoneName $Milestone -NewStatus $Status -Note $Notes
    }
    "status" {
        Get-TaskStatus -Task $TaskName
    }
    "complete" {
        if ($TaskName -eq "") {
            Write-Error "TaskName required"
        }
        Complete-Task -Task $TaskName
    }
    "list" {
        Get-TaskStatus -Task ""
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}