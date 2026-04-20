---
name: knowledge-graph
description: Advanced knowledge graph memory system with entities and relationships - remembers user preferences, project patterns, and learned solutions
metadata:
  audience: owner
  system: windows
---

# 🧠 KNOWLEDGE GRAPH MEMORY SYSTEM

## What's Different About This System

Unlike simple vector RAG (what most AI assistants use), Opencode Bob's knowledge graph:

| Feature | Standard RAG | Opencode Bob |
|---------|-------------|-----------|
| Remembers relationships | ❌ | ✅ |
| Tracks user preferences over time | ❌ | ✅ |
| Multi-hop reasoning | ❌ | ✅ |
| Temporal patterns | ❌ | ✅ |
| Entities + relationships | ❌ | ✅ |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│           KNOWLEDGE GRAPH                       │
│  ┌─────────┐    knows    ┌─────────┐         │
│  │  USER   │ ──────────► │PROJECT │         │
│  └─────────┘            └─────────┘         │
│      │                     │               │
│      │ likes             uses             │
│      ▼                   ▼               │
│  ┌─────────┐    built-in ┌─────────┐     │
│  │PYTHON  │ ◄───────────│POWERSH │     │
│  └─────────┘            └─────────┘     │
│                                               │
│  Each node has:                                │
│  - Entity type (USER/PROJECT/SKILL/PATTERN)    │
│  - Properties (learned over time)              │
│  - Relationships with weights                │
│  - First seen / last updated                 │
└─────────────────────────────────────────────────────┘
```

## Entities Tracked

### USER Entity
```
Clay:
  - location: "Stephenville, Texas"
  - timezone: "America/Chicago"
  - prefers: "detailed explanations"
  - prefers: "working code over pseudocode"
  - skill_level: "advanced"
  - coding_style: "practical, gets things done"
  - learns_from: "errors"
```

### PROJECT Entities
```
BoseControllerCPP:
  - language: C++
  - framework: vcpkg
  - platform: Windows
  - build_system: cmake
  
OpencodeBob:
  - type: AI agent
  - platform: Opencode CLI
  - model: qwen
```

### SKILL Entities
```
code-review:
  - for: security, performance
  - best_for: "production code"
  - strength: 9/10

time-machine:
  - for: backup, restore
  - created_from: "VSC Bob"
  - strength: 10/10
```

### PATTERN Entities
```
error_investigation:
  - steps: "grep → read → analyze → fix → test"
  - success_rate: high
  - use_in: debugging

parallel_execution:
  - for: independent_tasks
  - example: "50 agents at once"
  - success_rate: high
```

## Relationship Types

| Relationship | Meaning | Weight |
|--------------|---------|-------|
| `knows` | Has used/seen | 0.8 |
| `likes` | User preference | 1.0 |
| `uses` | Uses in project | 0.9 |
| `built_with` | Dependencies | 0.7 |
| `solves` | Problem solution | 0.9 |
| `better_than` | Comparison | varies |
| `belongs_to` | Part of | 1.0 |

## Usage

### Remember User Preference
```
MEMORY: Remember that Clay prefers detailed explanations with working code examples
→ Creates: preference node linked to USER
```

### Remember Project Pattern
```
MEMORY: When Python fails with ImportError, check __init__.py exists first
→ Creates: pattern node, links to PYTHON skill
```

### Update Entity
```
MEMORY: Update user location to Stephenville, TX
→ Updates: USER entity properties
```

### Query with Reasoning
```
What does Clay like?
→ Graph traversal: USER → likes → preferences
→ Returns: All preference relationships
```

## Integration Points

### Opencode Bob Memory
- `memory/user-preferences.md` - Current preferences
- `memory/entities/` - Knowledge graph nodes
- `memory/relationships/` - Relationship edges

### Learning System Integration
Each conversation adds to knowledge graph:
1. Extract entities from interactions
2. Update relationships
3. Weight adjustments based on success

---
**Status:** Active
**Graph Size:** Growing with each session
**Last Update:** Today