# =============================================================================
# BOB'S INTENT GATE - Request Classifier & Router
# =============================================================================
# Inspired by oh-my-claudecode's Cthulhu intent gate
# Classifies every user request and routes to the appropriate handler
#
# Intent Types:
#   TRIVIAL    - Direct execution (no planning needed)
#   EXPLORATORY - Research/discovery (parallel agents)
#   IMPLEMENTATION - Build tasks (plan first, then execute)
#   AMBIGUOUS  - Needs clarification
#   REFACTOR  - Code restructuring
#   DEBUG    - Bug fixing
#   REVIEW   - Analysis/review tasks
#
# 100% Local - No external dependencies
# =============================================================================

param(
    [string]$Operation = "classify",  

    [string]$Text = ""
)

$ErrorActionPreference = "Continue"

# =============================================================================
# INTENT PATTERNS & KEYWORDS
# =============================================================================

$INTENTS = @{
    TRIVIAL = @{
        description = "Simple requests requiring no planning"
        patterns = @(
            "what time is it", "what is the date", "show me", "list",
            "what does", "how do i", "just", "quick", "simple",
            "check", "get", "show", "tell me"
        )
        complexity = "low"
        route = "direct"
    }

    EXPLORATORY = @{
        description = "Research, discovery, and exploration tasks"
        patterns = @(
            "how does", "how do", "what is", "what are", "find", "search",
            "research", "explore", "discover", "look for", "find all",
            "show me how", "explain", "understand", "what happens"
        )
        complexity = "medium"
        route = "parallel_agents"
    }

    IMPLEMENTATION = @{
        description = "Build, create, add, implement tasks"
        patterns = @(
            "build", "create", "add", "implement", "make", "new",
            "write code", "setup", "configure", "install", "deploy",
            "init", "initialize", "start", "enable", "disable"
        )
        complexity = "high"
        route = "plan_first"
    }

    AMBIGUOUS = @{
        description = "Unclear intent, needs clarification"
        patterns = @(
            "fix", "improve", "update", "change", "modify",
            "broken", "not working", "error", "issue", "problem",
            "try", "help", "do it", "make it work"
        )
        complexity = "unknown"
        route = "clarify"
    }

    REFACTOR = @{
        description = "Code restructuring tasks"
        patterns = @(
            "refactor", "restructure", "reorganize", "clean up",
            "simplify", "extract", "rename", "move", "copy"
        )
        complexity = "high"
        route = "plan_first"
    }

    DEBUG = @{
        description = "Bug fixing and error resolution"
        patterns = @(
            "debug", "fix bug", "error", "crash", "broken",
            "failed", "exception", "stack trace", "not working"
        )
        complexity = "high"
        route = "analyze_first"
    }

    REVIEW = @{
        description = "Code review and analysis"
        patterns = @(
            "review", "analyze", "audit", "check",
            "assess", "evaluate", "score", "grade"
        )
        complexity = "medium"
        route = "direct"
    }

    TEST = @{
        description = "Testing tasks"
        patterns = @(
            "test", "spec", "verify", "validate",
            "ensure", "confirm", "check"
        )
        complexity = "medium"
        route = "plan_first"
    }

    DOCUMENT = @{
        description = "Documentation tasks"
        patterns = @(
            "document", "doc", "explain", "comment",
            "readme", "guide", "manual"
        )
        complexity = "low"
        route = "direct"
    }
}

# =============================================================================
# TEMPLATES
# =============================================================================

$TEMPLATES = @{
    TRIVIAL = @{
        intro = "I'll handle this directly:"
        thinking = "This is a straightforward request. No need for planning."
        execute = "Executing directly..."
    }

    EXPLORATORY = @{
        intro = "I'll research this thoroughly:"
        thinking = "This requires exploration. Fanning out parallel searches."
        execute = "Running parallel research agents..."
    }

    IMPLEMENTATION = @{
        intro = "I'll build this for you:"
        thinking = "This is an implementation task. Creating a plan first."
        execute = "Creating implementation plan..."
        require_plan = $true
    }

    AMBIGUOUS = @{
        intro = "I need to clarify a few things:"
        thinking = "This request is ambiguous. I need more information."
        execute = "Asking for clarification..."
        clarify = $true
    }

    REFACTOR = @{
        intro = "I'll refactor this:"
        thinking = "This is a refactoring task. Analyzing first."
        execute = "Analyzing code structure..."
        require_plan = $true
    }

    DEBUG = @{
        intro = "I'll debug this issue:"
        thinking = "This requires analysis. Investigating the problem first."
        execute = "Running error analysis..."
        require_analysis = $true
    }

    REVIEW = @{
        intro = "I'll review this:"
        thinking = "Analyzing for quality, security, and performance."
        execute = "Running review..."
    }

    TEST = @{
        intro = "I'll test this:"
        thinking = "Creating tests to verify correctness."
        execute = "Generating tests..."
        require_plan = $true
    }

    DOCUMENT = @{
        intro = "I'll document this:"
        thinking = "Creating documentation."
        execute = "Generating docs..."
    }
}

