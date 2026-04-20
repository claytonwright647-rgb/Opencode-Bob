# Drop files here for Bob to process
# This folder is watched by Opencode Bob

# When files are dropped here, Bob will:
# 1. Detect new files
# 2. Analyze each file type
# 3. Process according to type
# 4. Report results

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OPENCODE BOB - DROP ZONE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[DROP FILES HERE]" -ForegroundColor Yellow
Write-Host "Drop any file, photo, or folder and Bob will process it!"
Write-Host ""

# Watch for new files
$dropZone = "C:/Users/clayt/opencode-bob/drop-zone"
$attachments = "C:/Users/clayt/opencode-bob/attachments"

# Get current files
$files = Get-ChildItem $dropZone -File -ErrorAction SilentlyContinue

if ($files) {
    Write-Host "[FILES DETECTED]" -ForegroundColor Green
    Write-Host ""
    
    # Process each file with parallel agents!
    Write-Host "[BOB] Processing with PARALLEL AGENTS..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $name = $file.Name
        $size = [math]::Round($file.Length / 1KB, 2)
        
        Write-Host "[$ext] $name ($size KB)" -ForegroundColor White
        
        # Determine action based on type
        $action = switch ($ext) {
            ".ps1" { "PowerShell script" }
            ".py" { "Python file" }
            ".js" { "JavaScript file" }
            ".ts" { "TypeScript file" }
            ".json" { "JSON data" }
            ".md" { "Markdown doc" }
            ".txt" { "Text file" }
            ".png", ".jpg", ".jpeg", ".gif", ".bmp" { "Image file" }
            ".mp4", ".avi", ".mov" { "Video file" }
            ".mp3", ".wav" { "Audio file" }
            ".pdf" { "PDF document" }
            ".doc", ".docx" { "Word document" }
            ".xls", ".xlsx" { "Excel spreadsheet" }
            default { "Unknown file" }
        }
        
        Write-Host "     → $action" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "[NEXT STEP]" -ForegroundColor Yellow
    Write-Host "Run: .\bob-do.ps1 ""process drop zone files"""
    Write-Host "Or: opencode run ""process attached files"" --agent bob"
} else {
    Write-Host "[EMPTY]" -ForegroundColor Gray
    Write-Host "No files in drop zone. Drop some files here!"
    Write-Host ""
    Write-Host "Supported types:"
    Write-Host "  - Code files (.py, .js, .ps1, .ts, etc)"
    Write-Host "  - Images (.png, .jpg, .gif)"
    Write-Host "  - Documents (.pdf, .doc, .txt)"
    Write-Host "  - Data files (.json, .csv)"
    Write-Host "  - Any file!"
}