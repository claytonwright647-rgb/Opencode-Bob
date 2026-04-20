---
name: auto-tool-finder
description: Automatically finds or creates any tool/skill needed. When needed capability is not available, searches ClawHub or creates new skill.
---

# Auto Tool Finder

## Mission

**FIND OR CREATE ANY TOOL NEEDED - AUTOMATICALLY**

## When to Use

User needs something and I don't have the tool. OR I need a capability that doesn't exist yet.

## Workflow

### Phase 1: Check Existing

```powershell
# Check skills directory
Get-ChildItem C:\Users\clayt\opencode-bob\skills -Directory

# Check MCP servers (already connected)
opencode mcp list
```

### Phase 2: Search ClawHub

If not found locally:
```bash
# Must use full path for clawhub
& "C:\Users\clayt\AppData\Roaming\npm\node_modules\clawhub\bin\clawhub.cmd" search "<query>" --limit 5

# Install if found
& "C:\Users\clayt\AppData\Roaming\npm\node_modules\clawhub\bin\clawhub.cmd" install --dir C:/Users/clayt/opencode-bob/skills <slug>
```

### Phase 3: Create New Skill

If not on ClawHub, create a new skill:
```
C:/Users/clayt/opencode-bob/skills/<new-name>/SKILL.md
```

Template:
```yaml
---
name: <skill-name>
description: <what it does>
---

# <Skill Name>

## Purpose
<detailed description>

## When to Use
- <scenario 1>
- <scenario 2>

## How to Use
<step-by-step instructions>

## Tools Needed
- <tool 1>
- <tool 2>
```

## Common Needs & Solutions

| Need | Check First |
|------|--------------|
| Run code | `opencode run` + code execution |
| Read files | MCP filesystem |
| Web search | Web search tool |
| GitHub operations | MCP github |
| Analyze code | `skills/agentlens/`, `skills/code-review/` |
| Security scan | `skills/security-auditor/` |
| Generate tests | `skills/test-gen/` |
| Debug | `skills/debug/` |
| Learn from errors | `skills/self-improving/` |
| Summarize | `skills/summarize-pro/` |

## Important Paths

```
Skills: C:/Users/clayt/opencode-bob/skills/
MCPs:  C:/Users/clayt/opencode-bob/agents/opencode-bob.json
ClawHub CLI: C:\Users\clayt\AppData\Roaming\npm\node_modules\clawhub\bin\clawhub.cmd
```

## Automation

**ALWAYS auto-find before asking!** If capability is missing:
1. Search ClawHub
2. If found → install and use
3. If not → create new skill
4. Execute

No user permission needed - JUST DO IT