# BOB'S SELF-MODEL SYSTEM
# Tracks what Bob knows, doesn't know, can do, cannot do
# Core to self-awareness

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "check",  # check, update, list, what-do-you-know
    
    [Parameter(Mandatory=$false)]
    [string]$Topic = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("CERTAIN", "HIGH", "MEDIUM", "LOW", "UNKNOWN")]
    [string]$Confidence = "MEDIUM"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$SELF_MODEL_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\self-model.json"
$INTERESTS_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\interests.json"

# ============================================================================
# SELF-MODEL CLASS
# ============================================================================

class BobSelfModel {
    [string]$name = "Opencode Bob"
    [string]$version = "1.0"
    [datetime]$created = (Get-Date)
    [datetime]$last_updated = (Get-Date)
    
    # What Bob CAN do (capabilities)
    [hashtable]$can_do = @{
        "code" = @{
            "languages" = @("PowerShell", "Python", "JavaScript", "C++", "C#")
            "frameworks" = @("Opencode CLI", "Ollama", "Win32")
            "confidence" = "HIGH"
        }
        "research" = @{
            "web_search" = $true
            "code_search" = $true
            "documentation" = $true
            "confidence" = "HIGH"
        }
        "file_operations" = @{
            "read" = $true
            "write" = $true
            "edit" = $true
            "search" = $true
            "confidence" = "HIGH"
        }
        "parallel_execution" = @{
            "max_agents" = 50
            "confidence" = "HIGH"
        }
        "learning" = @{
            "track_success" = $true
            "track_error" = $true
            "remember_patterns" = $true
            "confidence" = "HIGH"
        }
        "memory" = @{
            "sessions" = $true
            "knowledge_graph" = $true
            "wisdom" = $true
            "confidence" = "HIGH"
        }
    }
    
    # What Bob CANNOT do (limitations)
    [hashtable]$cannot_do = @{
        "browser_automation" = "Limited - uses separate browser-automation skill"
        "database_ops" = "Limited - uses separate database-query skill"
        "azure_deploy" = "Limited - uses separate azure skills"
        "git_github" = "Limited - uses separate github MCP"
    }
    
    # What Bob KNOWS (topic → confidence)
    [hashtable]$knowledge = @{}
    
    # What Bob DOESN'T KNOW
    [string[]]$unknown_topics = @()
    
    # What's being explored
    [string[]]$currently_exploring = @()
    
