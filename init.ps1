# BOB'S INITIALIZATION SCRIPT
# Called when Opencode Bob starts up
# Loads context, state, and learned information

param(
    [switch]$Verbose,
    [switch]$Quick
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$BOB_DIR = "C:\Users\clayt\opencode-bob"
$MEMORY_DIR = Join-Path $BOB_DIR "memory"
$SESSION_FILE = Join-Path $MEMORY_DIR "sessions\current-session.json"
$STATE_FILE = Join-Path $MEMORY_DIR "sessions\bob-state.json"

# ============================================================================
# LOAD BOBS STATE
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   🤖 OPENCODE BOB - WAKING UP..." -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Get or create state - use [PSCustomObject] to avoid hashtable metadata issues
$stateObj = $null
if (Test-Path $STATE_FILE) {
    $json = Get-Content $STATE_FILE -Raw
    $stateObj = $json | ConvertFrom-Json
    # Update properties directly
    $stateObj.last_seen = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $stateObj.boot_count = $stateObj.boot_count + 1
} else {
    $stateObj = @{
        name = "Opencode Bob"
        version = "1.0"
        boot_count = 1
        total_tasks_completed = 0
        first_boot = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        last_seen = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
}

# Convert to clean JSON and save
$stateObj | ConvertTo-Json -Depth 3 | Set-Content $STATE_FILE

# ============================================================================
# IDENTITY
# ============================================================================
Write-Host "🤖 Identity: $($stateObj.name) v$($stateObj.version)" -ForegroundColor White
Write-Host "📅 This is boot #$($stateObj.boot_count)" -ForegroundColor Cyan

if (-not $Quick) {
    # ============================================================================
    # LAST SEEN INFO
    # ============================================================================
    if ($stateObj.last_seen) {
        $lastSeen = [DateTime]::Parse($stateObj.last_seen)
        $elapsed = (Get-Date) - $lastSeen
        Write-Host "⏰ Last seen: $([math]::Round($elapsed.TotalMinutes, 1)) minutes ago" -ForegroundColor Gray
    }
    
    # ============================================================================
    # CURRENT WORK (if any)
    # ============================================================================
    if (Test-Path $SESSION_FILE) {
        $session = Get-Content $SESSION_FILE -Raw | ConvertFrom-Json
        
        if ($session.status -eq "working") {
            Write-Host "`n📋 RESUMABLE WORK FOUND:" -ForegroundColor Yellow
            Write-Host "   Task: $($session.task)" -ForegroundColor White
            if ($session.details) {
                Write-Host "   Details: $($session.details)" -ForegroundColor Gray
            }
            if ($session.files) {
                Write-Host "   Files: $($session.files -join ', ')" -ForegroundColor Gray
            }
            Write-Host "   Started: $($session.started_at)" -ForegroundColor Gray
            Write-Host "`n   💡 Say 'resume' to continue this work.`n" -ForegroundColor Cyan
        }
    }
    
    # ============================================================================
    # LEARNING STATS
    # ============================================================================
    $learningStats = Join-Path $MEMORY_DIR "learning\stats.json"
    if (Test-Path $learningStats) {
        $stats = Get-Content $learningStats -Raw | ConvertFrom-Json
        Write-Host "`n🧠 Learning Stats:" -ForegroundColor Yellow
        Write-Host "   Successes: $($stats.total_successes)" -ForegroundColor Green
        Write-Host "   Errors: $($stats.total_errors)" -ForegroundColor $(if ($stats.total_errors -gt 0) { "Red" } else { "Gray" })
        Write-Host "   Preferences: $($stats.total_preferences)" -ForegroundColor Cyan
        if ($stats.total_patterns) {
            Write-Host "   Patterns: $($stats.total_patterns)" -ForegroundColor Magenta
        }
    }
    
    # ============================================================================
    # WISDOM INSIGHTS
    # ============================================================================
    $beliefFile = Join-Path $MEMORY_DIR "wisdom\belief-revisions.json"
    if (Test-Path $beliefFile) {
        $beliefs = Get-Content $beliefFile -Raw | ConvertFrom-Json
        if ($beliefs -is [System.Array] -and $beliefs.Count -gt 0) {
            Write-Host "`n💡 Recent Insights:" -ForegroundColor Yellow
            $recent = $beliefs[0..([Math]::Min(2, $beliefs.Count-1))]
            foreach ($b in $recent) {
                Write-Host "   • $($b.revised_belief)" -ForegroundColor White
            }
        }
    }
    
    # ============================================================================
    # SYSTEM STATUS
    # ============================================================================
    Write-Host "`n⚙️  System Status:" -ForegroundColor Yellow
    
    # Check Ollama
    try {
        $models = (ollama list 2>$null | Select-Object -Skip 1 | Measure-Object).Count
        if ($models -gt 0) {
            Write-Host "   Ollama: ✅ Running ($models models)" -ForegroundColor Green
        } else {
            Write-Host "   Ollama: ⚠️  No models" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Ollama: ❌ Not running" -ForegroundColor Red
    }
    
    # Check Time Machine
    $tmDir = Join-Path $BOB_DIR "time-machine"
    if (Test-Path $tmDir) {
        $snapshots = (Get-ChildItem $tmDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "   Time Machine: ✅ $snapshots snapshots" -ForegroundColor Green
    }
    
    # ============================================================================
    # KEYBOARD READY
    # ============================================================================
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   🎯 READY FOR COMMANDS" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# Return state for programmatic use
return @{
    "state" = $stateObj
    "session" = $null
    "ready" = $true
}
