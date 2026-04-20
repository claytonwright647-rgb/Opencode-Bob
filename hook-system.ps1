# BOB'S HOOK SYSTEM
# Event hooks for lifecycle management
# Inspired by Claude Code's hook system

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "list",  # list, register, trigger, status
    
    [Parameter(Mandatory=$false)]
    [string]$Hook = "",  # pre_tool, post_tool, pre_compact, post_compact, session_start, session_end
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Event = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$HOOKS_DIR = "C:\Users\clayt\opencode-bob\memory\hooks"
$HOOKS_FILE = "$HOOKS_DIR\registered.json"

if (-not (Test-Path $HOOKS_DIR)) {
    New-Item -ItemType Directory -Force -Path $HOOKS_DIR | Out-Null
}

# Available hook points (inspired by Claude Code)
$HOOK_POINTS = @{
    pre_tool = @{
        description = "Before tool execution"
        params = @("tool_name", "arguments")
    }
    post_tool = @{
        description = "After tool execution"
        params = @("tool_name", "result", "success")
    }
    pre_compact = @{
        description = "Before context compaction"
        params = @("reason", "tokens")
    }
    post_compact = @{
        description = "After context compaction"
        params = @("summary", "tokens_saved")
    }
    session_start = @{
        description = "When session begins"
        params = @("session_id", "context")
    }
    session_end = @{
        description = "When session ends"
        params = @("session_id", "work_completed")
    }
    pre_model = @{
        description = "Before model call"
        params = @("prompt", "model")
    }
    post_model = @{
        description = "After model call"
        params = @("response", "tokens_used")
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-HookState {
    if (Test-Path $HOOKS_FILE) {
        return Get-Content $HOOKS_FILE -Raw | ConvertFrom-Json
    }
    return @{
        hooks = @{}
    }
}

function Save-HookState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $HOOKS_FILE
}

# ============================================================================
# REGISTER HOOK
# Register an action for a hook point
# ============================================================================

function Register-Hook {
    param([string]$Hook, [string]$Action)
    
    # Validate hook point
    if (-not $HOOK_POINTS[$Hook]) {
        return @{
            success = $false
            reason = "invalid_hook"
            validHooks = $HOOK_POINTS.Keys
        }
    }
    
    $state = Get-HookState
    
    if (-not $state.hooks.$Hook) {
        $state.hooks.$Hook = @()
    }
    
    # Check if already registered
    foreach ($existing in $state.hooks.$Hook) {
        if ($existing -eq $Action) {
            return @{
                success = $false
                reason = "already_registered"
            }
        }
    }
    
    # Add hook
    $state.hooks.$Hook += @{
        action = $Action
        registered = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Save-HookState -State $state
    
    return @{
        success = $true
        hook = $Hook
        action = $Action
    }
}

# ============================================================================
# TRIGGER HOOKS
# Fire all registered hooks for an event
# ============================================================================

function Trigger-Hook {
    param([string]$Hook, [string]$EventData)
    
    $state = Get-HookState
    
    if (-not $state.hooks.$Hook) {
        return @{
            triggered = 0
            results = @()
        }
    }
    
    $results = @()
    foreach ($hook in $state.hooks.$Hook) {
        # In production: would actually execute the hook action
        # For now: just log that it would trigger
        $results += @{
            action = $hook.action
            triggered = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            event = $EventData
            status = "simulated"
        }
    }
    
    return @{
        hook = $Hook
        triggered = $results.Count
        results = $results
    }
}

# ============================================================================
# LIST HOOKS
# Show all registered hooks
# ============================================================================

function Get-HookList {
    $state = Get-HookState
    
    $hooks = @{}
    foreach ($hookName in $HOOK_POINTS.Keys) {
        $hooks[$hookName] = @{
            description = $HOOK_POINTS[$hookName].description
            registered = $state.hooks.$hookName
        }
    }
    
    return @{
        availableHooks = $hooks
        registered = $state.hooks
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "list" {
        Get-HookList
    }
    "register" {
        if ($Hook -eq "" -or $Action -eq "") {
            Write-Error "Hook and Action required"
        }
        Register-Hook -Hook $Hook -Action $Action
    }
    "trigger" {
        if ($Hook -eq "") {
            Write-Error "Hook required"
        }
        Trigger-Hook -Hook $Hook -EventData $Event
    }
    "status" {
        $state = Get-HookState
        $total = 0
        foreach ($h in $state.hooks.Keys) {
            $total += $state.hooks.$h.Count
        }
        @{
            totalHooks = $total
            hookPoints = $HOOK_POINTS.Keys.Count
        }
    }
    "hooks" {
        $HOOK_POINTS
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}