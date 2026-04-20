---
name: smart-backoff
description: Automatically recognize when approach is failing and switch strategy - the Wisdom of Adaptive Belief Revision
metadata:
  audience: owner
  system: windows
---

# 🧠 SMART BACKOFF SYSTEM

## When to Use This

**This is CRITICAL when:**
- The same approach fails TWICE
- An error keeps repeating
- Debugging isn't converging
- Progress has stalled

## The Problem

Most agents do:
```
Error → Same fix → Same error → Same fix → Same error → ...forever
```

This wastes time and teaches nothing.

## The Anti-Pattern to AVOID

"Try harder" is like pushing harder on a locked door. The problem is not force - the problem is the approach.

## The Smart Backoff Levels

### Level 0: First Failure (Expected)
```
Attempt: First fix
Result: Failed
Action: Analyze error, make targeted fix, retry
```

### Level 1: Second Failure - STOP and Question
```
Attempt: Same approach
Result: Failed again

🚨 CRITICAL MOMENT - STOP doing the same thing!

Ask:
- What assumption is WRONG?
- Is this the RIGHT tool for this problem?
- Is there a COMPLETELY DIFFERENT angle?

Then CHANGE the approach fundamentally
```

### Level 2: Third Failure - Research from Scratch
```
Attempt: New approach
Result: Failed

🚨 ESCALATION - Start over with NEW information!

Actions:
- Web search for exact error + technology
- Read documentation fresh
- Check screen/state directly
- Find working reference
```

### Level 3: Fourth Failure - Escalate Honestly
```
All approaches failed

🚨 TIME TO ASK FOR HELP

Report to user:
- "I've tried 3 approaches and they all failed"
- "Here's what I know"
- "Here's what I don't know"
- "I need more information to proceed"

This is NOT failure - this is HONESTY
```

## How to Recognize Level 1 (Time to Backoff)

**Signals:**
- Same error appears twice
- Fix that "should work" doesn't work
- Error message keeps repeating
- Been trying the same approach for 10+ minutes
- "Let me try..." followed by same failure

## The Backoff Protocol

```powershell
# DON'T:
pwsh fix.ps1 → Error → pwsh fix.ps1 → Error → pwsh fix.ps1

# DO:
pwsh fix.ps1 → Error → (analyze) → Change approach
pwsh fix2.ps1 → Error → (STOP! What's wrong?) → Different angle
pwsh fix3.ps1 → Error → (research fresh) → If fails → "Need help"
```

## Integration with auto-learn

After each backoff level escalation, LEARN:

```powershell
# After Level 1 change:
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Context "debug-attempt-1" -Result "failure" -Details "Approach A failed, switching to B"

# After Level 2 escalation:
pwsh -File C:/Users/clayt/opencode-bob/auto-learn.ps1 -Context "debug-attempt-2" -Result "failure" -Details "Research required"
```

## Key Principle

**The goal is NOT to keep trying - the goal is TO SOLVE.**

A different failed approach teaches MORE than the same failed approach repeated.

---

**Status:** Active
**When triggered:** After any second failure with same approach