# =============================================================================
# CLASSIFICATION LOGIC
# =============================================================================

function Get-IntentClassification {
    param([string]$Text)

    if (-not $Text) {
        return @{
            intent = "TRIVIAL"
            confidence = 0.5
            reason = "No input provided, defaulting to TRIVIAL"
            keywords = @()
            is_ambiguous = $false
            requires_clarification = $false
        }
    }

    $lowerInput = $Text.ToLower()
    $scores = @{}
    $keywords = @()

    # Score each intent
    foreach ($intent in $INTENTS.Keys) {
        $score = 0
        $intentKeywords = @()

        foreach ($pattern in $INTENTS[$intent].patterns) {
            if ($lowerInput -match [regex]::Escape($pattern)) {
                $score += 1
                $intentKeywords += $pattern
            }
        }

        # Boost score for explicit keywords
        if ($intentKeywords.Count -gt 0) {
            $scores[$intent] = $score
            $keywords += $intentKeywords
        }
    }

    # Find best intent
    $bestIntent = "TRIVIAL"
    $bestScore = 0

    foreach ($intent in $scores.Keys) {
        if ($scores[$intent] -gt $bestScore) {
            $bestScore = $scores[$intent]
            $bestIntent = $intent
        }
    }

    # Calculate confidence
    $confidence = 0.5
    if ($bestScore -gt 0) {
        $maxPossible = $INTENTS[$bestIntent].patterns.Count
        $confidence = [Math]::Min($bestScore / 3.0, 0.95)  # Max 95% confidence
    }

    # Determine if ambiguous
    $isAmbiguous = ($bestIntent -eq "AMBIGUOUS") -or ($confidence -lt 0.3)

    # Special handling for certain inputs
    # "fix" without specifying what = ambiguous
    if ($lowerInput -match "^fix$" -or $lowerInput -match "^fix the ") {
        $isAmbiguous = $true
        $bestIntent = "AMBIGUOUS"
    }

    # Check for explicit intent indicators
    if ($lowerInput -match "^(build|create|add|implement|make) ") {
        $bestIntent = "IMPLEMENTATION"
    }
    if ($lowerInput -match "^(refactor|restructure|clean) ") {
        $bestIntent = "REFACTOR"
    }
    if ($lowerInput -match "^(debug|fix|error) ") {
        $bestIntent = "DEBUG"
    }
    if ($lowerInput -match "^(test|verify|validate) ") {
        $bestIntent = "TEST"
    }
    if ($lowerInput -match "^(research|explore|find|search) ") {
        $bestIntent = "EXPLORATORY"
    }
    if ($lowerInput -match "^(review|analyze|audit) ") {
        $bestIntent = "REVIEW"
    }

    return @{
        intent = $bestIntent
        confidence = $confidence
        reason = "Matched keywords: $($keywords -join ', ')"
        keywords = $keywords
        is_ambiguous = $isAmbiguous
        requires_clarification = $isAmbiguous
    }
}

# =============================================================================
# ROUTING LOGIC
# =============================================================================

function Get-IntentRoute {
    param([hashtable]$Classification)

    $intent = $Classification.intent
    $info = $INTENTS[$intent]

    return @{
        intent = $intent
        route = $info.route
        complexity = $info.complexity
        description = $info.description
    }
}

# =============================================================================
# HANDLER EXECUTION
# =============================================================================

function Invoke-IntentHandler {
    param([hashtable]$Route, [string]$Text)

    $intent = $Route.intent

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "    INTENT GATE DECISION" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "  Intent: " -NoNewline
    Write-Host $intent -ForegroundColor Green

    Write-Host "  Route: " -NoNewline
    Write-Host $Route.route -ForegroundColor Cyan

    Write-Host "  Complexity: " -NoNewline
    Write-Host $Route.complexity -ForegroundColor Magenta

    Write-Host "  Description: $($Route.description)" -ForegroundColor Gray

    Write-Host ""

    $template = $TEMPLATES[$intent]

    Write-Host $template.intro -ForegroundColor Yellow
    Write-Host "  " -NoNewline
    Write-Host $template.thinking -ForegroundColor Gray

    Write-Host ""

    switch ($intent) {
        "TRIVIAL" {
            Write-Host "→ Executing directly..." -ForegroundColor Green
        }
        "EXPLORATORY" {
            Write-Host "→ Opening parallel research agents..." -ForegroundColor Cyan
        }
        "IMPLEMENTATION" {
            Write-Host "→ Creating TODO list and plan..." -ForegroundColor Yellow
        }
        "AMBIGUOUS" {
            Write-Host "→ Need clarification: What specifically should I $Text?" -ForegroundColor Yellow
            Write-Host "  Please specify:" -ForegroundColor Gray
            Write-Host "    - What you want to accomplish" -ForegroundColor Gray
            Write-Host "    - Any specific files or areas" -ForegroundColor Gray
            Write-Host "    - Expected outcome" -ForegroundColor Gray
        }
        "REFACTOR" {
            Write-Host "→ Analyzing code structure first..." -ForegroundColor Cyan
        }
        "DEBUG" {
            Write-Host "→ Analyzing error and gathering evidence..." -ForegroundColor Red
        }
        "REVIEW" {
            Write-Host "→ Running review checks..." -ForegroundColor Green
        }
        "TEST" {
            Write-Host "→ Creating test plan..." -ForegroundColor Yellow
        }
        "DOCUMENT" {
            Write-Host "→ Generating documentation..." -ForegroundColor Green
        }
    }

    Write-Host ""

    return $Route
}

