---
name: api-testing
description: "API endpoint testing - REST + GraphQL, contract/schema validation, collection & response testing, auth flows, mocks."
triggers: "api testing, API test, REST test, GraphQL test, endpoint test, contract test, schema validation, response validation, auth test, API mock, collection test, Postman, Bruno, insomnia, OpenAPI validation"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2265
---
## When to Use
API endpoint testing — REST+GraphQL contract validation, schema assertion, response validation, auth flows, mock integration. READ-ONLY/test-gen only—NEVER production. Output: plan/collection w/ assertions.
## Rules
1.NEVER production/unknown—mock/localhost only. 2.NEVER real credentials—env vars. 3.Format:`.bru`(Bruno)>JSON(Postman)>.ps1 4.Schema:JSON Schema Draft2020-12/OpenAPI3.1 5.Auth:mocked tokens—never real OAuth.
## Workflow
1.Discover(OpenAPI→paths|grep routes|collections→gaps) 2.Validate 3.Plan(P0 happy/auth 401/403|P1 400/edge|P2 404/409/422/429/500|P3 perf) 4.Output(.bru/.graphql/Pester)
## Edge Cases
1.Flaky→retry 3x w/ backoff (GET/idempotent only). 2.Token expiry mid-test→catch 401→refresh→retry once. 3.Cursor→loop while next_cursor, cap iterations. 4.429→honor Retry-After, backoff, fail after N.
## Anti-Patterns
Test prod·Hardcoded creds·No rate-limit delays·No schema first·One giant file(split by group)
> docs/skills/api-testing/reference.md
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "GraphQL sin contract validation" | Query sin schema assertion | JSON Schema Draft2020-12 / OpenAPI3.1 por endpoint, .bru collection |
| "Mocks que nunca expiran" | Token mock eterno sin refresh | Mocks con expiry; 401→refresh→retry once, 429→Retry-After backoff |
| "Test en prod con creds reales" | Prod/creds hardcode | Mock/localhost only + env vars; nunca prod/unknown |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: testing-strategy | e2e-testing

