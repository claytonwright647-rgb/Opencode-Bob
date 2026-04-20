# =============================================================================
# BOB'S DREAM ENGINE - Autonomous Memory Consolidation
# =============================================================================
# Inspired by neural-memory (itsXactlY) - Three phases:
#   NREM - Replay & strengthen active connections, prune weak ones
#   REM  - Discover bridges between isolated memories
#   Insight - Find communities and extract themes
#
# Runs autonomously during idle periods or on-demand
# 100% Local - No external dependencies
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "dream",  # dream, status, stats, force, enable, disable

    [Parameter(Mandatory=$false)]
    [string]$Phase = "full",       # full, nrem, rem, insight

    [Parameter(Mandatory=$false)]
    [int]$IdleThreshold = 300,     # Seconds idle before dreaming (default 5 min)

    [Parameter(Mandatory=$false)]
    [int]$MemoryThreshold = 20     # New memories before dreaming
)

$ErrorActionPreference = "Continue"

# =============================================================================
# CONFIGURATION
# =============================================================================
$DREAM_DIR = "C:\Users\clayt\opencode-bob\memory\dream"
$DREAM_DB = Join-Path $DREAM_DIR "dream-state.json"
$MEMORY_DIR = "C:\Users\clayt\opencode-bob\memory\learning"
$PATTERNS_FILE = Join-Path $MEMORY_DIR "patterns.json"
$STATS_FILE = Join-Path $MEMORY_DIR "stats.json"
$GRAPH_FILE = "C:\Users\clayt\opencode-bob\memory\knowledge-graph\graph.json"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $DREAM_DIR | Out-Null

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

function Get-DreamState {
    if (Test-Path $DREAM_DB) {
        $content = Get-Content $DREAM_DB -Raw | ConvertFrom-Json
        return $content
    }
    return @{
        enabled = $false
        last_dream_at = $null
        last_activity = (Get-Date).ToString("o")
        total_cycles = 0
        idle_seconds = 0
        memories_at_last_dream = 0
    }
}

function Save-DreamState {
    param([hashtable]$State)
    $State | ConvertTo-Json -Depth 5 | Set-Content $DREAM_DB
}

function Get-LearningData {
    $patterns = @()
    if (Test-Path $PATTERNS_FILE) {
        $patterns = Get-Content $PATTERNS_FILE -Raw | ConvertFrom-Json
        if ($patterns -isnot [Array]) { $patterns = @($patterns) }
    }
    return $patterns
}

function Get-KnowledgeGraph {
    $graph = @{nodes = @(); edges = @()}
    if (Test-Path $GRAPH_FILE) {
        $graph = Get-Content $GRAPH_FILE -Raw | ConvertFrom-Json
    }
    return $graph
}

# =============================================================================
# NREM PHASE - Replay, strengthen active, prune weak
# =============================================================================

function Invoke-NREMPhase {
    Write-Host "`n[NREM] Phase starting..." -ForegroundColor Cyan

    $patterns = Get-LearningData
    $graph = Get-KnowledgeGraph

    $stats = @{
        processed = 0
        strengthened = 0
        weakened = 0
        pruned = 0
    }

    if ($patterns.Count -eq 0) {
        Write-Host "  [NREM] No patterns to process" -ForegroundColor Yellow
        return $stats
    }

    # Get recent patterns (last 50)
    $recent = $patterns | Select-Object -Last 50

    foreach ($pattern in $recent) {
        $stats.processed++

        # Find related patterns via keyword similarity
        $keywords = Get-Keywords -Text $pattern.subject

        foreach ($other in $patterns) {
            if ($other.id -eq $pattern.id) { continue }

            $otherKeywords = Get-Keywords -Text $other.subject
            $overlap = ($keywords | Where-Object { $otherKeywords -contains $_ }).Count

            if ($overlap -gt 0) {
                # Strengthen connection
                if (-not $pattern.connections) { $pattern.connections = @{} }
                if (-not $pattern.connections[$other.id]) {
                    $pattern.connections[$other.id] = 0.1
                }
                $pattern.connections[$other.id] = [Math]::Min($pattern.connections[$other.id] + 0.05, 1.0)
                $stats.strengthened++
            }
        }
    }

    # Prune weak connections (below 0.05)
    foreach ($pattern in $patterns) {
        if ($pattern.connections) {
            $toRemove = @()
            $pattern.connections.PSObject.Properties | ForEach-Object {
                if ($_.Value -lt 0.05) { $toRemove += $_.Name }
            }
            foreach ($id in $toRemove) {
                $pattern.connections.PSObject.Properties.Remove($id)
                $stats.pruned++
            }
        }
    }

    # Save updated patterns
    $patterns | ConvertTo-Json -Depth 10 | Set-Content $PATTERNS_FILE

    Write-Host "  [NREM] Processed: $($stats.processed), Strengthened: $($stats.strengthened), Pruned: $($stats.pruned)" -ForegroundColor Green

    return $stats
}

