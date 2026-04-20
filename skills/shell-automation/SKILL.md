---
name: shell-automation
description: Terminal and shell command automation
license: MIT
---

# Shell Automation Skill

Automate terminal operations and shell scripts.

## Capabilities
- Execute commands
- Run scripts (PowerShell, bash, cmd)
- Pipeline operations
- Environment management
- Background processes

## Safety Rules
1. NEVER run destructive commands without confirmation
2. Always use full paths when possible
3. Check command safety (no rm -rf /)
4. Log all operations

## Common Commands
```bash
# Windows
Get-ChildItem -Recurse -File | Measure-Object
Get-Process | Sort-Object CPU -Descending

# Linux/macOS
find . -type f -name "*.js" | wc -l
ps aux | grep node
```

## Output
```markdown
## Shell Execution Result

### Command
\`\`\`bash
command here
\`\`\`

### Output
```
results here
```

### Exit Code: 0
### Duration: 1.23s
```