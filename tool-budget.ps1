# BOB'S TOOL BUDGET SYSTEM
# Per-tool token budgets to prevent context explosion
# Inspired by Claude Code's tool result budget limits

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, budget, check, reset
    
    [Parameter(Mandatory=$false)]
    [string]$ToolName = "",
    
    [Parameter(Mandatory=$false)]
    [int]$ToolResultSize = 0
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$BUDGET_FILE = "C:\Users\clayt\opencode-bob\memory\tool-budgets.json"

# Tool-specific budgets (in characters, ~4 chars per token)
$TOOL_BUDGETS = @{
    # READ TOOLS - moderate budgets
    Read = @{ maxResult = 50000; priceTier = "cheap" }
    glob = @{ maxResult = 30000; priceTier = "cheap" }
    grep = @{ maxResult = 40000; priceTier = "cheap" }
    
    # WRITE TOOLS - larger budgets
    Edit = @{ maxResult = 80000; priceTier = "smart" }
    Write = @{ maxResult = 100000; priceTier = "smart" }
    
    # EXECUTION TOOLS - expensive
    Bash = @{ maxResult = 80000; priceTier = "smart" }
    kbash = @{ maxResult = 60000; priceTier = "smart" }
    
    # WEB TOOLS - variable
    websearch = @{ maxResult = 30000; priceTier = "cheap" }
    webfetch = @{ maxResult = 50000; priceTier = "cheap" }
    
    # MCP TOOLS
    github = @{ maxResult = 60000; priceTier = "smart" }
    memory = @{ maxResult = 20000; priceTier = "cheap" }
    filesystem = @{ maxResult = 50000; priceTier = "cheap" }
    pdf = @{ maxResult = 80000; priceTier = "smart" }
}

# Hot tail size (recent tool results to always keep in memory)
$HOT_TAIL_COUNT = 3
$HOT_TAIL_SIZE = 15000

# ============================================================================
# LOAD/SAVE STATE
# ============================================================================

function Get-ToolBudgets {
    if (Test-Path $BUDGET_FILE) {
        return Get-Content $BUDGET_FILE -Raw | ConvertFrom-Json
    }
    return @{
        tools = @{}
        totalSpent = 0
        lastReset = $null
    }
}

function Save-ToolBudgets {
    param([object]$Budgets)
    $Budgets | ConvertTo-Json -Depth 10 | Set-Content $BUDGET_FILE
}

# ============================================================================
# BUDGET CHECK
# Returns whether tool can run and how much data to keep
# ============================================================================

function Test-ToolBudget {
    param([string]$Tool, [int]$Size)
    
    $budgets = Get-ToolBudgets
    $toolBudget = $TOOL_BUDGETS[$Tool]
    
    if (-not $toolBudget) {
        # Unknown tool - allow but flag
        return @{
            allowed = $true
            budget = 50000
            tier = "unknown"
            warning = "Unknown tool - using default budget"
        }
    }
    
    # Get current spent for this tool
    $currentSpent = 0
    if ($budgets.tools.$Tool) {
        $currentSpent = $budgets.tools.$Tool
    }
    
    # Check if under budget
    $remaining = $toolBudget.maxResult - $currentSpent
    $canRun = $remaining -gt 0
    
    # If result is too large, truncate to remaining budget
    $truncateTo = if ($Size -gt $remaining -and $remaining -gt 0) { $remaining } else { $Size }
    
    return @{
        allowed = $canRun
        budget = $toolBudget.maxResult
        spent = $currentSpent
        remaining = $remaining
        truncateTo = $truncateTo
        tier = $toolBudget.priceTier
        wouldTruncate = $Size -gt $remaining
    }
}

# ============================================================================
# RECORD USAGE
# ============================================================================

function Record-ToolUsage {
    param([string]$Tool, [int]$Bytes)
    
    $budgets = Get-ToolBudgets
    
    if (-not $budgets.tools) {
        $budgets.tools = @{}
    }
    
    $current = 0
    if ($budgets.tools.$Tool) {
        $current = $budgets.tools.$Tool
    }
    
    $budgets.tools.$Tool = $current + $Bytes
    $budgets.totalSpent = $budgets.totalSpent + $Bytes
    
    Save-ToolBudgets -Budgets $budgets
}

# ============================================================================
# RESET
# ============================================================================

function Reset-ToolBudgets {
    $budgets = Get-ToolBudgets
    $budgets.tools = @{}
    $budgets.totalSpent = 0
    $budgets.lastReset = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ToolBudgets -Budgets $budgets
}

# ============================================================================
# STATUS
# ============================================================================

function Get-BudgetStatus {
    $budgets = Get-ToolBudgets
    
    $toolStatus = @()
    foreach ($tool in $TOOL_BUDGETS.Keys) {
        $config = $TOOL_BUDGETS[$tool]
        $spent = if ($budgets.tools.$Tool) { $budgets.tools.$Tool } else { 0 }
        
        $toolStatus += @{
            tool = $tool
            budget = $config.maxResult
            spent = $spent
            remaining = $config.maxResult - $spent
            tier = $config.priceTier
        }
    }
    
    return @{
        totalSpent = $budgets.totalSpent
        lastReset = $budgets.lastReset
        tools = $toolStatus
        hotTailRules = @{
            count = $HOT_TAIL_COUNT
            maxSize = $HOT_TAIL_SIZE
            description = "Always keep last $HOT_TAIL_COUNT tool results (< $HOT_TAIL_SIZE chars each)"
        }
    } | ConvertTo-Json -Depth 5
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "status" {
        Get-BudgetStatus
    }
    "budget" {
        # Show all tool budgets
        $TOOL_BUDGETS | ConvertTo-Json -Depth 5
    }
    "check" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Test-ToolBudget -Tool $ToolName -Size $ToolResultSize
    }
    "record" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Record-ToolUsage -Tool $ToolName -Bytes $ToolResultSize
    }
    "reset" {
        Reset-ToolBudgets
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}