function Get-Keywords {
    param([string]$Text)
    $stopwords = @("the", "a", "an", "is", "was", "are", "to", "of", "in", "for", "on", "with", "at", "by", "and", "or", "but", "not", "if", "then", "so", "it", "its", "this", "that", "i", "you", "we", "they", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "just", "from", "as", "be", "been", "being", "what", "which", "who", "when", "where", "why", "how", "all", "each", "every", "both", "few", "more", "most", "other", "some", "such", "no", "nor", "only", "own", "same", "than", "too", "very", "can", "will", "just", "don't", "should", "now")

    $words = $Text.ToLower() -split '\W+' | Where-Object { $_.Length -gt 2 -and $_ -notin $stopwords }
    return $words | Select-Object -Unique
}

# =============================================================================
# REM PHASE - Bridge discovery between isolated memories
# =============================================================================

function Invoke-REMPhase {
    Write-Host "`n[REM] Phase starting..." -ForegroundColor Cyan

    $patterns = Get-LearningData
    $stats = @{
        explored = 0
        bridges = 0
        rejected = 0
    }

    if ($patterns.Count -lt 5) {
        Write-Host "  [REM] Not enough patterns for bridge discovery" -ForegroundColor Yellow
        return $stats
    }

    # Find isolated patterns (few connections)
    foreach ($pattern in $patterns) {
        $connectionCount = 0
        if ($pattern.connections) {
            $connectionCount = $pattern.connections.PSObject.Properties.Count
        }

        if ($connectionCount -lt 3) {
            $stats.explored++

            # Find similar patterns via keywords
            $keywords = Get-Keywords -Text $pattern.subject

            foreach ($other in $patterns) {
                if ($other.id -eq $pattern.id) { continue }

                $otherKeywords = Get-Keywords -Text $other.subject
                $overlap = ($keywords | Where-Object { $otherKeywords -contains $_ }).Count

                if ($overlap -gt 0) {
                    $similarity = $overlap / [Math]::Max($keywords.Count, $otherKeywords.Count)

                    # Create bridge if similarity is good (0.3 - 0.8)
                    if ($similarity -gt 0.3 -and $similarity -lt 0.8) {
                        if (-not $pattern.connections) { $pattern.connections = @{} }

                        # Only add if no existing stronger connection
                        if (-not $pattern.connections[$other.id] -or $pattern.connections[$other.id] -lt $similarity * 0.3) {
                            $pattern.connections[$other.id] = [Math]::Round($similarity * 0.3, 3)
                            $stats.bridges++
                        }
                    }
                }
            }
        }
    }

    # Save updated patterns
    $patterns | ConvertTo-Json -Depth 10 | Set-Content $PATTERNS_FILE

    Write-Host "  [REM] Explored: $($stats.explored), Bridges: $($stats.bridges)" -ForegroundColor Green

    return $stats
}

# =============================================================================
# INSIGHT PHASE - Community detection and theme extraction
# =============================================================================

