# SKILL: ERROR DETECTIVE
## Analyze errors like a detective, not a search engine
### Version 1.0 | April 19, 2026

---

## THE CORE PRINCIPLE

Errors are NOT noise to search-and-fix. They are **precise descriptions** of what the system thinks is wrong.

Every error message contains:
1. **The symptom** - what failed
2. **The location** - file, line, symbol
3. **The cause** - often hidden in the middle/last lines

---

## THE DETECTIVE METHOD

### Step 1: Read the FULL error, not just the first line
- First line = symptom
- Middle = call stack  
- Last lines = closest to cause
- PowerShell: `Get-Content error.log -Tail 50`

### Step 2: Identify the ERROR TYPE
| Type | What It Means | Common Cause |
|------|--------------|--------------|
| LNK2019 | Declared but not linked | CMakeLists link order, source file not in target |
| C2589 | Illegal token | NOMINMAX missing before Windows.h |
| C2039 | Not a member | Wrong include order or namespace |
| LNK1181 | Cannot open .lib | Library not built yet |
| C3861 | Identifier not found | Missing include or wrong namespace |
| E0349 | No operator matches | Type mismatch |
| Access denied | Permission issue | File locked or ACL |

### Step 3: Trace from SYMPTOM to CAUSE
1. What symbol/function is the error about?
2. Where is it defined?
3. Is that definition being compiled?
4. Is it being linked? In what order?

### Step 4: Make the MINIMUM change
- Fix THE CAUSE, not the symptom
- Not a rewrite - the smallest fix that addresses the root cause

---

## ERROR PATTERN LIBRARY

### C++/Windows Patterns
```
NOMINMAX → #define NOMINMAX must appear BEFORE #include <Windows.h>
          → Fix: Add #define NOMINMAX at VERY top of file

LNK2019 → Check: (1) symbol defined? (2) source in target? (3) link order?
         → Fix: Add source file to CMakeLists or reorder libraries

C2589 → Check: Is NOMINMAX defined before windows.h?
       → Fix: Add #define NOMINMAX as first line

ComPtr issues → Check: Using ComPtr<T> correctly?
             → Fix: Use .Get() not .GetAddressOf() for ref params
```

### PowerShell Patterns
```
Access denied → Check: Is file locked by another process?
             → Fix: Close process or use -Force

Module not found → Check: Module installed for current user?
                 → Fix: Install-Module -Scope CurrentUser

Command not found → Check: $env:PATH includes the tool
                  → Fix: Add to PATH or use full path
```

---

## USAGE

```
# Analyze an error log
.\error-detective.ps1 -ErrorLog "build_error.txt"

# Or manually input the error
.\error-detective.ps1 -ErrorText "LNK2019: unresolved external symbol"
```

---

## KEY INSIGHT

The most expensive debugging is trying the same approach with different syntax.

When something fails TWICE with the same approach:
1. STOP - your model is wrong
2. QUESTION the fundamental approach
3. REFORMULATE the understanding
4. TRY a completely different approach

---

*Based on Claude's detective error analysis approach from BOB-SKILLS*