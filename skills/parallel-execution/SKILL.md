---
name: parallel-execution
description: Multi-agent parallel execution - spawn unlimited agents for independent tasks simultaneously
metadata:
  audience: owner
  system: windows
---

# ⚡ PARALLEL EXECUTION FRAMEWORK

## What Makes This Special

Unlike Claude Code (1 sub-agent), ChatGPT (sequential), and Cursor (1 agent), Opencode Bob can spawn **unlimited parallel agents**:

| Tool | Parallel Agents | Use Case |
|------|-----------------|----------|
| **Opencode Bob** | **50+ simultaneous** | Max parallelism |
| Claude Code | 1 at a time | Sequential |
| ChatGPT | Sequential | Chat only |
| Cursor | 1 agent | IDE focus |
| Codex | Worktrees (limited) | Cloud-based |

## 🎯 When to Use

### ✅ Perfect Scenarios
- Independent file operations (search + compare + analyze)
- Multiple search queries at once
- Building multiple test files simultaneously
- Running analysis on different code sections
- Web research + local code analysis
- Git operations across multiple repos

### ❌ Not for Sequential Tasks
- Tasks that depend on each other
- Single-file edits
- Things that must happen in order

## 🚀 Usage Patterns

### Pattern 1: Research + Build
```
Commander: Take snapshot, then search web for best practices
         ├─ Agent 1: Create backup (30 files)
         └─ Agent 2: Research topic (web search)
         → Results combined!
```

### Pattern 2: Analyze + Modify
```
Commander: Find all Python files, analyze patterns, refactor
         ├─ Agent 1: Search .py files
         ├─ Agent 2: Analyze code structure  
         └─ Agent 3: Create refactor plan
         → Execute plan after analysis
```

### Pattern 3: Multi-Search
```
Commander: Research 5 different topics simultaneously
         ├─ Agent 1: Topic 1 (web)
         ├─ Agent 2: Topic 2 (web)
         ├─ Agent 3: Topic 3 (web)
         ├─ Agent 4: Topic 4 (web)
         └─ Agent 5: Topic 5 (web)
         → Results combined in 1/5 the time!
```

### Pattern 4: Massive Parallel (50+)
```
Commander: Process 50 files independently
         Launch 50 agents simultaneously
         → Each agent processes 1 file
         → Results aggregated
```

## ⚡ HOW IT WORKS

### Commander Rules (Opencode Bob)
```python
1. BREAK task into tiny independent chunks
2. PARALLELIZE each chunk with separate agent
3. VERIFY results independently  
4. AGGREGATE final output
```

### Agent Types Available
- `explore` - Fast file searching
- `general` - Research & execution
- `general-purpose` - Any multi-step task

## 📊 Performance Comparison

| Task | Sequential | Parallel | Speedup |
|------|------------|----------|--------|
| 10 web searches | 10 min | 1 min | 10x |
| 50 file analysis | 50 min | 2 min | 25x |
| Search + code + test | 3 operations | Combined | 3x |

## 🔧 Configuration

### Agent Limit
- Current: 50 agents (configurable)
- Recommended: 10-20 for stability
- Maximum: 50 for parallel operations

### Per-Agent Resources
- Each agent is independent
- Fresh context for each
- Can use same tools as commander

## 📦 Examples

### Example 1: Quick Research
```python
# Launch 3 agents for parallel research
Agent 1: "Find best practices for API design"
Agent 2: "Find error handling patterns in Python"
Agent 3: "Find testing frameworks for CLI tools"
# All run simultaneously!
```

### Example 2: Code Analysis
```python
# Launch 4 agents on different files
Agent 1: "Analyze main.py for security issues"
Agent 2: "Analyze database.py for SQL injection"
Agent 3: "Analyze auth.py for vulnerabilities"
Agent 4: "Analyze api.py for leaks"
# Combined security audit!
```

### Example 3: Multi-File Operations
```python
# Launch 10 agents to create tests
Agent 1-10: Each creates tests for different module
# 10 test files in parallel!
```

## 🎓 Best Practices

1. **Split into truly independent chunks** - No shared state
2. **Limit to 20 agents** for reliability
3. **Use for research, search, analysis** - Not single edits
4. **Aggregate results** - Commander combines outputs
5. **Verify independently** - Each agent verifies own work

## 🚫 Limitations

- No shared memory between parallel agents
- Each must be truly independent
- Commander aggregates, not all agents
- Can overwhelm if too many

---
**Status:** Active
**Max Agents:** 50 parallel
**Best For:** Research, analysis, multi-file operations