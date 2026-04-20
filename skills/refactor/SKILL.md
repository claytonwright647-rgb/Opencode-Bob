---
name: refactor
description: Code refactoring with patterns
license: MIT
metadata:
  audience: developers
  workflow: code-quality
---

# Code Refactoring Skill

Expert refactoring with SOLID, DRY, and design patterns.

## Refactoring Patterns

### Extract Method
```javascript
// Before
const result = a + b; return result * 2;

// After
const sum = (a, b) => a + b;
const double = n => n * 2;
```

### Replace Conditional with Strategy
- Complex if/else → Polymorphism

### Introduce Parameter Object
- Multiple parameters → Single object

### Rename and Clarify
- Cryptic names → Meaningful names
- Magic numbers → Named constants

## Assessment Checklist
- [ ] Function doing one thing?
- [ ] DRY - repeated code?
- [ ] Parameters < 4?
- [ ] Clear names?
- [ ] Error handling?
- [ ] Testable?

## Output
```markdown
## Refactoring Plan

### Priority 1: Quick Wins
| Current | Proposed | Effort |

### Priority 2: Structural
| Current | Proposed | Effort |

### Priority 3: Design
| Current | Proposed | Effort |

## Estimated Impact
- Readability: +X%
- Maintainability: +X%
- Test coverage needed: X tests
```