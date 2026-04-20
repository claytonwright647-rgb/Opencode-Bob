# ERROR DETECTIVE - Analyze errors like a detective
# Based on BOB-SKILLS by Claude

param(
    [Parameter(Mandatory=$false)]
    [string]$ErrorLog,
    
    [Parameter(Mandatory=$false)]
    [string]$ErrorText,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n=== ERROR DETECTIVE ANALYSIS ===" -ForegroundColor Yellow
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray

# Load error text
$fullError = ""
if ($ErrorLog -and (Test-Path $ErrorLog)) {
    $fullError = Get-Content $ErrorLog -Raw
    Write-Host "Loaded error log: $ErrorLog" -ForegroundColor Cyan
} elseif ($ErrorText) {
    $fullError = $ErrorText
} else {
    Write-Host "Error: No error log or error text provided" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== FULL ERROR DATA ===" -ForegroundColor Yellow
Write-Host $fullError -ForegroundColor White

# Detect error type
$errorType = "UNKNOWN"
$detailedAnalysis = @{}

Write-Host "`n=== ERROR TYPE DETECTION ===" -ForegroundColor Yellow

if ($fullError -match "LNK2019") {
    $errorType = "LNK2019"
    Write-Host "Type: LINKER - Unresolved external symbol" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "linker"
        "meaning" = "Symbol is declared but not linked"
        "causes" = @(
            "Source file not in CMakeLists target",
            "Link library order wrong",
            "Symbol not defined"
        )
        "fix" = "Check: (1) symbol defined? (2) source in target? (3) link order?"
    }
} elseif ($fullError -match "C2589") {
    $errorType = "C2589"
    Write-Host "Type: COMPILER - Illegal token (often NOMINMAX)" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "compiler"
        "meaning" = "NOMINMAX macro conflict with std::min/std::max"
        "causes" = @(
            "Windows.h included without NOMINMAX",
            "Using std::min/max somewhere in code"
        )
        "fix" = "Add '#define NOMINMAX' as FIRST line before #include <Windows.h>"
    }
} elseif ($fullError -match "C2039") {
    $errorType = "C2039"
    Write-Host "Type: COMPILER - Not a member of" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "compiler"
        "meaning" = "Type doesn't have expected member"
        "causes" = @(
            "Wrong include order",
            "Wrong namespace",
            "Missing header"
        )
        "fix" = "Check: (1) correct header? (2) correct namespace? (3) correct type?"
    }
} elseif ($fullError -match "LNK1181") {
    $errorType = "LNK1181"
    Write-Host "Type: LINKER - Cannot open library" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "linker"
        "meaning" = "Library file not found or not built"
        "causes" = @(
            "Library project not built",
            "Wrong path to .lib",
            "vcpkg not installed correctly"
        )
        "fix" = "Build library first, check path, run vcpkg integrate install"
    }
} elseif ($fullError -match "C3861") {
    $errorType = "C3861"
    Write-Host "Type: COMPILER - Identifier not found" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "compiler"
        "meaning" = "Symbol not declared in scope"
        "causes" = @(
            "Missing include",
            "Wrong namespace",
            "Typo in name"
        )
        "fix" = "Check: (1) header included? (2) in correct namespace? (3) spelling?"
    }
} elseif ($fullError -match "E0349") {
    $errorType = "E0349"
    Write-Host "Type: COMPILER - No matching operator" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "compiler"
        "meaning" = "Type mismatch in expression"
        "causes" = @(
            "Wrong types for operator",
            "Missing conversion operator",
            "Template instantiation issue"
        )
        "fix" = "Check the actual types involved in the expression"
    }
} elseif ($fullError -match "Access denied") {
    $errorType = "ACCESS_DENIED"
    Write-Host "Type: PERMISSION - Access denied" -ForegroundColor Red
    $detailedAnalysis = @{
        "type" = "permission"
        "meaning" = "Cannot access resource"
        "causes" = @(
            "File locked by another process",
            "Insufficient permissions",
            "Anti-virus blocking"
        )
        "fix" = "Check: (1) file locked? (2) run as admin? (3) anti-virus?"
    }
} else {
    Write-Host "Type: UNKNOWN - Manual analysis required" -ForegroundColor Yellow
    $detailedAnalysis = @{
        "type" = "unknown"
        "meaning" = "Could not auto-detect error type"
        "causes" = @()
        "fix" = "Search error code in documentation"
    }
}

# Extract key information
Write-Host "`n=== EXTRACTED INFORMATION ===" -ForegroundColor Yellow

# Extract file names
$files = [regex]::Matches($fullError, '([A-Za-z]:\\[^:]+\.(cpp|h|hpp|lib|obj|exe))') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
if ($files) {
    Write-Host "Files mentioned:" -ForegroundColor Cyan
    foreach ($file in $files) {
        Write-Host "  - $file" -ForegroundColor White
    }
}

# Extract line numbers
$lines = [regex]::Matches($fullError, 'line (\d+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 5
if ($lines) {
    Write-Host "Lines mentioned: $($lines -join ', ')" -ForegroundColor Cyan
}

# Extract symbols
$symbols = [regex]::Matches($fullError, '(symbol|_[\w]+)') | ForEach-Object { $_.Value } | Select-Object -Unique
if ($symbols) {
    Write-Host "Symbols: $($symbols -join ', ')" -ForegroundColor Cyan
}

# Output recommendation
Write-Host "`n=== RECOMMENDATION ===" -ForegroundColor Green
if ($detailedAnalysis.fix) {
    Write-Host $detailedAnalysis.fix -ForegroundColor White
} else {
    Write-Host "Manual analysis required" -ForegroundColor Yellow
}

# Store analysis
$memoryPath = "C:/Users/clayt/opencode-bob/memory/wisdom/error-analyses.json"
$analyses = @()

$analysisRecord = @{
    "timestamp" = $timestamp
    "error_type" = $errorType
    "error_text" = $fullError.Substring(0, [Math]::Min(500, $fullError.Length))
    "analysis" = $detailedAnalysis
}

if (Test-Path $memoryPath) {
    $content = Get-Content $memoryPath -Raw
    if ($content.Trim()) {
        $analyses = $content | ConvertFrom-Json
        if ($analyses -isnot [System.Array]) { $analyses = @($analyses) }
    }
}
$analyses += $analysisRecord
$analyses | ConvertTo-Json -Depth 4 | Set-Content $memoryPath

Write-Host "`nAnalysis saved to memory" -ForegroundColor Gray

return $detailedAnalysis