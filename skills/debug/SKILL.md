---
name: debug
description: Systematic debugging assistance
license: MIT
---

# Debug Skill

Systematic debugging framework for any issue.

## Debug Process

### 1. REPRODUCE
- Get exact steps to reproduce
- Note environment (OS, versions, config)
- Simplify to minimal reproduction case

### 2. OBSERVE
- Collect error messages exactly
- Note stack traces
- Check logs (application, system, debug)
- Identify the exact failure point

### 3. HYPOTHESIZE
- Generate possible root causes
- Rank by likelihood
- Note assumptions

### 4. TEST
- Test each hypothesis
- Use systematic isolation
- Binary search approach

### 5. FIX
- Verify root cause
- Apply minimal fix
- Test fix works
- Check for side effects

### 6. PREVENT
- Add regression test
- Document what went wrong
- Note lessons learned

## Output Format

```markdown
## Issue: [Brief description]

### Reproduction Steps
1. Step 1
2. Step 2
3. Step 3

### Observations
- Error: [exact error]
- Stack: [stack trace]
- Environment: [details]

### Root Cause
[Found at: file:function():line]

### Fix Applied
```[language]
code fix here
```

### Verification
- [ ] Tested on original case
- [ ] Tested edge cases
- [ ] No regression in adjacent features
```