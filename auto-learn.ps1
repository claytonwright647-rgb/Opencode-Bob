# Opencode Bob - Automatic Learning Integration (FIXED)
# Learns from EVERY operation automatically
# Called after each major operation

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "learn",
    
    [Parameter(Mandatory=$false)]
    [string]$Context = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Result = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Type = "auto"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$LEARNING_DIR = "C:\Users\clayt\opencode-bob\memory\learning"
$SUCCESS_FILE = Join-Path $LEARNING_DIR "successes.json"
$ERRORS_FILE = Join-Path $LEARNING_DIR "errors.json"
$PREFERENCES_FILE = Join-Path $LEARNING_DIR "preferences.json"
$PATTERNS_FILE = Join-Path $LEARNING_DIR "patterns.json"
$INTERACTIONS_FILE = Join-Path $LEARNING_DIR "interactions.json"

New-Item -ItemType Directory -Force -Path $LEARNING_DIR | Out-Null

# ============================================================================
# STORAGE FUNCTIONS
# ============================================================================

function Load-Data {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw | ConvertFrom-Json
            # Convert PSCustomObject to hashtable
            if ($content -is [System.Management.Automation.PSCustomObject]) {
                $hash = @{}
                $content.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
                return $hash
            }
            return @{}
        } catch { return @{} }
    }
    return @{}
}

function Load-Array {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw | ConvertFrom-Json
            # Convert to array if PSCustomObject
            if ($content -is [System.Management.Automation.PSCustomObject]) {
                return @($content)
            }
            return @($content)
        } catch { return @() }
    }
    return @()
}

