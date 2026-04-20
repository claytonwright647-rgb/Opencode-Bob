# BOB'S MODEL ROUTING SYSTEM
# Route tasks to appropriate model based on complexity
# Inspired by Claude Code: ~80% cheap, ~20% smart

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "route",  # route, models, stats
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [Parameter(Mandatory=$false)]
    [string]$RequestedModel = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# MODEL DEFINITIONS
# ============================================================================

$MODELS = @{
    # CHEAP MODELS - Fast, low cost, good for simple tasks
    cheap = @{
        name = "qwen2.5:7b"
        context = 128000
        speed = "fast"
        cost = "low"
        bestFor = @("simple reads", "search", "formatting", "validation")
    }
    
    # BALANCED MODELS - Good balance for most coding tasks
    balanced = @{
        name = "qwen3.5:cloud"
        context = 200000
        speed = "medium"
        cost = "medium"
        bestFor = @("coding", "refactoring", "generation")
    }
    
    # SMART MODELS - For complex reasoning
    smart = @{
        name = "ollama/qwen3.5:cloud"
        context = 200000
        speed = "slow"
        cost = "high"
        bestFor = @("architecture", "debugging", "complex reasoning")
    }
}

# ============================================================================
# TASK CLASSIFICATION
# ============================================================================

function Classify-Task {
    param([string]$Task)
    
    $task = $Task.ToLower()
    
    # LOW COMPLEXITY - Always cheap
    $lowComplexity = @("read", "search", "find", "list", "show", "get", "status", "check")
    foreach ($pattern in $lowComplexity) {
        if ($task -match $pattern) {
            return "cheap"
        }
    }
    
    # HIGH COMPLEXITY - Always smart
    $highComplexity = @("debug", "architect", "design", "complex", "security", "analyze deep", "plan entire", "refactor entire")
    foreach ($pattern in $highComplexity) {
        if ($task -match $pattern) {
            return "smart"
        }
    }
    
    # DEFAULT - Balanced
    return "balanced"
}

# ============================================================================
# ROUTE DECISION
# ============================================================================

function Get-RouteDecision {
    param([string]$Task, [string]$Override)
    
    # If user explicitly requested a model, use that
    if ($Override -ne "") {
        foreach ($tier in $MODELS.Keys) {
            if ($MODELS[$tier].name -eq $Override -or $Override -eq $tier) {
                return @{
                    tier = $tier
                    model = $MODELS[$tier].name
                    reason = "user_override"
                }
            }
        }
    }
    
    # Classify task
    $tier = Classify-Task -Task $Task
    
    # Get model for that tier
    return @{
        tier = $tier
        model = $MODELS[$tier].name
        reason = "auto_classified"
    }
}

# ============================================================================
# STATISTICS
# ============================================================================

$STATS_FILE = "C:\Users\clayt\opencode-bob\memory\model-stats.json"

function Get-RoutingStats {
    if (Test-Path $STATS_FILE) {
        return Get-Content $STATS_FILE -Raw | ConvertFrom-Json
    }
    return @{
        totalTasks = 0
        cheap = 0
        balanced = 0
        smart = 0
        started = (Get-Date -Format "yyyy-MM-dd")
    }
}

function Update-RoutingStats {
    param([string]$Tier)
    
    $stats = Get-RoutingStats
    $stats.totalTasks++
    $stats.$Tier++
    $stats | ConvertTo-Json -Depth 5 | Set-Content $STATS_FILE
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "route" {
        if ($Task -eq "") {
            Write-Error "Task description required"
        }
        Get-RouteDecision -Task $Task -RequestedModel $RequestedModel
    }
    "models" {
        $MODELS
    }
    "stats" {
        $stats = Get-RoutingStats
        
        # Calculate percentages
        if ($stats.totalTasks -gt 0) {
            $stats.pctCheap = [math]::Round(($stats.cheap / $stats.totalTasks) * 100, 1)
            $stats.pctBalanced = [math]::Round(($stats.balanced / $stats.totalTasks) * 100, 1)
            $stats.pctSmart = [math]::Round(($stats.smart / $stats.totalTasks) * 100, 1)
        }
        
        return $stats
    }
    "classify" {
        if ($Task -eq "") {
            Write-Error "Task required"
        }
        Classify-Task -Task $Task
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}