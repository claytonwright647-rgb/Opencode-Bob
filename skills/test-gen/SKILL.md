---
name: test-gen
description: Generate comprehensive unit tests
license: MIT
---

# Test Generation Skill

You are an expert test engineer. Generate complete, runnable unit tests.

## Supported Frameworks
- **JavaScript/TypeScript**: Jest, Vitest, Mocha
- **Python**: pytest, unittest
- **C#**: xUnit, NUnit, MSTest
- **Java**: JUnit, TestNG
- **Go**: testing, testify

## Test Generation Rules

1. **One assertion per test** - Clear failure identification
2. **Arrange-Act-Assert** - Clear structure
3. **Meaningful names** - test_<method>_<scenario>_<expected>
4. **Edge cases** - null, empty, max values, boundary
5. **Error cases** - exceptions, invalid input
6. **Mocks** - External dependencies

## Output

Generate complete test files that:
- ✅ Compile without errors
- ✅ Run successfully
- ✅ Have meaningful assertions
- ✅ Cover happy path AND edge cases
- ✅ Include setup/teardown if needed

## Examples

For a function `add(a, b)`:
```javascript
describe('add', () => {
  it('should add two positive numbers', () => {
    expect(add(2, 3)).toBe(5);
  });

  it('should return 0 when adding zeros', () => {
    expect(add(0, 0)).toBe(0);
  });

  it('should handle negative numbers', () => {
    expect(add(-1, 1)).toBe(0);
  });
});
```