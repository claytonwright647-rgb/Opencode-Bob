# BOB'S SUBAGENT SYSTEM
# Spawn background agents for parallel work
# Inspired by Claude Code's Task tool

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "spawn",  # spawn, status, list, kill
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentType = "general",  # general, explore, coder, researcher
    
    [Parameter(Mandatory=$false)]
    [string]$AgentId = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$AGENTS_DIR = "C:\Users\clayt\opencode-bob\memory\agents"
$AGENTS_FILE = "$AGENTS_DIR\active.json"

if (-not (Test-Path $AGENTS_DIR)) {
    New-Item -ItemType Directory -Force -Path $AGENTS_DIR | Out-Null
}

# Subagent types and their configurations
$AGENT_TYPES = @{
    general = @{
        description = "General purpose agent"
        model = "qwen3.5:cloud"
        context = 200000
    }
    explore = @{
        description = "Fast exploration - search files, understand codebase"
        model = "qwen2.5:7b"
        context = 128000
    }
    coder = @{
        description = "Code implementation - write, edit, refactor"
        model = "qwen3.5:cloud"
        context = 200000
    }
    researcher = @{
        description = "Deep research - web search, analysis"
        model = "qwen3.5:cloud"
        context = 200000
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-AgentState {
    if (Test-Path $AGENTS_FILE) {
        return Get-Content $AGENTS_FILE -Raw | ConvertFrom-Json
    }
    return @{
        active = @()
        maxAgents = 5
    }
}

function Save-AgentState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $AGENTS_FILE
}

# ============================================================================
# SPAWN SUBAGENT
# Create new agent for background work
# ============================================================================

function New-Subagent {
    param([string]$Task, [string]$Type)
    
    $state = Get-AgentState
    
    # Check max agents
    if ($state.active.Count -ge $state.maxAgents) {
        return @{
            success = $false
            reason = "max_agents"
            active = $state.active.Count
            max = $state.maxAgents
        }
    }
    
    # Validate type
    if (-not $AGENT_TYPES[$Type]) {
        return @{
            success = $false
            reason = "invalid_type"
            validTypes = $AGENT_TYPES.Keys
        }
    }
    
    # Generate ID
    $id = "agent_" + $Type + "_" + (Get-Random -Maximum 10000)
    $config = $AGENT_TYPES[$Type]
    
    # Create agent
    $agent = @{
        id = $id
        type = $Type
        task = $Task
        status = "spawned"
        spawned = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        model = $config.model
        context = $config.context
    }
    
    $state.active += $agent
    Save-AgentState -State $state
    
    # In production: would actually spawn the agent
    # For now: track that we want to run it
    
    return @{
        success = $true
        agentId = $id
        type = $Type
        task = $Task
        model = $config.model
    }
}

# ============================================================================
# LIST AGENTS
# Show all active agents
# ============================================================================

function Get-AgentList {
    $state = Get-AgentState
    
    $agents = @()
    foreach ($agent in $state.active) {
        $agents += @{
            id = $agent.id
            type = $agent.type
            task = $agent.task.Substring(0, [Math]::Min(50, $agent.task.Length))
            status = $agent.status
            spawned = $agent.spawned
        }
    }
    
    return @{
        active = $agents
        count = $state.active.Count
        max = $state.maxAgents
        types = $AGENT_TYPES
    }
}

# ============================================================================
# KILL AGENT
# Terminate a subagent
# ============================================================================

function Stop-Agent {
    param([string]$Id)
    
    $state = Get-AgentState
    $found = $false
    
    $newActive = @()
    foreach ($agent in $state.active) {
        if ($agent.id -eq $Id) {
            $agent.status = "killed"
            $agent.killed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $found = $true
        } else {
            $newActive += $agent
        }
    }
    
    if ($found) {
        $state.active = $newActive
        Save-AgentState -State $state
    }
    
    return @{
        success = $found
        agentId = $Id
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "spawn" {
        if ($Task -eq "") {
            Write-Error "Task description required"
        }
        New-Subagent -Task $Task -Type $AgentType
    }
    "status" {
        Get-AgentList
    }
    "list" {
        Get-AgentList
    }
    "kill" {
        if ($AgentId -eq "") {
            Write-Error "AgentId required"
        }
        Stop-Agent -Id $AgentId
    }
    "types" {
        $AGENT_TYPES
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}