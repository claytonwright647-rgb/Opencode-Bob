# =============================================================================
# BOB'S REWARD SCORING SYSTEM
# =============================================================================
# Inspired by rust-self-learning-memory (d-o-hub)
# Scores every task outcome and uses it to evolve patterns
#
# Score Components:
#   Correctness (40%) - Did it work?
#   Efficiency (20%) - Steps vs optimal
#   Quality (20%) - Code quality
#   Learning (20%) - Did I improve?
#
# 100% Local - No external dependencies
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "score",  # score, history, patterns, evolve, stats

    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",

    [Parameter(Mandatory=$false)]
    [int]$Correctness = 0,        # 0-100

    [Parameter(Mandatory=$false)]
    [int]$Efficiency = 0,         # 0-100

    [Parameter(Mandatory=$false)]
    [int]$Quality = 0,            # 0-100

    [Parameter(Mandatory=$false)]
    [int]$Learning = 0,           # 0-100

    [Parameter(Mandatory=$false)]
    [string]$Notes = "",

    [Parameter(Mandatory=$false)]
    [int]$Limit = 10
)

$ErrorActionPreference = "Continue"

# =============================================================================
# CONFIGURATION
# =============================================================================
$REWARDS_DIR = "C:\Users\clayt\opencode-bob\memory\rewards"
$SCORES_FILE = Join-Path $REWARDS_DIR "scores.json"
$PATTERNS_FILE = "C:\Users\clayt\opencode-bob\memory\learning\patterns.json"

# Weights for each component
$WEIGHTS = @{
    Correctness = 0.40
    Efficiency = 0.20
    Quality = 0.20
    Learning = 0.20
}

# Ensure directory exists
New-Item -ItemType Directory -Force -Path $REWARDS_DIR | Out-Null

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

function Get-ScoreHistory {
    if (Test-Path $SCORES_FILE) {
        $content = Get-Content $SCORES_FILE -Raw | ConvertFrom-Json
        if ($content -isnot [Array]) { return @($content) }
        return $content
    }
    return @()
}

function Save-ScoreHistory {
    param([array]$History)
    $History | ConvertTo-Json -Depth 10 | Set-Content $SCORES_FILE
}

function Get-LearningPatterns {
    if (Test-Path $PATTERNS_FILE) {
        $content = Get-Content $PATTERNS_FILE -Raw | ConvertFrom-Json
        if ($content -isnot [Array]) { return @($content) }
        return $content
    }
    return @()
}

function Save-LearningPatterns {
    param([array]$Patterns)
    $Patterns | ConvertTo-Json -Depth 10 | Set-Content $PATTERNS_FILE
}

# =============================================================================
# SCORE CALCULATION
# =============================================================================

function Get-TotalScore {
    param(
        [int]$Correctness,
        [int]$Efficiency,
        [int]$Quality,
        [int]$Learning
    )

    $total = ($Correctness * $WEIGHTS.Correctness) +
             ($Efficiency * $WEIGHTS.Efficiency) +
             ($Quality * $WEIGHTS.Quality) +
             ($Learning * $WEIGHTS.Learning)

    return [Math]::Round($total, 1)
}

function Get-ScoreGrade {
    param([double]$Score)

    switch ($true) {
        ($Score -ge 90) { return "A+" }
        ($Score -ge 85) { return "A" }
        ($Score -ge 80) { return "A-" }
        ($Score -ge 75) { return "B+" }
        ($Score -ge 70) { return "B" }
        ($Score -ge 65) { return "B-" }
        ($Score -ge 60) { return "C+" }
        ($Score -ge 55) { return "C" }
        ($Score -ge 50) { return "C-" }
        ($Score -ge 45) { return "D" }
        default { return "F" }
    }
}

# =============================================================================
# SCORE A TASK
# =============================================================================

