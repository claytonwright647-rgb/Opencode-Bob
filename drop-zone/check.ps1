# Drop files here for Bob to process
$dropZone = "C:/Users/clayt/opencode-bob/drop-zone"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OPENCODE BOB - DROP ZONE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[DROP FILES HERE]" -ForegroundColor Yellow
Write-Host "Drop any file, photo, or folder and Bob will process it!"
Write-Host ""

# Get current files
$files = Get-ChildItem $dropZone -File -ErrorAction SilentlyContinue

if ($files) {
    Write-Host "[FILES DETECTED]" -ForegroundColor Green
    Write-Host ""
    
    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $name = $file.Name
        $size = [math]::Round($file.Length / 1KB, 2)
        
        Write-Host "[$ext] $name ($size KB)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "[NEXT STEP]" -ForegroundColor Yellow
    Write-Host "Run: opencode run ""process attached files"" --agent bob"
} else {
    Write-Host "[EMPTY] No files in drop zone." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Supported: .py, .js, .ps1, .png, .jpg, .pdf, .json, etc!"
    Write-Host "Write-Host "Run: .\bob-do.ps1 'analyze my files'""
}