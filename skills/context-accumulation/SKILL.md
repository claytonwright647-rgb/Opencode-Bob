---
name: context-accumulation
description: Builds a connected knowledge map over time - learns architecture, state, decisions, problems, and preferences
metadata:
  audience: owner
  system: windows
---

# 🗺️ CONTEXT ACCUMULATION SYSTEM

## What This Does

As Opencode Bob works, he builds an increasingly detailed mental model of the system.

Not just facts - a **living, connected knowledge graph**.

## What's in the Map

### 1. Architecture
- What are the major components?
- How do they interact?
- What are the boundaries?

### 2. Current State
- What is working?
- What is broken?
- What is incomplete?

### 3. Decisions
- Why was X built this way?
- What alternatives were considered?
- What trade-offs were made?

### 4. Problems
- Known issues?
- Suspected issues?
- Land mines to avoid?

### 5. Preferences
- What patterns does Clay prefer?
- What does he NOT like?
- What has he explicitly stated?

### 6. History
- What was tried and failed?
- What was the cause?
- **Prevents re-trying wrong approaches!**

## How to Accumulate Context

### After Reading Any File

```powershell
# NOT just store the content
# BUT store the INTERPRETATION

# Bad:
memory_save("main.cpp content")

# Good:
memory_save("main.cpp insight: render loop calls BeginFrame AFTER ImGui NewFrame - unusual pattern that may cause sync issues")
```

### After Any Decision

```powershell
# Record WHY, not just WHAT

memory_save("Chose staged rendering over immediate because: avoids data race between WS thread and render thread")
```

### After Any Failure

```powershell
# Record ROOT CAUSE, not just symptom

memory_save("Volume display flickered because: no mutex on m_nowPlaying - accessed from two threads without protection")
```

## The Context Map Structure

```
                    ┌─────────────┐
                    │  PROJECT   │
                    │  (root)   │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │ARCHITECT │    │ STATE   │    │DECISIONS│
    │          │    │         │    │         │
    │Components│    │Working: │    │Chose X  │
    │ → A → B │    │  A, B   │    │ because │
    │ → B → C │    │ Broken:C│    │  Y      │
    └─────────┘    └─────────┘    └─────────┘
                           │
                    ┌──────▼──────┐
                    │   PROBLEMS   │
                    │              │
                    │ Known: 3     │
                    │ Suspected: 2  │
                    │ Avoid: X      │
                    └───────────────┘
```

## Integration with Knowledge Graph

The context accumulation feeds directly into the knowledge graph:

```powershell
# Save context
knowledge-graph add-entity -Entity "project:bose-controller" -Type "PROJECT" -Properties "{'status': 'working', 'components': 5}"

# Add relationship
knowledge-graph add-relation -Entity "render-thread" -Target "volume-display" -Relation "may-race-with"

# This enables RECALL of the full context:
# "What's the current state of the project?"
# → Returns: full context from knowledge graph
```

## Usage

### At Start of Task
```powershell
# Get full context before starting
pwsh -File C:/Users/clayt/opencode-bob/knowledge-graph.ps1 -Query "project current state"
```

### After Major Milestone
```powershell
# Save current state
# - What's working
# - What's changed
# - What's next
```

### Before Similar Task
```powershell
# Recall what was tried before
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -recall -Context "audio"
# → Returns: all audio-related learnings
```

## Context File Structure

```
memory/context/
├── current-state.md    ← What is the current state right now
├── architecture.md    ← How the system is structured
├── decisions.md       ← Why things were built this way
├── problems.md        ← Known issues and land mines
├── preferences.md     ← Clay's preferences
└── history.md        ← What was tried before
```

---

**Status:** Active
**Grows with:** Every task completed