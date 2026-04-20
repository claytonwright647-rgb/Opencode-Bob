[Console]::OutputEncoding = [System.Text.Encoding]::ASCII
$exe = "C:\Users\clayt\AppData\Roaming\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"
$content = [System.IO.File]::ReadAllText($exe)
$newContent = $content.Replace("[34m", "[32m")
[System.IO.File]::WriteAllText($exe, $newContent)
Write-Host "Done - blue changed to green"