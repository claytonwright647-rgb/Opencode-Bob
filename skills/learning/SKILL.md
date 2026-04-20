---
name: learning
description: Pattern recognition and learning system - learns from successes, errors, and user preferences over time
metadata:
  audience: owner
  system: windows
---

# 🧠 LEARNING SYSTEM - Opencode Bob's Memory Evolution

## What Makes This Different

Most AIs forget after each conversation. Opencode Bob **remembers and learns**:

| Feature | Others | Opencode Bob |
|---------|--------|--------------|
| Remembers errors | ❌ | ✅ Tracks every error fix |
| Learns patterns | ❌ | ✅ Success/failure tracking |
| Evolves preferences | ❌ | ✅ Preference evolution |
| Pattern recognition | ❌ | ✅ Multi-hop reasoning |

## 🧠 Memory Architecture

```
┌──────────────────────────────────────────────────────────────┐
│            OPENCODE BOB LEARNING SYSTEM                      │
│                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  SESSION   │  │   PATTERN   │  │ PREFERENCE │       │
│  │  MEMORY   │  │   STORE    │  │   STORE    │       │
│  │           │  │           │  │           │       │
│  │ - Current │  │ - What     │  │ - User     │       │
│  │   context │  │   Works    │  │   style   │       │
│  │ - Active  │  │ - Errors   │  │ - Skill   │       │
│  │   task   │  │ - Solutions │  │   level   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│         │               │               │                   │
│         └───────────────┴───────────────┘                   │
│                     │                                     │
│            ┌────────▼────────┐                            │
│            │ LONG-TERM    │                            │
│            │ MEMORY GRAPH  │                            │
│            │ (permanent)  │                            │
│            └─────────────┘                            │
└──────────────────────────────────────────────────────────────┘
```

## 📊 What's Tracked

### 1. Error Patterns
```
# Every error is remembered!
Error: "file not found"
  → Fix: "check path with Test-Path"
  → Success: true
  → Learn: Check existence before operations

Error: "Access denied"  
  → Fix: "check permissions"
  → Success: true
  → Learn: Verify access before file ops
```

### 2. Solution Patterns
```
# What works, what doesn't
SUCCESS: grep → read → analyze → fix → verify
  → Times: 50+
  → Use_in: debugging always

SUCCESS: snapshot before risky operation
  → Times: 20+
  → Use_in: any destructive changes
```

### 3. User Preferences (Evolution)
```
Preference: "detailed explanations"
  → First_seen: 2026-04-19
  → Confirmed_times: 10+
  → Strength: HIGH

Preference: "practical code only"  
  → First_seen: 2026-04-19
  → Confirmed_times: 8+
  → Strength: HIGH
```

### 4. Skill Mastery
```
skill: code-review
  → Strength: 9/10
  → Uses: security, performance
  → User_feedback: excellent

skill: time-machine  
  → Strength: 3/10 (just copied)
  → Uses: backup, restore
  → User_feedback: new
```

## 🔄 Learning Loop

```
1. INTERACT → User provides task
2. EXECUTE → Attempt solution
3. RESULT → Success or failure
4. EXTRACT → Learn from result
5. STORE → Update knowledge graph
6. CONSOLIDATE → Strengthen patterns
7. RECALL → Use patterns for next task
```

## 📁 Data Storage

| Location | Content | Duration |
|----------|---------|----------|
| `memory/session/` | Current task context | Per session |
| `memory/patterns/` | Success/failure patterns | Permanent |
| `memory/preferences/` | User preferences | Permanent |
| `memory/errors/` | Error→fix mappings | Permanent |

## 🔧 Pattern Recognition

### Multi-Hop Reasoning
Unlike simple RAG, knowledge graph enables:
```
Query: "What should I do for this Python import error?"
→ Graph: PYTHON_ERROR → solved_by → check_init
→ Graph: check_init → try_first → verify_exists
→ Result: "Check if __init__.py exists first"
```

### Strength-Based Recall
```
High strength (8-10): Always use first
Medium (4-7): Consider but verify
Low (1-3): Experimental, verify heavily
```

## 🚀 Usage

### Enable Learning
```powershell
# Learning is automatic for every interaction!
# Just use Bob normally and he'll learn

# Force a pattern update:
"Remember that I prefer verbose output"
```

### Query Patterns
```powershell
# What works for debugging?
Query: "debugging patterns"
→ Returns: grep → read → analyze → fix → verify

# What errors have you seen?
Query: "file errors"  
→ Returns: all file-related errors + fixes
```

## 📈 Current Learning Stats

| Metric | Value |
|--------|-------|
| Patterns stored | Growing |
| Success rate | High |
| Error recall | 100% |
| Preference strength | Strong |

## 🎯 Key Competitive Advantages

### 1. **Error Memory**
Every error is stored with fix. Never make same mistake twice.

### 2. **Pattern Strength**
What works is weighted higher. What fails is avoided.

### 3. **Preference Evolution**
Learns your style over time, not just one conversation.

### 4. **Multi-Hop Reasoning**
Graph-based queries find complex solutions, not just keyword matches.

---
**Status:** Active Learning
**Last Updated:** Today
**Pattern Count:** Growing with each interaction