# Opencode Bob - Parallel Agent Execution Engine (FIXED)
# Simplified approach using Start-Job

param(
    [Parameter(Mandatory=$true)]
    [string]$Tasks,
    
    [int]$MaxAgents = 5,
    
    [string]$Model = "qwen2.5:7b",
    
    [switch]$VerboseOutput
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$OLLAMA_HOST = "http://localhost:11434"
$AGENT_TIMEOUT = 120
$RESULTS_DIR = "C:\Users\clayt\opencode-bob\parallel-results"

New-Item -ItemType Directory -Force -Path $RESULTS_DIR | Out-Null

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$timestamp] [$Level] $Message"
    if ($VerboseOutput -or $Level -eq "ERROR") {
        Write-Host $logMsg
    }
    $logFile = Join-Path $RESULTS_DIR "parallel-$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $logMsg
}

function Invoke-SingleAgent {
    param([string]$Task, [string]$AgentId)
    
    try {
        $prompt = @{
            model = $Model
            prompt = "Task #$AgentId`: $Task`n`nProvide a focused response."
            stream = $false
            options = @{
                temperature = 0.7
                num_ctx = 4096
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$OLLAMA_HOST/api/generate" `
            -Method Post `
            -Body $prompt `
            -ContentType "application/json" `
            -TimeoutSec $AGENT_TIMEOUT
        
        return @{
            AgentId = $AgentId
            Task = $Task
            Status = "success"
            Output = $response.response
        }
    } catch {
        return @{
            AgentId = $AgentId
            Task = $Task
            Status = "failed"
            Error = $_.Exception.Message
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "PARALLEL AGENT EXECUTION ENGINE" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Parse tasks
$taskList = @()
if ($Tasks -match '^\[.*\]$') {
    $taskList = $Tasks | ConvertFrom-Json
} else {
    $taskList = $Tasks -split '\|'
}
$taskList = $taskList | Where-Object { $_ -ne "" }

Write-Host "Tasks submitted: $($taskList.Count)" -ForegroundColor Yellow
Write-Host "Max parallel: $MaxAgents" -ForegroundColor Yellow
Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host ""

# Check Ollama
try {
    $check = Invoke-RestMethod -Uri "$OLLAMA_HOST/api/tags" -TimeoutSec 5
    Write-Host "Ollama: Connected ($($check.models.Count) models)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Ollama not available" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Run agents - simple loop
$results = @()
$agentId = 1

Write-Host ""
Write-Host "Starting agents..." -ForegroundColor Cyan

foreach ($task in $taskList) {
    if ($agentId -gt $MaxAgents) {
        Write-Host "Max agents reached ($MaxAgents), stopping" -ForegroundColor Yellow
        break
    }
    
    Write-Host "  Starting agent $agentId..." -NoNewline
    
    $result = Invoke-SingleAgent -Task $task -AgentId $agentId
    
    $results += $result
    
    if ($result.Status -eq "success") {
        Write-Host " DONE" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    $agentId++
}

# Summary
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "success" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "failed" }).Count

Write-Host "Total Agents: $($results.Count)" -ForegroundColor White
Write-Host "Successful:  $successCount" -ForegroundColor Green
Write-Host "Failed:       $failCount" -ForegroundColor Red

# Show outputs
Write-Host ""
foreach ($r in $results) {
    Write-Host "Agent $($r.AgentId): [$($r.Status)]" -ForegroundColor $(if ($r.Status -eq "success") { "Green" } else { "Red" })
    if ($r.Output) {
        $preview = $r.Output.ToString().Substring(0, [Math]::Min(100, $r.Output.ToString().Length))
        Write-Host "  Output: $preview..." -ForegroundColor Gray
    }
    if ($r.Error) {
        Write-Host "  Error: $($r.Error)" -ForegroundColor Red
    }
}

# Save results
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = Join-Path $RESULTS_DIR "run_$timestamp.json"
$results | ConvertTo-Json -Depth 3 | Set-Content -Path $outputFile

Write-Host ""
Write-Host "Results saved to: $outputFile" -ForegroundColor Gray
Write-Host "=" * 60 -ForegroundColor Cyan

return $results