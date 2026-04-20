---
name: project-setup
description: Initialize new projects from templates
license: MIT
---

# Project Setup Skill

Quick project initialization from templates.

## Templates

| Template | Command |
|----------|---------|
| Node.js | `npm init -y` |
| Python | `python -m venv venv` |
| C# | `dotnet new console` |
| Go | `go mod init` |
| Rust | `cargo init` |

## Setup Process
1. Detect language from files/extension
2. Create directory structure
3. Initialize package manager
4. Add common dependencies
5. Create README
6. Set up git

## Output Structure
```
project/
├── src/
├── test/
├── README.md
├── .gitignore
└── package.json
```

## Example
```markdown
## Project: my-app (Node.js)

### Created
- package.json
- src/index.js
- test/
- README.md
- .gitignore

### Next Steps
1. npm install
2. Add your code to src/
3. npm test
```