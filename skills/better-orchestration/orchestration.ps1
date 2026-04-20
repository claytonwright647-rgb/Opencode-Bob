# =============================================================================
# BOB'S ENHANCED ORCHESTRATION
# =============================================================================
# Inspired by oh-my-claudecode's Cthulhu + Elder Gods system
#
# Enhanced Team Structure:
#   CTHULHU (Bob)    - Main orchestrator, routes everything
#   SHOGGOTH         - Parallel search agents
#   YOG-SOTHOTH      - Architecture advisor
#   TSATHOGUA        - Plan reviewer (blocker finder)
#   NYARLATHOTEP     - Autonomous executor
#   DAGON            - Documentation researcher
#
# Workflows:
#   direct       - Trivial tasks, execute directly
#   parallel     - Exploratory, fan out agents
#   plan-first   - Implementation, create plan then review
#   autonomous   - Complex, let Nyarlathotep handle end-to-end
#   review       - Review mode before execution
#
# 100% Local - No external dependencies
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "route",  # route, plan, review, execute, status

    [Parameter(Mandatory=$false)]
    [string]$Task = "",

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",       # direct, parallel, plan-first, autonomous

    [Parameter(Mandatory=$false)]
    [string]$TeamName = "",

    [Parameter(Mandatory=$false)]
    [switch]$RequireReview = $false,

    [Parameter(Mandatory=$false)]
    [switch]$AutoRoute = $false
)

$ErrorActionPreference = "Continue"

# =============================================================================
# ELDER GOD AGENTS (Enhanced Team Roles)
# =============================================================================

$ELDER_GODS = @{
    CTHULHU = @{
        name = "Cthulhu"
        role = "Main Orchestrator"
        description = "Routes every request, delegates to specialists"
        model = "current"
    }

    SHOGGOTH = @{
        name = "Shoggoth"
        role = "Parallel Search"
        description = "Formless search agents, fan out in parallel"
        model = "haiku"
    }

    YOG_SOTHOTH = @{
        name = "Yog-Sothoth"
        role = "Architecture Advisor"
        description = "Read-only consultant for architecture decisions"
        model = "current"
    }

    TSATHOGUA = @{
        name = "Tsathoggua"
        role = "Plan Reviewer"
        description = "Blocker finder - not a perfectionist"
        model = "sonnet"
    }

    NYARLATHOTEP = @{
        name = "Nyarlathotep"
        role = "Autonomous Executor"
        description = "End-to-end goal execution"
        model = "current"
    }

    DAGON = @{
        name = "Dagon"
        role = "Documentation Researcher"
        description = "External docs and source research"
        model = "sonnet"
    }
}

# =============================================================================
# WORKFLOW ROUTING
# =============================================================================

function Get-WorkflowFromTask {
    param([string]$Task)

    if (-not $Task) { return "direct" }

    $lower = $Task.ToLower()

    # Implementation tasks -> plan-first
    $implementationPatterns = @("build", "create", "add", "implement", "make new", "setup", "configure")
    foreach ($pattern in $implementationPatterns) {
        if ($lower -match "^$pattern") {
            return "plan-first"
        }
    }

    # Debug tasks -> autonomous (complex)
    $debugPatterns = @("debug", "fix bug", "fix error", "debugging")
    foreach ($pattern in $debugPatterns) {
        if ($lower -match "^$pattern") {
            return "autonomous"
        }
    }

    # Research/explore -> parallel
    $explorePatterns = @("research", "explore", "find", "search", "how does", "what is", "explain")
    foreach ($pattern in $explorePatterns) {
        if ($lower -match "^$pattern") {
            return "parallel"
        }
    }

    # Refactor -> review first
    if ($lower -match "^refactor") {
        return "review"
    }

    # Default to direct
    return "direct"
}

# =============================================================================
# ORCHESTRATION
# =============================================================================

