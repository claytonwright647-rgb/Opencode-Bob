# Ultra-fast binary replacement
$exePath = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"
$backupPath = $exePath + ".backup"

Write-Host "Reading..."
$bytes = [System.IO.File]::ReadAllBytes($exePath)

# Convert to ASCII string, replace, convert back
$str = [System.Text.Encoding]::ASCII.GetString($bytes)
$newStr = $str.Replace("[34m", "[32m")

Write-Host "Replacing [34m -> [32m"
$count = ($str.ToCharArray() | Where-Object { $_ -eq "[" }).Count
Write-Host "Replaced"

# Write directly
[System.IO.File]::WriteAllBytes($exePath, [System.Text.Encoding]::ASCII.GetBytes($newStr))
Write-Host "Done!"