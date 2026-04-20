# BOB'S REASONING NARRATOR
# Shows thinking process like Claude AI does
# Enables transparent reasoning

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "start",  # start, think, done, abort, show
    
    [Parameter(Mandatory=$false)]
    [string]$Reason = "",
    
    [Switch]$Silent
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$REASONING_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\current-reasoning.json"
$REASONING_HISTORY = "C:\Users\clayt\opencode-bob\memory\sessions\reasoning-history.json"

# ============================================================================
# REASONING TRACKER
# ============================================================================

class ReasoningStep {
    [int]$step_number
    [string]$thought
    [string]$type  # observation, hypothesis, evidence, plan, action, verification, conclusion
    [datetime]$timestamp
    [bool]$confirmed = $false
    [string]$confidence = "MEDIUM"
}

class ReasoningChain {
    [string]$id
    [string]$task
    [datetime]$started
    [datetime]$updated
    [ReasoningStep[]]$steps = @()
    [string]$current_step = ""
    [bool]$complete = $false
    [string]$conclusion = ""
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Start-Reasoning {
    param([string]$Task)
    
    $chain = [ReasoningChain]::new()
    $chain.id = [guid]::NewGuid().ToString()
    $chain.task = $Task
    $chain.started = Get-Date
    $chain.updated = Get-Date
    
    # First step: observation
    $step = [ReasoningStep]::new()
    $step.step_number = 1
    $step.thought = "Analyzing: $Task"
    $step.type = "observation"
    $step.timestamp = Get-Date
    $chain.steps += $step
    
    $chain | ConvertTo-Json -Depth 10 | Set-Content $REASONING_FILE
    
    if (-not $Silent) {
        Write-Host "🤔 Thinking about: $Task" -ForegroundColor Yellow
    }
    
    return $chain
}

function Think-Step {
    param(
        [string]$Thought,
        [string]$Type = "hypothesis",
        [string]$Confidence = "MEDIUM"
    )
    
    if (-not (Test-Path $REASONING_FILE)) {
        Write-Host "No active reasoning. Use -Operation start first." -ForegroundColor Red
        return $null
    }
    
    $json = Get-Content $REASONING_FILE -Raw | ConvertFrom-Json
    $chain = @{}
    $json.PSObject.Properties | ForEach-Object { $chain[$_.Name] = $_.Value }
    
    # Convert steps
    $steps = @()
    foreach ($s in $json.steps) {
        $step = @{}
        $s.PSObject.Properties | ForEach-Object { $step[$_.Name] = $_.Value }
        $steps += $step
    }
    
    # Add new step
    $newStep = @{
        "step_number" = $steps.Count + 1
        "thought" = $Thought
        "type" = $Type
        "timestamp" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "confidence" = $Confidence
    }
    $steps += $newStep
    
    $chain.steps = $steps
    $chain.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    # Save
    $chain | ConvertTo-Json -Depth 10 | Set-Content $REASONING_FILE
    
    # Show thinking based on type
    $color = switch ($Type) {
        "observation" { "Cyan" }
        "hypothesis" { "Yellow" }
        "evidence" { "Green" }
        "plan" { "Magenta" }
        "action" { "White" }
        "verification" { "Cyan" }
        "conclusion" { "Green" }
        default { "White" }
    }
    
    if (-not $Silent) {
        $indent = "  "
        if ($Type -eq "conclusion") { $indent = "" }
        Write-Host "$indent→ $Thought" -ForegroundColor $color
    }
    
    return $newStep
}

function Done-Reasoning {
    param([string]$Conclusion)
    
    if (-not (Test-Path $REASONING_FILE)) {
        return $null
    }
    
    $json = Get-Content $REASONING_FILE -Raw | ConvertFrom-Json
    
    # Add conclusion step
    Think-Step -Thought $Conclusion -Type "conclusion" -Confidence "HIGH"
    
    $json.complete = $true
    $json.conclusion = $Conclusion
    $json.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    # Archive to history
    Add-ReasoningToHistory $json
    
    if (-not $Silent) {
        Write-Host "`n✅ Conclusion: $Conclusion" -ForegroundColor Green
    }
    
    # Clear current
    Remove-Item $REASONING_FILE -Force -ErrorAction SilentlyContinue
    
    return $json
}

function Abort-Reasoning {
    if (Test-Path $REASONING_FILE) {
        Remove-Item $REASONING_FILE -Force
        Write-Host "Reasoning aborted" -ForegroundColor Yellow
    }
}

function Show-Reasoning {
    if (Test-Path $REASONING_FILE) {
        $json = Get-Content $REASONING_FILE -Raw | ConvertFrom-Json
        
        Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  🤔 REASONING CHAIN: $($json.task)" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
        
        foreach ($step in $json.steps) {
            $prefix = switch ($step.type) {
                "observation" { "🔍" }
                "hypothesis" { "💭" }
                "evidence" { "📋" }
                "plan" { "📝" }
                "action" { "⚡" }
                "verification" { "✓" }
                "conclusion" { "✅" }
                default { "•" }
            }
            
            $color = switch ($step.type) {
                "observation" { "Cyan" }
                "hypothesis" { "Yellow" }
                "evidence" { "Green" }
                "plan" { "Magenta" }
                "action" { "White" }
                "verification" { "Cyan" }
                "conclusion" { "Green" }
                default { "White" }
            }
            
            Write-Host "  $prefix [$($step.step_number)] $($step.thought)" -ForegroundColor $color
            if ($step.confidence -and $step.confidence -ne "MEDIUM") {
                Write-Host "      Confidence: $($step.confidence)" -ForegroundColor Gray
            }
        }
        
        if ($json.complete) {
            Write-Host "`n  🎯 FINAL: $($json.conclusion)" -ForegroundColor Green
        }
        
        Write-Host ""
    } else {
        Write-Host "No active reasoning chain" -ForegroundColor Yellow
    }
}

function Add-ReasoningToHistory {
    param([object]$Chain)
    
    $history = @()
    if (Test-Path $REASONING_HISTORY) {
        $history = Get-Content $REASONING_HISTORY -Raw | ConvertFrom-Json
        if ($history -isnot [System.Array]) { $history = @($history) }
    }
    
    $history = @($Chain) + $history
    
    # Keep last 50
    if ($history.Count -gt 50) {
        $history = $history[0..49]
    }
    
    $history | ConvertTo-Json -Depth 10 | Set-Content $REASONING_HISTORY
}

# ============================================================================
# COMMAND ALIASES (for brevity)
# ============================================================================

function Reasoning-Observation {
    param([string]$Observation)
    Think-Step -Thought $Observation -Type "observation" -Confidence "HIGH"
}

function Reasoning-hypothesis {
    param(
        [string]$Hypothesis,
        [string]$Confidence = "MEDIUM"
    )
    Think-Step -Thought $Hypothesis -Type "hypothesis" -Confidence $Confidence
}

function Reasoning-evidence {
    param([string]$Evidence)
    Think-Step -Thought $Evidence -Type "evidence" -Confidence "HIGH"
}

function Reasoning-plan {
    param([string]$Plan)
    Think-Step -Thought $Plan -Type "plan" -Confidence "HIGH"
}

function Reasoning-action {
    param([string]$Action)
    Think-Step -Thought $Action -Type "action" -Confidence "HIGH"
}

function Reasoning-verify {
    param([string]$Verification)
    Think-Step -Thought $Verification -Type "verification" -Confidence "HIGH"
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "start" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation start -Reason <task>"
            exit 1
        }
        Start-Reasoning -Task $Reason
    }
    
    "think" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation think -Reason <thought>"
            exit 1
        }
        Think-Step -Thought $Reason
    }
    
    "observe" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation observe -Reason <observation>"
            exit 1
        }
        Think-Step -Thought $Reason -Type "observation" -Confidence "HIGH"
    }
    
    "hypothesize" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation hypothesize -Reason <hypothesis>"
            exit 1
        }
        Think-Step -Thought $Reason -Type "hypothesis"
    }
    
    "evidence" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation evidence -Reason <evidence>"
            exit 1
        }
        Think-Step -Thought $Reason -Type "evidence" -Confidence "HIGH"
    }
    
    "plan" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation plan -Reason <plan>"
            exit 1
        }
        Think-Step -Thought $Reason -Type "plan" -Confidence "HIGH"
    }
    
    "verify" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation verify -Reason <verification>"
            exit 1
        }
        Think-Step -Thought $Reason -Type "verification" -Confidence "HIGH"
    }
    
    "done" {
        if (-not $Reason) {
            Write-Host "Usage: thinking.ps1 -Operation done -Reason <conclusion>"
            exit 1
        }
        Done-Reasoning -Conclusion $Reason
    }
    
    "abort" {
        Abort-Reasoning
    }
    
    "show" {
        Show-Reasoning
    }
    
    default {
        Show-Reasoning
    }
}