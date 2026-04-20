# Computer Control Quick Commands for Bob
# Use these to control the computer

param(
    [string]$Action = "list"
)

$ErrorActionPreference = "Continue"

switch ($Action.ToLower()) {
    "screenshot" {
        Add-Type -AssemblyName System.Windows.Forms
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        $path = "C:/Users/clayt/opencode-bob/screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        $bitmap.Save($path)
        $graphics.Dispose()
        $bitmap.Dispose()
        Write-Host "[SCREENSHOT] Saved: $path"
    }
    
    "processes" {
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name, Id, CPU, WorkingSet | Format-Table
    }
    
    "windows" {
        Get-Process | Where-Object {$_.MainWindowTitle} | Select-Object Id, MainWindowTitle, ProcessName | Format-Table
    }
    
    "systeminfo" {
        $computer = Get-ComputerInfo
        Write-Host "=== SYSTEM INFO ==="
        Write-Host "OS: $($computer.OsName)"
        Write-Host "Version: $($computer.OsVersion)"
        Write-Host "Computer: $($computer.CsName)"
        Write-Host "CPU: $($computer.CsProcessors.Name)"
        Write-Host "RAM: $([math]::Round($computer.CsTotalPhysicalMemory/1GB, 2)) GB"
    }
    
    "network" {
        Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv6Address | Format-Table
    }
    
    "services" {
        Get-Service | Where-Object Status -eq Running | Select-Object -First 20 Name, Status, DisplayName | Format-Table
    }
    
    "disks" {
        Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel, SizeRemaining, Size | Format-Table
    }
    
    default {
        Write-Host "Bob Computer Control Commands:"
        Write-Host "  computer-control screenshot   - Take screenshot"
        Write-Host "  computer-control processes  - List top processes"
        Write-Host "  computer-control windows     - List open windows"
        Write-Host "  computer-control systeminfo - System information"
        Write-Host "  computer-control network    - Network info"
        Write-Host "  computer-control services - Running services"
        Write-Host "  computer-control disks    - Disk info"
    }
}