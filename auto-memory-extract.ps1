# BOB'S AUTO-MEMORY EXTRACTION SYSTEM
# Inspired by Claude Code's memory extraction
# Extracts durable memories from sessions to disk
# Runs before compaction to preserve important info

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "extract",  # extract, status, search
    
    [Parameter(Mandatory=$false)]
    [string]$Session = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Query = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$MEMORY_DIR = "C:\Users\clayt\opencode-bob\memory\extracted"
$ENTITIES_FILE = "$MEMORY_DIR\entities.json"
$RELATIONS_FILE = "$MEMORY_DIR\relations.json"
$DECISIONS_FILE = "$MEMORY_DIR\decisions.json"
$ERRORS_FILE = "$MEMORY_DIR\errors.json"
$LEARNED_FILE = "$MEMORY_DIR\learned.json"

# Ensure directory exists
if (-not (Test-Path $MEMORY_DIR)) {
    New-Item -ItemType Directory -Force -Path $MEMORY_DIR | Out-Null
}

# ============================================================================
# CORE EXTRACTION SECTIONS
# What survives after compaction (9-section structure from Claude Code)
# ============================================================================

$EXTRACTION_SECTIONS = @{
    intent = "What the user wanted to accomplish"
    technicalConcepts = "Technical concepts and patterns used"
    filesTouched = "Files modified or created"
    errors = "Errors encountered and how they were resolved"
    nextSteps = "What remains to be done"
    decisions = "Architecture or design decisions made"
    learnings = "Key learnings from this session"
    toolsUsed = "Tools invoked and their results"
    context = "Important context that would be lost"
}

# ============================================================================
# EXTRACT FUNCTION
# Pulls key information from session and saves to memory
# ============================================================================

function Invoke-Extract {
    param([string]$SessionId)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Create session memory
    $memory = @{
        extractedAt = $timestamp
        sessionId = $SessionId
        sections = @{}
    }
    
    # Level 1: Extract decisions
    # Things like "we decided to use X architecture because Y"
    $decisions = @()
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\wisdom\belief-revisions.json") {
        $beliefs = Get-Content "C:\Users\clayt\opencode-bob\memory\wisdom\belief-revisions.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($beliefs) {
            foreach ($belief in $beliefs) {
                $decisions += @{
                    belief = $belief.belief
                    changed = $belief.changed
                    reason = $belief.reason
                }
            }
        }
    }
    $memory.sections.decisions = $decisions
    
    # Level 2: Extract errors and resolutions
    $errors = @()
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\wisdom\error-analyses.json") {
        $errorAnalyses = Get-Content "C:\Users\clayt\opencode-bob\memory\wisdom\error-analyses.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($errorAnalyses) {
            foreach ($err in $errorAnalyses) {
                $errors += @{
                    error = $err.error
                    resolution = $err.resolution
                    timestamp = $err.timestamp
                }
            }
        }
    }
    $memory.sections.errors = $errors
    
    # Level 3: Extract patterns learned
    $learnings = @()
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\learning\patterns.json") {
        $patterns = Get-Content "C:\Users\clayt\opencode-bob\memory\learning\patterns.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($patterns) {
            foreach ($pattern in $patterns) {
                $learnings += @{
                    pattern = $pattern.name
                    context = $pattern.context
                    result = $pattern.result
                }
            }
        }
    }
    $memory.sections.learnings = $learnings
    
    # Level 4: Extract current working context
    $workingContext = @{}
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json") {
        $wc = Get-Content "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($wc) {
            $workingContext = @{
                currentFocus = $wc.currentFocus
                details = $wc.details
            }
        }
    }
    $memory.sections.context = $workingContext
    
    # Save to memory
    $sessionFile = "$MEMORY_DIR\$SessionId.json"
    $memory | ConvertTo-Json -Depth 10 | Set-Content $sessionFile
    
    # Also update aggregate files
    Update-AggregateLearned -Memory $memory
    
    return @{
        success = $true
        file = $sessionFile
        sectionsExtracted = $memory.sections.Keys.Count
    }
}

# ============================================================================
# UPDATE AGGREGATE LEARNED FILE
# Appends to master learnings file
# ============================================================================

function Update-AggregateLearned {
    param([object]$Memory)
    
    $learned = @()
    if (Test-Path $LEARNED_FILE) {
        $learned = Get-Content $LEARNED_FILE -Raw | ConvertFrom-Json
        if (-not ($learned -is [array])) { $learned = @($learned) }
    }
    
    # Add new learnings
    if ($Memory.sections.learnings) {
        foreach ($learning in $Memory.sections.learnings) {
            $learned += @{
                learnedAt = $Memory.extractedAt
                pattern = $learning.pattern
                context = $learning.context
            }
        }
    }
    
    # Save aggregate (keep last 100)
    $learned = $learned | Select-Object -Last 100
    $learned | ConvertTo-Json -Depth 5 | Set-Content $LEARNED_FILE
}

# ============================================================================
# SEARCH FUNCTION
# Finds relevant memories based on query
# ============================================================================

function Invoke-Search {
    param([string]$Query)
    
    $results = @()
    $sessionFiles = Get-ChildItem -Path $MEMORY_DIR -Filter "*.json" -ErrorAction SilentlyContinue
    
    foreach ($file in $sessionFiles) {
        $memory = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        # Simple keyword matching for now (Claude Code uses LLM for this)
        $json = $memory | ConvertTo-Json -Depth 10
        if ($json -like "*$Query*") {
            $results += @{
                session = $memory.sessionId
                extractedAt = $memory.extractedAt
                file = $file.FullName
                relevance = "keyword_match"
            }
        }
    }
    
    return @{
        query = $Query
        results = $results
        count = $results.Count
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-MemoryStatus {
    $sessionFiles = Get-ChildItem -Path $MEMORY_DIR -Filter "*.json" -ErrorAction SilentlyContinue
    
    $totalLearned = 0
    if (Test-Path $LEARNED_FILE) {
        $learned = Get-Content $LEARNED_FILE -Raw | ConvertFrom-Json
        if ($learned) { $totalLearned = $learned.Count }
    }
    
    return @{
        memoryDirectory = $MEMORY_DIR
        totalSessions = $sessionFiles.Count
        totalLearnings = $totalLearned
        sectionsExtracted = $EXTRACTION_SECTIONS.Keys.Count
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "extract" {
        if ($Session -eq "") {
            $Session = "session_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        }
        Invoke-Extract -SessionId $Session
    }
    "status" {
        Get-MemoryStatus
    }
    "search" {
        if ($Query -eq "") {
            Write-Error "Query required for search operation"
        }
        Invoke-Search -Query $Query
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}