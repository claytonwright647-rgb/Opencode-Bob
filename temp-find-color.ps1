# Temp script to find and replace color in opencode.exe
$exePath = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"
$bytes = [System.IO.File]::ReadAllBytes($exePath)

# ANSI blue is ESC [ 3 4 m = 0x1B 0x5B 0x33 0x34 0x6D
# ANSI green is ESC [ 3 2 m = 0x1B 0x5B 0x33 0x32 0x6D
$bluePattern = [byte[]](0x1B, 0x5B, 0x33, 0x34, 0x6D)
$greenPattern = [byte[]](0x1B, 0x5B, 0x33, 0x32, 0x6D)

$foundPositions = @()
for ($i = 0; $i -lt $bytes.Length - $bluePattern.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $bluePattern.Length; $j++) {
        if ($bytes[$i + $j] -ne $bluePattern[$j]) {
            $match = $false
            break
        }
    }
    if ($match) {
        $foundPositions += $i
    }
}

Write-Host "Found ANSI blue [34m at positions: $($foundPositions -join ', ')"

if ($foundPositions.Count -gt 0) {
    # Replace all blue with green
    foreach ($pos in $foundPositions) {
        for ($j = 0; $j -lt $greenPattern.Length; $j++) {
            $bytes[$pos + $j] = $greenPattern[$j]
        }
    }

    # Write back
    [System.IO.File]::WriteAllBytes($exePath, $bytes)
    Write-Host "Replaced $($foundPositions.Count) occurrences with green [32m"
} else {
    Write-Host "No blue ANSI code found - may use different encoding"
}