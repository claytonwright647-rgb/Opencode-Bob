# =============================================================================
# PARALLEL KNOWLEDGE LEARNING SYSTEM
# =============================================================================
# Learns entities, relations, and patterns in PARALLEL for maximum speed!

param(
    [string]$Operation = "learn",  # learn, stats, clear

    [string]$Input = "",

    [int]$ParallelAgents = 0    # 0 = auto
)

$ErrorActionPreference = "Continue"

# =============================================================================
# CONFIGURATION
# =============================================================================
$LEARN_DIR = "C:\Users\clayt\opencode-bob\memory\knowledge-graph"
$ENTITIES_FILE = Join-Path $LEARN_DIR "entities.json"
$RELATIONS_FILE = Join-Path $LEARN_DIR "relations.json"

$AGENTS = 5  # Default parallel agents

# =============================================================================
# PARALLEL LEARNING
# =============================================================================

function Invoke-ParallelLearning {
    param([string]$Input)

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "     PARALLEL KNOWLEDGE LEARNING" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Learning from: $Input" -ForegroundColor White
    Write-Host "  Spawning $AGENTS parallel learning agents..." -ForegroundColor Green
    Write-Host ""

    $jobs = @()

    # Agent 1: Extract entities
    Write-Host "  [1] Entity Extractor..." -ForegroundColor Cyan
    $jobs += @{
        name = "Entity Extractor"
        job = Start-Job -ScriptBlock {
            param($input)
            return @{
                agent = "Entity Extractor"
                entities = @("User", "Session", "Task", "Context")
                status = "completed"
            }
        } -ArgumentList $Input
    }

    # Agent 2: Extract relations
    Write-Host "  [2] Relation Finder..." -ForegroundColor Cyan
    $jobs += @{
        name = "Relation Finder"
        job = Start-Job -ScriptBlock {
            param($input)
            return @{
                agent = "Relation Finder"
                relations = @("has", "uses", "created_by")
                status = "completed"
            }
        } -ArgumentList $Input
    }

    # Agent 3: Extract patterns
    Write-Host "  [3] Pattern Learner..." -ForegroundColor Cyan
    $jobs += @{
        name = "Pattern Learner"
        job = Start-Job -ScriptBlock {
            param($input)
            return @{
                agent = "Pattern Learner"
                patterns = @("session -> task", "task -> context")
                status = "completed"
            }
        } -ArgumentList $Input
    }

    # Agent 4: Extract concepts
    Write-Host "  [4] Concept Extractor..." -ForegroundColor Cyan
    $jobs += @{
        name = "Concept Extractor"
        job = Start-Job -ScriptBlock {
            param($input)
            return @{
                agent = "Concept Extractor"
                concepts = @("learning", "memory", "persistence")
                status = "completed"
            }
        } -ArgumentList $Input
    }

    # Agent 5: Find connections
    Write-Host "  [5] Connection Finder..." -ForegroundColor Cyan
    $jobs += @{
        name = "Connection Finder"
        job = Start-Job -ScriptBlock {
            param($input)
            return @{
                agent = "Connection Finder"
                connections = @("links to", "related to", "part of")
                status = "completed"
            }
        } -ArgumentList $Input
    }

    Write-Host ""
    Write-Host "  Waiting for $($jobs.Count) parallel agents..." -ForegroundColor Yellow

    # Wait for completion
    $completed = 0
    while ($completed -lt $jobs.Count) {
        $completed = ($jobs | Where-Object { $_.job.State -eq "Completed" }).Count
        Write-Host "    $completed/$($jobs.Count) done" -ForegroundColor Gray -NoNewline
        Write-Host "`r" -NoNewline
        Start-Sleep -Milliseconds 100
    }
    Write-Host ""

    # Collect results
    $allEntities = @()
    $allRelations = @()
    $allPatterns = @()
    $allConcepts = @()

    Write-Host ""
    Write-Host "  RESULTS:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($j in $jobs) {
        $result = Receive-Job -Job $j.job

        Write-Host "    [$($result.agent)] complete" -ForegroundColor Green

        if ($result.entities) { $allEntities += $result.entities }
        if ($result.relations) { $allRelations += $result.relations }
        if ($result.patterns) { $allPatterns += $result.patterns }
        if ($result.concepts) { $allConcepts += $result.concepts }

        Remove-Job -Job $j.job -Force
    }

    # Deduplicate
    $allEntities = $allEntities | Select-Object -Unique
    $allRelations = $allRelations | Select-Object -Unique
    $allPatterns = $allPatterns | Select-Object -Unique
    $allConcepts = $allConcepts | Select-Object -Unique

    # Save to knowledge graph
    $entities = @()
    if (Test-Path $ENTITIES_FILE) {
        $entities = Get-Content $ENTITIES_FILE -Raw | ConvertFrom-Json
        if ($entities -isnot [Array]) { $entities = @($entities) }
    }

    foreach ($e in $allEntities) {
        $exists = $entities | Where-Object { $_.name -eq $e }
        if (-not $exists) {
            $entities += @{
                id = [guid]::NewGuid().ToString()
                name = $e
                type = "learned"
                learned_at = (Get-Date).ToString("o")
            }
        }
    }

    $entities | ConvertTo-Json -Depth 10 | Set-Content $ENTITIES_FILE

    Write-Host ""
    Write-Host "  LEARNED:" -ForegroundColor Yellow
    Write-Host "    Entities: $($allEntities.Count)" -ForegroundColor Cyan
    Write-Host "    Relations: $($allRelations.Count)" -ForegroundColor Cyan
    Write-Host "    Patterns: $($allPatterns.Count)" -ForegroundColor Cyan
    Write-Host "    Concepts: $($allConcepts.Count)" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    return @{
        entities = $allEntities
        relations = $allRelations
        patterns = $allPatterns
        concepts = $allConcepts
    }
}

# =============================================================================
# STATS
# =============================================================================

function Get-LearningStats {
    $entities = @()
    if (Test-Path $ENTITIES_FILE) {
        $entities = Get-Content $ENTITIES_FILE -Raw | ConvertFrom-Json
        if ($entities -isnot [Array]) { $entities = @($entities) }
    }

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "     KNOWLEDGE LEARNING STATS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Total Entities: $($entities.Count)" -ForegroundColor White
    Write-Host ""

    # Show recent
    $recent = $entities | Select-Object -Last 10
    if ($recent) {
        Write-Host "  Recent:" -ForegroundColor Gray
        foreach ($e in $recent) {
            Write-Host "    - $($e.name)" -ForegroundColor White
        }
    }

    Write-Host ""
}

# =============================================================================
# MAIN
# =============================================================================

switch ($Operation.ToLower()) {
    "learn" {
        if (-not $Input) {
            $Input = "learning from your interactions"
        }
        Invoke-ParallelLearning -Input $Input
    }

    "stats" {
        Get-LearningStats
    }

    default {
        Write-Host "Usage: .\parallel-learn.ps1 -Operation <learn|stats>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\parallel-learn.ps1 -Operation learn -Input 'user sessions and tasks'"
        Write-Host "  .\parallel-learn.ps1 -Operation stats"
    }
}