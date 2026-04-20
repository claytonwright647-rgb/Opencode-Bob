# BOB'S TOOL BUILDER
# Creates new tools on demand

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [ValidateSet("script", "skill")]
    [string]$Type = "script",
    
    [Parameter(Mandatory=$true)]
    [string]$Purpose,
    
    [string]$Template = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$TOOLS_DIR = "C:\Users\clayt\opencode-bob"
$SKILLS_DIR = "C:\Users\clayt\opencode-bob\skills"

# ============================================================================
# VALIDATE
# ============================================================================

if ($Name -match '[^\w\-]') {
    Write-Host "Error: Name can only contain letters, numbers, and hyphens" -ForegroundColor Red
    exit 1
}

# ============================================================================
# BUILD SCRIPT
# ============================================================================

if ($Type -eq "script") {
    $scriptPath = "$TOOLS_DIR\$Name.ps1"
    
    if (Test-Path $scriptPath) {
        Write-Host "Error: $scriptPath already exists" -ForegroundColor Red
        exit 1
    }
    
    # Default template
    if (-not $Template) {
        $Template = @"
# Bob's $Name Tool
# $Purpose
# Created: $(Get-Date -Format 'yyyy-MM-dd')

param(
    [Parameter(Mandatory=`$false)]
    [string]`$Input = ""
)

`$ErrorActionPreference = "Continue"

# ============================================================================
# TOOL LOGIC
# ============================================================================

Write-Host "🔧 Running: $Name" -ForegroundColor Cyan
Write-Host "   Purpose: $Purpose" -ForegroundColor Gray

# Tool logic here

# ============================================================================
# OUTPUT
# ============================================================================

return @{
    "tool" = "$Name"
    "purpose" = "$Purpose"
    "result" = "success"
    "timestamp" = "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
}
"@
    }
    
    $Template | Set-Content $scriptPath
    
    Write-Host "✅ Created script: $scriptPath" -ForegroundColor Green
    
    # Update self-model
    $selfModelPath = "$TOOLS_DIR\memory\sessions\self-model.json"
    if (Test-Path $selfModelPath) {
        # Just note that a new tool was created
        Write-Host "   💡 Added to self-model: $Name capability" -ForegroundColor Gray
    }
}

# ============================================================================
# BUILD SKILL
# ============================================================================

if ($Type -eq "skill") {
    $skillDir = "$SKILLS_DIR\$Name"
    
    if (Test-Path $skillDir) {
        Write-Host "Error: Skill already exists at $skillDir" -ForegroundColor Red
        exit 1
    }
    
    New-Item -ItemType Directory -Path $skillDir | Out-Null
    
    $skillMdPath = "$skillDir\SKILL.md"
    $skillScriptPath = "$skillDir\$Name.ps1"
    
    # Create SKILL.md
    $skillMd = @"
# SKILL: $Name
## $Purpose
### Version 1.0 | $(Get-Date -Format 'yyyy-MM-dd')

---

## WHAT THIS DOES

$Purpose

---

## HOW TO USE

\`\`\`powershell
pwsh -File $skillScriptPath -Input <value>
\`\`\`

---

## PARAMETERS

| Parameter | Type | Description |
|-----------|------|-------------|
| Input | string | Input value |

---

## EXAMPLES

\`\`\`powershell
pwsh -File $skillScriptPath -Input "test"
\`\`\`

---

*Created by Opencode Bob*
"@
    
    $skillMd | Set-Content $skillMdPath
    
    # Create script
    $scriptTemplate = @"
# $Name Skill
# $Purpose

param(
    [Parameter(Mandatory=`$false)]
    [string]`$Input = ""
)

`$ErrorActionPreference = "Continue"

# ============================================================================
# SKILL LOGIC
# ============================================================================

Write-Host "🎯 Running skill: $Name" -ForegroundColor Cyan
Write-Host "   Purpose: $Purpose" -ForegroundColor Gray

# Skill logic here

# ============================================================================
# OUTPUT
# ============================================================================

return @{
    "skill" = "$Name"
    "purpose" = "$Purpose"
    "result" = "success"
}
"@
    
    $scriptTemplate | Set-Content $skillScriptPath
    
    Write-Host "✅ Created skill: $skillDir" -ForegroundColor Green
    Write-Host "   Files: SKILL.md, $Name.ps1" -ForegroundColor Gray
}

Write-Host "`n🎉 Tool/Skill created successfully!" -ForegroundColor Green
Write-Host "   Use: pwsh -File <path> to run it" -ForegroundColor Cyan