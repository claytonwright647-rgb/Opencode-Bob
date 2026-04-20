# BOB'S MULTI-AGENT ORCHESTRATION
# Coordinate multiple specialized agents
# Inspired by OpenClaw and production multi-agent systems

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "create",  # create, assign, status, list, delegate
    
    [Parameter(Mandatory=$false)]
    [string]$TeamName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentType = "general",  # coder, researcher, reviewer, planner
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentId = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$TEAM_DIR = "C:\Users\clayt\opencode-bob\memory\teams"
$TEAMS_FILE = "$TEAM_DIR\teams.json"
$SHARED_MEM = "$TEAM_DIR\shared-memory.json"

if (-not (Test-Path $TEAM_DIR)) {
    New-Item -ItemType Directory -Force -Path $TEAM_DIR | Out-Null
}

# ============================================================================
# AGENT TYPES
# ============================================================================

$AGENT_TYPES = @{
    general = @{
        name = "General Assistant"
        description = "Handles any task"
        tools = @("Read", "Write", "Bash", "glob", "grep")
    }
    coder = @{
        name = "Code Specialist"
        description = "Writes and edits code"
        tools = @("Read", "Write", "Edit", "Bash", "glob", "grep")
    }
    researcher = @{
        name = "Research Agent"
        description = "Web search and analysis"
        tools = @("websearch", "webfetch", "Read", "grep")
    }
    reviewer = @{
        name = "Code Reviewer"
        description = "Reviews code for issues"
        tools = @("glob", "grep", "Read", "code-review-skill")
    }
    planner = @{
        name = "Planner Agent"
        description = " Breaks down complex tasks"
        tools = @("Think", "Read")
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-TeamState {
    if (Test-Path $TEAMS_FILE) {
        return Get-Content $TEAMS_FILE -Raw | ConvertFrom-Json
    }
    return @{
        teams = @()
        agents = @()
    }
}

function Save-TeamState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $TEAMS_FILE
}

# ============================================================================
# CREATE TEAM
# ============================================================================

function New-Team {
    param([string]$Name, [string]$Type)
    
    $state = Get-TeamState
    
    # Check exists
    foreach ($team in $state.teams) {
        if ($team.name -eq $Name) {
            return @{ success = $false; reason = "exists" }
        }
    }
    
    $team = @{
        name = $Name
        type = $Type
        agents = @()
        status = "active"
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $state.teams += $team
    Save-TeamState -State $state
    
    return @{
        success = $true
        team = $Name
        type = $Type
    }
}

# ============================================================================
# ASSIGN AGENT TO TEAM
# ============================================================================

function Assign-Agent {
    param([string]$Team, [string]$Type, [string]$Task)
    
    $state = Get-TeamState
    
    # Find team
    $teamObj = $null
    foreach ($t in $state.teams) {
        if ($t.name -eq $Team) {
            $teamObj = $t
            break
        }
    }
    
    if (-not $teamObj) {
        return @{ success = $false; reason = "team_not_found" }
    }
    
    # Create agent
    $agent = @{
        id = "agent_" + (Get-Random -Maximum 10000)
        type = $Type
        task = $Task
        status = "assigned"
        assigned = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Add to team
    $teamObj.agents += $agent.id
    $state.agents += $agent
    
    Save-TeamState -State $state
    
    return @{
        success = $true
        agentId = $agent.id
        team = $Team
        type = $Type
    }
}

# ============================================================================
# DELEGATE TASK
# ============================================================================

function Delegate-Task {
    param([string]$Task, [string]$Type)
    
    # Find best agent for task type
    $bestType = $Type
    
    # Auto-detect type if not specified
    $taskLower = $Task.ToLower()
    if ($taskLower -match "code|write|edit|refactor") { $bestType = "coder" }
    elseif ($taskLower -match "search|research|find") { $bestType = "researcher" }
    elseif ($taskLower -match "review|audit|security") { $bestType = "reviewer" }
    elseif ($taskLower -match "plan|break down|strategy") { $bestType = "planner" }
    
    # Create task
    $taskObj = @{
        id = "task_" + (Get-Random -Maximum 10000)
        description = $Task
        type = $bestType
        status = "pending"
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Save to shared memory
    $shared = @()
    if (Test-Path $SHARED_MEM) {
        $shared = Get-Content $SHARED_MEM -Raw | ConvertFrom-Json
        if (-not ($shared -is [array])) { $shared = @($shared) }
    }
    
    $shared += $taskObj
    $shared | ConvertTo-Json -Depth 10 | Set-Content $SHARED_MEM
    
    return @{
        success = $true
        taskId = $taskObj.id
        type = $bestType
        task = $Task
    }
}

# ============================================================================
# LIST TEAMS AND AGENTS
# ============================================================================

function Get-TeamList {
    $state = Get-TeamState
    
    $teams = @()
    foreach ($team in $state.teams) {
        $teams += @{
            name = $team.name
            type = $team.type
            agentCount = $team.agents.Count
            status = $team.status
        }
    }
    
    $agents = @()
    foreach ($agent in $state.agents) {
        $agents += @{
            id = $agent.id
            type = $agent.type
            task = $agent.task
            status = $agent.status
        }
    }
    
    return @{
        teams = $teams
        agents = $agents
        agentTypes = $AGENT_TYPES.Keys
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "create" {
        if ($TeamName -eq "") {
            Write-Error "TeamName required"
        }
        New-Team -Name $TeamName -Type $AgentType
    }
    "assign" {
        if ($TeamName -eq "" -or $Task -eq "") {
            Write-Error "TeamName and Task required"
        }
        Assign-Agent -Team $TeamName -Type $AgentType -Task $Task
    }
    "delegate" {
        if ($Task -eq "") {
            Write-Error "Task required"
        }
        Delegate-Task -Task $Task -Type $AgentType
    }
    "list" {
        Get-TeamList
    }
    "status" {
        $state = Get-TeamState
        @{
            totalTeams = $state.teams.Count
            totalAgents = $state.agents.Count
            types = $AGENT_TYPES.Keys
        }
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}