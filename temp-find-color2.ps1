# Fast find and replace in binary
$exePath = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"

Write-Host "Reading file..."
$bytes = [System.IO.File]::ReadAllBytes($exePath)
Write-Host "File size: $($bytes.Length) bytes"

# Convert to string for fast search (simple ASCII subset)
$str = [System.Text.Encoding]::ASCII.GetString($bytes)

# Find all occurrences of [34m
$matches = @()
$idx = 0
while (($idx = $str.IndexOf("[34m", $idx)) -ge 0) {
    $matches += $idx
    $idx++
}

Write-Host "Found [34m at $($matches.Count) positions"
if ($matches.Count -gt 0) {
    Write-Host "First few: $($matches[0..[Math]::Min(5,$matches.Count-1)] -join ', ')"
}

# Try direct byte replacement
$blueBytes = [byte[]](0x1B, 0x5B, 0x33, 0x34, 0x6D)
$greenBytes = [byte[]](0x1B, 0x5B, 0x33, 0x32, 0x6D)

# Use .NET Replace for byte array
$byteList = [System.Collections.Generic.List[byte]]$bytes
$replacedCount = 0

for ($i = 0; $i -lt $bytes.Length - 5; $i++) {
    if ($bytes[$i] -eq 0x1B -and $bytes[$i+1] -eq 0x5B -and $bytes[$i+2] -eq 0x33 -and $bytes[$i+3] -eq 0x34 -and $bytes[$i+4] -eq 0x6D) {
        $bytes[$i+3] = 0x32  # Change 4 to 2 (blue 34 -> green 32)
        $replacedCount++
    }
}

if ($replacedCount -gt 0) {
    Write-Host "Replaced $replacedCount occurrences"
    [System.IO.File]::WriteAllBytes($exePath, $bytes)
    Write-Host "Written to disk"
} else {
    Write-Host "No matches found"
}