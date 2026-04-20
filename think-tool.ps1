# BOB'S THINK TOOL
# Explicit structured thinking step
# Like Claude's "think" tool - pause before acting

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "think",  # think, start, analyze, plan, done
    
    [Parameter(Mandatory=$false)]
    [string]$Question = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Context = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$THINK_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\thinking-current.json"
$THINK_HISTORY = "C:\Users\clayt\opencode-bob\memory\sessions\thinking-history.json"

# ============================================================================
# THINK LOGIC
# ============================================================================

function Start-Thinking {
    param([string]$Question)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💭 THINKING..." -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Question: $Question" -ForegroundColor White
    Write-Host ""
    
    # Before thinking - snapshot!
    Write-Host "[1/4] Creating backup before thinking..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "think-before-$((Get-Date).ToString('yyyy-MM-dd-HHmm'))" | Out-Null
    
    # Save thinking context
    $thinking = @{
        "question" = $Question
        "context" = $Context
        "started" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "steps" = @()
    }
    $thinking | ConvertTo-Json -Depth 5 | Set-Content $THINK_FILE
    
    return $thinking
}

function Add-Thought {
    param([string]$Thought, [string]$Type = "analysis")
    
    $thinking = Get-Content $THINK_FILE -Raw | ConvertFrom-Json
    
    $step = @{
        "thought" = $Thought
        "type" = $Type
        "timestamp" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $thinking.steps += $step
    $thinking | ConvertTo-Json -Depth 5 | Set-Content $THINK_FILE
    
    # Show with icon
    $icon = switch ($Type) {
        "observation" { "🔍" }
        "analysis" { "📊" }
        "hypothesis" { "💭" }
        "evidence" { "📋" }
        "plan" { "📝" }
        "decision" { "🎯" }
        default { "•" }
    }
    
    $color = switch ($Type) {
        "observation" { "Cyan" }
        "analysis" { "White" }
        "hypothesis" { "Yellow" }
        "evidence" { "Green" }
        "plan" { "Magenta" }
        "decision" { "Green" }
        default { "Gray" }
    }
    
    Write-Host "  $icon $Thought" -ForegroundColor $color
    
    return $step
}

function Finish-Thinking {
    param([string]$Conclusion)
    
    $thinking = Get-Content $THINK_FILE -Raw | ConvertFrom-Json
    
    $thinking.conclusion = $Conclusion
    $thinking.completed = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    # Add conclusion
    $step = @{
        "thought" = $Conclusion
        "type" = "conclusion"
        "timestamp" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    $thinking.steps += $step
    
    # Save to history
    $history = @()
    if (Test-Path $THINK_HISTORY) {
        $history = Get-Content $THINK_HISTORY -Raw | ConvertFrom-Json
        if ($history -isnot [System.Array]) { $history = @($history) }
    }
    $history = @($thinking) + $history
    
    # Keep last 20
    if ($history.Count -gt 20) { $history = $history[0..19] }
    $history | ConvertTo-Json -Depth 10 | Set-Content $THINK_HISTORY
    
    # After thinking - snapshot!
    Write-Host ""
    Write-Host "[4/4] Creating backup after thinking..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "think-after-$((Get-Date).ToString('yyyy-MM-dd-HHmm'))" | Out-Null
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ✅ CONCLUSION: $Conclusion" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Clean up current
    Remove-Item $THINK_FILE -ErrorAction SilentlyContinue
    
    return $thinking
}

function Show-Thinking {
    if (-not (Test-Path $THINK_FILE)) {
        Write-Host "No active thinking session" -ForegroundColor Yellow
        return
    }
    
    $thinking = Get-Content $THINK_FILE -Raw | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💭 THINKING SESSION" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Question: $($thinking.question)" -ForegroundColor White
    Write-Host "Started: $($thinking.started)" -ForegroundColor Gray
    Write-Host ""
    
    foreach ($step in $thinking.steps) {
        $icon = switch ($step.type) {
            "observation" { "🔍" }
            "analysis" { "📊" }
            "hypothesis" { "💭" }
            "evidence" { "📋" }
            "plan" { "📝" }
            "conclusion" { "✅" }
            default { "•" }
        }
        Write-Host "  $icon [$($step.type)] $($step.thought)" -ForegroundColor Cyan
    }
    
    if ($thinking.conclusion) {
        Write-Host ""
        Write-Host "  🎯 $($thinking.conclusion)" -ForegroundColor Green
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "think" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation think -Question 'your complex question'"
            exit 1
        }
        Start-Thinking -Question $Question
        
        # Guide through thinking
        Add-Thought -Thought "Let me analyze this systematically..." -Type "analysis"
        Add-Thought -Thought "What do I know about this?" -Type "observation"
        Add-Thought -Thought "What's my hypothesis?" -Type "hypothesis"
        Add-Thought -Thought "What evidence would confirm/reject?" -Type "evidence"
        Add-Thought -Thought "What's my plan?" -Type "plan"
    }
    
    "start" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation start -Question 'task'"
            exit 1
        }
        Start-Thinking -Question $Question
        Write-Host ""
        Write-Host "Thinking started. Use -Operation analyze to add thoughts." -ForegroundColor Cyan
    }
    
    "analyze" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation analyze -Question 'thought'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "analysis"
    }
    
    "observe" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation observe -Question 'observation'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "observation"
    }
    
    "hypothesize" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation hypothesize -Question 'hypothesis'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "hypothesis"
    }
    
    "evidence" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation evidence -Question 'evidence'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "evidence"
    }
    
    "plan" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation plan -Question 'plan'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "plan"
    }
    
    "decide" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation decide -Question 'decision'"
            exit 1
        }
        Add-Thought -Thought $Question -Type "decision"
    }
    
    "done" {
        if (-not $Question) {
            Write-Host "Usage: think-tool.ps1 -Operation done -Question 'conclusion'"
            exit 1
        }
        Finish-Thinking -Conclusion $Question
    }
    
    "show" {
        Show-Thinking
    }
    
    default {
        Write-Host "Usage: think-tool.ps1 -Operation <think|start|analyze|hypothesize|evidence|plan|done|show>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\think-tool.ps1 -Operation think -Question 'How do I fix this bug?'"
        Write-Host "  .\think-tool.ps1 -Operation hypothesize -Question 'The bug is in the loop'"
        Write-Host "  .\think-tool.ps1 -Operation done -Question 'Fixed by adding null check'"
    }
}