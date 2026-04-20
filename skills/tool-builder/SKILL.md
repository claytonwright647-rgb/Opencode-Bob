# SKILL: TOOL BUILDER
## Create new tools/skills on demand
### Version 1.0 | April 19, 2026

---

## WHAT THIS DOES

When you need a specialized tool that doesn't exist, build it!

**Examples:**
- Need to parse a specific file format? → Build a parser
- Need to analyze logs? → Build a log analyzer
- Need to generate specific output? → Build a generator

---

## HOW TO USE

```powershell
# Create a new script tool
pwsh -File C:/Users/clayt/opencode-bob/skills/tool-builder/build-tool.ps1 -Name "my-new-tool" -Type script -Purpose "What it does"

# Or create a new skill
pwsh -File C:/Users/clayt/opencode-bob/skills/tool-builder/build-tool.ps1 -Name "my-new-skill" -Type skill -Purpose "What it does"
```

---

## BEST PRACTICES

1. **Single Responsibility**: Each tool does ONE thing well
2. **Clear Interface**: Simple parameters, clear outputs
3. **Error Handling**: Handle errors gracefully
4. **Documentation**: Include help/text
5. **Testability**: Easy to verify it works

---

## TEMPLATES

### Script Tool Template
```
param(
    [Parameter()]
    [string]$Input
)

# Tool logic here

# Output
return @{ "result" = "value" }
```

### Skill Template
```
# SKILL: <SKILL NAME>
## What it does
### Version 1.0 | Date

---

## WHAT THIS DOES

Description...

---

## HOW TO USE

Examples...

---
```

---

## AUTO-DISCOVERY

After creating a tool, Bob automatically:
1. Saves it to the correct location
2. Updates his self-model with new capability
3. Adds to available tools list

---

*Created dynamically when needed*