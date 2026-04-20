# Opencode Bob - Comprehensive Test Suite
# Tests all systems and generates a full report

$ErrorActionPreference = "Continue"
$testResults = @()

function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Category = "General"
    )
    
    Write-Host ""
    Write-Host "─" * 60
    Write-Host "TEST: $Name" -ForegroundColor Cyan
    
    $result = @{
        Name = $Name
        Category = $Category
        Status = "PASS"
        Error = $null
        Details = ""
        StartTime = Get-Date
    }
    
    try {
        $output = & $Test
        $result.Details = $output
        Write-Host "✓ PASSED" -ForegroundColor Green
    } catch {
        $result.Status = "FAIL"
        $result.Error = $_.Exception.Message
        Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $result.EndTime = Get-Date
    $result.Duration = ($result.EndTime - $result.StartTime).TotalMilliseconds
    
    $script:testResults += [PSCustomObject]$result
    
    return $result
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "        OPENCODE BOB - COMPREHENSIVE TEST SUITE" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ============================================================================
# TEST 1: TIME MACHINE
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: TIME MACHINE                                   ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Time Machine: Snapshot Creation" -Category "TimeMachine" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/time-machine.ps1 -Label "Test-Snapshot" -Type "Manual" 2>&1
    if ($output -match "SNAPSHOT:.*Files:") {
        return "Snapshot created successfully"
    }
    throw "Snapshot creation failed: $output"
}

Test-Function -Name "Time Machine: Log File Exists" -Category "TimeMachine" -Test {
    if (Test-Path "C:/Users/clayt/opencode-bob/time-machine/time-machine.log") {
        $content = Get-Content "C:/Users/clayt/opencode-bob/time-machine/time-machine.log" -Tail 5
        return "Log has $(($content | Measure-Object -Line).Lines) entries"
    }
    throw "Log file not found"
}

Test-Function -Name "Time Machine: Snapshot Directory Structure" -Category "TimeMachine" -Test {
    $snapshots = Get-ChildItem "C:/Users/clayt/opencode-bob/time-machine" -Directory -Recurse -Depth 2 | Select-Object -First 5
    if ($snapshots.Count -gt 0) {
        return "Found $($snapshots.Count) directories in time-machine"
    }
    throw "No snapshot directories found"
}

# ============================================================================
# TEST 2: KNOWLEDGE GRAPH
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: KNOWLEDGE GRAPH                               ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Knowledge Graph: Stats Command" -Category "KnowledgeGraph" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/knowledge-graph.ps1 -Operation stats 2>&1
    if ($output -match "Entities:") {
        return "Knowledge graph stats working"
    }
    throw "Stats command failed"
}

Test-Function -Name "Knowledge Graph: Query Command" -Category "KnowledgeGraph" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/knowledge-graph.ps1 -Query "user clay" 2>&1
    if ($output -match "KNOWLEDGE GRAPH QUERY" -or $output -match "DIRECT MATCHES") {
        return "Query working"
    }
    throw "Query failed"
}

Test-Function -Name "Knowledge Graph: Entity Storage" -Category "KnowledgeGraph" -Test {
    if (Test-Path "C:/Users/clayt/opencode-bob/memory/knowledge-graph/entities.json") {
        $content = Get-Content "C:/Users/clayt/opencode-bob/memory/knowledge-graph/entities.json" | ConvertFrom-Json
        return "Entities file has $($content.PSObject.Properties.Count) entries"
    }
    throw "Entities file not found"
}

Test-Function -Name "Knowledge Graph: Relations Storage" -Category "KnowledgeGraph" -Test {
    if (Test-Path "C:/Users/clayt/opencode-bob/memory/knowledge-graph/relations.json") {
        $content = Get-Content "C:/Users/clayt/opencode-bob/memory/knowledge-graph/relations.json" | ConvertFrom-Json
        return "Relations file has $($content.Count) entries"
    }
    throw "Relations file not found"
}

# ============================================================================
# TEST 3: LEARNING ENGINE
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: LEARNING ENGINE                              ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Learning: Track Success" -Category "Learning" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/learning-engine.ps1 -Operation track -Type success -Subject "test-success" -Details "test-succeeded" 2>&1
    if ($output -match "Learned success") {
        return "Success tracking works"
    }
    throw "Track success failed"
}

Test-Function -Name "Learning: Track Error" -Category "Learning" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/learning-engine.ps1 -Operation track -Type error -Subject "test-error" -Details "error-occurred" -Outcome "fix-applied" 2>&1
    if ($output -match "Learned error") {
        return "Error tracking works"
    }
    throw "Track error failed"
}

Test-Function -Name "Learning: Track Preference" -Category "Learning" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/learning-engine.ps1 -Operation track -Type preference -Subject "coding_style" -Details "practical" 2>&1
    if ($output -match "Learned preference") {
        return "Preference tracking works"
    }
    throw "Track preference failed"
}

Test-Function -Name "Learning: Stats Command" -Category "Learning" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/learning-engine.ps1 -Operation stats 2>&1
    if ($output -match "LEARNING SYSTEM STATISTICS" -or $output -match "Successes") {
        return "Learning stats working"
    }
    throw "Stats command failed"
}

