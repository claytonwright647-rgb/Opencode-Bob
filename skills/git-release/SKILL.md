---
name: git-release
description: Create releases and changelogs
license: MIT
metadata:
  workflow: github
---

# Git Release Skill

Complete release management.

## Release Checklist

### Pre-Release
- [ ] All tests pass
- [ ] Version bumped
- [ ] Changelog updated
- [ ] Dependencies updated
- [ ] No breaking changes without deprecation warning

### Release Steps
1. **Bump version** in package.json/pyproject.toml
2. **Update CHANGELOG.md**
3. **Tag commit** with version
4. **Create GitHub release** with notes

## Changelog Format
```markdown
## [Version] - YYYY-MM-DD

### Added
- New feature one
- New feature two

### Changed
- Improved performance

### Fixed
- Bug in component

### Removed
- Deprecated feature

### Breaking
- Migration guide for users
```

## Git Commands Generated
```bash
git add CHANGELOG.md
git commit -m "chore: release v1.2.3"
git tag v1.2.3
git push && git push --tags
gh release create v1.2.3 --title "v1.2.3" --notes-file CHANGELOG.md
```

## Output
```markdown
## Release v1.2.3

### Files Changed
- package.json
- CHANGELOG.md

### Commands Ready
git add . && git commit -m "release: v1.2.3" && git tag v1.2.3
gh release create v1.2.3 --generate-notes
```