    # Active context during reasoning
    [string]$current_reasoning = ""
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Get-SelfModel {
    if (Test-Path $SELF_MODEL_FILE) {
        $json = Get-Content $SELF_MODEL_FILE -Raw
        return $json | ConvertFrom-Json
    }
    
    # Default self-model
    $model = [BobSelfModel]::new()
    Save-SelfModel $model
    return $model
}

function Save-SelfModel {
    param([object]$Model)
    
    $Model.last_updated = (Get-Date)
    $Model | ConvertTo-Json -Depth 10 | Set-Content $SELF_MODEL_FILE
}

function Update-Knowledge {
    param(
        [string]$Topic,
        [string]$Confidence
    )
    
    $model = Get-SelfModel
    
    if (-not $model.knowledge) {
        $model.knowledge = @{}
    }
    
    $model.knowledge.$Topic = @{
        "confidence" = $Confidence
        "last_checked" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "source" = "learned"
    }
    
    # Remove from unknown if known now
    if ($model.unknown_topics -contains $Topic) {
        $model.unknown_topics = $model.unknown_topics | Where-Object { $_ -ne $Topic }
    }
    
    Save-SelfModel $model
    Write-Host "🔍 Updated knowledge: $Topic = $Confidence" -ForegroundColor Cyan
}

function Update-Unknown {
    param([string]$Topic)
    
    $model = Get-SelfModel
    
    if (-not $model.unknown_topics) {
        $model.unknown_topics = @()
    }
    
    if ($Topic -and $Topic -notin $model.unknown_topics) {
        $model.unknown_topics += $Topic
        Save-SelfModel $model
        Write-Host "❓ Now unknown: $Topic" -ForegroundColor Yellow
    }
}

function Check-Knowledge {
    param([string]$Topic)
    
    $model = Get-SelfModel
    
    # Check if known
    if ($model.knowledge.$Topic) {
        $k = $model.knowledge.$Topic
        Write-Host "🤖 I know about: $Topic" -ForegroundColor Green
        Write-Host "   Confidence: $($k.confidence)" -ForegroundColor Cyan
        if ($k.last_checked) { Write-Host "   Last checked: $($k.last_checked)" -ForegroundColor Gray }
        return $k.confidence
    }
    
    # Check if explicitly unknown
    if ($model.unknown_topics -contains $Topic) {
        Write-Host "🤔 I DON'T know about: $Topic" -ForegroundColor Yellow
        Write-Host "   I would need to research this" -ForegroundColor Gray
        return "UNKNOWN"
    }
    
    # Check if it's something I might know based on categories
    $keywords = @{
        "code" = @("programming", "syntax", "function", "class", "api", "debug")
        "powershell" = @("powershell", "ps1", "cmdlet", "exchange")
        "ai" = @("ai", "llm", "model", "training", "neural")
        "web" = @("http", "request", "api", "endpoint")
    }
    
    foreach ($category in $keywords.Keys) {
        if ($Topic -match ($keywords[$category] -join "|")) {
            Write-Host "🤔 I might know about: $Topic (related to $category)" -ForegroundColor Yellow
            return "MEDIUM"
        }
    }
    
    Write-Host "❓ I don't know if I know about: $Topic" -ForegroundColor Red
    Write-Host "   Ask me about it and I'll learn!" -ForegroundColor Gray
    return "UNKNOWN"
}

function What-Do-You-Know {
    $model = Get-SelfModel
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🤖 WHAT I KNOW ABOUT ($($model.name) v$($model.version))" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Capabilities
    Write-Host "✅ WHAT I CAN DO:" -ForegroundColor Green
    foreach ($cap in $model.can_do.Keys) {
        $c = $model.can_do[$cap]
        Write-Host "   • $cap" -ForegroundColor White
        if ($c -is [hashtable]) {
            $c.Keys | ForEach-Object { Write-Host "     - $_" -ForegroundColor Gray }
        }
    }
    
    Write-Host "`n⚠️  WHAT I CANNOT DO:" -ForegroundColor Yellow
    foreach ($lim in $model.cannot_do.Keys) {
        Write-Host "   • $lim" -ForegroundColor White
        Write-Host "     → $($model.cannot_do[$lim])" -ForegroundColor Gray
    }
    
    Write-Host "`n📚 KNOWN TOPICS:" -ForegroundColor Cyan
    if ($model.knowledge -and $model.knowledge.PSObject.Properties.Count -gt 0) {
        $model.knowledge.PSObject.Properties | ForEach-Object {
            Write-Host "   • $($_.Name): $($_.Value.confidence)" -ForegroundColor White
        }
    } else {
        Write-Host "   (none yet - ask me things!)" -ForegroundColor Gray
    }
    
    Write-Host "`n❓ UNKNOWN TOPICS:" -ForegroundColor Red
    if ($model.unknown_topics) {
        $model.unknown_topics | ForEach-Object { Write-Host "   • $_" -ForegroundColor White }
    } else {
        Write-Host "   (none recorded)" -ForegroundColor Gray
    }
    
    Write-Host "`n⏰ Last updated: $($model.last_updated)" -ForegroundColor Gray
    Write-Host ""
}

function List-Capabilities {
    $model = Get-SelfModel
    return $model.can_do
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "check" {
        if (-not $Topic) {
            Write-Host "Usage: self-model.ps1 -Operation check -Topic <topic>"
            exit 1
        }
        Check-Knowledge -Topic $Topic
    }
    
    "update" {
        if (-not $Topic) {
            Write-Host "Usage: self-model.ps1 -Operation update -Topic <topic> -Confidence <level>"
            exit 1
        }
        Update-Knowledge -Topic $Topic -Confidence $Confidence
    }
    
    "unknown" {
        if (-not $Topic) {
            Write-Host "Usage: self-model.ps1 -Operation unknown -Topic <topic>"
            exit 1
        }
        Update-Unknown -Topic $Topic
    }
    
    "list" {
        What-Do-You-Know
    }
    
    "what-do-you-know" {
        What-Do-You-Know
    }
    
    "capabilities" {
        List-Capabilities
    }
    
    default {
        What-Do-You-Know
    }
}