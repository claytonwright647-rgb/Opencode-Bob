# BOB'S WORKFLOW AUTOMATION
# Define and run multi-step workflows
# Inspired by LangGraph and Prefect patterns

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "define",  # define, run, status, list
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Steps = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Data = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$WORKFLOW_DIR = "C:\Users\clayt\opencode-bob\memory\workflows"
$WORKFLOW_INDEX = "$WORKFLOW_DIR\index.json"

if (-not (Test-Path $WORKFLOW_DIR)) {
    New-Item -ItemType Directory -Force -Path $WORKFLOW_DIR | Out-Null
}

# ============================================================================
# WORKFLOW TEMPLATES
# ============================================================================

$WORKFLOW_TEMPLATES = @{
    "analyze-code" = @{
        name = "Analyze Code"
        description = "Full code analysis with security and performance"
        steps = @(
            @{ name = "glob"; description = "Find all code files" }
            @{ name = "read"; description = "Read main files" }
            @{ name = "security-scan"; description = "Run security audit" }
            @{ name = "analyze"; description = "Analyze results" }
        )
    }
    "fix-bug" = @{
        name = "Fix Bug"
        description = "Find and fix a bug with verification"
        steps = @(
            @{ name = "search"; description = "Find bug location" }
            @{ name = "read"; description = "Read affected code" }
            @{ name = "fix"; description = "Apply fix" }
            @{ name = "test"; description = "Verify fix works" }
        )
    }
    "build-feature" = @{
        name = "Build Feature"
        description = "Build a new feature end-to-end"
        steps = @(
            @{ name = "plan"; description = "Create implementation plan" }
            @{ name = "implement"; description = "Write code" }
            @{ name = "test"; description = "Write tests" }
            @{ name = "verify"; description = "Verify implementation" }
            @{ name = "document"; description = "Update documentation" }
        )
    }
    "review-code" = @{
        name = "Code Review"
        description = "Full code review workflow"
        steps = @(
            @{ name = "read-files"; description = "Read code to review" }
            @{ name = "security-check"; description = "Check for vulnerabilities" }
            @{ name = "style-check"; description = "Check code style" }
            @{ name = "generate-report"; description = "Generate review report" }
        )
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-WorkflowIndex {
    if (Test-Path $WORKFLOW_INDEX) {
        return Get-Content $WORKFLOW_INDEX -Raw | ConvertFrom-Json
    }
    return @{ workflows = @(); running = @() }
}

function Save-WorkflowIndex {
    param([object]$Index)
    $Index | ConvertTo-Json -Depth 10 | Set-Content $WORKFLOW_INDEX
}

# ============================================================================
# DEFINE WORKFLOW
# ============================================================================

function Define-Workflow {
    param([string]$Name, [string]$StepsJson)
    
    $index = Get-WorkflowIndex
    
    # Parse steps
    $steps = @()
    try {
        if ($StepsJson -ne "") {
            $steps = $StepsJson | ConvertFrom-Json
        }
    } catch {
        # Simple comma-separated steps
        $stepNames = $StepsJson -split ","
        foreach ($s in $stepNames) {
            $s = $s.Trim()
            if ($s -ne "") {
                $steps += @{
                    name = $s.ToLower().Replace(" ", "-")
                    description = $s
                }
            }
        }
    }
    
    # Save workflow
    $workflow = @{
        name = $Name
        steps = $steps
        defined = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $workflowFile = "$WORKFLOW_DIR\$Name.json"
    $workflow | ConvertTo-Json -Depth 10 | Set-Content $workflowFile
    
    # Add to index
    $index.workflows += @{
        name = $Name
        file = $workflowFile
        stepCount = $steps.Count
    }
    Save-WorkflowIndex -Index $index
    
    return @{
        success = $true
        name = $Name
        steps = $steps.Count
    }
}

# ============================================================================
# RUN WORKFLOW
# ============================================================================

function Run-Workflow {
    param([string]$Name)
    
    $index = Get-WorkflowIndex
    
    # Find workflow
    $workflowFile = "$WORKFLOW_DIR\$Name.json"
    if (-not (Test-Path $workflowFile)) {
        return @{ success = $false; reason = "not_found" }
    }
    
    $workflow = Get-Content $workflowFile -Raw | ConvertFrom-Json
    
    # Track execution
    $execution = @{
        workflow = $Name
        status = "running"
        started = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        currentStep = 0
        totalSteps = $workflow.steps.Count
        results = @()
    }
    
    # Simulate running through steps
    # In production: would execute actual step logic
    
    $execution.completed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $execution.status = "simulated"
    
    # Add to running
    $runningItem = @{
        id = (Get-Random -Maximum 10000)
        workflow = $Name
        status = "completed"
        started = $execution.started
        completed = $execution.completed
    }
    
    if (-not $index.running) { $index.running = @() }
    $index.running += $runningItem
    Save-WorkflowIndex -Index $index
    
    return @{
        success = $true
        name = $Name
        steps = $workflow.steps.Count
        execution = $execution
    }
}

# ============================================================================
# LIST WORKFLOWS
# ============================================================================

function Get-WorkflowList {
    $index = Get-WorkflowIndex
    
    $workflows = @()
    foreach ($w in $index.workflows) {
        $workflows += @{
            name = $w.name
            steps = $w.stepCount
        }
    }
    
    # Add templates
    $templates = @()
    foreach ($t in $WORKFLOW_TEMPLATES.Keys) {
        $templates += @{
            name = $t
            description = $WORKFLOW_TEMPLATES[$t].description
            steps = $WORKFLOW_TEMPLATES[$t].steps.Count
            isTemplate = $true
        }
    }
    
    return @{
        workflows = $workflows
        templates = $templates
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "define" {
        if ($WorkflowName -eq "" -or $Steps -eq "") {
            Write-Error "WorkflowName and Steps required"
        }
        Define-Workflow -Name $WorkflowName -StepsJson $Steps
    }
    "run" {
        if ($WorkflowName -eq "") {
            Write-Error "WorkflowName required"
        }
        Run-Workflow -Name $WorkflowName
    }
    "list" {
        Get-WorkflowList
    }
    "templates" {
        $WORKFLOW_TEMPLATES
    }
    "status" {
        $index = Get-WorkflowIndex
        @{
            totalWorkflows = $index.workflows.Count
            runningCount = $index.running.Count
        }
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}