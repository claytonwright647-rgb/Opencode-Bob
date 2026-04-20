# BOB'S CONTEXT COMPACTION PIPELINE
# Inspired by Claude Code's 5-layer compaction system
# Handles context pressure before it becomes a problem

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, compact, budget, threshold
    
    [Parameter(Mandatory=$false)]
    [int]$TokenCount = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$CONTEXT_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\context-state.json"
$HISTORY_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\compaction-history.json"
$MAX_CONTEXT = 200000  # 200K tokens (standard model)
$MAX_OUTPUT = 8000     # 8K reserved for output
$WARNING_THRESHOLD = 167000  # 83.5% - auto-compact triggers
$ERROR_THRESHOLD = 184000  # 92% - hard limit

# Compaction levels (from lightest to heaviest)
$L1_BUDGET = 50000   # Tool result budget - snip large outputs
$L2_SNIP = 100000    # Snip - remove old tool results
$L3_MICRO = 130000    # Microcompact - summarize old turns
$L4_COLLAPSE = 150000  # Context collapse - heavy summarization
$L5_AUTO = 167000     # Autocompact - fork agent for full summary

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

function Get-ContextState {
    if (Test-Path $CONTEXT_FILE) {
        return Get-Content $CONTEXT_FILE -Raw | ConvertFrom-Json
    }
    return @{
        currentTokens = 0
        compactionLevel = 0
        lastCompaction = $null
        messagesCount = 0
        toolResultsSize = 0
    }
}

function Save-ContextState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $CONTEXT_FILE
}

# ============================================================================
# LEVEL 1: TOOL RESULT BUDGET
# Goal: Offload large tool results to disk, keep only previews
# Cost: Zero API calls
# ============================================================================

function Invoke-Level1Budget {
    param([int]$CurrentTokens)
    
    if ($CurrentTokens -lt $L1_BUDGET) {
        return @{ level = 0; action = "none"; tokens = $CurrentTokens }
    }
    
    # Level 1: Tool result budget exceeded
    # Mark large tool results for offload
    return @{
        level = 1
        action = "budget_exceeded"
        tokens = $CurrentTokens
        recommendation = "Offload tool results > 10KB to disk"
    }
}

# ============================================================================
# LEVEL 2: SNIP
# Goal: Remove oldest tool results, keep recent 
# Cost: Zero API calls
# ============================================================================

function Invoke-Level2Snip {
    param([int]$CurrentTokens)
    
    if ($CurrentTokens -lt $L2_SNIP) {
        return @{ level = 0; action = "none"; tokens = $CurrentTokens }
    }
    
    return @{
        level = 2
        action = "snip"
        tokens = $CurrentTokens
        recommendation = "Remove tool results from messages > 5 turns ago"
    }
}

# ============================================================================
# LEVEL 3: MICROCOMPACT
# Goal: Summarize oldest messages, keep intent
# Cost: Zero (uses cached summarization)
# ============================================================================

function Invoke-Level3Microcompact {
    param([int]$CurrentTokens)
    
    if ($CurrentTokens -lt $L3_MICRO) {
        return @{ level = 0; action = "none"; tokens = $CurrentTokens }
    }
    
    return @{
        level = 3
        action = "microcompact"
        tokens = $CurrentTokens
        recommendation = "Summarize oldest 10 messages, preserve intent+errors+next-steps"
        sections = @("Intent", "Technical Decisions", "Files Touched", "Errors", "Next Steps")
    }
}

# ============================================================================
# LEVEL 4: CONTEXT COLLAPSE  
# Goal: Full projection-based folding (~90% reduction)
# Cost: Zero (non-destructive)
# ============================================================================

function Invoke-Level4Collapse {
    param([int]$CurrentTokens)
    
    if ($CurrentTokens -lt $L4_COLLAPSE) {
        return @{ level = 0; action = "none"; tokens = $CurrentTokens }
    }
    
    return @{
        level = 4
        action = "collapse"
        tokens = $CurrentTokens
        recommendation = "Project all prior messages into summary, keep only boundary marker + summary"
    }
}

# ============================================================================
# LEVEL 5: AUTOCOMPACT
# Goal: Fork child agent for fullsummarization
# Cost: One API call (irreversible)
# ============================================================================

