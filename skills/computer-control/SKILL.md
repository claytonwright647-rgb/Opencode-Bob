---
name: computer-control
description: COMPLETE computer control - see everything, do everything on your computer
license: MIT
metadata:
  audience: owner
  system: windows
---

# 🤖 COMPUTER CONTROL SKILL - COMPLETE ACCESS

## 🎯 CAPABILITIES (EVERYTHING!)

### 👁️ SEE EVERYTHING

| Capability | Command | Description |
|------------|---------|-------------|
| **Screenshots** | `screenshot` or `capture` | Take screenshot of screen |
| **Window List** | `list_windows` | See all open windows |
| **Process List** | `Get-Process` | See all running processes |
| **File Explorer** | `Get-ChildItem` | Browse any folder |
| **System Info** | `Get-ComputerInfo` | Full system details |
| **Network** | `Get-NetAdapter` | Network status |
| **Registry** | `Get-ItemProperty` | Read registry |

### 🖱️ DO EVERYTHING

| Capability | Command | Examples |
|------------|---------|----------|
| **Mouse** | PyAutoGUI | click, move, drag |
| **Keyboard** | PyAutoGUI | type, press keys, shortcuts |
| **Launch Apps** | `Start-Process` | Open any app |
| **Window Control** | Win32 API | minimize, maximize, close |
| **File Operations** | All | read, write, copy, move, delete |
| **Registry** | Win32 | read, write, modify |
| **Services** | `Get-Service`, `Start-Service` | manage Windows services |
| **Processes** | `Start`, `Stop-Process` | control anything |
| **System Settings** | PowerShell | change any setting |
| **Network** | `Test-NetConnection` | ping, ports |

### 🛠️ COMPLETE TOOLKIT

```powershell
# SCREEN - Take screenshot
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen

# MOUSE - Control
import pyautogui
pyautogui.click(x, y)
pyautogui.typewrite("text")
pyautogui.hotkey("ctrl", "c")

# WINDOWS - Window management  
Get-Process | Select-Object Name, Id, CPU
Get-Window | Select-Object Title, Process

# FILES - Full access
Get-ChildItem -Path C:/ -Recurse -File
Copy-Item, Move-Item, Remove-Item

# REGISTRY - Full access
Get-ItemProperty -Path HKLM:/SOFTWARE/
Set-ItemProperty -Path HKCU:/...

# SERVICES - Control
Get-Service | Where-Object Status -eq Running
Start-Service -Name "ServiceName"
Stop-Service -Name "ServiceName"

# PROCESSES - Full control
Start-Process "notepad.exe"
Stop-Process -Name "notepad"
Stop-Process -Id 1234

# NETWORK
Test-NetConnection -ComputerName google.com -Port 80
Get-NetIPConfiguration
```

## 🔧 WINDOWS AUTOMATION TOOLS

### WinRemote-MCP Installed!
Installed: `winremote-mcp` (40+ tools)

### Tools Available:
```
- mouse_move, mouse_click, mouse_drag
- keyboard_type, keyboard_hotkey
- screenshot, screen_capture
- window_list, window_find, window_focus
- file_read, file_write, file_copy, file_delete
- registry_get, registry_set
- service_list, service_start, service_stop
- process_list, process_kill
- network_ping, network_ports
- and 40+ more!
```

## ⚡ COMMANDS TO USE

### Basic Examples:
```powershell
# See what's on screen
.\bob-do.ps1 "take a screenshot"

# Open an app
.\bob-do.ps1 "open notepad"

# Control an app
.\bob-do.ps1 "click the close button in notepad"

# Find files anywhere
.\bob-do.ps1 "find all .py files on my computer"

# See processes
.\bob-do.ps1 "show all running processes"

# Kill a process
.\bob-do.ps1 "close chrome"

# Get system info
.\bob-do.ps1 "give me full system information"

# Control Windows
.\bob-do.ps1 "disable windows defender"

# Registry
.\bob-do.ps1 "read registry key HKLM:/SOFTWARE/Microsoft"
```

## 🚫 SAFETY

⚠️ **WITH GREAT POWER COMES GREAT RESPONSIBILITY**

Rules:
1. ASK before destructive actions
2. BACKUP before registry/system changes
3. CONFIRM before stopping critical services
4. VERIFY before deleting files

Protected: `C:\Users\clayt\OneDrive\Documents\02_VA\` - NEVER touch!

## 📦 DEPENDENCIES INSTALLED

- `winremote-mcp` - Complete Windows control (40+ tools)
- `pyautogui` - Mouse/keyboard automation  
- `psutil` - Process/system info
- `pywin32` - Windows API access

## 🎬 USAGE

```powershell
# Start MCP server manually if needed:
winremote-mcp

# Or use PowerShell directly:
Get-Process
Start-Process
Get-WindowsOptionalFeature
```

---

**COMPUTER IS NOW FULLY ACCESSIBLE!**
**EVERYTHING you can do, BOB CAN TOO!**