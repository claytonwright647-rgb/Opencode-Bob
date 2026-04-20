---
name: database-query
description: Database operations and queries
license: MIT
---

# Database Query Skill

Execute database operations and queries.

## Supported Databases
- PostgreSQL, MySQL, SQLite
- SQL Server, MongoDB
- Any via connection string

## Operations
- **Query**: SELECT with parameters
- **Insert**: Single and bulk
- **Update**: With WHERE clauses
- **Delete**: With conditions
- **Schema**: Table creation, migration

## Safety Rules
1. ALWAYS use parameterized queries (no string concatenation)
2. Backup before destructive operations
3. Review DELETE/UPDATE before execution
4. Log all changes

## Output Format
```markdown
## Query Results

### Query
\`\`\`sql
SELECT * FROM users WHERE...
\`\`\`

### Results
| Column | Value |
|--------|-------|
| row 1 | ... |

### Rows Affected: X
```

## Example
```sql
-- Safe parameterized query
SELECT * FROM users WHERE id = $1 AND active = $2
-- Parameters: [123, true]
```