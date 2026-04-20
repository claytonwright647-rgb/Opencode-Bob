# BOB'S SMART ERROR RECOVERY
# NEVER repeat the same mistake twice
# TRY → FAIL → LEARN → DIFFERENT APPROACH → SUCCESS

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "track",  # track, failed, success, avoid, check
    
    [Parameter(Mandatory=$false)]
    [string]$Problem = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Context = "",
    
    [Parameter(Mandatory=$false)]
    [string]$FixAttempted = "",
    
    [Parameter(Mandatory=$false)]
    [string]$NewApproach = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$ERROR_HISTORY = "C:\Users\clayt\opencode-bob\memory\learning\error-history.json"
$AVOID_PATTERNS = "C:\Users\clayt\opencode-bob\memory\learning\avoid-patterns.json"
$RECOVERY_LOG = "C:\Users\clayt\opencode-bob\memory\learning\recovery-log.json"

# ============================================================================
# SMART ERROR RECOVERY LOGIC
# ============================================================================

function Get-ErrorHistory {
    if (Test-Path $ERROR_HISTORY) {
        $content = Get-Content $ERROR_HISTORY -Raw
        if ($content.Trim()) {
            return $content | ConvertFrom-Json
        }
    }
    return @()
}

function Save-ErrorHistory {
    param([object]$History)
    $History | ConvertTo-Json -Depth 10 | Set-Content $ERROR_HISTORY
}

function Get-AvoidPatterns {
    if (Test-Path $AVOID_PATTERNS) {
        $content = Get-Content $AVOID_PATTERNS -Raw
        if ($content.Trim()) {
            return $content | ConvertFrom-Json
        }
    }
    return @()
}

function Save-AvoidPatterns {
    param([object]$Patterns)
    $Patterns | ConvertTo-Json -Depth 10 | Set-Content $AVOID_PATTERNS
}

# ============================================================================
# TRACK ERROR
# ============================================================================

function Track-Error {
    param(
        [string]$Error,
        [string]$Context,
        [string]$FixAttempted
    )
    
    # First - snapshot in case things get worse!
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "error-$((Get-Date).ToString('yyyy-MM-dd-HHmm'))" | Out-Null
    
    $history = Get-ErrorHistory
    if ($history -isnot [System.Array]) { $history = @($history) }
    
    # Generate error signature (for pattern matching)
    $errorSig = Generate-ErrorSignature $Error
    
    # Check if we've seen this before
    $seenBefore = $false
    $previousAttempts = @()
    
    foreach ($entry in $history) {
        if ($entry.error_signature -eq $errorSig) {
            $seenBefore = $true
            $previousAttempts += $entry
        }
    }
    
    # Record this error
    $errorRecord = @{
        "timestamp" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "error" = $Error
        "context" = $Context
        "fix_attempted" = $FixAttempted
        "error_signature" = $errorSig
        "attempt_count" = if ($seenBefore) { $previousAttempts.Count + 1 } else { 1 }
        "status" = "failed"
    }
    
    $history = @($errorRecord) + $history
    
    # Keep last 100 errors
    if ($history.Count -gt 100) { $history = $history[0..99] }
    
    Save-ErrorHistory $history
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ❌ ERROR TRACKED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Error: $Error" -ForegroundColor White
    Write-Host "   Attempt: #$($errorRecord.attempt_count)" -ForegroundColor Yellow
    Write-Host "   Context: $Context" -ForegroundColor Gray
    
    if ($seenBefore) {
        Write-Host ""
        Write-Host "   ⚠️  SEEN THIS BEFORE!" -ForegroundColor Red
        Write-Host "   Previous attempts failed. Need DIFFERENT approach!" -ForegroundColor Yellow
        
        # Show what was tried before
        Write-Host ""
        Write-Host "   What was tried:" -ForegroundColor Gray
        foreach ($prev in $previousAttempts) {
            Write-Host "     - $($prev.fix_attempted)" -ForegroundColor Gray
        }
        
        # Add to avoid patterns
        $avoidPatterns = Get-AvoidPatterns
        if ($avoidPatterns -isnot [System.Array]) { $avoidPatterns = @($avoidPatterns) }
        
        $avoidPattern = @{
            "error_signature" = $errorSig
            "avoid" = $FixAttempted
            "learned" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            "reason" = "Failed $($previousAttempts.Count) times - need different approach"
        }
        
        $avoidPatterns = @($avoidPattern) + $avoidPatterns
        Save-AvoidPatterns $avoidPatterns
    }
    
    Write-Host ""
    Write-Host "   💡 Next: Try a DIFFERENT approach!" -ForegroundColor Cyan
    Write-Host ""
    
    return @{
        "seen_before" = $seenBefore
        "attempt_count" = $errorRecord.attempt_count
        "avoid_these" = if ($seenBefore) { $previousAttempts.fix_attempted } else { @() }
    }
}

