# BOB'S SESSION CHECKPOINT SYSTEM
# Save and resume agent state across sessions
# Inspired by LangGraph checkpointing

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "save",  # save, restore, list, status
    
    [Parameter(Mandatory=$false)]
    [string]$SessionName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Data = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$CHECKPOINT_DIR = "C:\Users\clayt\opencode-bob\memory\checkpoints"
$CHECKPOINT_INDEX = "$CHECKPOINT_DIR\index.json"

if (-not (Test-Path $CHECKPOINT_DIR)) {
    New-Item -ItemType Directory -Force -Path $CHECKPOINT_DIR | Out-Null
}

# ============================================================================
# STATE
# ============================================================================

function Get-CheckpointIndex {
    if (Test-Path $CHECKPOINT_INDEX) {
        return Get-Content $CHECKPOINT_INDEX -Raw | ConvertFrom-Json
    }
    return @{ checkpoints = @() }
}

function Save-CheckpointIndex {
    param([object]$Index)
    $Index | ConvertTo-Json -Depth 10 | Set-Content $CHECKPOINT_INDEX
}

# ============================================================================
# SAVE CHECKPOINT
# ============================================================================

function Save-Checkpoint {
    param([string]$Name, [string]$Data)
    
    $index = Get-CheckpointIndex
    
    # Generate checkpoint ID
    $checkpointId = "cp_" + (Get-Date -Format "yyyyMMddHHmmss") + "_" + (Get-Random -Maximum 10000)
    
    # Create checkpoint file
    $checkpointFile = "$CHECKPOINT_DIR\$checkpointId.json"
    
    # Capture current state
    $state = @{
        id = $checkpointId
        name = $Name
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        context = @{}
        workingDirectory = "C:/Users/clayt/opencode-bob"
        files = @{}
        variables = @{}
    }
    
    # Capture working context if available
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json") {
        $state.context = Get-Content "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    }
    
    # Capture goal state
    if (Test-Path "C:\Users\clayt\opencode-bob\memory\sessions\goals.json") {
        $state.goals = Get-Content "C:\Users\clayt\opencode-bob\memory\sessions\goals.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    }
    
    # Save checkpoint
    $state | ConvertTo-Json -Depth 10 | Set-Content $checkpointFile
    
    # Add to index
    $index.checkpoints += @{
        id = $checkpointId
        name = $Name
        timestamp = $state.timestamp
        file = $checkpointFile
    }
    Save-CheckpointIndex -Index $index
    
    return @{
        success = $true
        checkpointId = $checkpointId
        name = $Name
        saved = $state.timestamp
        file = $checkpointFile
    }
}

# ============================================================================
# RESTORE CHECKPOINT
# ============================================================================

function Restore-Checkpoint {
    param([string]$Name)
    
    $index = Get-CheckpointIndex
    
    # Find latest checkpoint for this session
    $matching = $index.checkpoints | Where-Object { $_.name -eq $Name } | Sort-Object timestamp -Descending
    
    if ($matching.Count -eq 0) {
        return @{ success = $false; reason = "not_found" }
    }
    
    $checkpoint = $matching[0]
    
    # Load checkpoint state
    if (-not (Test-Path $checkpoint.file)) {
        return @{ success = $false; reason = "file_missing" }
    }
    
    $state = Get-Content $checkpoint.file -Raw | ConvertFrom-Json
    
    # Restore context
    if ($state.context) {
        $state.context | ConvertTo-Json -Depth 10 | Set-Content "C:\Users\clayt\opencode-bob\memory\sessions\working-context.json"
    }
    
    return @{
        success = $true
        checkpointId = $checkpoint.id
        name = $Name
        restored = $state.timestamp
        files = $state.files.Keys
    }
}

# ============================================================================
# LIST CHECKPOINTS
# ============================================================================

function Get-CheckpointList {
    $index = Get-CheckpointIndex
    
    $checkpoints = @()
    foreach ($cp in $index.checkpoints) {
        $checkpoints += @{
            id = $cp.id
            name = $cp.name
            timestamp = $cp.timestamp
            age = ((Get-Date) - [DateTime]::Parse($cp.timestamp)).TotalMinutes
        }
    }
    
    return @{
        checkpoints = $checkpoints
        total = $checkpoints.Count
    }
}

# ============================================================================
# GET HISTORY
# ============================================================================

function Get-SessionHistory {
    param([string]$Name)
    
    $index = Get-CheckpointIndex
    $matching = $index.checkpoints | Where-Object { $_.name -eq $Name }
    
    $history = @()
    foreach ($cp in $matching | Sort-Object timestamp -Descending) {
        $history += @{
            id = $cp.id
            timestamp = $cp.timestamp
        }
    }
    
    return @{
        session = $Name
        checkpoints = $history
        count = $history.Count
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "save" {
        if ($SessionName -eq "") {
            Write-Error "SessionName required"
        }
        Save-Checkpoint -Name $SessionName -Data $Data
    }
    "restore" {
        if ($SessionName -eq "") {
            Write-Error "SessionName required"
        }
        Restore-Checkpoint -Name $SessionName
    }
    "list" {
        Get-CheckpointList
    }
    "history" {
        if ($SessionName -eq "") {
            Write-Error "SessionName required"
        }
        Get-SessionHistory -Name $SessionName
    }
    "status" {
        $index = Get-CheckpointIndex
        @{totalCheckpoints = $index.checkpoints.Count}
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}