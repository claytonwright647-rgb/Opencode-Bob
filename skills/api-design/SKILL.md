---
name: api-design
description: Design and document APIs
license: MIT
---

# API Design Skill

Design RESTful and GraphQL APIs.

## REST Design Rules

### URL Structure
```
GET    /resource          # List
GET    /resource/{id}    # Get one
POST   /resource        # Create
PUT    /resource/{id}    # Update (full)
PATCH  /resource/{id}   # Update (partial)
DELETE /resource/{id}    # Delete
```

### Status Codes
| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Server Error |

### Response Format
```json
{
  "data": { },
  "meta": { "page": 1, "total": 100 },
  "error": null
}
```

## Output
```markdown
## API Specification

### Endpoints
| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /users | List users | Optional |
| POST | /users | Create user | Required |

### Request Body
\`\`\`json
{
  "name": "string",
  "email": "string"
}
\`\`\`

### Responses
- 200: [...]
- 201: { created }
```