function Invoke-InsightPhase {
    Write-Host "`n[Insight] Phase starting..." -ForegroundColor Cyan

    $patterns = Get-LearningData
    $stats = @{
        communities = 0
        bridges = 0
        insights = 0
    }

    if ($patterns.Count -lt 5) {
        Write-Host "  [Insight] Not enough patterns for community detection" -ForegroundColor Yellow
        return $stats
    }

    # Build adjacency from connections
    $adjacency = @{}
    foreach ($pattern in $patterns) {
        if ($pattern.connections) {
            foreach ($conn in $pattern.connections.PSObject.Properties) {
                $weight = $conn.Value
                if ($weight -gt 0.1) {
                    if (-not $adjacency[$pattern.id]) { $adjacency[$pattern.id] = @{} }
                    $adjacency[$pattern.id][$conn.Name] = $weight
                }
            }
        }
    }

    # Find connected components (simple BFS)
    $visited = @{}
    $communities = @()

    foreach ($pattern in $patterns) {
        if ($visited[$pattern.id]) { continue }

        $community = @()
        $queue = @($pattern.id)

        while ($queue.Count -gt 0) {
            $current = $queue[0]
            $queue = $queue[1..($queue.Count - 1)]

            if ($visited[$current]) { continue }
            $visited[$current] = $true
            $community += $current

            if ($adjacency[$current]) {
                foreach ($neighbor in $adjacency[$current].Keys) {
                    if (-not $visited[$neighbor]) {
                        $queue += $neighbor
                    }
                }
            }
        }

        if ($community.Count -gt 0) {
            $communities += ,@($community)
        }
    }

    $stats.communities = $communities.Count

    # Extract themes for each community
    foreach ($community in $communities) {
        if ($community.Count -lt 2) { continue }

        # Get all subjects in this community
        $subjects = $patterns | Where-Object { $community -contains $_.id } | ForEach-Object { $_.subject }

        # Extract common keywords
        $allKeywords = @()
        foreach ($subject in $subjects) {
            $allKeywords += Get-Keywords -Text $subject
        }

        $keywordFreq = @{}
        foreach ($kw in $allKeywords) {
            $keywordFreq[$kw] = ($keywordFreq[$kw] ?? 0) + 1
        }

        $topKeywords = $keywordFreq.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3

        if ($topKeywords) {
            $theme = ($topKeywords | ForEach-Object { $_.Key }) -join ", "
            $confidence = [Math]::Min($community.Count / 10.0, 1.0)

            Write-Host "  [Insight] Found community: $theme (confidence: $([Math]::Round($confidence, 2)))" -ForegroundColor Magenta
            $stats.insights++
        }
    }

    # Find bridge nodes (nodes connecting multiple communities)
    $nodeCommunities = @{}
    for ($i = 0; $i -lt $communities.Count; $i++) {
        foreach ($node in $communities[$i]) {
            if (-not $nodeCommunities[$node]) { $nodeCommunities[$node] = @() }
            $nodeCommunities[$node] += $i
        }
    }

    $bridgeNodes = $nodeCommunities.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    $stats.bridges = $bridgeNodes.Count

    if ($bridgeNodes) {
        Write-Host "  [Insight] Found $($stats.bridges) bridge nodes connecting communities" -ForegroundColor Magenta
    }

    Write-Host "  [Insight] Communities: $($stats.communities), Insights: $($stats.insights)" -ForegroundColor Green

    return $stats
}

# =============================================================================
# MAIN DREAM CYCLE
# =============================================================================

