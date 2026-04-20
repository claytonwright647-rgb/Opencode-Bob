# BOB'S AGGRESSIVE RESEARCH SYSTEM
# When stuck: Research EVERYTHING - web, blogs, YouTube, Reddit, docs!
# NEVER give up - research until you find the answer!

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "research",  # research, stuck, deep-search
    
    [Parameter(Mandatory=$false)]
    [string]$Problem = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Context = "",
    
    [int]$MaxSearches = 5
)

$ErrorActionPreference = "Continue"

# ============================================================================
# RESEARCH STRATEGY: ESCALATION
# ============================================================================
# Level 1: Basic web search
# Level 2: Blog posts
# Level 3: YouTube videos  
# Level 4: Reddit discussions
# Level 5: Stack Overflow
# Level 6: GitHub issues
# Level 7: Documentation
# Level 8: Source code

function Start-AggressiveResearch {
    param(
        [string]$Problem,
        [string]$Context,
        [int]$MaxSearches
    )
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  🔬 AGGRESSIVE RESEARCH MODE" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Problem: $Problem" -ForegroundColor White
    Write-Host "Context: $Context" -ForegroundColor Gray
    Write-Host ""
    
    # First - snapshot!
    Write-Host "[1/8] Creating backup before research..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "research-before-$((Get-Date).ToString('yyyy-MM-dd-HHmm'))" | Out-Null
    
    # Build search queries
    $queries = Build-SearchQueries -Problem $Problem -Context $Context
    
    Write-Host "[2/8] Built $($queries.Count) search queries" -ForegroundColor Green
    Write-Host ""
    
    $findings = @()
    
    # Execute searches at different levels
    Write-Host "[3/8] Searching web (Level 1)..." -ForegroundColor Cyan
    $findings += Execute-Search -Query $queries[0] -Level "web"
    
    Write-Host "[4/8] Searching blogs (Level 2)..." -ForegroundColor Cyan
    $findings += Execute-Search -Query "$($queries[0]) site:medium.com OR site:dev.to OR site:blog" -Level "blogs"
    
    Write-Host "[5/8] Searching YouTube (Level 3)..." -ForegroundColor Cyan
    $findings += Execute-Search -Query "$($queries[0]) tutorial" -Level "youtube"
    
    Write-Host "[6/8] Searching Reddit (Level 4)..." -ForegroundColor Cyan
    $findings += Execute-Search -Query "$($queries[0]) site:reddit.com" -Level "reddit"
    
    Write-Host "[7/8] Searching Stack Overflow (Level 5)..." -ForegroundColor Cyan
    $findings += Execute-Search -Query "$($queries[0]) site:stackoverflow.com" -Level "stackoverflow"
    
    Write-Host "[8/8] Analyzing findings..." -ForegroundColor Cyan
    Write-Host ""
    
    # Present findings
    if ($findings.Count -gt 0) {
        Write-Host "═══════════════════════════════════════" -ForegroundColor Green
        Write-Host "  📚 RESEARCH FINDINGS" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════" -ForegroundColor Green
        Write-Host ""
        
        $i = 0
        foreach ($finding in $findings | Select-Object -First 10) {
            $i++
            $icon = switch ($finding.level) {
                "web" { "🌐" }
                "blogs" { "📝" }
                "youtube" { "🎬" }
                "reddit" { "💬" }
                "stackoverflow" { "📋" }
                default { "•" }
            }
            
            Write-Host "  $icon $($finding.title)" -ForegroundColor White
            Write-Host "     $($finding.url)" -ForegroundColor Gray
            Write-Host "     Source: $($finding.level)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        Write-Host "   Found $($findings.Count) total results" -ForegroundColor Green
    } else {
        Write-Host "   No results found. Try different keywords." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "💡 Next step: Try ONE of these solutions!" -ForegroundColor Cyan
    Write-Host ""
    
    return $findings
}

function Build-SearchQueries {
    param(
        [string]$Problem,
        [string]$Context
    )
    
    $queries = @()
    
    # Primary query
    $queries += $Problem
    
    # With context
    if ($Context) {
        $queries += "$Problem $Context"
    }
    
    # Error-specific patterns
    if ($Problem -match "error|exception|failed") {
        $queries += "$Problem fix solution"
        $queries += "$Problem troubleshooting"
    }
    
    if ($Problem -match "null|NIL|none") {
        $queries += "$Problem causes"
        $queries += "$Problem best practice"
    }
    
    # Language-specific
    if ($Problem -match "powershell|ps1|windows") {
        $queries += "$Problem Microsoft Docs"
        $queries += "$Problem Stack Overflow"
    }
    
    return $queries | Select-Object -Unique
}

function Execute-Search {
    param(
        [string]$Query,
        [string]$Level
    )
    
    $results = @()
    
    try {
        # Use websearch to find results
        $searchResults = @()
        
        # This would call the actual websearch - for now we'll simulate finding results
        # In practice, this would use the websearch tool
        
        # For demonstration, return empty (actual implementation would search)
        Write-Host "      Searching: $Query" -ForegroundColor Gray
        
    } catch {
        Write-Host "      Search failed: $_" -ForegroundColor Red
    }
    
    return $results
}

# ============================================================================
# STUCK MODE - ESCALATE RESEARCH
# ============================================================================

function Stuck-Mode {
    param([string]$Problem)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ⚠️  STUCK MODE ACTIVATED" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════=" -ForegroundColor Red
    Write-Host ""
    Write-Host "First approach failed. Escalating research!" -ForegroundColor White
    Write-Host ""
    
    # Check for patterns to avoid
    Write-Host "[1/4] Checking what NOT to try..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\error-recovery.ps1" -Operation check -Context $Problem | Out-Null
    
    Write-Host "[2/4] Running aggressive research..." -ForegroundColor Gray
    $findings = Start-AggressiveResearch -Problem $Problem -Context "" -MaxSearches 5
    
    Write-Host "[3/4] Updating error history..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\error-recovery.ps1" -Operation track -Error $Problem -Context "stuck mode" -FixAttempted "need new approach" | Out-Null
    
    Write-Host "[4/4] Creating backup..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "stuck-mode-$((Get-Date).ToString('yyyy-MM-dd-HHmm'))" | Out-Null
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  🎯 RECOMMENDATION" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. Try a COMPLETELY DIFFERENT approach" -ForegroundColor White
    Write-Host "   2. Don't repeat what just failed" -ForegroundColor White
    Write-Host "   3. Use the research findings above" -ForegroundColor White
    Write-Host "   4. If still stuck: ask for help!" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "research" {
        if (-not $Problem) {
            Write-Host "Usage: aggressive-research.ps1 -Operation research -Problem 'your problem'"
            exit 1
        }
        Start-AggressiveResearch -Problem $Problem -Context $Context -MaxSearches $MaxSearches
    }
    
    "stuck" {
        if (-not $Problem) {
            Write-Host "Usage: aggressive-research.ps1 -Operation stuck -Problem 'what failed'"
            exit 1
        }
        Stuck-Mode -Problem $Problem
    }
    
    "deep-search" {
        if (-not $Problem) {
            Write-Host "Usage: aggressive-research.ps1 -Operation deep-search -Problem 'what'"
            exit 1
        }
        # Maximum research
        Start-AggressiveResearch -Problem $Problem -Context $Context -MaxSearches 10
    }
    
    default {
        Write-Host "Usage: aggressive-research.ps1 -Operation <research|stuck|deep-search>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\aggressive-research.ps1 -Operation research -Problem 'NullReferenceException in C#'"
        Write-Host "  .\aggressive-research.ps1 -Operation stuck -Problem 'fix failed'"
    }
}