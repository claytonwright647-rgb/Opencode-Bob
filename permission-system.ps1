# BOB'S PERMISSION SYSTEM
# 7 permission modes inspired by Claude Code
# Controls what tools can run without asking

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, mode, check, set
    
    [Parameter(Mandatory=$false)]
    [string]$ToolName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$NewMode = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$PERM_FILE = "C:\Users\clayt\opencode-bob\memory\permissions.json"

# Permission modes (from Claude Code)
$MODES = @{
    default = @{
        name = "Default"
        description = "Ask before running dangerous tools"
        autoAllow = @("Read", "glob", "grep", "websearch", "memory_search_nodes")
        autoDeny = @()
    }
    auto = @{
        name = "Auto"
        description = "Auto-accept reasonable requests"
        autoAllow = @("Read", "glob", "grep", "websearch", "Write", "Edit", "Bash", "kbash")
        autoDeny = @()
    }
    plan = @{
        name = "Plan"
        description = "Read-only mode - planning and understanding only"
        autoAllow = @("Read", "glob", "grep", "websearch", "webfetch")
        autoDeny = @("Write", "Edit", "Bash", "kbash", "github")
    }
    bypass = @{
        name = "Bypass"
        description = "Allow all tools without confirmation"
        autoAllow = @("*")
        autoDeny = @()
    }
    restricted = @{
        name = "Restricted"
        description = "Most restrictive - confirm everything"
        autoAllow = @()
        autoDeny = @("*")
    }
    wcgw = @{
        name = "WCGW"
        description = "Let me think - Claude thinks before tool use"
        # This is more of a prompt pattern than a permission mode
        autoAllow = @("Read", "glob", "grep")
        autoDeny = @()
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-PermissionState {
    if (Test-Path $PERM_FILE) {
        return Get-Content $PERM_FILE -Raw | ConvertFrom-Json
    }
    return @{
        currentMode = "default"
        history = @()
    }
}

function Save-PermissionState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $PERM_FILE
}

# ============================================================================
# CHECK PERMISSION
# Determines if tool can run without asking
# ============================================================================

function Test-ToolPermission {
    param([string]$Tool)
    
    $state = Get-PermissionState
    $mode = $MODES[$state.currentMode]
    
    # Check auto-deny first
    if ($mode.autoDeny -contains "*" -or $mode.autoDeny -contains $Tool) {
        return @{
            allowed = $false
            reason = "auto_deny"
            mode = $state.currentMode
        }
    }
    
    # Check auto-allow
    if ($mode.autoAllow -contains "*" -or $mode.autoAllow -contains $Tool) {
        return @{
            allowed = $true
            reason = "auto_allow"
            mode = $state.currentMode
        }
    }
    
    # Default: ask
    return @{
        allowed = $false
        reason = "requires_confirmation"
        mode = $state.currentMode
    }
}

# ============================================================================
# SET MODE
# ============================================================================

function Set-PermissionMode {
    param([string]$Mode)
    
    if (-not $MODES[$Mode]) {
        return @{
            success = $false
            reason = "invalid_mode"
            validModes = $MODES.Keys
        }
    }
    
    $state = Get-PermissionState
    $state.currentMode = $Mode
    $state.lastChanged = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-PermissionState -State $state
    
    return @{
        success = $true
        mode = $Mode
        description = $MODES[$Mode].description
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-PermissionStatus {
    $state = Get-PermissionState
    $mode = $MODES[$state.currentMode]
    
    return @{
        currentMode = $state.currentMode
        description = $mode.description
        autoAllow = $mode.autoAllow
        autoDeny = $mode.autoDeny
        allModes = $MODES.Keys
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "status" {
        Get-PermissionStatus
    }
    "mode" {
        Get-PermissionStatus | ConvertTo-Json -Depth 5
    }
    "check" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Test-ToolPermission -Tool $ToolName
    }
    "set" {
        if ($NewMode -eq "") {
            Write-Error "NewMode required"
        }
        Set-PermissionMode -Mode $NewMode
    }
    "modes" {
        $MODES
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}