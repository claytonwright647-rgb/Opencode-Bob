# BOB'S CONTEXT MANAGER V2
# Smart context management with summarization
# Based on 2026 Claude Code best practices

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, add, summarize, prune, clear
    
    [Parameter(Mandatory=$false)]
    [string]$Item = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Content = "",
    
    [int]$MaxItems = 7
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$CONTEXT_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\smart-context.json"
$SUMMARIES_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\summaries.json"

# ============================================================================
# FUNCTIONS
# ============================================================================

function Get-SmartContext {
    if (Test-Path $CONTEXT_FILE) {
        return Get-Content $CONTEXT_FILE -Raw | ConvertFrom-Json
    }
    
    return @{
        "items" = @()
        "focus" = $null
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
}

function Save-SmartContext {
    param([object]$Context)
    $Context.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $Context | ConvertTo-Json -Depth 10 | Set-Content $CONTEXT_FILE
}

function Add-ToContext {
    param(
        [string]$Item,
        [string]$Content
    )
    
    $context = Get-SmartContext
    
    # Check if already exists
    $exists = $false
    foreach ($i in $context.items) {
        if ($i.item -eq $Item) {
            $i.content = $Content
            $i.updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            $exists = $true
            break
        }
    }
    
    if (-not $exists) {
        $context.items += @{
            "item" = $Item
            "content" = $Content
            "added" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            "access_count" = 0
        }
    }
    
    # Set as focus
    $context.focus = $Item
    
    # Prune if too many items
    if ($context.items.Count -gt $MaxItems) {
        Prune-Context
    }
    
    Save-SmartContext $context
    
    Write-Host "📌 Added to context: $Item" -ForegroundColor Cyan
    if ($Content) { Write-Host "   → $Content" -ForegroundColor Gray }
}

function Prune-Context {
    param([int]$Keep = 5)
    
    $context = Get-SmartContext
    
    if ($context.items.Count -le $Keep) { return }
    
    # Sort by access count and recency
    $sorted = $context.items | Sort-Object -Property access_count, updated -Descending
    
    # Keep top items
    $context.items = $sorted[0..($Keep-1)]
    
    Write-Host "🧹 Pruned context to $Keep items" -ForegroundColor Yellow
}

function Summarize-Context {
    $context = Get-SmartContext
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📋 CONTEXT SUMMARY" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    if ($context.items.Count -eq 0) {
        Write-Host "  (empty)" -ForegroundColor Gray
        return
    }
    
    Write-Host "  Items: $($context.items.Count)/$MaxItems" -ForegroundColor White
    Write-Host "  Focus: $($context.focus)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  Contents:" -ForegroundColor Gray
    foreach ($item in $context.items) {
        $marker = if ($item.item -eq $context.focus) { "🔶" } else { "•" }
        Write-Host "    $marker $($item.item)" -ForegroundColor White
        if ($item.content) {
            Write-Host "        → $($item.content.Substring(0, [Math]::Min(60, $item.content.Length)))..." -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Clear-Context {
    $context = @{
        "items" = @()
        "focus" = $null
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "updated" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    Save-SmartContext $context
    Write-Host "Context cleared" -ForegroundColor Yellow
}

function Show-Status {
    $context = Get-SmartContext
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🎯 SMART CONTEXT MANAGER" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Host "  Memory Slots: $($context.items.Count)/$MaxItems" -ForegroundColor White
    
    if ($context.focus) {
        Write-Host "  Current Focus: $($context.focus)" -ForegroundColor Cyan
    }
    
    Write-Host "`n  Items:" -ForegroundColor Gray
    foreach ($item in $context.items) {
        $accessCount = if ($item.access_count) { "($($item.access_count) accesses)" } else { "" }
        Write-Host "    • $($item.item) $accessCount" -ForegroundColor White
    }
    
    Write-Host "`n  Last Updated: $($context.updated)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Show-Status
    }
    
    "add" {
        if (-not $Item) {
            Write-Host "Usage: context-v2.ps1 -Operation add -Item <name> -Content <content>"
            exit 1
        }
        Add-ToContext -Item $Item -Content $Content
    }
    
    "summarize" {
        Summarize-Context
    }
    
    "summary" {
        Summarize-Context
    }
    
    "prune" {
        Prune-Context -Keep $MaxItems
    }
    
    "clear" {
        Clear-Context
    }
    
    default {
        Show-Status
    }
}