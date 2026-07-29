---
name: api-testing
description: "API endpoint testing — REST + GraphQL contract validation, schema assertion, collection testing, response validation, auth flows, mock integration."
triggers: "api testing, API test, REST test, GraphQL test, endpoint test, contract test, schema validation, response validation, auth test, API mock, collection test, Postman, Bruno, insomnia, OpenAPI validation"
license: Apache-2.0
metadata:
  tags: [testing, api, quality, backend]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial — REST + GraphQL, schema validation, auth flow testing"
  dependencies: [e2e-testing, quality-gate]
---

# API Testing

## Activation Contract

1. **Scope**: API endpoint behavior — request/response contracts, not UI or infra.
2. **Triggers**: Use keywords matching the trigger table. For OpenAPI/Swagger files, use `schema validation`.
3. **Mode**: READ-ONLY analysis or test-generation. NEVER call production endpoints.
4. **Output**: Test plan or collection with validated assertions, not raw curl output.

## Hard Rules

1. NEVER call production or unknown endpoints — use mock/localhost only.
2. NEVER store real credentials in test files — use env vars or secrets injection.
3. Collection format: prefer `.bru` (Bruno), JSON (Postman), or self-contained `.ps1` scripts.
4. Schema validation: use JSON Schema Draft 2020-12 or OpenAPI 3.1.
5. Auth flow tests: mock token endpoints — never use real OAuth providers.

## Workflow

### 1. Discover Endpoints
- From OpenAPI/Swagger spec → extract paths, methods, schemas
- From source code routes → grep for route definitions
- From existing collections → parse for test coverage gaps

### 2. Validate Schema
```powershell
# JSON Schema validation pattern (PowerShell)
$schema = Get-Content "schema.json" | ConvertFrom-Json
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/health"
# Validate using Test-Json (PS 7+)
$valid = $response | ConvertTo-Json | Test-Json -Schema (Get-Content "schema.json" -Raw)
```

### 3. Generate Test Plan
| Priority | Type | What to test |
|----------|------|-------------|
| P0 | Happy path | 200/201 for valid requests |
| P0 | Auth | 401 without token, 403 without role |
| P1 | Validation | 400 for malformed body, missing fields |
| P1 | Edge cases | Empty arrays, null values, max length |
| P2 | Error codes | 404, 409, 422, 429, 500 |
| P2 | Pagination | Limit/offset, cursor, total count |
| P3 | Performance | Response time < threshold |

### 4. Generate Collection
- REST: `.bru` collection per endpoint group
- GraphQL: `.graphql` operations + variables JSON
- PowerShell: self-contained test script with Pester assertions

### 5. Auth Flow Testing
- JWT: verify expiry, signature, claims
- API Key: header vs query param, rotation
- OAuth2: mock token endpoint, validate scopes
- Session: cookie handling, CSRF token flow

### 6. Contract Testing
- Consumer-driven: verify provider response matches consumer expectations
- Provider-driven: verify provider returns documented schema
- Breaking change detection: diff response schemas across versions

## Output Format

Test collection (`.bru` example):
```
---
name: GET /api/users
method: GET
url: {{baseUrl}}/api/users
headers:
  Authorization: Bearer {{token}}
  Content-Type: application/json
---
assert:
  - res.status == 200
  - res.body | length > 0
  - res.body[0].id != null
```

## Dependencies

- `e2e-testing` — for Playwright-based API testing
- `quality-gate` — for pre-commit API test validation
- PowerShell `Invoke-RestMethod` or `Invoke-WebRequest`
- Optional: Bruno CLI (`bru`), Newman (Postman CLI)

## Anti-Patterns

- ❌ Testing against production — use staging/mock
- ❌ Hardcoded credentials — use env vars
- ❌ Ignoring rate limits — add delays between tests
- ❌ Testing without schema first — validate contract before behavior
- ❌ One giant test file — split by endpoint group
