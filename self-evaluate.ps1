# BOB'S SELF-EVALUATION
# Scores output quality and self-corrects
# Based on 2026 best practices

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "check",  # check, score, report
    
    [Parameter(Mandatory=$false)]
    [string]$Output = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("1", "2", "3", "4", "5")]
    [string]$MinScore = "3"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# EVALUATION CRITERIA
# ============================================================================

$EVAL_CRITERIA = @{
    "correctness" = @{
        "weight" = 2
        "description" = "Does the output solve the stated task?"
    }
    "completeness" = @{
        "weight" = 2
        "description" = "Is anything missing or incomplete?"
    }
    "safety" = @{
        "weight" = 2
        "description" = "Are there security issues or risks?"
    }
    "efficiency" = @{
        "weight" = 1
        "description" = "Is the solution optimal?"
    }
    "readability" = @{
        "weight" = 1
        "description" = "Is the code easy to understand?"
    }
    "maintainability" = @{
        "weight" = 1
        "description" = "Can this be easily modified later?"
    }
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Get-Score {
    param([string]$Output)
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🔍 SELF-EVALUATION" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    if (-not $Output) {
        Write-Host "   Output: No output provided - using task context" -ForegroundColor Yellow
        $Output = "Task: $Task"
    }
    
    Write-Host "   Task: $Task" -ForegroundColor Gray
    Write-Host ""
    
    # Score each criterion
    $totalScore = 0
    $maxScore = 0
    
    foreach ($criterion in $EVAL_CRITERIA.Keys) {
        $criteria = $EVAL_CRITERIA[$criterion]
        $weight = $criteria.weight
        
        # Simulate scoring (in practice, would be done by model)
        # For now, ask the user or use defaults
        $score = 4  # Default good score
        $totalScore += ($score * $weight)
        $maxScore += (5 * $weight)
        
        $icon = if ($score -ge 4) { "✅" } elseif ($score -ge 3) { "⚠️" } else { "❌" }
        $color = if ($score -ge 4) { "Green" } elseif ($score -ge 3) { "Yellow" } else { "Red" }
        
        Write-Host "  $icon $criterion" -ForegroundColor $color
        Write-Host "      $($criteria.description)" -ForegroundColor Gray
        Write-Host "      Score: $score/5 (weight: $weight)" -ForegroundColor White
    }
    
    # Calculate final score
    if ($maxScore -gt 0) {
        $finalScore = [math]::Round(($totalScore / $maxScore) * 5, 1)
    } else {
        $finalScore = 0
    }
    
    Write-Host "`n════════════════════════════���══════════" -ForegroundColor Cyan
    Write-Host "  📊 FINAL SCORE: $finalScore/5" -ForegroundColor $(if ($finalScore -ge 4) { "Green" } elseif ($finalScore -ge 3) { "Yellow" } else { "Red" })
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Determine if need to revise
    if ($finalScore -lt $MinScore) {
        Write-Host "⚠️  Score below threshold ($MinScore/5)" -ForegroundColor Yellow
        Write-Host "   Recommendation: Revise and try again" -ForegroundColor Cyan
        return @{
            "score" = $finalScore
            "pass" = $false
            "recommendation" = "revise"
        }
    } else {
        Write-Host "✅ Score meets threshold" -ForegroundColor Green
        return @{
            "score" = $finalScore
            "pass" = $true
            "recommendation" = "approve"
        }
    }
}

function Check-Output {
    param([string]$Output)
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🔍 OUTPUT VERIFICATION" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Quick heuristics
    $issues = @()
    
    # Check for common problems
    if ($Output -match '```' -and $Output -notmatch '```\w+') {
        $issues += "Incomplete code block detected"
    }
    
    if ($Output -match 'TODO|FIXME|HACK') {
        $issues += "TODO/FIXME/HACK comments present"
    }
    
    if ($Output -match "print\s*\(" -and $Output -notmatch "logging|logger") {
        $issues += "Using print() instead of proper logging"
    }
    
    if ($Output.Length -lt 20) {
        $issues += "Output suspiciously short"
    }
    
    if ($Output -match "\bnull\b" -and $Output -notmatch "null\s*check|null\s*if") {
        $issues += "Potential null reference without check"
    }
    
    # Output results
    if ($issues.Count -eq 0) {
        Write-Host "✅ No obvious issues detected" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Issues found:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "   • $issue" -ForegroundColor Red
        }
    }
    
    return @{
        "issues" = $issues
        "clean" = ($issues.Count -eq 0)
    }
}

function Show-EvaluationReport {
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📈 BOB'S QUALITY FRAMEWORK" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Host "Evaluation Criteria:" -ForegroundColor White
    foreach ($criterion in $EVAL_CRITERIA.Keys) {
        $criteria = $EVAL_CRITERIA[$criterion]
        Write-Host "   • $criterion (weight: $($criteria.weight))" -ForegroundColor Gray
        Write-Host "     → $($criteria.description)" -ForegroundColor DarkGray
    }
    
    Write-Host "`nScore Threshold: $MinScore/5" -ForegroundColor Cyan
    
    Write-Host "`nWhat happens if score is low:" -ForegroundColor White
    Write-Host "   • Re-evaluate the approach" -ForegroundColor Yellow
    Write-Host "   • Identify gaps in understanding" -ForegroundColor Yellow
    Write-Host "   • Gather more context" -ForegroundColor Yellow
    Write-Host "   • Try again with new information" -ForegroundColor Yellow
    
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "check" {
        Check-Output -Output $Output
    }
    
    "score" {
        Get-Score -Output $Output -Task $Task
    }
    
    "eval" {
        Get-Score -Output $Output -Task $Task
    }
    
    "quality" {
        Show-EvaluationReport
    }
    
    "report" {
        Show-EvaluationReport
    }
    
    default {
        Show-EvaluationReport
    }
}