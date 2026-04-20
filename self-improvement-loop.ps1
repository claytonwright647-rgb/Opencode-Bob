# BOB'S SELF-IMPROVEMENT FEEDBACK LOOP
# Agents learn from corrections and improve over time
# Inspired by OpenAI's Self-Evolving Agents Cookbook

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "record",  # record, learn, status, analyze
    
    [Parameter(Mandatory=$false)]
    [string]$FeedbackType = "",  # correction, success, failure
    
    [Parameter(Mandatory=$false)]
    [string]$Context = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Improvement = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$IMPROVE_DIR = "C:\Users\clayt\opencode-bob\memory\improvement"
$FEEDBACK_FILE = "$IMPROVE_DIR\feedback.json"
$PATTERNS_FILE = "$IMPROVE_DIR\patterns.json"
$EVOLUTION_FILE = "$IMPROVE_DIR\evolution.json"

if (-not (Test-Path $IMPROVE_DIR)) {
    New-Item -ItemType Directory -Force -Path $IMPROVE_DIR | Out-Null
}

# ============================================================================
# FEEDBACK TYPES
# ============================================================================

$FEEDBACK_TYPES = @{
    correction = @{
        description = "Human corrected the agent's output"
        color = "red"
    }
    success = @{
        description = "Task completed successfully"
        color = "green"
    }
    failure = @{
        description = "Task failed or was abandoned"
        color = "yellow"
    }
    partial = @{
        description = "Task partially completed"
        color = "yellow"
    }
}

# ============================================================================
# RECORD FEEDBACK
# ============================================================================

function Record-Feedback {
    param([string]$Type, [string]$Ctx, [string]$Improve)
    
    $feedback = @()
    if (Test-Path $FEEDBACK_FILE) {
        $feedback = Get-Content $FEEDBACK_FILE -Raw | ConvertFrom-Json
        if (-not ($feedback -is [array])) { $feedback = @($feedback) }
    }
    
    $entry = @{
        id = (Get-Random -Maximum 100000)
        type = $Type
        context = $Ctx
        improvement = $Improve
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $feedback += $entry
    $feedback | ConvertTo-Json -Depth 10 | Set-Content $FEEDBACK_FILE
    
    # Trigger pattern extraction if correction
    if ($Type -eq "correction") {
        Extract-Pattern -Context $Ctx -Improvement $Improve
    }
    
    return @{
        success = $true
        feedbackId = $entry.id
        type = $Type
    }
}

# ============================================================================
# EXTRACT PATTERNS
# Learn from corrections to avoid same mistakes
# ============================================================================

function Extract-Pattern {
    param([string]$Ctx, [string]$Improve)
    
    $patterns = @()
    if (Test-Path $PATTERNS_FILE) {
        $patterns = Get-Content $PATTERNS_FILE -Raw | ConvertFrom-Json
        if (-not ($patterns -is [array])) { $patterns = @($patterns) }
    }
    
    # Extract the key learning
    $pattern = @{
        context = $Ctx.Substring(0, [Math]::Min(200, $Ctx.Length))
        improvement = $Improve
        timesSeen = 1
        lastSeen = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Check for existing similar pattern
    $found = $false
    foreach ($p in $patterns) {
        if ($p.context -like "*$($pattern.context.Substring(0, 50))*") {
            $p.timesSeen++
            $p.lastSeen = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $found = $true
        }
    }
    
    if (-not $found) {
        $patterns += $pattern
    }
    
    $patterns | ConvertTo-Json -Depth 10 | Set-Content $PATTERNS_FILE
}

# ============================================================================
# ANALYZE PATTERNS
# Find most common mistakes
# ============================================================================

function Get-PatternAnalysis {
    $patterns = @()
    if (Test-Path $PATTERNS_FILE) {
        $patterns = Get-Content $PATTERNS_FILE -Raw | ConvertFrom-Json
        if (-not ($patterns -is [array])) { $patterns = @($patterns) }
    }
    
    # Sort by times seen
    $sorted = $patterns | Sort-Object -Property timesSeen -Descending | Select-Object -First 10
    
    return @{
        totalPatterns = $patterns.Count
        topPatterns = $sorted
    }
}

# ============================================================================
# EVOLVE STRATEGY
# Adjust behavior based on feedback
# ============================================================================

function Evolve-Strategy {
    $analysis = Get-PatternAnalysis
    
    $evolutions = @()
    if (Test-Path $EVOLUTION_FILE) {
        $evolutions = Get-Content $EVOLUTION_FILE -Raw | ConvertFrom-Json
        if (-not ($evolutions -is [array])) { $evolutions = @($evolutions) }
    }
    
    # Create new strategy adjustments based on patterns
    foreach ($pattern in $analysis.topPatterns) {
        $evolve = @{
            pattern = $pattern.context.Substring(0, 100)
            adjustment = "Avoid: $($pattern.improvement)"
            timesApplied = 0
            recommended = $pattern.timesSeen -gt 2  # Recommend if seen multiple times
        }
        
        $evolutions += $evolve
    }
    
    $evolutions | ConvertTo-Json -Depth 10 | Set-Content $EVOLUTION_FILE
    
    return @{
        evolutions = $evolutions
        count = $evolutions.Count
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-ImprovementStatus {
    $feedback = @()
    if (Test-Path $FEEDBACK_FILE) {
        $feedback = Get-Content $FEEDBACK_FILE -Raw | ConvertFrom-Json
        if ($feedback -is [array]) { $feedback = $feedback }
        else { $feedback = @($feedback) }
    }
    
    $patterns = Get-PatternAnalysis
    
    return @{
        totalFeedback = $feedback.Count
        totalPatterns = $patterns.totalPatterns
        feedbackTypes = $FEEDBACK_TYPES.Keys
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "record" {
        if ($FeedbackType -eq "" -or $Context -eq "") {
            Write-Error "FeedbackType and Context required"
        }
        Record-Feedback -Type $FeedbackType -Ctx $Context -Improve $Improvement
    }
    "learn" {
        Extract-Pattern -Context $Context -Improvement $Improvement
    }
    "analyze" {
        Get-PatternAnalysis
    }
    "evolve" {
        Evolve-Strategy
    }
    "status" {
        Get-ImprovementStatus
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}