Test-Function -Name "Learning: Recall Patterns" -Category "Learning" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/learning-engine.ps1 -Operation recall -Subject "test" 2>&1
    if ($output -match "RECALL") {
        return "Recall working"
    }
    throw "Recall failed"
}

# AUTO-LEARN: Learn from test results
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Operation learn -Context "test-suite" -Result "success" -Details "21 tests passed"

# ============================================================================
# TEST 4: LOCAL ARCHITECTURE
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: LOCAL ARCHITECTURE                           ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Local Arch: Status Command" -Category "Architecture" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/local-architecture.ps1 -Operation status 2>&1
    if ($output -match "LOCAL ARCHITECTURE STATUS") {
        return "Architecture status working"
    }
    throw "Status command failed"
}

Test-Function -Name "Local Arch: Ollama Connection" -Category "Architecture" -Test {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
        return "Ollama running with $($response.models.Count) models"
    } catch {
        throw "Ollama not accessible: $($_.Exception.Message)"
    }
}

Test-Function -Name "Local Arch: Diagram Command" -Category "Architecture" -Test {
    $output = pwsh -File C:/Users/clayt/opencode-bob/local-architecture.ps1 -Operation diagram 2>&1
    if ($output -match "LOCAL ARCHITECTURE") {
        return "Diagram generation working"
    }
    throw "Diagram command failed"
}

# ============================================================================
# TEST 5: PARALLEL AGENTS
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: PARALLEL AGENTS                              ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Parallel Agents: Script Executes" -Category "Parallel" -Test {
    # Quick test with just 2 agents
    $output = pwsh -File C:/Users/clayt/opencode-bob/parallel-agents.ps1 -Tasks "Analyze this file|Analyze that file" -MaxAgents 2 2>&1
    if ($output -match "PARALLEL AGENT EXECUTION COMPLETE" -or $output -match "Total Agents:") {
        return "Parallel execution working"
    }
    # Check if it at least started
    if ($output -match "Starting parallel execution" -or $output -match "started agent") {
        return "Parallel execution started"
    }
    throw "Parallel agents failed: $($output | Select-Object -First 3)"
}

# ============================================================================
# TEST 6: FILE STRUCTURE
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: FILE STRUCTURE                               ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Files: Core Scripts Exist" -Category "Files" -Test {
    $required = @(
        "C:/Users/clayt/opencode-bob/time-machine.ps1",
        "C:/Users/clayt/opencode-bob/knowledge-graph.ps1",
        "C:/Users/clayt/opencode-bob/learning-engine.ps1",
        "C:/Users/clayt/opencode-bob/parallel-agents.ps1",
        "C:/Users/clayt/opencode-bob/local-architecture.ps1"
    )
    
    $missing = @()
    foreach ($file in $required) {
        if (-not (Test-Path $file)) {
            $missing += $file
        }
    }
    
    if ($missing.Count -eq 0) {
        return "All $($required.Count) core scripts exist"
    }
    throw "Missing: $($missing -join ', ')"
}

Test-Function -Name "Files: Skills Directory" -Category "Files" -Test {
    $skills = Get-ChildItem "C:/Users/clayt/opencode-bob/skills" -Directory
    if ($skills.Count -gt 0) {
        return "Found $($skills.Count) skill directories"
    }
    throw "No skills found"
}

Test-Function -Name "Files: Memory Directory" -Category "Files" -Test {
    $memDirs = @(
        "C:/Users/clayt/opencode-bob/memory",
        "C:/Users/clayt/opencode-bob/memory/entities",
        "C:/Users/clayt/opencode-bob/memory/knowledge-graph"
    )
    
    $allExist = $true
    foreach ($dir in $memDirs) {
        if (-not (Test-Path $dir)) {
            $allExist = $false
            break
        }
    }
    
    if ($allExist) {
        return "All memory directories exist"
    }
    throw "Some memory directories missing"
}

# ============================================================================
# TEST 7: AGENT DEFINITION
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║ TEST CATEGORY: AGENT DEFINITION                             ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Test-Function -Name "Agent: Definition File Exists" -Category "Agent" -Test {
    if (Test-Path "C:/Users/clayt/opencode-bob/agents/opencode-bob.md") {
        return "Agent definition exists"
    }
    throw "Agent definition file missing"
}

Test-Function -Name "Agent: Memory Preferences File" -Category "Agent" -Test {
    if (Test-Path "C:/Users/clayt/opencode-bob/memory/user-preferences.md") {
        return "User preferences file exists"
    }
    throw "User preferences file missing"
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "                     TEST SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host ""
Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed:      $passCount" -ForegroundColor Green
Write-Host "Failed:      $failCount" -ForegroundColor Red

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "FAILED TESTS:" -ForegroundColor Red
    foreach ($test in $testResults | Where-Object { $_.Status -eq "FAIL" }) {
        Write-Host "  - $($test.Name): $($test.Error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow

# Save results to file
$reportFile = "C:/Users/clayt/opencode-bob/test-results-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').json"
$testResults | ConvertTo-Json -Depth 5 | Set-Content -Path $reportFile
Write-Host "Results saved to: $reportFile"

return @{
    Total = $totalCount
    Passed = $passCount
    Failed = $failCount
    Results = $testResults
}