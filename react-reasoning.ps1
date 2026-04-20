# BOB'S REACT REASONING SYSTEM
# Reasoning + Acting pattern - The core of intelligent agents
# Inspired by Claude Code and production agent patterns

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "think",  # think, act, observe, loop, status
    
    [Parameter(Mandatory=$false)]
    [string]$Question = "",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxIterations = 10
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$REACT_DIR = "C:\Users\clayt\opencode-bob\memory\react"
$REACT_STATE_FILE = "$REACT_DIR\current.json"
$REACT_HISTORY_FILE = "$REACT_DIR\history.json"

if (-not (Test-Path $REACT_DIR)) {
    New-Item -ItemType Directory -Force -Path $REACT_DIR | Out-Null
}

# ============================================================================
# REACT STATE
# ============================================================================

function Get-ReactState {
    if (Test-Path $REACT_STATE_FILE) {
        return Get-Content $REACT_STATE_FILE -Raw | ConvertFrom-Json
    }
    return @{
        question = ""
        iterations = @()
        currentStep = 0
        thinking = ""
        acting = ""
        observation = ""
        finalAnswer = $null
    }
}

function Save-ReactState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $REACT_STATE_FILE
}

# ============================================================================
# THINK STEP
# Generate reasoning for the current state
# ============================================================================

function Invoke-Think {
    param([string]$Question, [int]$Iteration)
    
    # This is where you'd call the LLM
    # For now: generate reasoning prompts
    
    $prompt = @"
Question: $Question
Iteration: $Iteration

Think step: Analyze the question and plan your approach.
- What's the goal?
- What do I know?
- What do I need to find out?
- What's my plan?
"@
    
    return @{
        step = "think"
        prompt = $prompt
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ============================================================================
# ACT STEP  
# Execute planned action
# ============================================================================

function Invoke-Act {
    param([string]$Plan, [int]$Iteration)
    
    # Convert plan to tool calls
    # This is simplified - real implementation would call tools
    
    return @{
        step = "act"
        action = "Would execute: $Plan"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ============================================================================
# OBSERVE STEP
# Process results and decide next move
# ============================================================================

function Invoke-Observe {
    param([object]$ActResult, [int]$Iteration)
    
    # Analyze what happened and decide next step
    # Loop if needed, or finish
    
    return @{
        step = "observe"
        result = $ActResult
        shouldContinue = $true  # Would be determined by analyzing result
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ============================================================================
# REACT LOOP
# Main reasoning loop
# ============================================================================

function Start-ReactLoop {
    param([string]$Question, [int]$MaxIter)
    
    $state = Get-ReactState
    $state.question = $Question
    $state.started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $state.iterations = @()
    $state.currentStep = 0
    
    # Run the loop
    for ($i = 0; $i -lt $MaxIter; $i++) {
        $state.currentStep = $i
        
        # Think
        $thought = Invoke-Think -Question $Question -Iteration $i
        $state.iterations += @{
            step = $i
            think = $thought
        }
        
        # In production: would call LLM to decide action based on thought
        # Then act
        # Then observe
        # Then decide continue or break
        
        Save-ReactState -State $state
        
        # For demo: just track iterations
    }
    
    $state.completed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ReactState -State $state
    
    return @{
        success = $true
        question = $Question
        iterations = $state.currentStep + 1
        state = $state
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-ReactStatus {
    $state = Get-ReactState
    
    return @{
        question = $state.question
        currentStep = $state.currentStep
        iterations = $state.iterations.Count
        started = $state.started
        completed = $state.completed
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "think" {
        if ($Question -eq "") {
            Write-Error "Question required"
        }
        Invoke-Think -Question $Question -Iteration 0
    }
    "act" {
        Invoke-Act -Plan $Question -Iteration 0
    }
    "loop" {
        if ($Question -eq "") {
            Write-Error "Question required"
        }
        Start-ReactLoop -Question $Question -MaxIter $MaxIterations
    }
    "status" {
        Get-ReactStatus
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}