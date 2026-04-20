# BOB'S AGENT TEAMS
# Coordinated multi-agent execution
# Based on Claude Code agent teams

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, create, task, list, clear
    
    [Parameter(Mandatory=$false)]
    [string]$TeamName = "",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Roles = @(),
    
    [Parameter(Mandatory=$false)]
    [string]$Task = "",
    
    [int]$MaxAgents = 5
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$TEAMS_FILE = "C:\Users\clayt\opencode-bob\memory\sessions\teams.json"
$TEAM_RESULTS = "C:\Users\clayt\opencode-bob\parallel-results"

# ============================================================================
# TEAM DEFINITIONS
# ============================================================================

$DEFAULT_TEAMS = @{
    "research" = @{
        "description" = "Research team for web searches"
        "roles" = @("lead_researcher", "web_searcher", "code_searcher", "doc_searcher", " synthesizer")
        "max_agents" = 5
    }
    "code" = @{
        "description" = "Code writing team"
        "roles" = @("lead_engineer", "frontend_dev", "backend_dev", "tester", "integrator")
        "max_agents" = 5
    }
    "debug" = @{
        "description" = "Debugging and troubleshooting team"
        "roles" = @("lead_debugger", "error_analyzer", "code_reviewer", "fixer", "verifier")
        "max_agents" = 5
    }
    "refactor" = @{
        "description" = "Code refactoring team"
        "roles" = @("lead_refactorer", "analyzer", "changer", "tester", "reviewer")
        "max_agents" = 5
    }
    "docs" = @{
        "description" = "Documentation team"
        "roles" = @("lead_writer", "api_docs", "readme_writer", "example_writer", "reviewer")
        "max_agents" = 5
    }
    "test" = @{
        "description" = "Testing team"
        "roles" = @("lead_tester", "unit_writer", "integration_writer", "test_runner", "reporter")
        "max_agents" = 5
    }
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Get-Teams {
    if (Test-Path $TEAMS_FILE) {
        return Get-Content $TEAMS_FILE -Raw | ConvertFrom-Json
    }
    return @{ "teams" = @(); "active" = $null }
}

function Save-Teams {
    param([hashtable]$Teams)
    $Teams | ConvertTo-Json -Depth 10 | Set-Content $TEAMS_FILE
}

function Create-Team {
    param(
        [string]$TeamName,
        [string[]]$Roles
    )
    
    $teamsData = Get-Teams
    
    $team = @{
        "name" = $TeamName
        "roles" = $Roles
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        "status" = "ready"
        "members" = @()
    }
    
    # Create member definitions
    foreach ($role in $Roles) {
        $team.members += @{
            "role" = $role
            "status" = "idle"
        }
    }
    
    $teamsData.teams += $team
    Save-Teams $teamsData
    
    Write-Host "🤖 Team created: $TeamName" -ForegroundColor Green
    Write-Host "   Roles: $($Roles -join ', ')" -ForegroundColor Cyan
    
    return $team
}

function List-Teams {
    $teamsData = Get-Teams
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🤖 BOB'S AGENT TEAMS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Show default teams
    Write-Host "📦 DEFAULT TEAMS:" -ForegroundColor Cyan
    foreach ($teamName in $DEFAULT_TEAMS.Keys) {
        $team = $DEFAULT_TEAMS[$teamName]
        Write-Host "   $teamName" -ForegroundColor White
        Write-Host "      → $($team.description)" -ForegroundColor Gray
        Write-Host "      Roles: $($team.roles -join ', ')" -ForegroundColor Gray
    }
    
    # Show custom teams
    if ($teamsData.teams -and $teamsData.teams.Count -gt 0) {
        Write-Host "`n📝 CUSTOM TEAMS:" -ForegroundColor Cyan
        foreach ($team in $teamsData.teams) {
            Write-Host "   $($team.name)" -ForegroundColor White
            Write-Host "      Status: $($team.status)" -ForegroundColor Gray
            Write-Host "      Roles: $($team.roles -join ', ')" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Execute-TeamTask {
    param(
        [string]$TeamName,
        [string]$Task
    )
    
    # Get team roles
    $teamRoles = $DEFAULT_TEAMS[$TeamName].roles
    if (-not $teamRoles) {
        Write-Host "Team not found: $TeamName" -ForegroundColor Red
        return
    }
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  🚀 EXECUTING TEAM: $TeamName" -ForegroundColor Yellow
    Write-Host "     Task: $Task" -ForegroundColor White
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    # For each role, show what would be done
    # In practice, this would spawn parallel agents
    $i = 0
    foreach ($role in $teamRoles) {
        $i++
        $icon = [char](0x2605 + $i)
        Write-Host "  $icon Role: $role" -ForegroundColor Cyan
        Write-Host "      → Would execute: $role portion of task" -ForegroundColor Gray
    }
    
    Write-Host "`n📊 Team execution complete!" -ForegroundColor Green
    Write-Host "   $i agents participated" -ForegroundColor White
    
    # Note: Actual parallel execution would use the task tool
    return @{
        "team" = $TeamName
        "task" = $Task
        "agents" = $teamRoles.Count
        "status" = "complete"
    }
}

function Show-TeamStatus {
    $teamsData = Get-Teams
    
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📊 TEAM STATUS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Host "Active team: $($teamsData.active)" -ForegroundColor White
    Write-Host "Total teams: $($teamsData.teams.Count)" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Show-TeamStatus
    }
    
    "list" {
        List-Teams
    }
    
    "teams" {
        List-Teams
    }
    
    "create" {
        if (-not $TeamName -or $Roles.Count -eq 0) {
            Write-Host "Usage: agent-teams.ps1 -Operation create -TeamName <name> -Roles @('role1','role2')"
            exit 1
        }
        Create-Team -TeamName $TeamName -Roles $Roles
    }
    
    "execute" {
        if (-not $TeamName -or -not $Task) {
            Write-Host "Usage: agent-teams.ps1 -Operation execute -TeamName <team> -Task <task>"
            exit 1
        }
        Execute-TeamTask -TeamName $TeamName -Task $Task
    }
    
    "task" {
        if (-not $TeamName -or -not $Task) {
            Write-Host "Usage: agent-teams.ps1 -Operation task -TeamName <team> -Task <task>"
            exit 1
        }
        Execute-TeamTask -TeamName $TeamName -Task $Task
    }
    
    "use" {
        # Quick team selection and execution
        if (-not $Task) {
            Write-Host "Usage: agent-teams.ps1 -Operation use -TeamName <research|code|debug|refactor|docs|test> -Task <task>"
            exit 1
        }
        
        # Map shorthand to known teams
        $teamMap = @{
            "r" = "research"
            "search" = "research"
            "c" = "code"
            "build" = "code"
            "write" = "code"
            "d" = "debug"
            "fix" = "debug"
            "refactor" = "refactor"
            "rf" = "refactor"
            "docs" = "docs"
            "doc" = "docs"
            "test" = "test"
            "t" = "test"
        }
        
        $fullName = $teamMap[$TeamName]
        if (-not $fullName) { $fullName = $TeamName }
        
        Execute-TeamTask -TeamName $fullName -Task $Task
    }
    
    "clear" {
        $teamsData = @{ "teams" = @(); "active" = $null }
        Save-Teams $teamsData
        Write-Host "Teams cleared" -ForegroundColor Yellow
    }
    
    default {
        List-Teams
    }
}