function Add-TaskScore {
    param(
        [string]$TaskId,
        [int]$Correctness,
        [int]$Efficiency,
        [int]$Quality,
        [int]$Learning,
        [string]$Notes
    )

    # Validate inputs
    $Correctness = [Math]::Max(0, [Math]::Min(100, $Correctness))
    $Efficiency = [Math]::Max(0, [Math]::Min(100, $Efficiency))
    $Quality = [Math]::Max(0, [Math]::Min(100, $Quality))
    $Learning = [Math]::Max(0, [Math]::Min(100, $Learning))

    $totalScore = Get-TotalScore -Correctness $Correctness -Efficiency $Efficiency -Quality $Quality -Learning $Learning
    $grade = Get-ScoreGrade -Score $totalScore

    # Get existing scores
    $history = Get-ScoreHistory

    # Create new score entry
    $newScore = @{
        id = [guid]::NewGuid().ToString()
        task_id = $TaskId
        timestamp = (Get-Date).ToString("o")
        correctness = $Correctness
        efficiency = $Efficiency
        quality = $Quality
        learning = $Learning
        total = $totalScore
        grade = $grade
        notes = $Notes
    }

    # Add to history
    $history = @($newScore) + $history
    Save-ScoreHistory -History $history

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "       TASK SCORED" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "  Task ID: $TaskId" -ForegroundColor White

    Write-Host "`n  Components:" -ForegroundColor Gray
    Write-Host "    Correctness: $Correctness% (×$($WEIGHTS.Correctness))" -ForegroundColor $(if($Correctness -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Efficiency:   $Efficiency% (×$($WEIGHTS.Efficiency))" -ForegroundColor $(if($Efficiency -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Quality:      $Quality% (×$($WEIGHTS.Quality))" -ForegroundColor $(if($Quality -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Learning:     $Learning% (×$($WEIGHTS.Learning))" -ForegroundColor $(if($Learning -ge 70){'Green'}else{'Yellow'})

    Write-Host "`n  Total Score: " -NoNewline
    Write-Host "$totalScore%" -ForegroundColor Green

    Write-Host "  Grade: " -NoNewline
    $gradeColor = switch ($grade) {
        "A+" { "Green" }
        "A" { "Green" }
        "A-" { "Green" }
        "B+" { "Cyan" }
        "B" { "Cyan" }
        "C" { "Yellow" }
        default { "Red" }
    }
    Write-Host $grade -ForegroundColor $gradeColor

    if ($Notes) {
        Write-Host "`n  Notes: $Notes" -ForegroundColor Gray
    }

    Write-Host ""

    return $newScore
}

# =============================================================================
# SHOW HISTORY
# =============================================================================

function Show-ScoreHistory {
    param([int]$Limit = 10)

    $history = Get-ScoreHistory | Select-Object -First $Limit

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "       SCORE HISTORY" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($history.Count -eq 0) {
        Write-Host "  No scores recorded yet." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    foreach ($score in $history) {
        $gradeColor = switch ($score.grade) {
            "A+" { "Green" }
            "A" { "Green" }
            "A-" { "Green" }
            "B+" { "Cyan" }
            "B" { "Cyan" }
            "C" { "Yellow" }
            default { "Red" }
        }

        Write-Host "[$($score.grade)] " -NoNewline -ForegroundColor $gradeColor
        Write-Host "$($score.task_id) " -NoNewline -ForegroundColor White
        Write-Host "$([Math]::Round($score.total, 1))%" -ForegroundColor Gray

        $date = [DateTime]::Parse($score.timestamp)
        Write-Host "    $($date.ToString('MM/dd HH:mm'))" -ForegroundColor DarkGray
    }

    Write-Host ""
}

# =============================================================================
# STATISTICS
# =============================================================================

function Show-ScoreStats {
    $history = Get-ScoreHistory

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "       SCORE STATISTICS" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($history.Count -eq 0) {
        Write-Host "  No scores recorded yet." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Write-Host "  Total scores: $($history.Count)" -ForegroundColor White

    # Calculate averages
    $avgCorrectness = ($history | Measure-Object -Property correctness -Average).Average
    $avgEfficiency = ($history | Measure-Object -Property efficiency -Average).Average
    $avgQuality = ($history | Measure-Object -Property quality -Average).Average
    $avgLearning = ($history | Measure-Object -Property learning -Average).Average
    $avgTotal = ($history | Measure-Object -Property total -Average).Average

    Write-Host "`n  Averages:" -ForegroundColor Gray
    Write-Host "    Correctness: $([Math]::Round($avgCorrectness, 1))%" -ForegroundColor $(if($avgCorrectness -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Efficiency:   $([Math]::Round($avgEfficiency, 1))%" -ForegroundColor $(if($avgEfficiency -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Quality:      $([Math]::Round($avgQuality, 1))%" -ForegroundColor $(if($avgQuality -ge 70){'Green'}else{'Yellow'})
    Write-Host "    Learning:     $([Math]::Round($avgLearning, 1))%" -ForegroundColor $(if($avgLearning -ge 70){'Green'}else{'Yellow'})

    Write-Host "`n  Overall Average: " -NoNewline
    Write-Host "$([Math]::Round($avgTotal, 1))%" -ForegroundColor Green

    # Grade distribution
    $grades = @{}
    foreach ($score in $history) {
        $grades[$score.grade] = ($grades[$score.grade] ?? 0) + 1
    }

    Write-Host "`n  Grade Distribution:" -ForegroundColor Gray
    foreach ($grade in @("A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F")) {
        if ($grades[$grade]) {
            $pct = [Math]::Round($grades[$grade] / $history.Count * 100, 1)
            Write-Host "    $grade : " -NoNewline
            Write-Host "$($grades[$grade]) ($pct%)" -ForegroundColor White
        }
    }

    # Trend (last 10 vs previous 10)
    if ($history.Count -ge 10) {
        $recent10 = $history | Select-Object -First 10
        $older10 = $history | Select-Object -Skip 10 -First 10

        if ($older10.Count -gt 0) {
            $recentAvg = ($recent10 | Measure-Object -Property total -Average).Average
            $olderAvg = ($older10 | Measure-Object -Property total -Average).Average

            $trend = $recentAvg - $olderAvg

            Write-Host "`n  Trend (last 10 vs previous 10):" -ForegroundColor Gray
            Write-Host "    Recent: $([Math]::Round($recentAvg, 1))%" -ForegroundColor White
            Write-Host "    Older:  $([Math]::Round($olderAvg, 1))%" -ForegroundColor White

            if ($trend -gt 0) {
                Write-Host "    Trend:  " -NoNewline
                Write-Host "+$([Math]::Round($trend, 1))% (improving)" -ForegroundColor Green
            } elseif ($trend -lt 0) {
                Write-Host "    Trend:  " -NoNewline
                Write-Host "$([Math]::Round($trend, 1))% (declining)" -ForegroundColor Red
            } else {
                Write-Host "    Trend:  stable" -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
}

# =============================================================================
# PATTERN EVOLUTION
# =============================================================================

function Invoke-PatternEvolution {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "       PATTERN EVOLUTION (PARALLEL)" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    $history = Get-ScoreHistory
    $patterns = Get-LearningPatterns

    if ($history.Count -lt 5) {
        Write-Host "  Need at least 5 scores to evolve patterns" -ForegroundColor Yellow
        Write-Host "  Current: $($history.Count)" -ForegroundColor Gray
        Write-Host ""
        return
    }

    # Group by task type/pattern
    $byType = @{}
    foreach ($score in $history) {
        $type = $score.task_id
        if (-not $byType[$type]) { $byType[$type] = @() }
        $byType[$type] += $score
    }

    $typesList = $byType.Keys
    $jobs = @()

    Write-Host "  Evolving $($typesList.Count) patterns in PARALLEL..." -ForegroundColor Yellow
    Write-Host ""

    # Run evolution analysis in parallel for each pattern
    foreach ($type in $typesList) {
        $job = Start-Job -ScriptBlock {
            param($type, $scores)

            $avgScore = ($scores | Measure-Object -Property total -Average).Average
            $status = if ($avgScore -ge 75) { "STRENGTHEN" } elseif ($avgScore -ge 50) { "MAINTAIN" } else { "WEAKEN" }

            $trend = "stable"
            if ($scores.Count -ge 3) {
                $first3 = ($scores | Select-Object -Skip ($scores.Count - 3) | Measure-Object -Property total -Average).Average
                $last3 = ($scores | Select-Object -First 3 | Measure-Object -Property total -Average).Average
                if ($last3 -gt $first3 + 5) { $trend = "improving" }
                if ($last3 -lt $first3 - 5) { $trend = "declining" }
            }

            return @{
                pattern = $type
                status = $status
                avg_score = $avgScore
                trend = $trend
            }
        } -ArgumentList $type, $byType[$type]

        $jobs += @{ name = $type; job = $job }
    }

    # Wait for all parallel evolutions
    Write-Host "  Waiting for parallel evolution..." -ForegroundColor Cyan

    $completed = 0
    while ($completed -lt $jobs.Count) {
        $completed = ($jobs | Where-Object { $_.job.State -eq "Completed" }).Count
        Start-Sleep -Milliseconds 50
    }

    $evolutions = @()
    foreach ($j in $jobs) {
        $result = Receive-Job -Job $j.job
        $evolutions += $result

        $color = switch ($result.status) {
            "STRENGTHEN" { "Green" }
            "MAINTAIN" { "Yellow" }
            "WEAKEN" { "Red" }
        }

        Write-Host "  [$($result.status)] $($result.pattern): $([Math]::Round($result.avg_score, 1))% ($($result.trend))" -ForegroundColor $color

        # Update pattern with insight
        foreach ($p in $patterns) {
            if ($p.subject -like "*$($result.pattern)*") {
                if (-not $p.insights) { $p.insights = @{} }
                $p.insights.last_evaluation = @{
                    score = $result.avg_score
                    status = $result.status
                    trend = $result.trend
                    evaluated_at = (Get-Date).ToString("o")
                }
            }
        }

        Remove-Job -Job $j.job -Force
    }

    # Save updated patterns
    if ($patterns.Count -gt 0) {
        Save-LearningPatterns -Patterns $patterns
    }

    Write-Host ""
    Write-Host "  Evolved $($evolutions.Count) patterns in parallel" -ForegroundColor Green
    Write-Host ""

    return $evolutions
}

# =============================================================================
# MAIN
# =============================================================================

switch ($Operation.ToLower()) {
    "score" {
        if (-not $TaskId) {
            # Auto-generate task ID if not provided
            $TaskId = "task-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }

        if ($Correctness -eq 0 -and $Efficiency -eq 0 -and $Quality -eq 0 -and $Learning -eq 0) {
            Write-Host "Error: At least one score component is required" -ForegroundColor Red
            Write-Host "  -Correctness <0-100>" -ForegroundColor Gray
            Write-Host "  -Efficiency <0-100>" -ForegroundColor Gray
            Write-Host "  -Quality <0-100>" -ForegroundColor Gray
            Write-Host "  -Learning <0-100>" -ForegroundColor Gray
            exit 1
        }

        Add-TaskScore -TaskId $TaskId -Correctness $Correctness -Efficiency $Efficiency -Quality $Quality -Learning $Learning -Notes $Notes
    }

    "history" {
        Show-ScoreHistory -Limit $Limit
    }

    "stats" {
        Show-ScoreStats
    }

    "evolve" {
        Invoke-PatternEvolution
    }

    "patterns" {
        $patterns = Get-LearningPatterns
        Write-Host "`n  Found $($patterns.Count) learning patterns" -ForegroundColor Cyan

        foreach ($p in $patterns) {
            Write-Host "  - $($p.subject)" -ForegroundColor White
            if ($p.insights -and $p.insights.last_evaluation) {
                $eval = $p.insights.last_evaluation
                Write-Host "    Score: $([Math]::Round($eval.score, 1))% | Trend: $($eval.trend)" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }

    default {
        Write-Host "Usage: score-task.ps1 -Operation <score|history|stats|evolve|patterns>"
        Write-Host ""
        Write-Host "Operations:"
        Write-Host "  score    - Record a task score"
        Write-Host "  history  - Show score history"
        Write-Host "  stats    - Show score statistics"
        Write-Host "  evolve  - Evolve patterns based on scores"
        Write-Host "  patterns - Show patterns with scores"
        Write-Host ""
        Write-Host "Score Components:"
        Write-Host "  -Correctness 0-100  Did it work? (weight: 40%)"
        Write-Host "  -Efficiency 0-100   Steps vs optimal (weight: 20%)"
        Write-Host "  -Quality 0-100     Code quality (weight: 20%)"
        Write-Host "  -Learning 0-100    Did I improve? (weight: 20%)"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\score-task.ps1 -Operation score -TaskId 'build-login' -Correctness 90 -Efficiency 80 -Quality 85 -Learning 70"
        Write-Host "  .\score-task.ps1 -Operation history"
        Write-Host "  .\score-task.ps1 -Operation stats"
        Write-Host "  .\score-task.ps1 -Operation evolve"
    }
}