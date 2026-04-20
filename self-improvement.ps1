# BOB'S SELF-IMPROVEMENT ANALYZER
# Tracks performance, finds improvement opportunities
# Gets smarter over time

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, analyze, trends, improve, suggest
    
    [Parameter(Mandatory=$false)]
    [string]$Area = ""  # code, research, communication, speed, quality
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$PERF_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\performance.json"
$IMPROVE_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\improvements.json"
$TRENDS_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\trends.json"

# ============================================================================
# PERFORMANCE TRACKING
# ============================================================================

function Get-Performance {
    if (Test-Path $PERF_FILE) {
        return Get-Content $PERF_FILE -Raw | ConvertFrom-Json
    }
    
    return @{
        "code" = @{
            "tasks_total" = 0
            "tasks_success" = 0
            "success_rate" = 0
            "avg_time" = 0
            "patterns_used" = @()
        }
        "research" = @{
            "searches" = 0
            "findings_useful" = 0
            "accuracy" = 0
        }
        "communication" = @{
            "clarity_score" = 0
            "response_time" = 0
            "feedback_positive" = 0
        }
        "learning" = @{
            "successes_tracked" = 0
            "errors_tracked" = 0
            "patterns_learned" = 0
            "improvement_rate" = 0
        }
        "last_updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
}

function Save-Performance {
    param([object]$Perf)
    $Perf.last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $Perf | ConvertTo-Json -Depth 10 | Set-Content $PERF_FILE
}

function Record-Task {
    param(
        [string]$Area,
        [string]$Outcome,  # success, failure
        [int]$TimeSeconds
    )
    
    $perf = Get-Performance
    
    if (-not $perf.$Area) {
        $perf.$Area = @{}
    }
    
    $area = $perf.$Area
    if (-not $area.tasks_total) {
        $area.tasks_total = 0
        $area.tasks_success = 0
        $area.success_rate = 0
    }
    
    $area.tasks_total++
    if ($Outcome -eq "success") {
        $area.tasks_success++
    }
    
    # Calculate success rate
    $area.success_rate = [math]::Round(($area.tasks_success / $area.tasks_total) * 100, 1)
    
    # Update time
    if ($TimeSeconds -gt 0 -and $area.avg_time) {
        $area.avg_time = [math]::Round(($area.avg_time + $TimeSeconds) / 2, 1)
    } elseif ($TimeSeconds -gt 0) {
        $area.avg_time = $TimeSeconds
    }
    
    Save-Performance $perf
    Write-Host "📊 Recorded: $Area = $Outcome" -ForegroundColor Cyan
}

function Analyze-Performance {
    $perf = Get-Performance
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📈 BOB'S PERFORMANCE" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Code
    if ($perf.code) {
        Write-Host "💻 CODE:" -ForegroundColor Yellow
        Write-Host "   Tasks: $($perf.code.tasks_total)" -ForegroundColor White
        Write-Host "   Success: $($perf.code.success_rate)%" -ForegroundColor $(if ($perf.code.success_rate -ge 80) { "Green" } else { "Yellow" })
        if ($perf.code.avg_time) {
            Write-Host "   Avg time: $($perf.code.avg_time)s" -ForegroundColor Gray
        }
    }
    
    # Research
    if ($perf.research) {
        Write-Host "`n🔍 RESEARCH:" -ForegroundColor Yellow
        Write-Host "   Searches: $($perf.research.searches)" -ForegroundColor White
        Write-Host "   Accuracy: $($perf.research.accuracy)%" -ForegroundColor $(if ($perf.research.accuracy -ge 80) { "Green" } else { "Yellow" })
    }
    
    # Learning
    if ($perf.learning) {
        Write-Host "`n🧠 LEARNING:" -ForegroundColor Yellow
        Write-Host "   Successes: $($perf.learning.successes_tracked)" -ForegroundColor Green
        Write-Host "   Errors: $($perf.learning.errors_tracked)" -ForegroundColor $(if ($perf.learning.errors_tracked -gt 5) { "Red" } else { "Gray" })
        Write-Host "   Patterns: $($perf.learning.patterns_learned)" -ForegroundColor Cyan
    }
    
    # Overall
    $total = $perf.code.tasks_total + $perf.research.searches
    $overall = if ($total -gt 0) { [math]::Round(($perf.code.tasks_success + $perf.research.findings_useful) / $total * 100, 1) } else { 0 }
    
    Write-Host "`n🎯 OVERALL: $overall% success rate" -ForegroundColor $(if ($overall -ge 80) { "Green" } elseif ($overall -ge 60) { "Yellow" } else { "Red" })
    Write-Host ""
}

function Get-Trends {
    if (Test-Path $TRENDS_FILE) {
        return Get-Content $TRENDS_FILE -Raw | ConvertFrom-Json
    }
    return @{ "trends" = @(); "weekly" = @(); "monthly" = @() }
}

function Add-Insight {
    param(
        [string]$Insight,
        [string]$Category
    )
    
    $improveData = @{
        "insight" = $Insight
        "category" = $Category
        "applied" = $false
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $improvements = @()
    if (Test-Path $IMPROVE_FILE) {
        $improvements = Get-Content $IMPROVE_FILE -Raw | ConvertFrom-Json
        if ($improvements -isnot [System.Array]) { $improvements = @($improvements) }
    }
    
    $improvements += $improveData
    $improvements | ConvertTo-Json -Depth 10 | Set-Content $IMPROVE_FILE
    
    Write-Host "💡 Insight added: $Insight" -ForegroundColor Cyan
}

function Get-Suggestions {
    $perf = Get-Performance
    $suggestions = @()
    
    # Analyze each area
    
    # Code quality
    if ($perf.code.success_rate -lt 80) {
        $suggestions += @{
            "priority" = "high"
            "area" = "code"
            "suggestion" = "Code success rate is $($perf.code.success_rate)%. Focus on understanding before coding."
        }
    }
    
    # Learning
    if ($perf.learning.errors_tracked -gt 3 -and $perf.learning.errors_tracked -gt ($perf.learning.successes_tracked / 2)) {
        $suggestions += @{
            "priority" = "high"
            "area" = "learning"
            "suggestion" = "High error rate. Need to understand failures better before retrying."
        }
    }
    
    # Research
    if ($perf.research.searches -gt 0 -and $perf.research.accuracy -lt 70) {
        $suggestions += @{
            "priority" = "medium"
            "area" = "research"
            "suggestion" = "Research accuracy is low. Focus on fewer, more targeted searches."
        }
    }
    
    # Output suggestions
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💡 IMPROVEMENT SUGGESTIONS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    if ($suggestions.Count -eq 0) {
        Write-Host "  No specific suggestions. Looking good!" -ForegroundColor Green
    } else {
        foreach ($s in $suggestions) {
            $color = if ($s.priority -eq "high") { "Red" } else { "Yellow" }
            Write-Host "  [$($s.priority.ToUpper())] $($s.area)" -ForegroundColor $color
            Write-Host "     → $($s.suggestion)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    
    return $suggestions
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Analyze-Performance
    }
    
    "record" {
        if (-not $Area) {
            Write-Host "Usage: self-improvement.ps1 -Operation record -Area <area> -Outcome <success|failure>"
            exit 1
        }
        Record-Task -Area $Area -Outcome "success"
    }
    
    "analyze" {
        Analyze-Performance
    }
    
    "suggest" {
        Get-Suggestions
    }
    
    "improvements" {
        Get-Suggestions
    }
    
    "insight" {
        if (-not $Area) {
            $Area = "general"
        }
        Add-Insight -Insight $Operation -Category $Area
    }
    
    "clear" {
        $perf = Get-Performance
        $perf.code.tasks_total = 0
        $perf.code.tasks_success = 0
        $perf.code.success_rate = 0
        $perf.research.searches = 0
        $perf.research.findings_useful = 0
        $perf.research.accuracy = 0
        $perf.learning.errors_tracked = 0
        $perf.learning.successes_tracked = 0
        Save-Performance $perf
        Write-Host "Performance cleared" -ForegroundColor Yellow
    }
    
    default {
        Analyze-Performance
    }
}