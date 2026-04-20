# Opencode Bob - Continuous Learning Engine
# Learns from every interaction - errors, successes, patterns
# Pattern strength based on success rate over time

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "track",  # track, recall, consolidate, stats
    
    [Parameter(Mandatory=$false)]
    [string]$Type = "success",  # success, error, preference, pattern
    
    [Parameter(Mandatory=$false)]
    [string]$Subject = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Outcome = "",
    
    [switch]$VerboseOutput
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
$STATS_FILE = Join-Path $LEARNING_DIR "stats.json"

# Ensure directory exists
New-Item -ItemType Directory -Force -Path $LEARNING_DIR | Out-Null

# ============================================================================
# LEARNING CLASSES
# ============================================================================

class LearningEntry {
    [string]$Id
    [string]$Type
    [string]$Subject
    [string]$Details
    [datetime]$FirstSeen
    [datetime]$LastSeen
    [int]$Count
    [float]$SuccessRate
    
    LearningEntry([string]$id, [string]$type, [string]$subject, [string]$details) {
        $this.Id = $id
        $this.Type = $type
        $this.Subject = $subject
        $this.Details = $details
        $this.FirstSeen = Get-Date
        $this.LastSeen = Get-Date
        $this.Count = 1
        $this.SuccessRate = 1.0
    }
}

class Preference {
    [string]$Key
    [string]$Value
    [datetime]$FirstSeen
    [datetime]$LastSeen
    [int]$ConfirmedCount
    [float]$Strength
    
    Preference([string]$key, [string]$value) {
        $this.Key = $key
        $this.Value = $value
        $this.FirstSeen = Get-Date
        $this.LastSeen = Get-Date
        $this.ConfirmedCount = 1
        $this.Strength = 0.5
    }
}

class Pattern {
    [string]$Id
    [string]$Trigger
    [string]$Action
    [int]$TimesUsed
    [int]$Successes
    [int]$Failures
    [float]$Strength
    [datetime]$LastUsed
    
    Pattern([string]$id, [string]$trigger, [string]$action) {
        $this.Id = $id
        $this.Trigger = $trigger
        $this.Action = $action
        $this.TimesUsed = 0
        $this.Successes = 0
        $this.Failures = 0
        $this.Strength = 0.5
        $this.LastUsed = Get-Date
    }
}

# ============================================================================
# STORAGE FUNCTIONS
# ============================================================================

function Load-Json {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-Content $Path | ConvertFrom-Json)
    }
    return @{}
}

