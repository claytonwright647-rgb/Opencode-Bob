# Opencode Bob - Multi-Window Launcher
# Launch multiple Bob chat windows for parallel work!

param(
    [int]$NumWindows = 3,
    [string]$Task = "test"
)

$ErrorActionPreference = "Continue"

Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "  OPENCODE BOB - MULTI-WINDOW LAUNCHER" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

$basePort = 8080

for ($i = 1; $i -le $NumWindows; $i++) {
    $port = $basePort + $i
    
    Write-Host "[Window $i] Starting on port $port..." -ForegroundColor Green
    
    # Start Opencode in background on different port
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "opencode web --port $port --hostname 127.0.0.1" -WindowStyle Minimized
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "[READY] $NumWindows chat windows opening!" -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

Write-Host "Windows:" -ForegroundColor White

for ($i = 1; $i -le $NumWindows; $i++) {
    $port = $basePort + $i
    Write-Host "  Window $i: http://127.0.0.1:$port" -ForegroundColor Green
}

Write-Host ""
Write-Host "Each window can run Bob on a DIFFERENT task!" -ForegroundColor Cyan

Write-Host ""
Write-Host "Quick Start:" -ForegroundColor White
Write-Host "  1. Open http://127.0.0.1:8081" -ForegroundColor Gray
Write-Host "  2. Type: .\bob-do.ps1 'write unit tests'" -ForegroundColor Gray
Write-Host "  3. Open http://127.0.0.1:8082 in new window" -ForegroundColor Gray
Write-Host "  4. Type: .\bob-do.ps1 'analyze code'" -ForegroundColor Gray