---
name: api-testing
description: "API endpoint testing - REST + GraphQL, contract/schema validation, collection & response testing, auth flows, mocks."
triggers: "api testing, API test, REST test, GraphQL test, endpoint test, contract test, schema validation, response validation, auth test, API mock, collection test, Postman, Bruno, insomnia, OpenAPI validation"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
API endpoint testing — REST + GraphQL contract validation, schema assertion, collection testing, response validation, auth flows, mock integration.

**Scope**: API endpoint behavior—request/response contracts, not UI/infra.
**Mode**: READ-ONLY analysis or test-gen. NEVER call production.
**Output**: Test plan/collection with assertions, not raw curl.

## Rules
1.NEVER production/unknown—mock/localhost only. 2.NEVER real credentials—env vars. 3.Format:`.bru`(Bruno)>JSON(Postman)>.ps1 4.Schema:JSON Schema Draft2020-12/OpenAPI3.1 5.Auth:mocked tokens—never real OAuth.

## Workflow
1.Discover:OpenAPI→paths/methods/schemas|source→grep routes|collections→coverage gaps
2.Validate:```powershell
$schema=Get-Content schema.json|ConvertFrom-Json;$r=Invoke-RestMethod http://localhost:3000/api/health;$r|ConvertTo-Json|Test-Json -Schema(Get-Content schema.json -Raw)
```
3.Test plan:
P0:Happy path 200/201|Auth 401/403|P1:Validation 400/missing/edge|P2:Error 404/409/422/429/500|Pagination limit/offset|P3:Perf <threshold
4.Collection:REST→`.bru`|GraphQL→`.graphql`+variables|PS→Pester
5.Auth:JWT(expiry/sig/claims)|Key(header vs query)|OAuth2(mock)|Session(cookie/CSRF)
6.Contract:Consumer-driven|Provider-driven|Breaking change diff

## Output
```
---
name:GET/api/users method:GET url:{{baseUrl}}/api/users
headers:Authorization:Bearer{{token}}
---
assert:res.status==200|res.body|length>0|res.body[0].id!=null
```

## Dependencies: e2e-testing·quality-gate·Invoke-RestMethod·Bruno(bru)·Newman

## Anti-Patterns
Test prod·Hardcoded creds·No rate-limit delays·No schema first·One giant file(split by group)
