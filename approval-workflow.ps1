# BOB'S HUMAN-IN-THE-LOOP APPROVAL SYSTEM
# Approval workflows for sensitive or irreversible actions
# Inspired by production agent patterns

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "request",  # request, approve, deny, list, status
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Risk = "medium",  # low, medium, high, critical
    
    [Parameter(Mandatory=$false)]
    [string]$RequestId = ""
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$APPROVAL_DIR = "C:\Users\clayt\opencode-bob\memory\approvals"
$REQUESTS_FILE = "$APPROVAL_DIR\pending.json"
$HISTORY_FILE = "$APPROVAL_DIR\history.json"

if (-not (Test-Path $APPROVAL_DIR)) {
    New-Item -ItemType Directory -Force -Path $APPROVAL_DIR | Out-Null
}

# ============================================================================
# RISK LEVELS
# ============================================================================

$RISK_LEVELS = @{
    low = @{
        autoApprove = $true
        description = "Safe actions, no confirmation needed"
        confirmBefore = $false
    }
    medium = @{
        autoApprove = $false
        description = "Should confirm before proceeding"
        confirmBefore = $true
    }
    high = @{
        autoApprove = $false
        description = "Requires explicit approval"
        confirmBefore = $true
    }
    critical = @{
        autoApprove = $false
        description = "Must have human in the loop"
        confirmBefore = $true
    }
}

# Auto-approve certain patterns
$ALWAYS_DENY = @(
    "delete *",
    "drop table",
    "rm -rf",
    "format drive"
)

# ============================================================================
# STATE
# ============================================================================

function Get-ApprovalState {
    if (Test-Path $REQUESTS_FILE) {
        return Get-Content $REQUESTS_FILE -Raw | ConvertFrom-Json
    }
    return @{ pending = @() }
}

function Save-ApprovalState {
    param([object]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $REQUESTS_FILE
}

# ============================================================================
# REQUEST APPROVAL
# ============================================================================

function Request-Approval {
    param([string]$Action, [string]$Risk)
    
    $riskLevel = $RISK_LEVELS[$Risk]
    
    # Check if always denied
    foreach ($pattern in $ALWAYS_DENY) {
        if ($Action -like $pattern) {
            return @{
                success = $false
                reason = "always_denied"
                action = $Action
            }
        }
    }
    
    # Check auto-approve for low risk
    if ($riskLevel.autoApprove) {
        return @{
            success = $true
            approved = $true
            reason = "auto_approved"
            risk = $Risk
        }
    }
    
    # Create approval request
    $state = Get-ApprovalState
    $id = "req_" + (Get-Random -Maximum 100000)
    
    $request = @{
        id = $id
        action = $Action
        risk = $Risk
        status = "pending"
        requested = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $state.pending += $request
    Save-ApprovalState -State $state
    
    return @{
        success = $true
        approved = $false
        requestId = $id
        reason = "approval_required"
        risk = $Risk
        message = "Please approve: $Action (Risk: $Risk)"
    }
}

# ============================================================================
# APPROVE REQUEST
# ============================================================================

function Approve-Request {
    param([string]$Id)
    
    $state = Get-ApprovalState
    $approved = $false
    
    foreach ($req in $state.pending) {
        if ($req.id -eq $Id) {
            $req.status = "approved"
            $req.approved = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $approved = $true
            break
        }
    }
    
    if ($approved) {
        # Save to history
        $history = @()
        if (Test-Path $HISTORY_FILE) {
            $history = Get-Content $HISTORY_FILE -Raw | ConvertFrom-Json
            if (-not ($history -is [array])) { $history = @($history) }
        }
        $history += $state.pending | Where-Object { $_.id -eq $Id }
        $history | ConvertTo-Json -Depth 10 | Set-Content $HISTORY_FILE
        
        # Remove from pending
        $state.pending = $state.pending | Where-Object { $_.id -ne $Id }
        Save-ApprovalState -State $state
    }
    
    return @{
        success = $approved
        requestId = $Id
        status = "approved"
    }
}

# ============================================================================
# DENY REQUEST
# ============================================================================

function Deny-Request {
    param([string]$Id)
    
    $state = Get-ApprovalState
    $denied = $false
    
    foreach ($req in $state.pending) {
        if ($req.id -eq $Id) {
            $req.status = "denied"
            $req.denied = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $denied = $true
            break
        }
    }
    
    if ($denied) {
        # Save to history
        $history = @()
        if (Test-Path $HISTORY_FILE) {
            $history = Get-Content $HISTORY_FILE -Raw | ConvertFrom-Json
            if (-not ($history -is [array])) { $history = @($history) }
        }
        $history += $state.pending | Where-Object { $_.id -eq $Id }
        $history | ConvertTo-Json -Depth 10 | Set-Content $HISTORY_FILE
        
        # Remove from pending
        $state.pending = $state.pending | Where-Object { $_.id -ne $Id }
        Save-ApprovalState -State $state
    }
    
    return @{
        success = $denied
        requestId = $Id
        status = "denied"
    }
}

# ============================================================================
# LIST PENDING
# ============================================================================

function Get-PendingRequests {
    $state = Get-ApprovalState
    
    $pending = @()
    foreach ($req in $state.pending) {
        $pending += @{
            id = $req.id
            action = $req.action
            risk = $req.risk
            requested = $req.requested
        }
    }
    
    return @{
        pending = $pending
        count = $pending.Count
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-ApprovalStatus {
    $state = Get-ApprovalState
    $history = @()
    if (Test-Path $HISTORY_FILE) {
        $history = Get-Content $HISTORY_FILE -Raw | ConvertFrom-Json
        if ($history -is [array]) { $history = $history }
        else { $history = @($history) }
    }
    
    return @{
        pending = $state.pending.Count
        total = $history.Count
        riskLevels = $RISK_LEVELS.Keys
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "request" {
        if ($Action -eq "") {
            Write-Error "Action required"
        }
        Request-Approval -Action $Action -Risk $Risk
    }
    "approve" {
        if ($RequestId -eq "") {
            Write-Error "RequestId required"
        }
        Approve-Request -Id $RequestId
    }
    "deny" {
        if ($RequestId -eq "") {
            Write-Error "RequestId required"
        }
        Deny-Request -Id $RequestId
    }
    "list" {
        Get-PendingRequests
    }
    "status" {
        Get-ApprovalStatus
    }
    "risk" {
        $RISK_LEVELS
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}