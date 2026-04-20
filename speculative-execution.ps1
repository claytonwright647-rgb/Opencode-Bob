# BOB'S SPECULATIVE EXECUTION SYSTEM
# Start read-only tools during model streaming, before response completes
# Inspired by Claude Code's speculative execution

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, spawn, cancel, list
    
    [Parameter(Mandatory=$false)]
    [string]$ToolName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Arguments = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$SPEC_FILE = "C:\Users\clayt\opencode-bob\memory\speculative.json"

# Read-only tools that can run speculatively
$READ_TOOLS = @(
    "Read",
    "glob", 
    "grep",
    "websearch",
    "webfetch",
    "filesystem_list_directory",
    "filesystem_read_file",
    "memory_search_nodes"
)

# Write tools that CANNOT run speculatively
$WRITE_TOOLS = @(
    "Edit",
    "Write",
    "Bash",
    "kbash",
    "github",
    "memory_create_entities"
)

# ============================================================================
# STATE
# ============================================================================

function Get-SpeculativeState {
    if (Test-Path $SPEC_FILE) {
        return Get-Content $SPEC_FILE -Raw | ConvertFrom-Json
    }
    return @{
        running = @()
        completed = @()
        maxConcurrent = 3
    }
}

function Save-SpeculativeState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $SPEC_FILE
}

# ============================================================================
# CAN RUN SPECULATIVELY?
# Returns whether tool is read-only
# ============================================================================

function Test-CanSpeculate {
    param([string]$Tool)
    
    return $READ_TOOLS -contains $Tool
}

# ============================================================================
# SPAWN SPECULATIVE TOOL
# Start a read-only tool during streaming
# ============================================================================

function Start-Speculative {
    param([string]$Tool, [string]$Args)
    
    $state = Get-SpeculativeState
    
    # Check if already at max concurrent
    if ($state.running.Count -ge $state.maxConcurrent) {
        return @{
            success = $false
            reason = "max_concurrent"
            running = $state.running.Count
            max = $state.maxConcurrent
        }
    }
    
    # Validate tool is read-only
    if (-not (Test-CanSpeculate -Tool $Tool)) {
        return @{
            success = $false
            reason = "not_read_only"
            tool = $Tool
            allowed = $READ_TOOLS
        }
    }
    
    # Create speculative task
    $taskId = "spec_" + (Get-Date -Format "yyyyMMddHHmmss") + "_" + (Get-Random -Maximum 1000)
    
    $task = @{
        id = $taskId
        tool = $Tool
        args = $Args
        status = "running"
        started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $state.running += $task
    Save-SpeculativeState -State $state
    
    # Execute asynchronously (fire and forget for now, would use async in production)
    # In production: would spawn real async process
    # For now: just track that we requested it
    
    return @{
        success = $true
        taskId = $taskId
        tool = $Tool
        speculative = $true
        warning = "Fire-and-forget mode - implement async for production"
    }
}

# ============================================================================
# COMPLETE SPECULATIVE TASK
# Mark task as done, store result
# ============================================================================

function Complete-Speculative {
    param([string]$TaskId, [object]$Result)
    
    $state = Get-SpeculativeState
    
    # Find and remove from running
    $newRunning = @()
    $completedTask = $null
    
    foreach ($task in $state.running) {
        if ($task.id -eq $TaskId) {
            $completedTask = $task
            $completedTask.status = "completed"
            $completedTask.completed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $completedTask.result = $Result
        } else {
            $newRunning += $task
        }
    }
    
    $state.running = $newRunning
    
    if ($completedTask) {
        $state.completed += $completedTask
        # Keep last 50 completed
        $state.completed = $state.completed | Select-Object -Last 50
    }
    
    Save-SpeculativeState -State $state
    
    return @{
        success = $true
        taskId = $TaskId
    }
}

# ============================================================================
# CANCEL SPECULATIVE
# Cancel a running speculative task
# ============================================================================

function Cancel-Speculative {
    param([string]$TaskId)
    
    $state = Get-SpeculativeState
    
    $newRunning = @()
    $cancelled = $false
    
    foreach ($task in $state.running) {
        if ($task.id -eq $TaskId) {
            $task.status = "cancelled"
            $task.cancelled = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $state.completed += $task
            $cancelled = $true
        } else {
            $newRunning += $task
        }
    }
    
    $state.running = $newRunning
    Save-SpeculativeState -State $state
    
    return @{
        success = $cancelled
        taskId = $TaskId
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-SpeculativeStatus {
    $state = Get-SpeculativeState
    
    return @{
        running = $state.running
        completed = ($state.completed | Select-Object -Last 10)
        maxConcurrent = $state.maxConcurrent
        readOnlyTools = $READ_TOOLS
        writeTools = $WRITE_TOOLS
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "status" {
        Get-SpeculativeStatus
    }
    "spawn" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Start-Speculative -Tool $ToolName -Args $Arguments
    }
    "complete" {
        if ($ToolName -eq "") {
            Write-Error "TaskId required (Use ToolName for now)"
        }
        Complete-Speculative -TaskId $ToolName -Result $Arguments
    }
    "cancel" {
        if ($ToolName -eq "") {
            Write-Error "TaskId required (Use ToolName for now)"
        }
        Cancel-Speculative -TaskId $ToolName
    }
    "can-speculate" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Test-CanSpeculate -Tool $ToolName
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}