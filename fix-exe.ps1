$src = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"
$dst = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode-new.exe"

Write-Host "Reading..."
$content = [System.IO.File]::ReadAllText($src)
Write-Host "Replacing..."
$newContent = $content.Replace("[34m", "[32m")
Write-Host "Writing to new file..."
[System.IO.File]::WriteAllText($dst, $newContent)
Write-Host "Copying..."
Copy-Item $dst $src -Force
Remove-Item $dst
Write-Host "Done!"