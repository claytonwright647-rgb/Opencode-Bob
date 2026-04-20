# BOB'S GOAL TRACKER
# Tracks objectives, subgoals, progress
# Enables multi-tasking with clear goals

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, goal, complete, fail, list
    
    [Parameter(Mandatory=$false)]
    [string]$Goal = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ParentGoal = "",
    
    [ValidateSet("pending", "in_progress", "completed", "blocked", "failed")]
    [string]$Status = "pending"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$GOALS_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\goals.json"
$GOAL_HISTORY = "C:\Users\clayt\opencode-bob\memory\sessions\goal-history.json"

# ============================================================================
# GOAL MANAGEMENT
# ============================================================================

function Get-Goals {
    if (Test-Path $GOALS_FILE) {
        return Get-Content $GOALS_FILE -Raw | ConvertFrom-Json
    }
    return @{ "goals" = @(); "root_goals" = @() }
}

function Save-Goals {
    param([hashtable]$Goals)
    $Goals | ConvertTo-Json -Depth 10 | Set-Content $GOALS_FILE
}

function Add-Goal {
    param(
        [string]$Goal,
        [string]$Details,
        [string]$ParentGoal
    )
    
    $goalsData = Get-Goals
    
    $newGoal = @{
        "id" = [guid]::NewGuid().ToString().Substring(0, 8)
        "goal" = $Goal
        "details" = $Details
        "status" = "pending"
        "parent" = $ParentGoal
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "progress" = 0
        "subgoals" = @()
    }
    
    # Add as root goal or sub-goal
    if ($ParentGoal) {
        # Find parent
        foreach ($g in $goalsData.goals) {
            if ($g.goal -eq $ParentGoal) {
                if (-not $g.subgoals) { $g.subgoals = @() }
                $g.subgoals += $newGoal
                break
            }
        }
    } else {
        $goalsData.root_goals += $newGoal
    }
    
    $goalsData.goals += $newGoal
    Save-Goals $goalsData
    
    Write-Host "📌 Goal added: $Goal" -ForegroundColor Green
    if ($Details) { Write-Host "   → $Details" -ForegroundColor Gray }
}

function Complete-Goal {
    param([string]$Goal)
    
    $goalsData = Get-Goals
    
    foreach ($g in $goalsData.goals) {
        if ($g.goal -eq $Goal) {
            $g.status = "completed"
            $g.progress = 100
            $g.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            break
        }
    }
    
    Save-Goals $goalsData
    Write-Host "✅ Goal completed: $Goal" -ForegroundColor Green
}

function Fail-Goal {
    param([string]$Goal)
    
    $goalsData = Get-Goals
    
    foreach ($g in $goalsData.goals) {
        if ($g.goal -eq $Goal) {
            $g.status = "failed"
            $g.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            break
        }
    }
    
    Save-Goals $goalsData
    Write-Host "❌ Goal failed: $Goal" -ForegroundColor Red
}

function Update-Progress {
    param(
        [string]$Goal,
        [int]$Progress
    )
    
    $goalsData = Get-Goals
    
    foreach ($g in $goalsData.goals) {
        if ($g.goal -eq $Goal) {
            $g.progress = $Progress
            $g.status = if ($Progress -ge 100) { "completed" } elseif ($Progress -gt 0) { "in_progress" } else { "pending" }
            $g.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            break
        }
    }
    
    Save-Goals $goalsData
    Write-Host "📈 Progress: $Goal = $Progress%" -ForegroundColor Cyan
}

function Show-Status {
    $goalsData = Get-Goals
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📌 BOB'S GOALS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    $rootGoals = $goalsData.root_goals
    if (-not $rootGoals -or $rootGoals.Count -eq 0) {
        Write-Host "  (no active goals)" -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    foreach ($g in $rootGoals) {
        $statusIcon = switch ($g.status) {
            "pending" { "⏳" }
            "in_progress" { "🔄" }
            "completed" { "✅" }
            "blocked" { "🚫" }
            "failed" { "❌" }
            default { "•" }
        }
        
        $statusColor = switch ($g.status) {
            "completed" { "Green" }
            "in_progress" { "Cyan" }
            "failed" { "Red" }
            "blocked" { "Yellow" }
            default { "White" }
        }
        
        Write-Host "  $statusIcon [$($g.status)] $($g.goal)" -ForegroundColor $statusColor
        
        if ($g.details) {
            Write-Host "     → $($g.details)" -ForegroundColor Gray
        }
        
        if ($g.progress -and $g.progress -gt 0 -and $g.progress -lt 100) {
            Write-Host "     📊 $($g.progress)%" -ForegroundColor Cyan
        }
        
        # Show subgoals
        if ($g.subgoals -and $g.subgoals.Count -gt 0) {
            Write-Host "     Subgoals:" -ForegroundColor Gray
            foreach ($sg in $g.subgoals) {
                $sgIcon = switch ($sg.status) {
                    "completed" { "✅" }
                    "pending" { "⏳" }
                    "in_progress" { "🔄" }
                    default { "•" }
                }
                Write-Host "       $sgIcon $($sg.goal)" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Show-Status
    }
    
    "goal" {
        if (-not $Goal) {
            Write-Host "Usage: goal-tracker.ps1 -Operation goal -Goal <goal> -Details <details> [-ParentGoal <parent>]"
            exit 1
        }
        Add-Goal -Goal $Goal -Details $Details -ParentGoal $ParentGoal
    }
    
    "complete" {
        if (-not $Goal) {
            Write-Host "Usage: goal-tracker.ps1 -Operation complete -Goal <goal>"
            exit 1
        }
        Complete-Goal -Goal $Goal
    }
    
    "fail" {
        if (-not $Goal) {
            Write-Host "Usage: goal-tracker.ps1 -Operation fail -Goal <goal>"
            exit 1
        }
        Fail-Goal -Goal $Goal
    }
    
    "progress" {
        if (-not $Goal -or -not $Details) {
            Write-Host "Usage: goal-tracker.ps1 -Operation progress -Goal <goal> -Details <0-100>"
            exit 1
        }
        Update-Progress -Goal $Goal -Progress ([int]$Details)
    }
    
    "list" {
        Show-Status
    }
    
    "clear" {
        $goalsData = @{ "goals" = @(); "root_goals" = @() }
        Save-Goals $goalsData
        Write-Host "Goals cleared" -ForegroundColor Yellow
    }
    
    default {
        Show-Status
    }
}