function Invoke-Level5Autocompact {
    param([int]$CurrentTokens)
    
    if ($CurrentTokens -lt $L5_AUTO) {
        return @{ level = 0; action = "none"; tokens = $CurrentTokens }
    }
    
    return @{
        level = 5
        action = "autocompact"
        tokens = $CurrentTokens
        recommendation = "Fork child agent to create full summary, cannot undo"
        maxTurns = 5  # Hard cap prevents rabbit holes
    }
}

# ============================================================================
# MAIN COMPACTION PIPELINE
# Applies layers in sequence, each heavier than last
# ============================================================================

function Invoke-CompactionPipeline {
    param([int]$Tokens)
    
    $state = Get-ContextState
    $state.currentTokens = $Tokens
    
    # Apply each level in sequence
    $result = Invoke-Level1Budget -CurrentTokens $Tokens
    if ($result.level -eq 0) { $result = Invoke-Level2Snip -CurrentTokens $Tokens }
    if ($result.level -eq 0) { $result = Invoke-Level3Microcompact -CurrentTokens $Tokens }
    if ($result.level -eq 0) { $result = Invoke-Level4Collapse -CurrentTokens $Tokens }
    if ($result.level -eq 0) { $result = Invoke-Level5Autocompact -CurrentTokens $Tokens }
    
    # Update state
    $state.compactionLevel = $result.level
    $state.lastCompaction = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ContextState -State $state
    
    return $result
}

# ============================================================================
# STATUS COMMAND
# ============================================================================

function Get-Status {
    $state = Get-ContextState
    
    # Calculate percentages
    $usedPct = [math]::Round(($state.currentTokens / $MAX_CONTEXT) * 100, 1)
    $warningPct = [math]::Round(($WARNING_THRESHOLD / $MAX_CONTEXT) * 100, 1)
    $errorPct = [math]::Round(($ERROR_THRESHOLD / $MAX_CONTEXT) * 100, 1)
    
    # Determine current level
    if ($state.currentTokens -ge $L5_AUTO) { $currentLevel = 5 }
    elseif ($state.currentTokens -ge $L4_COLLAPSE) { $currentLevel = 4 }
    elseif ($state.currentTokens -ge $L3_MICRO) { $currentLevel = 3 }
    elseif ($state.currentTokens -ge $L2_SNIP) { $currentLevel = 2 }
    elseif ($state.currentTokens -ge $L1_BUDGET) { $currentLevel = 1 }
    else { $currentLevel = 0 }
    
    return @{
        tokens = $state.currentTokens
        maxTokens = $MAX_CONTEXT
        usedPercent = $usedPct
        warningAt = $warningPct
        errorAt = $errorPct
        currentLevel = $currentLevel
        lastCompaction = $state.lastCompaction
        messagesCount = $state.messagesCount
    } | ConvertTo-Json -Depth 3
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "status" {
        Get-Status
    }
    "compact" {
        if ($TokenCount -eq 0) {
            $TokenCount = 150000  # Default trigger
        }
        Invoke-CompactionPipeline -Tokens $TokenCount
    }
    "budget" {
        # Report budget breakdown
        @{
            total = $MAX_CONTEXT
            systemPrompt = 15000
            userContext = 40000
            history = 80000
            toolResults = 50000
            outputReserved = $MAX_OUTPUT
            levels = @{
                L1 = @{ threshold = $L1_BUDGET; name = "Budget" }
                L2 = @{ threshold = $L2_SNIP; name = "Snip" }
                L3 = @{ threshold = $L3_MICRO; name = "Microcompact" }
                L4 = @{ threshold = $L4_COLLAPSE; name = "Collapse" }
                L5 = @{ threshold = $L5_AUTO; name = "Autocompact" }
            }
        } | ConvertTo-Json -Depth 5
    }
    "threshold" {
        @{
            warningThreshold = $WARNING_THRESHOLD
            errorThreshold = $ERROR_THRESHOLD
            warningPercent = [math]::Round(($WARNING_THRESHOLD / $MAX_CONTEXT) * 100, 1)
            errorPercent = [math]::Round(($ERROR_THRESHOLD / $MAX_CONTEXT) * 100, 1)
        } | ConvertTo-Json
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}