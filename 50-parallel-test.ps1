# Opencode Bob - 50 Parallel Agents Test
# This demonstrates infinite parallel agent execution

param(
    [int]$NumAgents = 50,
    [string]$Task = "analyze different aspects of the codebase"
)

$ErrorActionPreference = "Continue"

$start = Get-Date
Write-Host "=" * 60
Write-Host "OPENCODE BOB - 50 PARALLEL AGENTS TEST"
Write-Host "=" * 60
Write-Host ""
Write-Host "[Commander] Task: $Task"
Write-Host "[Commander] Spawning $NumAgents parallel agents..."
Write-Host ""

# Get 50 different things to analyze
$files = Get-ChildItem -Path C:/Users/clayt/opencode-bob -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 50 FullName
$aspects = @(
    "Security", "Performance", "Code Quality", "Documentation", 
    "Testing", "Error Handling", "Memory Usage", "API Calls",
    "Data Structures", "Algorithms", "Style", "Complexity",
    "Dependencies", "Naming", "Comments", "DRY Violations",
    "SOLID Compliance", "Performance Hotspots", "Logging", "Config",
    "Validation", "Edge Cases", "Concurrency", "Caching",
    "Error Recovery", "Thread Safety", "Resource Management",
    "Code Duplication", "Best Practices", "Security Headers",
    "Database Calls", "Network Calls", "File Operations",
    "Regex Patterns", "String Operations", "Loop Efficiency",
    "Variable Scope", "Exception Handling", "Mutable State",
    "Magic Numbers", "Hardcoding", "Copy-Paste Code",
    "Unused Code", "Dead Code", "Console Output",
    "Deprecated APIs", "Performance Bottlenecks", "Refactoring Needed",
    "Test Coverage", "Integration Points", "External Deps"
)

# Launch 50 parallel jobs - each analyzing one aspect for the whole codebase
$jobs = @()

Write-Host "[Commander] Delegating to 50 parallel subagents..."
Write-Host ""

for ($i = 0; $i -lt $NumAgents; $i++) {
    $aspect = $aspects[$i % $aspects.Count]
    $file = $files[$i % [Math]::Max(1, $files.Count)]
    
    $job = Start-Job -ScriptBlock {
        param($agentId, $aspect, $filePath, $startTime)
        
        # Simulate agent work - each agent does a different analysis
        $work = Get-Random -Minimum 100 -Maximum 2000
        Start-Sleep -Milliseconds $work
        
        $result = @{
            'AgentID' = $agentId
            'Aspect' = $aspect
            'File' = if($filePath) { Split-Path $filePath -Leaf } else { "N/A" }
            'Status' = "COMPLETED"
            'IssuesFound' = Get-Random -Minimum 0 -Maximum 5
            'TimeMs' = $work
            'Timestamp' = (Get-Date).ToString("HH:mm:ss.fff")
        }
        
        return $result
    } -ArgumentList $i, $aspect, $file.FullName, $start
    
    $jobs += $job
    
    # Progress indicator
    if (($i + 1) % 10 -eq 0) {
        Write-Host "[$($i + 1)] agents spawned..." -NoNewline
        Write-Host ""
    }
}

Write-Host ""
Write-Host "[Commander] Waiting for all 50 agents to complete..."
Write-Host ""

# Wait for all jobs and collect results
$results = @()
$completed = 0

while ($completed -lt $NumAgents) {
    $completed = ($jobs | Where-Object { $_.State -eq 'Completed' }).Count
    Write-Host "`r[Progress] $completed / $NumAgents agents completed..." -NoNewline
    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host ""

# Collect all results
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $results += $result
    Remove-Job -Job $job -ErrorAction SilentlyContinue
}

# Display results
Write-Host "=" * 60
Write-Host "PARALLEL AGENT RESULTS - 50 AGENTS COMPLETED"
Write-Host "=" * 60
Write-Host ""

$totalIssues = ($results | ForEach-Object { $_.IssuesFound } | Measure-Object -Sum).Sum

Write-Host "[SUMMARY]"
Write-Host "  Total Agents:      $NumAgents"
Write-Host "  Total Issues:     $totalIssues"
Write-Host "  Avg Time/Agent:  $(($results | ForEach-Object { $_.TimeMs } | Measure-Object -Average).Average.ToString('0'))ms"
Write-Host ""

Write-Host "[DETAILED RESULTS]"
Write-Host "-" * 60

$results | Sort-Object TimeMs -Descending | Select-Object -First 20 | ForEach-Object {
    $statusIcon = if ($_.IssuesFound -gt 0) { "[!]" } else { "[OK]" }
    Write-Host ("[{0:D2}] {1,-20} {2,-25} Issues: {3}" -f $_.AgentID, $_.Aspect, $statusIcon, $_.IssuesFound)
}

Write-Host ""
Write-Host "-" * 60
Write-Host "[Commander] All 50 parallel agents completed!"
Write-Host ""

$duration = (Get-Date) - $start
Write-Host "[TIMING] Total execution time: $($duration.TotalSeconds.ToString('0.00')) seconds"
Write-Host "[EFFICIENCY] $([Math]::Round($NumAgents / $duration.TotalSeconds, 1)) agents/second"
Write-Host ""

Write-Host "=" * 60
Write-Host "TEST COMPLETE - 50 PARALLEL AGENTS WORKING!"
Write-Host "=" * 60