# BOB'S MEMORY EXTRACTION SYSTEM
# Runs after conversations/tasks to extract and save learnings
# Like Claude's auto-memory system

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "extract",  # extract, review, list
    
    [Parameter(Mandatory=$false)]
    [string]$Type = "all",  # all, project, user, thread, resource
    
    [int]$MaxMemories = 5
)

$ErrorActionPreference = "Continue"

# ============================================================================
# MEMORY TYPES (Claude's taxonomy)
# ============================================================================
# project  - Project conventions, patterns, decisions
# user     - User preferences, communication style  
# thread   - Current conversation context
# resource - External references, links, docs

# ============================================================================
# MEMORY DIRECTORIES
# ============================================================================
$MEMORY_DIR = "C:\Users\clayt\opencode-bob\memory\memories"
$PROJECT_DIR = Join-Path $MEMORY_DIR "project"
$USER_DIR = Join-Path $MEMORY_DIR "user"
$THREAD_DIR = Join-Path $MEMORY_DIR "thread"
$RESOURCE_DIR = Join-Path $MEMORY_DIR "resource"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Initialize-MemoryDirs {
    @($MEMORY_DIR, $PROJECT_DIR, $USER_DIR, $THREAD_DIR, $RESOURCE_DIR) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Force -Path $_ | Out-Null
        }
    }
}

function Get-MemoryAge {
    param([string]$File)
    
    if (-not (Test-Path $File)) { return 0 }
    
    $lastWrite = (Get-Item $File).LastWriteTime
    $days = ((Get-Date) - $lastWrite).TotalDays
    return [math]::Round($days, 1)
}

function Get-StalenessWarning {
    param([string]$Age)
    
    if ($Age -gt 14) { return "⚠️ STALE (may be outdated)" }
    if ($Age -gt 7) { return "⚠️ Older than 1 week" }
    if ($Age -gt 3) { return "⚠️ A few days old" }
    return "✓ Fresh"
}

# ============================================================================
# MEMORY EXTRACTION
# ============================================================================

function Extract-Memories {
    param(
        [string]$Type,
        [int]$MaxFiles
    )
    
    Initialize-MemoryDirs
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💾 MEMORY EXTRACTION" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # First, snapshot before extraction
    Write-Host "[1/5] Creating Time Machine backup..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "memory-extract-before" | Out-Null
    
    # Analyze what's happened in this session
    Write-Host "[2/5] Analyzing session..." -ForegroundColor Gray
    
    $sessionFile = "C:\Users\clayt\opencode-bob\memory\sessions\current-session.json"
    $learningFile = "C:\Users\clayt\opencode-bob\memory\learning\interactions.json"
    $beliefFile = "C:\Users\clayt\opencode-bob\memory\wisdom\belief-revisions.json"
    
    $learnings = @()
    
    # Get recent learnings
    if (Test-Path $learningFile) {
        $interactions = Get-Content $learningFile -Raw | ConvertFrom-Json
        if ($interactions -is [System.Array]) {
            $learnings += $interactions[0..[Math]::Min(5, $interactions.Count-1)]
        }
    }
    
    # Get recent beliefs
    if (Test-Path $beliefFile) {
        $beliefs = Get-Content $beliefFile -Raw | ConvertFrom-Json
        if ($beliefs -is [System.Array]) {
            $learnings += $beliefs
        }
    }
    
    Write-Host "   Found $($learnings.Count) learnings to extract" -ForegroundColor Cyan
    
    # Identify memory-worthy content
    Write-Host "[3/5] Identifying memory-worthy content..." -ForegroundColor Gray
    
    $memoriesToSave = @()
    
    # Check each learning
    foreach ($learning in $learnings) {
        if ($learning -is [hashtable] -or $learning.PSObject.Properties["type"]) {
            $memoriesToSave += @{
                "content" = $learning.description
                "type" = "project"
                "source" = "extraction"
                "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                "importance" = "high"
            }
        }
    }
    
    # Save memories by type
    Write-Host "[4/5] Saving memories..." -ForegroundColor Gray
    
    $savedCount = 0
    foreach ($memory in $memoriesToSave) {
        $targetDir = switch ($memory.type) {
            "project" { $PROJECT_DIR }
            "user" { $USER_DIR }
            "thread" { $THREAD_DIR }
            "resource" { $RESOURCE_DIR }
            default { $PROJECT_DIR }
        }
        
        $filename = "$($memory.type)-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').md"
        $filepath = Join-Path $targetDir $filename
        
        $content = @"
---
type: $($memory.type)
importance: $($memory.importance)
created: $($memory.created)
source: extraction
---

$($memory.content)
"@
        $content | Set-Content $filepath
        $savedCount++
    }
    
    Write-Host "   Saved $savedCount memories" -ForegroundColor Green
    
    # After extraction - snapshot!
    Write-Host "[5/5] Creating Time Machine backup..." -ForegroundColor Gray
    & "C:\Users\clayt\opencode-bob\time-machine.ps1" -Operation snapshot -Name "memory-extract-after" | Out-Null
    
    Write-Host ""
    Write-Host "✅ Memory extraction complete!" -ForegroundColor Green
    
    return $memoriesToSave
}