function Save-Data {
    param([string]$Path, [hashtable]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Path
}

function Save-Array {
    param([string]$Path, [array]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Path
}

function Get-Id {
    param([string]$Text)
    return ($Text.ToLower() -replace '[^a-z0-9]', '-').Substring(0, [Math]::Min(40, $Text.Length))
}

# ============================================================================
# CORE LEARNING FUNCTIONS
# ============================================================================

function Learn-From-Interaction {
    param([string]$Context, [string]$Result, [string]$Details)
    
    $interactions = Load-Data -Path $INTERACTIONS_FILE
    
    if ($interactions.Count -eq 0) { $interactions = @{} }
    
    $entry = @{
        context = $Context
        result = $Result
        details = $Details
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = "auto"
    }
    
    $id = Get-Id -Text "$Context-$(Get-Date -Format 'HHmmss')"
    $interactions[$id] = $entry
    
    # Keep only last 100
    if ($interactions.Count -gt 100) {
        $keys = @($interactions.Keys) | Sort-Object
        $keys[0..($interactions.Count - 101)] | ForEach-Object { $interactions.Remove($_) }
    }
    
    Save-Data -Path $INTERACTIONS_FILE -Data $interactions
    Learn-Pattern -Trigger $Context -Action $Result -Success ($Result -eq "success")
    
    if ($Result -eq "success") {
        Learn-Success -Context $Context -Details $Details
    } else {
        Learn-Error -Context $Context -Details $Details
    }
    
    Write-Host "✓ Learned from interaction: $Context -> $Result" -ForegroundColor Green
}

function Learn-Success {
    param([string]$Context, [string]$Details)
    
    $successes = Load-Data -Path $SUCCESS_FILE
    if ($successes.Count -eq 0) { $successes = @{} }
    
    $id = Get-Id -Text "$Context-$Details"
    
    if ($successes[$id]) {
        $successes[$id].count++
        $successes[$id].lastSeen = Get-Date
        $successes[$id].successRate = [Math]::Min(1.0, $successes[$id].successRate + 0.1)
    } else {
        $successes[$id] = @{
            id = $id
            context = $Context
            details = $Details
            count = 1
            successCount = 1
            successRate = 1.0
            firstSeen = Get-Date
            lastSeen = Get-Date
        }
    }
    
    Save-Data -Path $SUCCESS_FILE -Data $successes
}

function Learn-Error {
    param([string]$Context, [string]$Details)
    
    $errors = Load-Data -Path $ERRORS_FILE
    if ($errors.Count -eq 0) { $errors = @{} }
    
    $id = Get-Id -Text "$Context-$Details"
    
    if ($errors[$id]) {
        $errors[$id].count++
        $errors[$id].lastSeen = Get-Date
    } else {
        $errors[$id] = @{
            id = $id
            context = $Context
            details = $Details
            count = 1
            firstSeen = Get-Date
            lastSeen = Get-Date
        }
    }
    
    Save-Data -Path $ERRORS_FILE -Data $errors
}

function Learn-Pattern {
    param([string]$Trigger, [string]$Action, [bool]$Success)
    
    $patterns = Load-Data -Path $PATTERNS_FILE
    if ($patterns.Count -eq 0) { $patterns = @{} }
    
    $id = Get-Id -Text "$Trigger-$Action"
    
    if ($patterns[$id]) {
        $patterns[$id].timesUsed++
        $patterns[$id].lastUsed = Get-Date
        if ($Success) { $patterns[$id].successes++ } else { $patterns[$id].failures++ }
        $patterns[$id].strength = $patterns[$id].successes / $patterns[$id].timesUsed
    } else {
        $patterns[$id] = @{
            id = $id
            trigger = $Trigger
            action = $Action
            timesUsed = 1
            successes = if ($Success) { 1 } else { 0 }
            failures = if (-not $Success) { 1 } else { 0 }
            strength = if ($Success) { 1.0 } else { 0.0 }
            firstUsed = Get-Date
            lastUsed = Get-Date
        }
    }
    
    Save-Data -Path $PATTERNS_FILE -Data $patterns
}

function Learn-Preference {
    param([string]$Key, [string]$Value)
    
    $prefs = Load-Data -Path $PREFERENCES_FILE
    if ($prefs.Count -eq 0) { $prefs = @{} }
    
    $id = "$Key=$Value"
    
    if ($prefs[$id]) {
        $prefs[$id].confirmedCount++
        $prefs[$id].lastSeen = Get-Date
        $prefs[$id].strength = [Math]::Min(1.0, $prefs[$id].strength + 0.15)
    } else {
        $prefs[$id] = @{
            id = $id
            key = $Key
            value = $Value
            confirmedCount = 1
            strength = 0.5
            firstSeen = Get-Date
            lastSeen = Get-Date
        }
    }
    
    Save-Data -Path $PREFERENCES_FILE -Data $prefs
}

# ============================================================================
# RECALL FUNCTIONS
# ============================================================================

function Recall-Context {
    param([string]$Context)
    
    $patterns = Load-Data -Path $PATTERNS_FILE
    $successes = Load-Data -Path $SUCCESS_FILE
    $errors = Load-Data -Path $ERRORS_FILE
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "RECALL: $Context" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    $matching = @($patterns.Values) | Where-Object { 
        $_.trigger -match $Context -or $_.action -match $Context 
    } | Sort-Object strength -Descending
    
    if ($matching) {
        Write-Host ""
        Write-Host "Patterns:" -ForegroundColor Yellow
        foreach ($p in $matching | Select-Object -First 5) {
            $status = if ($p.strength -gt 0.7) { "✓" } elseif ($p.strength -gt 0.4) { "~" } else { "✗" }
            Write-Host "  $status [$([math]::Round($p.strength,2))] $($p.trigger) -> $($p.action)" -ForegroundColor $(if ($p.strength -gt 0.7) { "Green" } else { "White" })
        }
    }
    
    $matchingSuccess = @($successes.Values) | Where-Object { $_.context -match $Context -or $_.details -match $Context }
    if ($matchingSuccess) {
        Write-Host ""
        Write-Host "Successes:" -ForegroundColor Green
        foreach ($s in $matchingSuccess | Select-Object -First 3) {
            Write-Host "  ✓ $($s.context): $($s.details)" -ForegroundColor Green
        }
    }
    
    $matchingErrors = @($errors.Values) | Where-Object { $_.context -match $Context -or $_.details -match $Context }
    if ($matchingErrors) {
        Write-Host ""
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($e in $matchingErrors | Select-Object -First 3) {
            Write-Host "  ✗ $($e.context): $($e.details)" -ForegroundColor Red
        }
    }
    
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Get-LearningStats {
    $successes = Load-Data -Path $SUCCESS_FILE
    $errors = Load-Data -Path $ERRORS_FILE
    $prefs = Load-Data -Path $PREFERENCES_FILE
    $patterns = Load-Data -Path $PATTERNS_FILE
    $interactions = Load-Data -Path $INTERACTIONS_FILE
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "LEARNING SYSTEM STATISTICS" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "Total Learned:      $($interactions.Count) interactions" -ForegroundColor White
    Write-Host "Success Patterns:   $($successes.Count) patterns" -ForegroundColor Green
    Write-Host "Error Patterns:     $($errors.Count) patterns" -ForegroundColor Red
    Write-Host "Preferences:         $($prefs.Count) items" -ForegroundColor Yellow
    Write-Host "All Patterns:        $($patterns.Count) total" -ForegroundColor Cyan
    
    $topPatterns = @($patterns.Values) | Sort-Object strength -Descending | Select-Object -First 5
    if ($topPatterns) {
        Write-Host ""
        Write-Host "Top Performing Patterns:" -ForegroundColor Green
        foreach ($p in $topPatterns) {
            Write-Host "  $([math]::Round($p.strength,2)) - $($p.trigger) -> $($p.action)" -ForegroundColor Green
        }
    }
    
    $topPrefs = @($prefs.Values) | Sort-Object strength -Descending | Select-Object -First 5
    if ($topPrefs) {
        Write-Host ""
        Write-Host "Strongest Preferences:" -ForegroundColor Yellow
        foreach ($p in $topPrefs) {
            Write-Host "  $([math]::Round($p.strength,2)) - $($p.key) = $($p.value)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "=" * 60 -ForegroundColor Cyan
}

# ============================================================================
# MAIN DISPATCH
# ============================================================================

switch ($Operation.ToLower()) {
    "learn" {
        if ($Context -and $Result) {
            Learn-From-Interaction -Context $Context -Result $Result -Details $Details
        } else {
            Write-Host "Usage: auto-learn.ps1 -Context 'context' -Result 'success/failure' -Details 'details'"
        }
    }
    
    "recall" {
        if ($Context) { Recall-Context -Context $Context } else { Get-LearningStats }
    }
    
    "stats" { Get-LearningStats }
    
    "preference" {
        if ($Context -and $Details) { Learn-Preference -Key $Context -Value $Details }
    }
    
    default { Get-LearningStats }
}