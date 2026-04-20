# BOB'S WORKING MEMORY / CONTEXT MANAGER
# Tracks what's in attention right now
# Like "at this point, X is happening"

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, focus, remember, forget, history
    
    [Parameter(Mandatory=$false)]
    [string]$Item = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Priority = 5
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$CONTEXT_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json"
$CONTEXT_HISTORY = "C:\Users\clayt\opencode-bob\memory\sessions\context-history.json"

# ============================================================================
# WORKING MEMORY
# ============================================================================

function Get-Context {
    if (Test-Path $CONTEXT_FILE) {
        return Get-Content $CONTEXT_FILE -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-Context {
    param([object]$Context)
    $Context | ConvertTo-Json -Depth 10 | Set-Content $CONTEXT_FILE
}

function Set-Focus {
    param(
        [string]$Item,
        [string]$Details,
        [int]$Priority
    )
    
    $context = Get-Context
    if (-not $context) {
        $context = @{
            "focus" = $null
            "items" = @()
            "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        }
    }
    
    # Add to items (if not already there, move to front)
    $items = @()
    if ($context.items) {
        $items = $context.items
    }
    
    # Remove if exists
    $items = $items | Where-Object { $_.item -ne $Item }
    
    # Add at front
    $newItem = @{
        "item" = $Item
        "details" = $Details
        "priority" = $Priority
        "added_at" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    $items = @($newItem) + $items
    
    # Keep max 10
    if ($items.Count -gt 10) {
        $items = $items[0..9]
    }
    
    $context.focus = $Item
    $context.items = $items
    $context.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    Save-Context $context
    
    Write-Host "🎯 Focused on: $Item" -ForegroundColor Yellow
    if ($Details) { Write-Host "   → $Details" -ForegroundColor Gray }
}

function Remember {
    param(
        [string]$Item,
        [string]$Details
    )
    
    # Shorthand for adding important info to remember
    Set-Focus -Item $Item -Details $Details -Priority 10
}

function Forget {
    param([string]$Item)
    
    $context = Get-Context
    if (-not $context) { return }
    
    $items = @()
    if ($context.items) {
        $items = $context.items | Where-Object { $_.item -ne $Item }
    }
    
    $context.items = $items
    if ($context.focus -eq $Item) {
        $context.focus = if ($items.Count -gt 0) { $items[0].item } else { "" }
    }
    $context.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    Save-Context $context
    
    Write-Host "Forgot: $Item" -ForegroundColor Gray
}

function Show-Status {
    $context = Get-Context
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🎯 BOB'S WORKING MEMORY" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    if (-not $context -or $context.items.Count -eq 0) {
        Write-Host "  (nothing in attention)" -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    # Focus
    if ($context.focus) {
        Write-Host "  🔶 FOCUS: $($context.focus)" -ForegroundColor Yellow
    }
    
    # Items in attention
    Write-Host "`n  📌 IN ATTENTION:" -ForegroundColor Cyan
    $i = 0
    foreach ($item in $context.items) {
        $i++
        $marker = if ($i -eq 1) { "🔶" } else { "•" }
        $color = if ($i -eq 1) { "White" } else { "Gray" }
        
        Write-Host "     $marker $($item.item)" -ForegroundColor $color
        if ($item.details) {
            Write-Host "        → $($item.details)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n  Updated: $($context.updated)" -ForegroundColor Gray
    Write-Host ""
}

function Add-ToHistory {
    param([object]$Context)
    
    $history = @()
    if (Test-Path $CONTEXT_HISTORY) {
        $history = Get-Content $CONTEXT_HISTORY -Raw | ConvertFrom-Json
        if ($history -isnot [System.Array]) { $history = @($history) }
    }
    
    $history = @($Context) + $history
    
    if ($history.Count -gt 50) {
        $history = $history[0..49]
    }
    
    $history | ConvertTo-Json -Depth 10 | Set-Content $CONTEXT_HISTORY
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Show-Status
    }
    
    "focus" {
        if (-not $Item) {
            Write-Host "Usage: context-manager.ps1 -Operation focus -Item <item> -Details <details>"
            exit 1
        }
        Set-Focus -Item $Item -Details $Details -Priority $Priority
    }
    
    "remember" {
        if (-not $Item) {
            Write-Host "Usage: context-manager.ps1 -Operation remember -Item <item> -Details <details>"
            exit 1
        }
        Remember -Item $Item -Details $Details
    }
    
    "forget" {
        if (-not $Item) {
            Write-Host "Usage: context-manager.ps1 -Operation forget -Item <item>"
            exit 1
        }
        Forget -Item $Item
    }
    
    "history" {
        if (Test-Path $CONTEXT_HISTORY) {
            $history = Get-Content $CONTEXT_HISTORY -Raw | ConvertFrom-Json
            if ($history -isnot [System.Array]) { $history = @($history) }
            
            Write-Host "CONTEXT HISTORY (last 10):" -ForegroundColor Yellow
            $i = 0
            foreach ($h in $history) {
                $i++
                if ($i -gt 10) { break }
                Write-Host "  $($h.focus): $($h.updated)" -ForegroundColor White
            }
        }
    }
    
    "clear" {
        $context = @{
            "focus" = ""
            "items" = @()
            "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        }
        Save-Context $context
        Write-Host "Working memory cleared" -ForegroundColor Yellow
    }
    
    default {
        Show-Status
    }
}