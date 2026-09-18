---
name: data-quality
description: "Trigger: data audit, pipeline audit, schema validation, data governance, ETL. Audit data quality and reliability."
triggers: "data audit, data pipeline audit, schema validation, data governance, ETL audit, data quality check, data review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 3895
---
## When to Use
Reviewing data pipelines, schemas, ETL, analytics. No data layer → report and stop.
## SCAN DIMENSIONS
**Schema**: `grep -rn "CREATE TABLE\|ALTER TABLE\|schema\|migration" --include="*.sql" --include="*.py" --include="*.ts"` — types match usage, nullable have defaults, indexes on FKs. Tools: `sqlfluff lint --rules L010,L014,L016`, `alembic check`, `prisma validate`.
**Ingestion**: `grep -rn "pd\.read_\|spark\.read\|requests\.\|httpx\.\|curl" --include="*.py" --include="*.ipynb"` — error handling, retries, timeouts, dtype validation. Cleaning: `fillna\|dropna\|replace\|interpolate`. Actionable: `try:\|except\|retry\|timeout`, validate `df.dtypes`.
**Transformation**: `grep -rn "concat\|merge\|join\|groupby\|GROUP BY" --include="*.py" --include="*.sql" --include="*.ipynb"` — join key integrity, dtype coercion, null handling. Actionable: `on=\|how=\|suffixes=`, `coalesce\|IFNULL\|COALESCE`.
**dbt/YAML** + **Profiling** — greps, tools, drift → reference.
## OUTPUT
`DQ-REPORT:<date> Checks:<n> Schema:[table]:[issue] P0:[critical fix] P1:[improvement]`
## Rules
1. Schema BEFORE ingestion. 2. Measure (profiling) not just grep. 3. Every finding: file:line + evidence.
## Anti-Patterns
Skip schema validation · Ignore error handling · No profiling · Python-only bias · Skip dbt/YAML · Assume ingestion succeeds · Silent schema drift · No late-data strategy · Hard-delete in DW · Magic numbers in transforms
## Reference
dbt/YAML + Profiling detail → docs/skills/data-quality/reference.md
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "validar schema al inicio basta" | Schema solo al inicio, drift ignorado | Rule Schema BEFORE ingestion + `alembic check`/`prisma validate` + profiling |
| "nulls tolerables sin política" | `fillna`/`coalesce` sin política | SCAN Transformation null handling + `df.dtypes` verify |
| "lineage es nice-to-have" | Sin linaje dbt/YAML | SCAN dbt/YAML + reference lineage check |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Backend Security Playbook
Secrets: env/vault only - never code/logs (grep src for `password|api[_-]?key|secret`, exclude tests) | vault runtime read (HashiCorp/AWS SM) | no default creds
AuthZ: deny-by-default (403 unless allowlisted route) | scopes per endpoint (least-priv) | IDOR: ownership check per resource (`WHERE owner_id=session.id`) -> 403/404 never 200 | enforce server-side - never trust client role claims
Injection: SQL/LDAP parameterized/prepared stmts only | OS cmd: exec list, no `shell=True`, no user-input concat | raw SQL via bind vars
Logging: mask PII/creds (`token→redacted`, email `u***@`) | stack traces DEBUG-only | strip \n from user input (log forging)
Errors: generic client msg (500 + req id) | full exception detail to server logs only
Deps: lockfile committed + exact pin | CI audit (pip-audit/npm audit/osv-scanner) fail build | private scope/pkg index-url (dependency confusion)
SSTI: template engines sandboxed ONLY (Jinja2 sandbox / Twig sandbox) - user input is DATA, never template source | eval/exec/compile in templates = CRIT | {{ }} from user input = CRIT
XXE: XML parsers disable external entities + DTD (defusedxml, lxml resolve_entities=False, FEATURE_SECURE_PROCESSING + disallow-doctype-decl) | no xinclude/external DTD (SSRF/file-read)
Deserialization: pickle/yaml.load NEVER - yaml.safe_load only | JSON allowlist | reject __reduce__/gadget classes | no untrusted bytes to unserialize/ObjectInputStream/Marshal
> changelog: odd/tasks/mejora-security.md (2026-09-18, slice 6)
> changelog: odd/tasks/mejora-security.md (2026-09-18, slice 3)
## Refs
Cross-Refs: perf-profiling | testing-strategy