function Invoke-Orchestration {
    param(
        [string]$Task,
        [string]$Workflow = ""
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   BOB'S ORCHESTRATION" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Auto-route if not specified
    if (-not $Workflow) {
        $Workflow = Get-WorkflowFromTask -Task $Task
    }

    Write-Host "  Task: $Task" -ForegroundColor White
    Write-Host "  Workflow: " -NoNewline
    Write-Host $Workflow -ForegroundColor Green

    # Execute based on workflow
    switch ($Workflow) {
        "direct" {
            Write-Host "`n[DIRECT] Trivial task - executing directly" -ForegroundColor Cyan
        }
        "parallel" {
            Write-Host "`n[PARALLEL] Fanning out Shoggoth search agents..." -ForegroundColor Cyan
            Write-Host "  → Run: agent-teams.ps1 -Operation use -TeamName research -Task '$Task'" -ForegroundColor Cyan
        }
        "plan-first" {
            Write-Host "`n[PLAN-FIRST] Creating plan, then review with Tsathoggua..." -ForegroundColor Cyan
            $steps = Get-TaskSteps -Task $Task
            Write-Host "  Steps:" -ForegroundColor Gray
            $i = 1
            foreach ($s in $steps) {
                Write-Host "    $i. $s" -ForegroundColor White
                $i++
            }
            Write-Host "  → Run: agent-teams.ps1 -Operation use -TeamName code -Task '$Task'" -ForegroundColor Cyan
        }
        "autonomous" {
            Write-Host "`n[AUTONOMOUS] Nyarlathotep handles end-to-end..." -ForegroundColor Cyan
            Write-Host "  → Run: agent-teams.ps1 -Operation use -TeamName debug -Task '$Task'" -ForegroundColor Cyan
        }
        "review" {
            Write-Host "`n[REVIEW] Reviewing with Tsathoggua..." -ForegroundColor Cyan
        }
    }

    Write-Host ""
}

function Get-TaskSteps {
    param([string]$Task)

    $steps = @()

    if ($Task -match "login|auth|authentication") {
        $steps += "Create auth middleware"
        $steps += "Add login/logout endpoints"
        $steps += "Add session handling"
    }

    if ($Task -match "api|endpoint|route") {
        $steps += "Define API schema"
        $steps += "Create route handlers"
        $steps += "Add validation"
    }

    if ($Task -match "database|db|storage") {
        $steps += "Design database schema"
        $steps += "Create migration"
        $steps += "Add repository layer"
    }

    if ($Task -match "test") {
        $steps += "Write unit tests"
        $steps += "Write integration tests"
        $steps += "Run test suite"
    }

    if ($steps.Count -eq 0) {
        $steps += "Analyze requirements"
        $steps += "Create implementation plan"
        $steps += "Write code"
        $steps += "Test the solution"
    }

    return $steps
}

function Invoke-PlanReview {
    param([string]$Task)

    Write-Host "`n[PLAN REVIEW] Tsathoggua analyzing..." -ForegroundColor Cyan

    $blockers = @()

    if ($Task.Length -lt 20) {
        $blockers += "Task is too vague"
    }

    if ($Task -match "and|plus|also") {
        $blockers += "Multiple tasks - consider splitting"
    }

    if ($blockers.Count -eq 0) {
        Write-Host "  ✅ APPROVED - No blockers" -ForegroundColor Green
    } else {
        Write-Host "  ❌ REJECTED:" -ForegroundColor Red
        foreach ($b in $blockers) { Write-Host "    - $b" -ForegroundColor Yellow }
    }

    Write-Host ""
}

# =============================================================================
# MAIN
# =============================================================================

switch ($Operation.ToLower()) {
    "route" {
        if (-not $Task) {
            Write-Host "Error: -Task required" -ForegroundColor Red
            exit 1
        }
        Invoke-Orchestration -Task $Task -Workflow $Workflow
    }

    "plan" {
        if (-not $Task) {
            Write-Host "Error: -Task required" -ForegroundColor Red
            exit 1
        }
        $steps = Get-TaskSteps -Task $Task
        Write-Host "Plan for: $Task" -ForegroundColor Cyan
        $i = 1
        foreach ($s in $steps) {
            Write-Host "  $i. $s" -ForegroundColor White
            $i++
        }
        Invoke-PlanReview -Task $Task
    }

    "review" {
        if (-not $Task) {
            Write-Host "Error: -Task required" -ForegroundColor Red
            exit 1
        }
        Invoke-PlanReview -Task $Task
    }

    "status" {
        Write-Host "`nELDER GOD AGENTS:" -ForegroundColor Yellow
        foreach ($g in $ELDER_GODS.Values) {
            Write-Host "  $($g.name) - $($g.role)" -ForegroundColor Cyan
            Write-Host "    $($g.description)" -ForegroundColor Gray
        }
        Write-Host ""
    }

    "agents" {
        Write-Host "`nAvailable Agents:" -ForegroundColor Yellow
        foreach ($g in $ELDER_GODS.Values) {
            Write-Host "  $($g.name): $($g.role)" -ForegroundColor Green
        }
        Write-Host ""
    }

    default {
        Write-Host "Usage: .\orchestration.ps1 -Operation <route|plan|review|status|agents>"
        Write-Host "Examples:"
        Write-Host "  .\orchestration.ps1 -Operation route -Task 'build login'"
        Write-Host "  .\orchestration.ps1 -Operation status"
    }
}