function Generate-ErrorSignature {
    param([string]$Error)
    
    # Create a simplified signature from error
    # e.g., "NullReferenceException" → "NULL_REF"
    # e.g., "File not found" → "FILE_NOT_FOUND"
    
    $sig = $Error.ToUpper()
    $sig = $sig -replace '[0-9]', ''
    $sig = $sig -replace '[^\w]', '_'
    $sig = $sig -replace '_+', '_'
    $sig = $sig.Trim('_')
    
    # Key error patterns
    if ($sig -match "NULL|NIL") { return "NULL_ERROR" }
    if ($sig -match "NOT_FOUND|MISSING") { return "NOT_FOUND" }
    if ($sig -match "ACCESS_DENIED|PERMISSION") { return "PERMISSION" }
    if ($sig -match "TIMEOUT") { return "TIMEOUT" }
    if ($sig -match "SYNTAX|INVALID") { return "SYNTAX_ERROR" }
    if ($sig -match "LINK|LNK") { return "LINK_ERROR" }
    if ($sig -match "COMPILE|BUILD|ERROR") { return "BUILD_ERROR" }
    
    return $sig.Substring(0, [Math]::Min(30, $sig.Length))
}

# ============================================================================
# SUCCESS - LEARN FROM FIX
# ============================================================================

