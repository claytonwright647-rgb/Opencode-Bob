---
name: auto-learning
description: Automatic learning from every operation - learns success and failure patterns, preferences, and stores them permanently
metadata:
  audience: owner
  system: windows
---

# 🧠 AUTO-LEARNING SYSTEM

## What It Does

Opencode Bob **automatically learns from EVERY operation**:

| Learning Type | Trigger | Storage |
|--------------|---------|---------|
| **Success** | Operation completes successfully | patterns.json |
| **Failure** | Operation fails | errors.json |
| **Preference** | User preference expressed | preferences.json |
| **Pattern** | Repeated successful approach | patterns.json |

## How It Works

### After Every Operation
```
1. Operation completes
2. Call auto-learn.ps1 with context + result
3. Pattern strength updated
4. Success = +10%, Failure = reset to 0%
```

### Pattern Strength Evolution
```
First success:   50% strength
Repeated:        Increases toward 100%
Failed:          Decreases toward 0%
Unused (30d):    Decays by 10%
```

## Usage

### Learn from Operation
```powershell
# After successful operation
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Context "file-delete" -Result "success" -Details "Deleted 5 files safely"

# After failed operation
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Context "api-call" -Result "failure" -Details "Rate limited"
```

### Recall Patterns
```powershell
# What works for debugging?
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -recall -Context "debug"

# What works for file operations?
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -recall -Context "file"
```

### View Stats
```powershell
# Learning statistics
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Operation stats
```

## Key Learnings Today

| Context | Result | Details |
|---------|--------|---------|
| test-suite | success | 21 tests passed |
| copy-time-machine | success | From VSC Bob |
| create-knowledge-graph | success | Entity+relation system |
| create-parallel-agents | success | Multi-agent system |
| create-learning-engine | success | Pattern strength |
| test-parallel-agents | success | Fixed bug |

## What's Been Learned

- User prefers: practical, verbose output
- Successful approaches stored with strength
- Errors remembered for prevention

---
**Status:** Active Learning
**Sessions Learned:** 7+
**Pattern Strength:** Growing