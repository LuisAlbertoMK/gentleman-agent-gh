---
name: api-testing
description: "API endpoint testing - REST + GraphQL, contract/schema validation, collection & response testing, auth flows, mocks."
triggers: "api testing, API test, REST test, GraphQL test, endpoint test, contract test, schema validation, response validation, auth test, API mock, collection test, Postman, Bruno, insomnia, OpenAPI validation"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
API endpoint testing — REST+GraphQL contract validation, schema assertion, response validation, auth flows, mock integration. READ-ONLY/test-gen only—NEVER production. Output: plan/collection w/ assertions.

## Rules
1.NEVER production/unknown—mock/localhost only. 2.NEVER real credentials—env vars. 3.Format:`.bru`(Bruno)>JSON(Postman)>.ps1 4.Schema:JSON Schema Draft2020-12/OpenAPI3.1 5.Auth:mocked tokens—never real OAuth.

## Workflow
1.Discover(OpenAPI→paths|grep routes|collections→gaps) 2.Validate 3.Plan(P0 happy/auth 401/403|P1 400/edge|P2 404/409/422/429/500|P3 perf) 4.Output(.bru/.graphql/Pester)

## Examples
**REST contract (schema+response)**
```powershell
$s=Get-Content schema.json -Raw;$r=Invoke-RestMethod http://localhost:3000/api/users
$r|ConvertTo-Json -Depth 5|Test-Json -Schema $s
$r[0].id -ne $null -and $r.Count -gt 0
```
**GraphQL (query+mutation)**
```powershell
$q=@{query='query{user(id:1){id name}}'}|ConvertTo-Json
$r=Invoke-RestMethod http://localhost:3000/graphql -Method Post -ContentType 'application/json' -Body $q
$r.data.user.id -eq 1
$m=@{query='mutation($n:String!){createUser(name:$n){id}}';variables=@{n='x'}}|ConvertTo-Json
```
**Auth flow (Bearer+refresh)**
```powershell
$h=@{Authorization="Bearer $((Invoke-RestMethod http://localhost:3000/token -Method Post -Body @{u='t';p='p'}).access_token)"}
Invoke-RestMethod http://localhost:3000/me -Headers $h
# 401->refresh,retry
$h=@{Authorization="Bearer $((Invoke-RestMethod http://localhost:3000/refresh -Method Post -Headers $h).refresh_token)"}
Invoke-RestMethod http://localhost:3000/me -Headers $h
```
**Pagination (cursor loop)**
```powershell
$c=$null;$i=0;do{$r=Invoke-RestMethod "http://localhost:3000/users?cursor=$c";$c=$r.next_cursor;$i++}while($c -and $i -lt 5)
```

## Patterns
**Mock server (WireMock/MSW)**—stub then assert:
```java
stubFor(get(urlEqualTo("/api/users")).willReturn(okJson("[{\"id\":1}]")));
verify(getRequestedFor(urlEqualTo("/api/users")));
```
**Collection/run**—`.bru` per endpoint + env; run `newman run col.json -e env.json`; assert `pm.response.code==200`.
**Property-based**—gen valid+invalid payloads; assert valid pass Test-Json, invalid fail.

## Edge Cases
1.Flaky→retry 3x w/ backoff (GET/idempotent only). 2.Token expiry mid-test→catch 401→refresh→retry once. 3.Cursor→loop while next_cursor, cap iterations. 4.429→honor Retry-After, backoff, fail after N.

## Dependencies: e2e-testing·quality-gate·Invoke-RestMethod·Bruno(bru)·Newman

## Anti-Patterns
Test prod·Hardcoded creds·No rate-limit delays·No schema first·One giant file(split by group)