# =============================================================================
# MAIN
# =============================================================================

function Show-Templates {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "      INTENT GATE TEMPLATES" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    foreach ($intent in $TEMPLATES.Keys) {
        $t = $TEMPLATES[$intent]
        $i = $INTENTS[$intent]

        Write-Host "[$intent]" -ForegroundColor Green
        Write-Host "  Route: $($i.route)" -ForegroundColor Cyan
        Write-Host "  $($t.intro)" -ForegroundColor White
        Write-Host ""
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

switch ($Operation.ToLower()) {
    "classify" {
        if (-not $Text) {
            Write-Host "Error: -Text is required for classify operation" -ForegroundColor Red
            exit 1
        }

        Write-Host "Classifying: ""$Text""" -ForegroundColor Cyan
        Write-Host ""

        $classification = Get-IntentClassification -Input $Text

        Write-Host "Intent: " -NoNewline
        Write-Host $classification.intent -ForegroundColor Green

        Write-Host "Confidence: $([Math]::Round($classification.confidence * 100, 0))%" -ForegroundColor Cyan

        if ($classification.reason) {
            Write-Host "Reason: $($classification.reason)" -ForegroundColor Gray
        }

        if ($classification.is_ambiguous) {
            Write-Host "⚠ This request is ambiguous and needs clarification" -ForegroundColor Yellow
        }

        Write-Host ""

        $route = Get-IntentRoute -Classification $classification
        Invoke-IntentHandler -Route $route -Input $Text

        # AUTO-SPAWN PARALLEL AGENTS based on intent!
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  AUTO-SPAWNING PARALLEL AGENTS!" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        $mode = switch ($classification.intent) {
            "EXPLORATORY" { "research" }
            "IMPLEMENTATION" { "full" }
            "DEBUG" { "debug" }
            "REFACTOR" { "analyze" }
            "REVIEW" { "analyze" }
            "TEST" { "implement" }
            "DOCUMENT" { "research" }
            default { "auto" }
        }

        Write-Host "  Spawning parallel agents in mode: $mode" -ForegroundColor Green

        # Call parallel engine
        $parallelScript = "C:\Users\clayt\opencode-bob\skills\parallel-execution\parallel-engine.ps1"
        if (Test-Path $parallelScript) {
            Write-Host ""
            & $parallelScript -Operation run -Task $Text -Mode $mode | Out-Null
        } else {
            Write-Host "  → Run: orchestration.ps1 -Operation route -Task '$Text'" -ForegroundColor Cyan
        }

        Write-Host ""

        return @{
            classification = $classification
            route = $route
        }
    }

    "route" {
        if (-not $Text) {
            Write-Host "Error: -Input is required for route operation" -ForegroundColor Red
            exit 1
        }

        $classification = Get-IntentClassification -Input $Text
        $route = Get-IntentRoute -Classification $classification

        return $route
    }

    "templates" {
        Show-Templates
    }

    "init" {
        Write-Host "[Intent Gate] Initializing..." -ForegroundColor Cyan

        # Initialize templates directory
        $templateDir = "C:\Users\clayt\opencode-bob\skills\intent-gate\templates"
        New-Item -ItemType Directory -Force -Path $templateDir | Out-Null

        # Save templates
        $INTENTS | ConvertTo-Json -Depth 5 | Set-Content "$templateDir\intents.json"

        Write-Host "[Intent Gate] Initialized with $($INTENTS.Count) intent types" -ForegroundColor Green
    }

    default {
        Write-Host "Usage: intent-gate.ps1 -Operation <classify|route|templates|init> [-Input '<text>']"
        Write-Host ""
        Write-Host "Operations:"
        Write-Host "  classify  - Classify input and execute handler"
        Write-Host "  route      - Just return the route (no execution)"
        Write-Host "  templates - Show all intent templates"
        Write-Host "  init      - Initialize intent gate"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\intent-gate.ps1 -Operation classify -Input 'build login feature'"
        Write-Host "  .\intent-gate.ps1 -Operation classify -Input 'how does auth work'"
        Write-Host "  .\intent-gate.ps1 -Operation templates"
    }
}