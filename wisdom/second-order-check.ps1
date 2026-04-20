# BOB'S SECOND-ORDER THINKING SYSTEM
# Traces ripple effects before committing changes
# Based on BOB-WISDOM by Claude

param(
    [Parameter(Mandatory=$true)]
    [string]$ChangeDescription,
    
    [Parameter(Mandatory=$true)]
    [string[]]$ModifiedFiles,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$DependencyMap = @{}
)

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$analysis = @{
    "timestamp" = $timestamp
    "change_description" = $ChangeDescription
    "modified_files" = $ModifiedFiles
    "structural_dependencies" = @()
    "runtime_dependencies" = @()
    "build_dependencies" = @()
    "behavioral_dependencies" = @()
    "risks" = @()
    "type" = "SECOND_ORDER_ANALYSIS"
}

Write-Host "`n=== SECOND-ORDER ANALYSIS: $ChangeDescription" -ForegroundColor Yellow
Write-Host "Modified files: $($ModifiedFiles -join ', ')" -ForegroundColor Cyan

# Analyze structural dependencies (what calls what)
foreach ($file in $ModifiedFiles) {
    Write-Host "`n[Structural] Checking dependencies for: $file" -ForegroundColor Gray
    
    # Check what includes this file
    $includingFiles = Get-ChildItem -Path "C:/Users/clayt" -Recurse -Include "*.cpp","*.h","*.hpp" -ErrorAction SilentlyContinue | 
        Select-String -Pattern (Split-Path $file -Leaf) -SimpleMatch -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
    
    if ($includingFiles) {
        $analysis.structural_dependencies += @{
            "file" = $file
            "dependents" = $includingFiles
        }
        Write-Host "  Found $($includingFiles.Count) files depending on this" -ForegroundColor Cyan
    }
}

# Common structural patterns to warn about
$structuralPatterns = @(
    @{ "pattern" = "Init"; "risk" = "Initialization order may have changed" }
    @{ "pattern" = "Destroy"; "risk" = "Resource cleanup order may cause issues" }
    @{ "pattern" = "Callback"; "risk" = "Callback could be called before registration" }
    @{ "pattern" = "static"; "risk" = "Static initialization order fiasco risk" }
)

foreach ($file in $ModifiedFiles) {
    foreach ($pat in $structuralPatterns) {
        if ((Get-Content $file -Raw) -match $pat.pattern) {
            $analysis.risks += @{
                "category" = "structural"
                "file" = $file
                "pattern" = $pat.pattern
                "risk" = $pat.risk
            }
            Write-Host "  ⚠ $($pat.risk)" -ForegroundColor Yellow
        }
    }
}

# Runtime dependencies analysis
$analysis.runtime_dependencies += @{
    "threading" = "Check for shared state between threads"
    "initialization" = "Check initialization order requirements"
    "lifetime" = "Check object lifetime assumptions"
}

# Build dependencies
$analysis.build_dependencies += @{
    "header_changes" = "Header changes may require full rebuild"
    "linking" = "Check link order if adding libraries"
}

# Behavioral dependencies
$analysis.behavioral_dependencies += @{
    "workarounds" = "Check for code that works around current behavior"
    "assumptions" = "Check for hardcoded assumptions"
}

# Store analysis
$memoryPath = "C:/Users/clayt/opencode-bob/memory/wisdom/second-order-analyses.json"
$analyses = @()

if (Test-Path $memoryPath) {
    $content = Get-Content $memoryPath -Raw
    if ($content.Trim()) {
        $analyses = $content | ConvertFrom-Json
        if ($analyses -isnot [System.Array]) { $analyses = @($analyses) }
    }
}
$analyses += $analysis
$analyses | ConvertTo-Json -Depth 4 | Set-Content $memoryPath

Write-Host "`nSECOND-ORDER ANALYSIS COMPLETE" -ForegroundColor Green
Write-Host "  Structural deps: $($analysis.structural_dependencies.Count)"
Write-Host "  Risks identified: $($analysis.risks.Count)"

return $analysis | ConvertTo-Json -Depth 4