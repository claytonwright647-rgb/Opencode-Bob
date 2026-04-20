# BOB'S "SO WHAT?" SYNTHESIS SYSTEM
# Transforms findings into actionable insights
# Based on BOB-WISDOM by Claude

param(
    [Parameter(Mandatory=$true)]
    [string]$FindingName,
    
    [Parameter(Mandatory=$true)]
    [object[]]$Findings,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$Context
)

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

Write-Host "`n=== SO WHAT ANALYSIS: $FindingName" -ForegroundColor Yellow

$synthesis = @{
    "timestamp" = $timestamp
    "finding_name" = $FindingName
    "classifications" = @()
    "quantifications" = @()
    "priorities" = @()
    "recommendations" = @()
    "type" = "SO_WHAT_SYNTHESIS"
}

# Analyze each finding
foreach ($finding in $Findings) {
    $findingText = $finding.ToString()
    Write-Host "`nFinding: $findingText" -ForegroundColor Cyan
    
    # Classify the finding
    $classification = "unknown"
    if ($findingText -match "error|fail|crash|broken") {
        $classification = "blocker"
        Write-Host "  → Classification: BLOCKER" -ForegroundColor Red
    } elseif ($findingText -match "warning|leak|race|unsafe") {
        $classification = "risk"
        Write-Host "  → Classification: RISK" -ForegroundColor Yellow
    } elseif ($findingText -match "unused|dead|cleanup") {
        $classification = "cleanup"
        Write-Host "  → Classification: CLEANUP" -ForegroundColor Gray
    } else {
        $classification = "no-action"
        Write-Host "  → Classification: NO-ACTION" -ForegroundColor Green
    }
    
    $synthesis.classifications += @{
        "finding" = $findingText
        "classification" = $classification
    }
    
    # Generate recommendation based on classification
    $recommendation = ""
    switch ($classification) {
        "blocker" { $recommendation = "Fix immediately - blocks progress"; $synthesis.priorities += "P1_BLOCKER" }
        "risk" { $recommendation = "Fix before release - correctness risk"; $synthesis.priorities += "P2_RISK" }
        "cleanup" { $recommendation = "Fix when convenient - reduces confusion"; $synthesis.priorities += "P3_CLEANUP" }
        "no-action" { $recommendation = "No action needed"; $synthesis.priorities += "P4_NONE" }
    }
    
    $synthesis.recommendations += @{
        "finding" = $findingText
        "recommendation" = $recommendation
        "priority" = $synthesis.priorities[-1]
    }
}

# Sort by priority
$priorityOrder = @{ "P1_BLOCKER" = 1; "P2_RISK" = 2; "P3_CLEANUP" = 3; "P4_NONE" = 4 }
$synthesis.recommendations = $synthesis.recommendations | Sort-Object { $priorityOrder[$_.priority] }

# Output summary
Write-Host "`n=== SYNTHESIS SUMMARY ===" -ForegroundColor Green
Write-Host "Total Findings: $($Findings.Count)" -ForegroundColor White
Write-Host "Blockers: $(($synthesis.classifications | Where-Object { $_.classification -eq 'blocker' }).Count)" -ForegroundColor Red
Write-Host "Risks: $(($synthesis.classifications | Where-Object { $_.classification -eq 'risk' }).Count)" -ForegroundColor Yellow
Write-Host "Cleanup: $(($synthesis.classifications | Where-Object { $_.classification -eq 'cleanup' }).Count)" -ForegroundColor Gray

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Green
foreach ($rec in $synthesis.recommendations) {
    $color = if ($rec.priority -eq "P1_BLOCKER") { "Red" } elseif ($rec.priority -eq "P2_RISK") { "Yellow" } else { "Gray" }
    Write-Host "[$($rec.priority)] $($rec.recommendation)" -ForegroundColor $color
    Write-Host "         → $($rec.finding)" -ForegroundColor Gray
}

# Store synthesis
$memoryPath = "C:/Users/clayt/opencode-bob/memory/wisdom/so-what-analyses.json"
$syntheses = @()

if (Test-Path $memoryPath) {
    $content = Get-Content $memoryPath -Raw
    if ($content.Trim()) {
        $syntheses = $content | ConvertFrom-Json
        if ($syntheses -isnot [System.Array]) { $syntheses = @($syntheses) }
    }
}
$syntheses += $synthesis
$syntheses | ConvertTo-Json -Depth 5 | Set-Content $memoryPath

return $synthesis | ConvertTo-Json -Depth 5