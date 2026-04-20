# Opencode Bob - Attach Files Here
# Drop files, photos, or folders here for Bob to process

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string]$Files
)

$ErrorActionPreference = "Continue"

$attachmentsDir = "C:/Users/clayt/opencode-bob/attachments"

# Create attachments folder if needed
if (-not (Test-Path $attachmentsDir)) {
    New-Item -ItemType Directory -Path $attachmentsDir -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OPENCODE BOB - ATTACHMENT HANDLER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# If no files provided, show instructions
if (-not $Files) {
    Write-Host "[INSTRUCTIONS]" -ForegroundColor Yellow
    Write-Host "Drop files here or specify files to attach:" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Green
    Write-Host "  1. Drag & drop files into this folder"
    Write-Host "  2. Or run: .\attach-files.ps1 ""file1.jpg"" ""file2.png"""
    Write-Host "  3. Bob will process all attachments!"
    Write-Host ""
    Write-Host "Files attached:" -ForegroundColor Green
    
    $attached = Get-ChildItem $attachmentsDir -File -ErrorAction SilentlyContinue
    if ($attached) {
        $attached | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 2)
            Write-Host "  [$($_.Extension)] $($_.Name) ($size KB)" -ForegroundColor White
        }
    } else {
        Write-Host "  (No files attached)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "[ACTIONS]" -ForegroundColor Yellow
    Write-Host "  process     - Have Bob process all attachments"
    Write-Host "  list        - List attached files"
    Write-Host "  clear       - Remove all attachments"
    Write-Host "  open        - Open attachments folder"
    exit 0
}

# Process each file
$filesToAttach = $Files -split ' '

foreach ($file in $filesToAttach) {
    if (Test-Path $file) {
        $sourcePath = (Resolve-Path $file).Path
        $fileName = Split-Path $sourcePath -Leaf
        $destPath = Join-Path $attachmentsDir $fileName
        
        Copy-Item $sourcePath -Destination $destPath -Force
        Write-Host "[ATTACHED] $fileName" -ForegroundColor Green
    } else {
        Write-Host "[NOT FOUND] $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[READY] Files ready for Bob to process!" -ForegroundColor Cyan

# Ask Bob to process
Write-Host ""
$response = Read-Host "Have Bob process now? (y/n)"
if ($response -eq "y") {
    Write-Host ""
    $attached = Get-ChildItem $attachmentsDir -File
    if ($attached) {
        Write-Host "[BOB] Processing attachments..." -ForegroundColor Cyan
        $fileList = ($attached | ForEach-Object { $_.Name }) -join ", "
        opencode run "Process these files: $fileList. Analyze each, list what they contain, and tell me about them." --agent bob
    }
}