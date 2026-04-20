# =============================================================================
# BOB'S AUTO-SYNC - STARTUP SCRIPT
# =============================================================================
# Run this to start continuous auto-sync on Windows startup
# Creates a scheduled task to run auto-sync.ps1 in background
# =============================================================================

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "     BOB'S AUTO-SYNC - SETUP" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "C:\Users\clayt\opencode-bob\auto-sync.ps1"
$taskName = "OpencodeBob-AutoSync"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] auto-sync.ps1 not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[SETUP] Creating scheduled task: $taskName" -ForegroundColor Cyan

# Create the scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Opencode Bob auto-sync to GitHub" -Force

Write-Host "[SETUP] ✅ Scheduled task created!" -ForegroundColor Green
Write-Host ""
Write-Host "  Task: $taskName" -ForegroundColor White
Write-Host "  Runs: On user logon" -ForegroundColor Gray
Write-Host "  Script: $scriptPath" -ForegroundColor Gray
Write-Host ""

# Also start it now
Write-Host "[SETUP] Starting auto-sync now..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    param($path)
    & $path
} -ArgumentList $scriptPath -Name "OpencodeBob-AutoSync"

Write-Host "[SETUP] ✅ Auto-sync is now running in background!" -ForegroundColor Green
Write-Host ""
Write-Host "  To stop: Get-Job -Name 'OpencodeBob-AutoSync' | Stop-Job" -ForegroundColor Gray
Write-Host "  To view: Get-Job -Name 'OpencodeBob-AutoSync'" -ForegroundColor Gray
Write-Host ""