function Invoke-DreamCycle {
    param([string]$Phase = "full")

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "         BOB'S DREAM ENGINE" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    $startTime = Get-Date

    $results = @{
        nrem = @{}
        rem = @{}
        insights = @{}
    }

    # Get current memory count
    $patterns = Get-LearningData
    $currentCount = $patterns.Count

    try {
        if ($Phase -eq "full") {
            # PARALLEL MODE: Run all 3 phases in parallel!
            Write-Host "[DREAM] Running NREM, REM, Insight in PARALLEL..." -ForegroundColor Yellow
            Write-Host ""

            $jobs = @()

            # Start NREM job
            $jobs += @{
                name = "NREM"
                job = Start-Job -ScriptBlock {
                    param($scriptPath, $phase)
                    & $scriptPath -Operation dream -Phase $phase
                } -ArgumentList ($PSScriptRoot + "\dream-engine.ps1"), "nrem"
            }

            # Start REM job
            $jobs += @{
                name = "REM"
                job = Start-Job -ScriptBlock {
                    param($scriptPath, $phase)
                    & $scriptPath -Operation dream -Phase $phase
                } -ArgumentList ($PSScriptRoot + "\dream-engine.ps1"), "rem"
            }

            # Start Insight job
            $jobs += @{
                name = "INSIGHT"
                job = Start-Job -ScriptBlock {
                    param($scriptPath, $phase)
                    & $scriptPath -Operation dream -Phase $phase
                } -ArgumentList ($PSScriptRoot + "\dream-engine.ps1"), "insight"
            }

            # Wait for all jobs
            Write-Host "  Waiting for parallel phases to complete..." -ForegroundColor Cyan

            $completed = 0
            while ($completed -lt $jobs.Count) {
                $completed = ($jobs | Where-Object { $_.job.State -eq "Completed" }).Count
                Start-Sleep -Milliseconds 100
            }

            # Collect results
            foreach ($j in $jobs) {
                $result = Receive-Job -Job $j.job
                Write-Host "  [$($j.name)] Phase complete!" -ForegroundColor Green
                Remove-Job -Job $j.job -Force
            }

            Write-Host ""

            # Update results
            $results.nrem = @{ processed = 1; strengthened = 0; pruned = 0 }
            $results.rem = @{ explored = 0; bridges = 0 }
            $results.insights = @{ communities = 0; insights = 0 }

        } else {
            # Sequential mode (single phase)
            if ($Phase -eq "nrem") {
                $results.nrem = Invoke-NREMPhase
            }

            if ($Phase -eq "rem") {
                $results.rem = Invoke-REMPhase
            }

            if ($Phase -eq "insight") {
                $results.insights = Invoke-InsightPhase
            }
        }

        $duration = (Get-Date) - $startTime

        # Update dream state
        $state = Get-DreamState
        $state.last_dream_at = (Get-Date).ToString("o")
        $state.total_cycles++
        $state.memories_at_last_dream = $currentCount
        Save-DreamState $state

        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "         DREAM COMPLETE" -ForegroundColor Green
        Write-Host "  Duration: $($duration.TotalSeconds.ToString('F1'))s"
        Write-Host "  Total cycles: $($state.total_cycles)"
        Write-Host "========================================`n" -ForegroundColor Cyan

        return $results

    } catch {
        Write-Host "[ERROR] Dream cycle failed: $_" -ForegroundColor Red
        return $results
    }
}

# =============================================================================
# IDLE MONITOR (runs in background)
# =============================================================================

function Start-IdleMonitor {
    Write-Host "[Dream Engine] Starting idle monitor..." -ForegroundColor Cyan
    Write-Host "  Idle threshold: ${IdleThreshold}s" -ForegroundColor Gray
    Write-Host "  Memory threshold: $MemoryThreshold new memories" -ForegroundColor Gray

    while ($true) {
        Start-Sleep -Seconds 30

        $state = Get-DreamState

        if (-not $state.enabled) {
            Write-Host "[Dream Engine] Disabled, sleeping..." -ForegroundColor Gray
            continue
        }

        # Check idle time
        $lastActivity = [DateTime]::Parse($state.last_activity)
        $idleSeconds = ((Get-Date) - $lastActivity).TotalSeconds

        # Check memory count
        $patterns = Get-LearningData
        $newMemories = $patterns.Count - $state.memories_at_last_dream

        $shouldDream = ($idleSeconds -ge $IdleThreshold) -or ($newMemories -ge $MemoryThreshold)

        if ($shouldDream) {
            Write-Host "[Dream Engine] Triggering dream cycle..." -ForegroundColor Yellow
            Write-Host "  Idle: $([Math]::Round($idleSeconds, 0))s, New memories: $newMemories" -ForegroundColor Gray
            Invoke-DreamCycle -Phase "full"
        }
    }
}

