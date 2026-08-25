# api-testing — Reference Materials

> **Externalized from** .agents/skills/api-testing/SKILL.md to keep the skill under the 2KB
> token budget (ADR-007). Contains worked examples and patterns.

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
