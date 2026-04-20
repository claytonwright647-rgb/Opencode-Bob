---
name: autonomous
description: Autonomous automation hooks - automatic snapshots, error recovery, and proactive assistance
metadata:
  audience: owner
  system: windows
---

# 🤖 AUTONOMOUS OPERATION SYSTEM

## What Makes This Special

Opencode Bob operates **autonomously** - not just when you ask:

| Feature | Manual Only | Opencode Bob |
|---------|------------|-------------|
| Auto snapshot | ❌ | ✅ Before risky ops |
| Error recovery | ❌ | ✅ Remembers fixes |
| Proactive help | ❌ | ✅ Suggests improvements |
| Background tasks | ❌ | ✅ Scheduled runs |
| Learning | ❌ | ✅ Continuous |

## ⚡ Automatic Behaviors

### 1. Auto Snapshot
```powershell
# BEFORE any destructive operation:
# - file deletion
# - registry changes  
# - service stops
# - bulk modifications
# → Creates automatic backup first!
```

### 2. Error Prevention
```powershell
# If error pattern recognized:
# - Missing file → Check exists first
# - Permission denied → Verify access
# - Import error → Check __init__.py
# - Syntax error → Validate before run
```

### 3. Proactive Suggestions
```powershell
# When pattern detected:
# - Old approach → Suggest better way
# - Known error → Warn and suggest fix
# - Missing test → Suggest adding tests
```

### 4. Scheduled Operations
```powershell
# Automatic Time Machine snapshots:
# - Every 15 minutes when active
# - 6-month retention
# - Full logging
```

## 🎯 Hook Points

### Pre-Execution Hooks
```powershell
BEFORE:
  - Delete → Snapshot first
  - Modify → Check backup exists
  - Run test → Record state
  - API call → Validate inputs
```

### Post-Execution Hooks
```powershell
AFTER:
  - Success → Store pattern
  - Failure → Store error + fix
  - Warning → Note for review
  - Timeout → Log + retry strategy
```

### Error Recovery Hooks
```powershell
ON ERROR:
  - Retry with adjustment
  - Use known fix from memory
  - Snapshot before major changes
  - Escalate to user
```

## 📦 Implementation

### Auto-Snapshot Hook
```powershell
# Triggered automatically when:
# - Using Remove-Item
# - Using Set-Content (bulk)
# - Stop-Service
# - Registry modifications

function Pre-Destructive {
    # Create snapshot automatically
    & $SCRIPT:time-machine.ps1 -Label "Auto-Before-$Operation" -Type "Auto"
}
```

### Error Recovery Hook
```powershell
function On-Error($error, $context) {
    # Check knowledge graph for known fixes
    $fix = Get-KnownFix $error
    
    if ($fix) {
        # Try known fix automatically
        Apply-Fix $fix
        # Log success/failure
        Learn-From-Result $fix $success
    }
}
```

## 🚀 Usage

### Enable Autonomous Mode
```powershell
# Autonomous is default!
# Just work normally and Bob helps automatically

# Manual trigger:
"Enable autonomous mode"
```

### Configure Hooks
```powershell
# Which hooks to enable:
$AUTONOMOUS = @(
    "auto-snapshot",      # Always backup
    "error-prevention",   # Check first
    "proactive-help",     # Suggest improvements
    "scheduled-backup"   # Time Machine
)
```

### Manual Override
```powershell
# Disable for specific operation:
"Work without autonomous mode"

# Enable specific hook:
"Only auto-snapshot, no proactive"
```

## 📊 Hook Status

| Hook | Status | Times Triggered |
|------|--------|-----------------|
| auto-snapshot | ✅ Active | Today: 1 |
| error-prevention | ✅ Active | Today: 0 |
| proactive-help | ✅ Active | Today: 0 |
| scheduled-backup | ��� Active | Today: ~50 |

## 🎯 Competitive Advantage

### vs Claude Code
- Claude: Manual / one-shot
- Opencode Bob: Auto + continuous learning

### vs ChatGPT
- ChatGPT: No memory between sessions
- Opencode Bob: Permanent memory graph

### vs Cursor
- Cursor: IDE-focused only
- Opencode Bob: Full system control + automation

### vs OpenClaw
- OpenClaw: Similar automation
- Opencode Bob: Different platform + local Ollama models

---
**Status:** Active
**Hooks Enabled:** All
**Auto-Snapshots:** ~50 today