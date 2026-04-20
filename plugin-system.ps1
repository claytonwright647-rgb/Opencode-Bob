# BOB'S PLUGIN SYSTEM
# Extensible plugins for Bob

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "install",  # install, list, enable, disable, unload
    
    [Parameter(Mandatory=$false)]
    [string]$PluginName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PluginSource = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$PLUGIN_DIR = "C:\Users\clayt\opencode-bob\plugins"
$PLUGIN_INDEX = "$PLUGIN_DIR\index.json"

if (-not (Test-Path $PLUGIN_DIR)) {
    New-Item -ItemType Directory -Force -Path $PLUGIN_DIR | Out-Null
}

# ============================================================================
# PLUGIN STRUCTURE
# ============================================================================

$PLUGIN_SCHEMA = @{
    name = ""
    version = "1.0"
    description = ""
    author = ""
    dependencies = @()
    hooks = @()  # pre_tool, post_tool, etc.
    tools = @()   # Additional tools provided
    skills = @() # Skills provided
}

# ============================================================================
# STATE
# ============================================================================

function Get-PluginIndex {
    if (Test-Path $PLUGIN_INDEX) {
        return Get-Content $PLUGIN_INDEX -Raw | ConvertFrom-Json
    }
    return @{ installed = @(); enabled = @() }
}

function Save-PluginIndex {
    param([object]$Index)
    $Index | ConvertTo-Json -Depth 10 | Set-Content $PLUGIN_INDEX
}

# ============================================================================
# INSTALL PLUGIN
# ============================================================================

function Install-Plugin {
    param([string]$Name, [string]$Source)
    
    $index = Get-PluginIndex
    
    # Check if already installed
    foreach ($p in $index.installed) {
        if ($p.name -eq $Name) {
            return @{ success = $false; reason = "already_installed" }
        }
    }
    
    # Create plugin directory
    $pluginDir = "$PLUGIN_DIR\$Name"
    if (-not (Test-Path $pluginDir)) {
        New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null
    }
    
    # Create basic plugin structure
    $plugin = @{
        name = $Name
        source = $Source
        version = "1.0"
        installed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        enabled = $true
    }
    
    $pluginFile = "$pluginDir\plugin.json"
    $plugin | ConvertTo-Json -Depth 10 | Set-Content $pluginFile
    
    # Add to index
    $index.installed += $plugin
    $index.enabled += $Name
    Save-PluginIndex -Index $index
    
    return @{
        success = $true
        name = $Name
        installed = $plugin.installed
    }
}

# ============================================================================
# ENABLE/DISABLE PLUGIN
# ============================================================================

function Set-PluginEnabled {
    param([string]$Name, [bool]$Enabled)
    
    $index = Get-PluginIndex
    $found = $false
    
    foreach ($p in $index.installed) {
        if ($p.name -eq $Name) {
            $p.enabled = $Enabled
            $found = $true
        }
    }
    
    if ($found) {
        if ($Enabled -and $Name -notin $index.enabled) {
            $index.enabled += $Name
        } elseif (-not $Enabled -and $Name -in $index.enabled) {
            $index.enabled = $index.enabled | Where-Object { $_ -ne $Name }
        }
        Save-PluginIndex -Index $index
    }
    
    return @{
        success = $found
        name = $Name
        enabled = $Enabled
    }
}

# ============================================================================
# LIST PLUGINS
# ============================================================================

function Get-PluginList {
    $index = Get-PluginIndex
    
    $installed = @()
    foreach ($p in $index.installed) {
        $installed += @{
            name = $p.name
            version = $p.version
            enabled = $p.enabled
            installed = $p.installed
        }
    }
    
    return @{
        installed = $installed
        enabled = $index.enabled
        count = $installed.Count
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "install" {
        if ($PluginName -eq "") {
            Write-Error "PluginName required"
        }
        Install-Plugin -Name $PluginName -Source $PluginSource
    }
    "list" {
        Get-PluginList
    }
    "enable" {
        if ($PluginName -eq "") {
            Write-Error "PluginName required"
        }
        Set-PluginEnabled -Name $PluginName -Enabled $true
    }
    "disable" {
        if ($PluginName -eq "") {
            Write-Error "PluginName required"
        }
        Set-PluginEnabled -Name $PluginName -Enabled $false
    }
    "status" {
        $index = Get-PluginIndex
        @{
            totalInstalled = $index.installed.Count
            totalEnabled = $index.enabled.Count
        }
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}