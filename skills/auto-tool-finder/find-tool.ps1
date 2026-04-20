# Auto Tool Finder for Opencode Bob
# Searches ClawHub for skills and installs them automatically
# Usage: find-tool.ps1 -Query "search-term" [-Install "skill-slug"]

param(
    [string]$Query = "",
    [string]$Install = ""
)

$ErrorActionPreference = "Continue"

# Main execution
if ($Query) {
    Write-Host "`n🔍 Searching ClawHub for: $Query" -ForegroundColor Cyan
    npx -y clawhub search $Query --limit 5
}

if ($Install) {
    Write-Host "`n📦 Installing: $Install" -ForegroundColor Green
    npx -y clawhub install --dir C:/Users/clayt/opencode-bob/skills $Install
    Write-Host "✅ Done" -ForegroundColor Green
}

if (-not $Query -and -not $Install) {
    Write-Host "Auto Tool Finder - Usage:" -ForegroundColor Yellow
    Write-Host "  -Query 'search-term'    Search ClawHub"
    Write-Host "  -Install 'slug'      Install found skill"
}