function Save-Json {
    param([string]$Path, [object]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Path
}

function Get-Id {
    param([string]$Text)
    return ($Text.ToLower() -replace '[^a-z0-9]', '-').Substring(0, [Math]::Min(40, $Text.Length))
}

# ============================================================================
# CORE LEARNING OPERATIONS
# ============================================================================

function Track-Success {
    param([string]$Subject, [string]$Details)
    
    $successes = Load-Json -Path $SUCCESS_FILE
    $id = Get-Id -Text "$Subject-$Details"
    
    if ($successes.ContainsKey($id)) {
        $successes[$id].Count++
        $successes[$id].LastSeen = Get-Date
        $successes[$id].SuccessRate = [Math]::Min(1.0, $successes[$id].SuccessRate + 0.05)
    } else {
        $entry = [LearningEntry]::new($id, "success", $Subject, $Details)
        $successes[$id] = $entry
    }
    
    Save-Json -Path $SUCCESS_FILE -Data $successes
    
    # Also record as a pattern
    Track-Pattern -Trigger $Subject -Action $Details -Success $true
    
    Write-Host "✓ Learned success: $Subject -> $Details"
    
    return $successes[$id]
}

function Track-Error {
    param([string]$Subject, [string]$Details, [string]$Fix = "")
    
    $errors = Load-Json -Path $ERRORS_FILE
    $id = Get-Id -Text "$Subject-$Details"
    
    if ($errors.ContainsKey($id)) {
        $errors[$id].Count++
        $errors[$id].LastSeen = Get-Date
        if ($Fix) {
            $errors[$id].Details = $Fix
        }
    } else {
        $entry = [LearningEntry]::new($id, "error", $Subject, $Details)
        if ($Fix) {
            $entry.Details = "Fix: $Fix"
        }
        $errors[$id] = $entry
    }
    
    Save-Json -Path $ERRORS_FILE -Data $errors
    
    # Record failure pattern
    if ($Fix) {
        Track-Pattern -Trigger $Subject -Action $Fix -Success $false
    }
    
    Write-Host "✗ Learned error: $Subject -> $Fix"
    
    return $errors[$id]
}

function Track-Preference {
    param([string]$Key, [string]$Value)
    
    $prefs = Load-Json -Path $PREFERENCES_FILE
    
    $fullKey = "$Key=$Value"
    
    if ($prefs.ContainsKey($fullKey)) {
        $prefs[$fullKey].ConfirmedCount++
        $prefs[$fullKey].LastSeen = Get-Date
        $prefs[$fullKey].Strength = [Math]::Min(1.0, $prefs[$fullKey].Strength + 0.1)
    } else {
        $pref = [Preference]::new($Key, $Value)
        $prefs[$fullKey] = $pref
    }
    
    Save-Json -Path $PREFERENCES_FILE -Data $prefs
    
    Write-Host "★ Learned preference: $Key = $Value (strength: $($prefs[$fullKey].Strength))"
    
    return $prefs[$fullKey]
}

function Track-Pattern {
    param(
        [string]$Trigger,
        [string]$Action,
        [bool]$Success
    )
    
    $patterns = Load-Json -Path $PATTERNS_FILE
    $id = Get-Id -Text "$Trigger-$Action"
    
    if ($patterns.ContainsKey($id)) {
        $patterns[$id].TimesUsed++
        $patterns[$id].LastUsed = Get-Date
        if ($Success) {
            $patterns[$id].Successes++
        } else {
            $patterns[$id].Failures++
        }
        # Recalculate strength
        $total = $patterns[$id].TimesUsed
        $patterns[$id].Strength = $patterns[$id].Successes / $total
    } else {
        $pat = [Pattern]::new($id, $Trigger, $Action)
        $pat.TimesUsed = 1
        if ($Success) { $pat.Successes = 1 } else { $pat.Failures = 1 }
        $patterns[$id] = $pat
    }
    
    Save-Json -Path $PATTERNS_FILE -Data $patterns
    
    return $patterns[$id]
}

function Recall-Patterns {
    param([string]$Subject)
    
    $patterns = Load-Json -Path $PATTERNS_FILE
    $successes = Load-Json -Path $SUCCESS_FILE
    $errors = Load-Json -Path $ERRORS_FILE
    
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "RECALL: $Subject"
    Write-Host "=" * 60
    
    # Find patterns matching subject
    $matches = $patterns.Values | Where-Object { 
        $_.Trigger -match $Subject -or $_.Action -match $Subject 
    } | Sort-Object Strength -Descending
    
    Write-Host ""
    Write-Host "PATTERNS (by strength):"
    foreach ($p in $matches | Select-Object -First 5) {
        $status = if ($p.Strength -gt 0.7) { "✓ HIGH" } elseif ($p.Strength -gt 0.4) { "~ MED" } else { "✗ LOW" }
        Write-Host "  $status [$($p.Strength)] $($p.Trigger) -> $($p.Action) (used $($p.TimesUsed)x)"
    }
    
    # Find related successes
    $relSuccess = $successes.Values | Where-Object { $_.Subject -match $Subject }
    if ($relSuccess) {
        Write-Host ""
        Write-Host "SUCCESSES:"
        foreach ($s in $relSuccess | Select-Object -First 3) {
            Write-Host "  ✓ $($s.Subject) -> $($s.Details)"
        }
    }
    
    # Find related errors
    $relErrors = $errors.Values | Where-Object { $_.Subject -match $Subject }
    if ($relErrors) {
        Write-Host ""
        Write-Host "ERRORS (with fixes):"
        foreach ($e in $relErrors | Select-Object -First 3) {
            Write-Host "  ✗ $($e.Subject): $($e.Details)"
        }
    }
    
    Write-Host "=" * 60
    
    return @{
        Patterns = $matches
        Successes = $relSuccess
        Errors = $relErrors
    }
}

function Get-LearningStats {
    $successes = Load-Json -Path $SUCCESS_FILE
    $errors = Load-Json -Path $ERRORS_FILE
    $prefs = Load-Json -Path $PREFERENCES_FILE
    $patterns = Load-Json -Path $PATTERNS_FILE
    
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "LEARNING SYSTEM STATISTICS"
    Write-Host "=" * 60
    Write-Host "Successes learned:  $($successes.Count)"
    Write-Host "Errors remembered: $($errors.Count)"
    Write-Host "Preferences stored: $($prefs.Count)"
    Write-Host "Patterns tracked:   $($patterns.Count)"
    
    # Top patterns
    $topPatterns = $patterns.Values | Sort-Object Strength -Descending | Select-Object -First 5
    Write-Host ""
    Write-Host "TOP PATTERNS (by strength):"
    foreach ($p in $topPatterns) {
        Write-Host "  $($p.Strength) - $($p.Trigger) -> $($p.Action)"
    }
    
    # Top preferences
    $topPrefs = $prefs.Values | Sort-Object Strength -Descending | Select-Object -First 5
    Write-Host ""
    Write-Host "TOP PREFERENCES (by strength):"
    foreach ($p in $topPrefs) {
        Write-Host "  $($p.Strength) - $($p.Key) = $($p.Value)"
    }
    
    Write-Host "=" * 60
    
    return @{
        Successes = $successes.Count
        Errors = $errors.Count
        Preferences = $prefs.Count
        Patterns = $patterns.Count
    }
}

function Consolidate-Learning {
    Write-Host "Running learning consolidation..."
    
    $patterns = Load-Json -Path $PATTERNS_FILE
    
    foreach ($id in $patterns.Keys) {
        $p = $patterns[$id]
        $total = $p.TimesUsed
        
        if ($total -gt 5) {
            # Decay unused patterns
            $daysSinceUse = (Get-Date) - $p.LastUsed
            if ($daysSinceUse.Days -gt 30) {
                $p.Strength = $p.Strength * 0.9  # Decay
            }
        }
        
        # Boost frequently used successful patterns
        if ($total -gt 10 -and $p.Strength -gt 0.8) {
            $p.Strength = [Math]::Min(1.0, $p.Strength + 0.05)
        }
    }
    
    Save-Json -Path $PATTERNS_FILE -Data $patterns
    
    Write-Host "Consolidation complete"
    
    return $patterns
}

# ============================================================================
# MAIN DISPATCH
# ============================================================================

switch ($Operation.ToLower()) {
    "track" {
        switch ($Type.ToLower()) {
            "success" {
                Track-Success -Subject $Subject -Details $Details
            }
            "error" {
                Track-Error -Subject $Subject -Details $Details -Fix $Outcome
            }
            "preference" {
                Track-Preference -Key $Subject -Value $Details
            }
            "pattern" {
                $success = $Outcome -eq "success"
                Track-Pattern -Trigger $Subject -Action $Details -Success $success
            }
        }
    }
    
    "recall" {
        Recall-Patterns -Subject $Subject
    }
    
    "consolidate" {
        Consolidate-Learning
    }
    
    "stats" {
        Get-LearningStats
    }
    
    default {
        Get-LearningStats
    }
}