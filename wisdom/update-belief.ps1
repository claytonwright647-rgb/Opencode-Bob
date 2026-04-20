# BOB'S BELIEF REVISION SYSTEM
# Adaptive Belief Revision - When Evidence Contradicts Assumptions
# Based on BOB-WISDOM by Claude

param(
    [Parameter(Mandatory=$true)]
    [string]$BeliefName,
    
    [Parameter(Mandatory=$true)]
    [string]$PreviousBelief,
    
    [Parameter(Mandatory=$true)]
    [string]$NewEvidence,
    
    [Parameter(Mandatory=$true)]
    [string]$RevisedBelief,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("CERTAIN", "HIGH", "HYPOTHESIS", "UNKNOWN")]
    [string]$ConfidenceLevel = "HIGH"
)

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$beliefRecord = @{
    "timestamp" = $timestamp
    "belief_name" = $BeliefName
    "previous_belief" = $PreviousBelief
    "new_evidence" = $NewEvidence
    "revised_belief" = $RevisedBelief
    "confidence_level" = $ConfidenceLevel
    "type" = "BELIEF_REVISION"
}

$memoryPath = "C:/Users/clayt/opencode-bob/memory/wisdom/belief-revisions.json"

# Load existing beliefs
$beliefs = @()
if (Test-Path $memoryPath) {
    $content = Get-Content $memoryPath -Raw
    if ($content.Trim()) {
        $beliefs = $content | ConvertFrom-Json
        if ($beliefs -isnot [System.Array]) { $beliefs = @($beliefs) }
    }
}

# Add new belief
$beliefs += $beliefRecord

# Save
$beliefs | ConvertTo-Json -Depth 3 | Set-Content $memoryPath

Write-Host "BELIEF REVISION: $BeliefName" -ForegroundColor Yellow
Write-Host "  Previous: $PreviousBelief" -ForegroundColor Gray
Write-Host "  Evidence: $NewEvidence" -ForegroundColor Cyan
Write-Host "  Revised: $RevisedBelief" -ForegroundColor Green
Write-Host "  Confidence: $ConfidenceLevel" -ForegroundColor $(if ($ConfidenceLevel -eq "CERTAIN") { "Green" } elseif ($ConfidenceLevel -eq "HIGH") { "Cyan" } else { "Yellow" })

# Also log to learning (this is a learning event)
$learningPath = "C:/Users/clayt/opencode-bob/memory/learning/interactions.json"
$interaction = @{
    "timestamp" = $timestamp
    "type" = "belief_revision"
    "description" = "${BeliefName}: ${PreviousBelief} to ${RevisedBelief}"
    "outcome" = "success"
    "rule" = "When evidence contradicts belief, update the model explicitly"
}

if (Test-Path $learningPath) {
    $existing = Get-Content $learningPath -Raw | ConvertFrom-Json
    if ($existing -is [System.Array]) {
        $existing += $interaction
        $existing | ConvertTo-Json -Depth 2 | Set-Content $learningPath
    } else {
        @($existing, $interaction) | ConvertTo-Json -Depth 2 | Set-Content $learningPath
    }
} else {
    @($interaction) | ConvertTo-Json -Depth 2 | Set-Content $learningPath
}

return $beliefRecord | ConvertTo-Json -Depth 3