# ============================================================================
# REVIEW MEMORIES
# ============================================================================

function Review-Memories {
    param([string]$Type)
    
    Initialize-MemoryDirs
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💾 MEMORY REVIEW" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $dirs = @{
        "project" = $PROJECT_DIR
        "user" = $USER_DIR
        "thread" = $THREAD_DIR
        "resource" = $RESOURCE_DIR
    }
    
    foreach ($typeName in $dirs.Keys) {
        if ($Type -ne "all" -and $Type -ne $typeName) { continue }
        
        $dir = $dirs[$typeName]
        $files = Get-ChildItem $dir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxMemories
        
        Write-Host "[$typeName.ToUpper()] ($(($files | Measure-Object).Count) memories)" -ForegroundColor Cyan
        
        foreach ($file in $files) {
            $age = Get-MemoryAge -File $file.FullName
            $staleness = Get-StalenessWarning -Age $age
            
            Write-Host "  📄 $($file.Name)" -ForegroundColor White
            Write-Host "     $staleness" -ForegroundColor $(if ($age -gt 7) { "Yellow" } else { "Gray" })
            
            # Read and show first line
            $content = Get-Content $file.FullName -Raw
            if ($content.Length -gt 100) {
                $content = $content.Substring(0, 100) + "..."
            }
            Write-Host "     → $content" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    Write-Host "Total stored: $((Get-ChildItem $MEMORY_DIR -Recurse -Filter '*.md' | Measure-Object).Count) memories" -ForegroundColor White
}

# ============================================================================
# LIST SPECIFIC MEMORIES
# ============================================================================

function List-Memories {
    param([string]$Type)
    
    Initialize-MemoryDirs
    
    $memories = @()
    
    $targetDir = switch ($Type) {
        "project" { $PROJECT_DIR }
        "user" { $USER_DIR }
        "thread" { $THREAD_DIR }
        "resource" { $RESOURCE_DIR }
        default { $PROJECT_DIR }
    }
    
    $files = Get-ChildItem $targetDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 20
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  💾 $Type MEMORIES" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($file in $files) {
        $age = Get-MemoryAge -File $file.FullName
        $staleness = Get-StalenessWarning -Age $age
        
        $content = Get-Content $file.FullName | Select-Object -Skip 7 | Select-Object -First 3
        $contentStr = $content -join " "
        
        Write-Host "📄 $($file.Name)" -ForegroundColor White
        Write-Host "   $ staleness" -ForegroundColor $(if ($age -gt 7) { "Yellow" } else { "Gray" })
        if ($contentStr) {
            Write-Host "   → $($contentStr.Substring(0, [Math]::Min(80, $contentStr.Length)))..." -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "extract" {
        Extract-Memories -Type $Type -MaxFiles $MaxMemories
    }
    
    "review" {
        Review-Memories -Type $Type
    }
    
    "list" {
        List-Memories -Type $Type
    }
    
    "project" {
        List-Memories -Type "project"
    }
    
    "user" {
        List-Memories -Type "user"
    }
    
    "thread" {
        List-Memories -Type "thread"
    }
    
    "resource" {
        List-Memories -Type "resource"
    }
    
    "all" {
        Review-Memories -Type "all"
    }
    
    default {
        Write-Host "Usage: memory-extract.ps1 -Operation <extract|review|list>"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\memory-extract.ps1 -Operation extract    # Extract learnings to memory"
        Write-Host "  .\memory-extract.ps1 -Operation review     # Review all memories"
        Write-Host "  .\memory-extract.ps1 -Operation list    # List memories"
        Write-Host "  .\memory-extract.ps1 -Operation project  # List project memories"
    }
}