# BOB'S RESOURCE MONITOR
# Track and limit resource usage for safety
# Inspired by AI sandbox best practices

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status",  # status, check, limit, reset
    
    [Parameter(Mandatory=$false)]
    [string]$Resource = "",  # cpu, memory, network, disk
    
    [Parameter(Mandatory=$false)]
    [int]$Value = 0
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$RESOURCE_FILE = "C:\Users\clayt\opencode-bob\memory\resources.json"

# Default limits (matches best practices from research)
$LIMITS = @{
    cpu = @{
        value = 2  # 2 cores
        unit = "cores"
        description = "CPU cores"
    }
    memory = @{
        value = 512  # 512 MB
        unit = "MB"
        description = "Memory limit"
    }
    disk = @{
        value = 100  # 100 MB
        unit = "MB"
        description = "Disk writes per operation"
    }
    network = @{
        value = 10  # 10 MB
        unit = "MB"
        description = "Network bandwidth"
    }
    runtime = @{
        value = 30  # 30 seconds
        unit = "seconds"
        description = "Wall-clock time per operation"
    }
    fileSize = @{
        value = 10  # 10 MB
        unit = "MB"
        description = "Max single file size"
    }
}

# ============================================================================
# STATE
# ============================================================================

function Get-ResourceState {
    if (Test-Path $RESOURCE_FILE) {
        return Get-Content $RESOURCE_FILE -Raw | ConvertFrom-Json
    }
    return @{
        limits = $LIMITS
        current = @{
            cpu = 0
            memory = 0
            disk = 0
            network = 0
            runtime = 0
        }
        history = @()
    }
}

function Save-ResourceState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $RESOURCE_FILE
}

# ============================================================================
# CHECK LIMIT
# ============================================================================

function Test-ResourceLimit {
    param([string]$Res, [int]$Value)
    
    $state = Get-ResourceState
    $limit = $state.limits[$Res]
    
    if (-not $limit) {
        return @{
            allowed = $true
            reason = "unknown_resource"
        }
    }
    
    $allowed = $Value -le $limit.value
    
    return @{
        allowed = $allowed
        resource = $Res
        requested = $Value
        limit = $limit.value
        unit = $limit.unit
        reason = if ($allowed) { "within_limit" } else { "exceeds_limit" }
    }
}

# ============================================================================
# UPDATE LIMIT
# ============================================================================

function Update-Limit {
    param([string]$Res, [int]$NewValue)
    
    if (-not $LIMITS[$Res]) {
        return @{ success = $false; reason = "unknown_resource" }
    }
    
    $state = Get-ResourceState
    $state.limits[$Res].value = $NewValue
    $state.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ResourceState -State $state
    
    return @{
        success = $true
        resource = $Res
        newLimit = $NewValue
        unit = $state.limits[$Res].unit
    }
}

# ============================================================================
# RECORD USAGE
# ============================================================================

function Record-Usage {
    param([string]$Res, [int]$Value)
    
    $state = Get-ResourceState
    $state.current.$Res = $Value
    $state.lastUsed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ResourceState -State $state
    
    return @{
        recorded = $true
        resource = $Res
        value = $Value
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-ResourceStatus {
    $state = Get-ResourceState
    
    return @{
        limits = $state.limits
        current = $state.current
        lastUsed = $state.lastUsed
        lastUpdated = $state.lastUpdated
    }
}

# ============================================================================
# RESET
# ============================================================================

function Reset-Resources {
    $state = Get-ResourceState
    $state.current = @{
        cpu = 0
        memory = 0
        disk = 0
        network = 0
        runtime = 0
    }
    $state.lastReset = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-ResourceState -State $state
    
    return @{ success = $true; message = "Resources reset" }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "status" {
        Get-ResourceStatus
    }
    "check" {
        if ($Resource -eq "" -or $Value -eq 0) {
            Write-Error "Resource and Value required"
        }
        Test-ResourceLimit -Res $Resource -Value $Value
    }
    "limit" {
        if ($Resource -eq "" -or $Value -eq 0) {
            Write-Error "Resource and Value required"
        }
        Update-Limit -Res $Resource -NewValue $Value
    }
    "record" {
        if ($Resource -eq "" -or $Value -eq 0) {
            Write-Error "Resource and Value required"
        }
        Record-Usage -Res $Resource -Value $Value
    }
    "reset" {
        Reset-Resources
    }
    "defaults" {
        $LIMITS
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}