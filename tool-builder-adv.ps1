# BOB'S DYNAMIC TOOL CREATION SYSTEM
# Create custom tools on-the-fly based on needs
# Advanced feature for self-improving agents

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "create",  # create, list, invoke, delete
    
    [Parameter(Mandatory=$false)]
    [string]$ToolName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ToolSpec = "",
    
    [Parameter(Mandatory=$false)]
    [object]$Arguments = @{}
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$TOOLS_DIR = "C:\Users\clayt\opencode-bob\memory\dynamic-tools"
$TOOLS_FILE = "$TOOLS_DIR\registered.json"

if (-not (Test-Path $TOOLS_DIR)) {
    New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
}

# ============================================================================
# STATE
# ============================================================================

function Get-ToolsState {
    if (Test-Path $TOOLS_FILE) {
        return Get-Content $TOOLS_FILE -Raw | ConvertFrom-Json
    }
    return @{ tools = @() }
}

function Save-ToolsState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $TOOLS_FILE
}

# ============================================================================
# CREATE TOOL
# ============================================================================

function New-Tool {
    param([string]$Name, [string]$Spec)
    
    $state = Get-ToolsState
    
    # Parse spec (JSON or simple format)
    $toolDef = @{
        name = $Name
        description = "Custom tool"
        action = "Write-Output 'Default action'"
    }
    
    try {
        if ($Spec -ne "") {
            $parsed = $Spec | ConvertFrom-Json
            if ($parsed.description) { $toolDef.description = $parsed.description }
            if ($parsed.action) { $toolDef.action = $parsed.action }
        }
    } catch {
        # Simple format: "description|action"
        $parts = $Spec -split "\|"
        if ($parts.Count -ge 2) {
            $toolDef.description = $parts[0].Trim()
            $toolDef.action = $parts[1].Trim()
        }
    }
    
    # Validate
    if ($toolDef.name -eq "") {
        return @{success=$false; reason="name_required"}
    }
    
    # Check exists
    foreach ($t in $state.tools) {
        if ($t.name -eq $Name) {
            return @{success=$false; reason="exists"}
        }
    }
    
    # Generate tool file
    $toolFile = "$TOOLS_DIR\$Name.ps1"
    
    # Create PowerShell script from spec
    $script = @"
# Dynamic Tool: $Name
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Description: $($toolDef.description)

param(
    [Parameter(Mandatory=`$false)]
    [string]`$Input = ""
)

`$ErrorActionPreference = "Continue"

# Tool implementation
$($toolDef.action)

# Return result
Write-Output "Completed: $Name"
"@
    
    $script | Set-Content $toolFile
    
    # Register tool
    $state.tools += @{
        name = $Name
        description = $toolDef.description
        file = $toolFile
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Save-ToolsState -State $state
    
    return @{
        success = $true
        name = $Name
        file = $toolFile
    }
}

# ============================================================================
# INVOKE TOOL
# ============================================================================

function Invoke-Tool {
    param([string]$Name, [object]$Args)
    
    $state = Get-ToolsState
    $tool = $null
    
    foreach ($t in $state.tools) {
        if ($t.name -eq $Name) {
            $tool = $t
            break
        }
    }
    
    if (-not $tool) {
        return @{success=$false; reason="not_found"}
    }
    
    # Execute tool
    $result = & $tool.file -Input ($Args | ConvertTo-Json)
    
    return @{
        success = $true
        name = $Name
        result = $result
    }
}

# ============================================================================
# LIST TOOLS
# ============================================================================

function Get-ToolList {
    $state = Get-ToolsState
    
    $tools = @()
    foreach ($t in $state.tools) {
        $tools += @{
            name = $t.name
            description = $t.description
            created = $t.created
        }
    }
    
    return @{
        tools = $tools
        count = $tools.Count
    }
}

# ============================================================================
# DELETE TOOL
# ============================================================================

function Remove-Tool {
    param([string]$Name)
    
    $state = Get-ToolsState
    $removed = $false
    
    $newTools = @()
    foreach ($t in $state.tools) {
        if ($t.name -eq $Name) {
            # Delete file
            if (Test-Path $t.file) {
                Remove-Item $t.file
            }
            $removed = $true
        } else {
            $newTools += $t
        }
    }
    
    if ($removed) {
        $state.tools = $newTools
        Save-ToolsState -State $state
    }
    
    return @{
        success = $removed
        name = $Name
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "create" {
        if ($ToolName -eq "" -or $ToolSpec -eq "") {
            Write-Error "ToolName and ToolSpec required"
        }
        New-Tool -Name $ToolName -Spec $ToolSpec
    }
    "list" {
        Get-ToolList
    }
    "invoke" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Invoke-Tool -Name $ToolName -Args $Arguments
    }
    "delete" {
        if ($ToolName -eq "") {
            Write-Error "ToolName required"
        }
        Remove-Tool -Name $ToolName
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}