function Record-Success {
    param(
        [string]$Error,
        [string]$FixThatWorked,
        [string]$Approach
    )
    
    $history = Get-ErrorHistory
    if ($history -isnot [System.Array]) { $history = @($history) }
    
    # Mark the error as resolved
    $errorSig = Generate-ErrorSignature $Error
    
    foreach ($entry in $history) {
        if ($entry.error_signature -eq $errorSig -and $entry.status -eq "failed") {
            $entry.status = "resolved"
            $entry.resolved_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            $entry.fix_that_worked = $FixThatWorked
            $entry.approach_used = $Approach
        }
    }
    
    Save-ErrorHistory $history
    
    # Remove from avoid patterns if present
    $avoidPatterns = Get-AvoidPatterns
    $avoidPatterns = $avoidPatterns | Where-Object { $_.error_signature -ne $errorSig }
    Save-AvoidPatterns $avoidPatterns
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✅ SUCCESS - ERROR RESOLVED!" -ForegroundColor Green
    Write-Host "══════════════════════════════════════=" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Error: $Error" -ForegroundColor White
    Write-Host "   Fix: $FixThatWorked" -ForegroundColor Green
    Write-Host "   Approach: $Approach" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   📝 Added to pattern memory - won't make this mistake again!" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# CHECK AVOID PATTERNS
# ============================================================================

function Check-AvoidPatterns {
    param([string]$Context)
    
    $patterns = Get-AvoidPatterns
    if ($patterns.Count -eq 0) { return @() }
    
    $relevant = @()
    
    foreach ($pattern in $patterns) {
        if ($Context -match $pattern.error_signature) {
            $relevant += $pattern
        }
    }
    
    if ($relevant.Count -gt 0) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ⚠️  PATTERNS TO AVOID" -ForegroundColor Yellow
        Write-Host "══════════════════════════════════════=" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Context: $Context" -ForegroundColor Gray
        Write-Host "   These approaches FAILED before:" -ForegroundColor White
        
        foreach ($p in $relevant) {
            Write-Host ""
            Write-Host "   ❌ AVOID: $($p.avoid)" -ForegroundColor Red
            Write-Host "      Reason: $($p.reason)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "   💡 Try a DIFFERENT approach!" -ForegroundColor Cyan
        Write-Host ""
    }
    
    return $relevant
}

# ============================================================================
# SHOW ERROR STATS
# ============================================================================

function Show-ErrorStats {
    $history = Get-ErrorHistory
    $resolved = ($history | Where-Object { $_.status -eq "resolved" }).Count
    $failed = ($history | Where-Object { $_.status -eq "failed" }).Count
    $patterns = Get-AvoidPatterns
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📊 ERROR RECOVERY STATS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Total errors tracked: $($history.Count)" -ForegroundColor White
    Write-Host "   Resolved: $resolved" -ForegroundColor Green
    Write-Host "   Still failing: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
    Write-Host "   Patterns to avoid: $($patterns.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    # Show recent resolved
    if ($resolved -gt 0) {
        Write-Host "   Recent fixes:" -ForegroundColor Gray
        $recentResolved = $history | Where-Object { $_.status -eq "resolved" } | Select-Object -First 5
        foreach ($r in $recentResolved) {
            Write-Host "   ✓ $($r.error) → $($r.fix_that_worked)" -ForegroundColor Green
        }
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "track" {
        if (-not $Error) {
            Write-Host "Usage: error-recovery.ps1 -Operation track -Error 'error message' -Context 'what you were doing' -FixAttempted 'what you tried'"
            exit 1
        }
        Track-Error -Error $Error -Context $Context -FixAttempted $FixAttempted
    }
    
    "failed" {
        if (-not $Error) {
            Write-Host "Usage: error-recovery.ps1 -Operation failed -Error 'error' -FixAttempted 'fix'"
            exit 1
        }
        Track-Error -Error $Error -Context $Context -FixAttempted $FixAttempted
    }
    
    "success" {
        if (-not $Error) {
            Write-Host "Usage: error-recovery.ps1 -Operation success -Error 'original error' -FixThatWorked 'what worked' -Approach 'how you solved it'"
            exit 1
        }
        Record-Success -Error $Error -FixThatWorked $FixAttempted -Approach $NewApproach
    }
    
    "check" {
        if (-not $Context) {
            Write-Host "Usage: error-recovery.ps1 -Operation check -Context 'what you're about to do'"
            exit 1
        }
        Check-AvoidPatterns -Context $Context
    }
    
    "avoid" {
        $patterns = Get-AvoidPatterns
        Write-Host ""
        Write-Host "═══════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ⚠️  PATTERNS TO AVOID" -ForegroundColor Yellow
        Write-Host "══════════════════════════════════════=" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($p in $patterns) {
            Write-Host "   ❌ $($p.avoid)" -ForegroundColor Red
            Write-Host "      Because: $($p.reason)" -ForegroundColor Gray
            Write-Host ""
        }
        
        if ($patterns.Count -eq 0) {
            Write-Host "   No avoid patterns yet!" -ForegroundColor Green
            Write-Host "   (You haven't made repeat mistakes yet!)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    "stats" {
        Show-ErrorStats
    }
    
    default {
        Write-Host "Usage: error-recovery.ps1 -Operation <track|success|check|avoid|stats>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\error-recovery.ps1 -Operation track -Error 'NullRef' -Context 'coding' -FixAttempted 'added null check'"
        Write-Host "  .\error-recovery.ps1 -Operation success -Error 'NullRef' -FixThatWorked 'added null check' -NewApproach 'checked docs first'"
        Write-Host "  .\error-recovery.ps1 -Operation check -Context 'working on auth'"
        Write-Host "  .\error-recovery.ps1 -Operation avoid"
    }
}