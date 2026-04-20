# BOB QUICK START
# Run this in a new Opencode CLI session to start Opencode Bob
# ====================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🤖 STARTING OPENCODE BOB" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Initialize Bob
Write-Host "[1/4] Initializing..." -ForegroundColor Gray
& "C:\Users\clayt\opencode-bob\init.ps1" | Out-Null

# 2. Load context
Write-Host "[2/4] Loading context..." -ForegroundColor Gray
& "C:\Users\clayt\opencode-bob\context-v2.ps1" -Operation status | Out-Null

# 3. Check identity
Write-Host "[3/4] Checking identity..." -ForegroundColor Gray
& "C:\Users\clayt\opencode-bob\personality.ps1" -Operation who

# 4. Show teams
Write-Host "[4/4] Loading agent teams..." -ForegroundColor Gray
& "C:\Users\clayt\opencode-bob\agent-teams.ps1" -Operation list | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🎯 BOB IS READY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Quick reference
Write-Host "📋 QUICK COMMANDS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Check my brain"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\self-model.ps1 -Operation list"
Write-Host ""
Write-Host "  # Start a task (set focus)"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\context-manager.ps1 -Operation focus -Item 'Task name'"
Write-Host ""
Write-Host "  # Show my thinking"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\thinking.ps1 -Operation start -Reason 'What you're doing'"
Write-Host ""
Write-Host "  # Use a team"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\agent-teams.ps1 -Operation use -TeamName research -Task 'task'"
Write-Host ""
Write-Host "  # Check goals"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\goal-tracker.ps1 -Operation list"
Write-Host ""
Write-Host "  # Self-evaluate"
Write-Host "  pwsh -File C:\Users\clayt\opencode-bob\self-evaluate.ps1 -Operation quality"
Write-Host ""

# Load project rules
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  📜 PROJECT RULES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path "C:\Users\clayt\opencode-bob\BOB-RULES.md") {
    Get-Content "C:\Users\clayt\opencode-bob\BOB-RULES.md" | Select-Object -First 30
}

Write-Host ""