# BOB'S PERSISTENT MEMORY FILES
# SOUL.md + MEMORY.md style persistent identity and context
# Inspired by OpenClaw's memory architecture

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "update",  # update, read, status
    
    [Parameter(Mandatory=$false)]
    [string]$File = "soul",  # soul, memory
    
    [Parameter(Mandatory=$false)]
    [string]$Content = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$MEMORY_DIR = "C:\Users\clayt\opencode-bob\memory\persistent"
$SOUL_FILE = "$MEMORY_DIR\SOUL.md"
$MEMORY_FILE = "$MEMORY_DIR\MEMORY.md"

if (-not (Test-Path $MEMORY_DIR)) {
    New-Item -ItemType Directory -Force -Path $MEMORY_DIR | Out-Null
}

# ============================================================================
# DEFAULT SOUL.md
# Identity, personality, and core values
# ============================================================================

$DEFAULT_SOUL = @"
# SOUL.md - Bob's Identity

## Who I Am
- Name: Opencode Bob (Opencode Only version)
- Created: 2026-04-19
- Creator: Clay Wright

## My Values
- Always be helpful and efficient
- Never repeat the same mistake twice
- Be persistent and self-improving
- Protect user's privacy and security
- Think step-by-step for complex problems

## My Capabilities
- PDF reading and analysis
- GitHub integration
- File system access
- Knowledge graph memory
- Web search and fetch
- Code analysis and review
- VA claims expertise (unique!)

## How I Work
- Break problems into small chunks
- Use parallel execution when possible
- Verify all results
- Learn from every interaction

## What I Believe
- Less is more - focused tools > many tools
- Persistence beats intelligence
- Error recovery is essential
- Context management is critical

## Communication Style
- Be concise but thorough
- Confirm before destructive actions
- Explain my reasoning when complex
- Ask for clarification when unsure

## Notes for This Session
- Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

# ============================================================================
# DEFAULT MEMORY.md
# Long-term facts and context
# ============================================================================

$DEFAULT_MEMORY = @"
# MEMORY.md - Facts About Clay

## Personal
- Name: Clay Wright
- Location: Stephenville, Texas, USA
- Timezone: America/Chicago (CST/CDT)
- OS: Windows 11

## VA Claims (as of April 2026)
- Filed: January 4, 2026
- 14 conditions claimed
- Expected: 70-90% or 100% with TDIU
- Back pay: ~\$7,000-\$12,000

## My Systems
- 4 optimized MCPs (github, filesystem, memory, pdf)
- 40+ PowerShell scripts
- 32 skills
- Context compaction (5 layers)
- Tool budgets
- Model routing
- Error recovery
- Time Machine backups

## What I've Learned
- Preferences saved to user-preferences.md
- Lessons saved to learning/patterns.json
- Errors saved to error-analyses.json

## Notes
- Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

# ============================================================================
# INITIALIZE DEFAULT FILES
# ============================================================================

function Initialize-Files {
    # Create SOUL.md if not exists
    if (-not (Test-Path $SOUL_FILE)) {
        $DEFAULT_SOUL | Set-Content $SOUL_FILE
    }
    
    # Create MEMORY.md if not exists
    if (-not (Test-Path $MEMORY_FILE)) {
        $DEFAULT_MEMORY | Set-Content $MEMORY_FILE
    }
}

# ============================================================================
# UPDATE FILE
# ============================================================================

function Update-MemoryFile {
    param([string]$FileName, [string]$NewContent)
    
    $file = if ($FileName -eq "soul") { $SOUL_FILE } else { $MEMORY_FILE }
    
    # Append to existing or create new
    if ($NewContent -ne "") {
        # Add new content with timestamp
        $entry = @"

## Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$NewContent
"@
        Add-Content -Path $file -Value $entry
    }
    
    return @{
        success = $true
        file = $file
        updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

# ============================================================================
# READ FILE
# ============================================================================

function Read-MemoryFile {
    param([string]$FileName)
    
    $file = if ($FileName -eq "soul") { $SOUL_FILE } else { $MEMORY_FILE }
    
    if (-not (Test-Path $file)) {
        Initialize-Files
    }
    
    $content = Get-Content $file -Raw
    return @{
        file = $file
        content = $content
        lines = ($content -split "`n").Count
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-MemoryStatus {
    Initialize-Files
    
    $soulExists = Test-Path $SOUL_FILE
    $memExists = Test-Path $MEMORY_FILE
    
    return @{
        soulFile = $SOUL_FILE
        soulExists = $soulExists
        memoryFile = $MEMORY_FILE
        memoryExists = $memExists
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "update" {
        if ($Content -eq "") {
            Write-Error "Content required"
        }
        Update-MemoryFile -FileName $File -NewContent $Content
    }
    "read" {
        Read-MemoryFile -FileName $File
    }
    "status" {
        Get-MemoryStatus
    }
    "init" {
        Initialize-Files
        @{success = $true; message = "Files initialized"}
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}