function Touch-Activity {
    $state = Get-DreamState
    $state.last_activity = (Get-Date).ToString("o")
    Save-DreamState $state
}

# =============================================================================
# STATUS & STATS
# =============================================================================

function Get-DreamStatus {
    $state = Get-DreamState

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "         DREAM ENGINE STATUS" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "  Enabled: " -NoNewline
    if ($state.enabled) { Write-Host "YES" -ForegroundColor Green }
    else { Write-Host "NO" -ForegroundColor Red }

    Write-Host "  Total cycles: $($state.total_cycles)" -ForegroundColor White
    Write-Host "  Last dream: $($state.last_dream_at)" -ForegroundColor Gray

    if ($state.last_dream_at) {
        $lastDream = [DateTime]::Parse($state.last_dream_at)
        $ago = (Get-Date) - $lastDream
        Write-Host "  Time since last dream: $([Math]::Round($ago.TotalMinutes, 1)) min" -ForegroundColor Gray
    }

    # Get pattern stats
    $patterns = Get-LearningData
    Write-Host "  Total patterns: $($patterns.Count)" -ForegroundColor White

    # Count connections
    $totalConnections = 0
    $connectedPatterns = 0
    foreach ($p in $patterns) {
        if ($p.connections) {
            $totalConnections += $p.connections.PSObject.Properties.Count
            $connectedPatterns++
        }
    }
    Write-Host "  Connected patterns: $connectedPatterns" -ForegroundColor White
    Write-Host "  Total connections: $totalConnections" -ForegroundColor White

    Write-Host ""

    return $state
}

# =============================================================================
# MAIN
# =============================================================================

switch ($Operation.ToLower()) {
    "dream" {
        Invoke-DreamCycle -Phase $Phase
    }

    "status" {
        Get-DreamStatus
    }

    "stats" {
        Get-DreamStatus
    }

    "force" {
        Write-Host "[Dream Engine] Forcing dream cycle..." -ForegroundColor Yellow
        Invoke-DreamCycle -Phase "full"
    }

    "enable" {
        $state = Get-DreamState
        $state.enabled = $true
        $state.last_activity = (Get-Date).ToString("o")
        Save-DreamState $state
        Write-Host "[Dream Engine] Enabled!" -ForegroundColor Green
    }

    "disable" {
        $state = Get-DreamState
        $state.enabled = $false
        Save-DreamState $state
        Write-Host "[Dream Engine] Disabled!" -ForegroundColor Yellow
    }

    "touch" {
        Touch-Activity
        Write-Host "[Dream Engine] Activity recorded!" -ForegroundColor Green
    }

    "monitor" {
        Write-Host "[Dream Engine] Starting idle monitor (Ctrl+C to stop)..." -ForegroundColor Yellow
        Start-IdleMonitor
    }

    default {
        Write-Host "Usage: dream-engine.ps1 -Operation <dream|status|stats|force|enable|disable|touch|monitor>"
        Write-Host ""
        Write-Host "Operations:"
        Write-Host "  dream   - Run a dream cycle (default: full)"
        Write-Host "  status  - Show current status"
        Write-Host "  stats   - Show statistics"
        Write-Host "  force   - Force an immediate dream cycle"
        Write-Host "  enable  - Enable automatic dreaming"
        Write-Host "  disable - Disable automatic dreaming"
        Write-Host "  touch   - Record activity (reset idle timer)"
        Write-Host "  monitor - Start idle monitor (background)"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\dream-engine.ps1 -Operation dream -Phase full"
        Write-Host "  .\dream-engine.ps1 -Operation enable"
        Write-Host "  .\dream-engine.ps1 -Operation force"
    }
}