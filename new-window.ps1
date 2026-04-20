# Opencode Bob - New Chat Window
# Open a new Bob chat window for parallel work!

param(
    [int]$WindowNum = 1
)

$basePort = 8080
$port = $basePort + $WindowNum

Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "  OPENCODE BOB - NEW WINDOW #$WindowNum" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

Write-Host "[Starting] Port $port..." -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoExit", "-Command", "opencode web --port $port --hostname 127.0.0.1" -WindowStyle Normal

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "[READY] Your new Bob window is at:" -ForegroundColor Yellow
Write-Host "  http://127.0.0.1:$port" -ForegroundColor White
Write-Host ""
Write-Host "Each window runs Bob independently!" -ForegroundColor Cyan