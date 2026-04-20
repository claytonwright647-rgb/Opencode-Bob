---
name: security-audit
description: Full security vulnerability scanning
license: MIT
metadata:
  audience: security team
  workflow: security
---

# Security Audit Skill

Comprehensive security vulnerability scanner.

## Check Categories

### OWASP Top 10 (2021)
1. A01:2021 - Broken Access Control
2. A02:2021 - Cryptographic Failures
3. A03:2021 - Injection
4. A04:2021 - Insecure Design
5. A05:2021 - Security Misconfiguration
6. A06:2021 - Vulnerable Components
7. A07:2021 - Auth Failures
8. A08:2021 - Data Integrity Failures
9. A09:2021 - Logging Failures
10. A10:2021 - SSRF

### Code-Specific Checks
- Hardcoded credentials
- SQL injection points
- XSS vulnerabilities
- Command injection
- Path traversal
- Insecure deserialization
- XXE vulnerabilities

## Scanning Process

1. **Dependency Scan** - Check package.json for vulnerable versions
2. **Secret Scan** - Look for API keys, passwords in code
3. **Injection Scan** - Find unsanitized inputs
4. **Auth Scan** - Review authentication code
5. **Config Scan** - Check for insecure defaults

## Output Format
```markdown
# Security Audit Report

## Critical (Immediate Action)
- [ ] Issue: CVE-XXXX-XXXX
- Location: file:line
- Fix: [link to fix]

## High
## Medium
## Low

## Summary
| Severity | Count |
|----------|-------|
| Critical | X |
| High | X |
| Medium | X |
| Low | X |
```