---
name: data-quality
description: "Trigger: data audit, pipeline audit, schema validation, data governance, ETL. Audit data quality and reliability."
triggers: "data audit, data pipeline audit, schema validation, data governance, ETL audit, data quality check, data review"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Reviewing data pipelines, schemas, ETL processes, analytics. If no data layer → report and stop.

## AUDIT ORDER: Schema → Ingestion → Transformation → Output

## SCAN DIMENSIONS

**Schema**: `grep -rn "CREATE TABLE\|ALTER TABLE\|schema\|migration" --include="*.sql" --include="*.py" --include="*.ts"`
- Validate: types match usage, nullable fields have defaults, indexes on FKs
- Tools: `sqlfluff lint --rules L010,L014,L016`, `alembic check`, `prisma validate`

**Ingestion**: `grep -rn "pd\.read_\|spark\.read\|requests\.\|httpx\.\|curl" --include="*.py" --include="*.ipynb"`
- Check: error handling, retries, timeouts, dtype validation on load
- Cleaning: `grep -rn "fillna\|dropna\|replace\|interpolate" --include="*.py"`
- Actionable: `grep -rn "try:\|except\|retry\|timeout" --include="*.py" -A 3 -B 1`, validate `df.dtypes`

**Transformation**: `grep -rn "concat\|merge\|join\|groupby\|GROUP BY" --include="*.py" --include="*.sql" --include="*.ipynb"`
- Check: join key integrity, dtype coercion, null handling in aggs
- Actionable: `grep -rn "on=\|how=\|suffixes=" --include="*.py"`, `grep -rn "coalesce\|IFNULL\|COALESCE" --include="*.sql"`

**dbt/YAML**: `grep -rn "tests:\|schema:\|column_name\|data_type" --include="*.yml" --include="*.yaml"`
- Check: not_null, unique, accepted_values, relationships tests
- Actionable: `dbt test --select tag:schema`, `grep -rn "severity:\|warn_if:" --include="*.yml"`

**Data Profiling** (measure, don't just grep):
- Python: `df.describe(include='all')`, `df.isnull().sum()/len(df)`, `df.nunique()`
- SQL: `SELECT COUNT(*), COUNT(DISTINCT col), MIN/MAX(col), SUM(CASE WHEN col IS NULL THEN 1 ELSE 0 END) FROM table`
- Tools: `great_expectations suite new`, `soda scan -c configuration.yml -d warehouse checks.yml`
- Drift: `grep -rn "schema_evolution\|alter_column\|rename_column" --include="*.py" --include="*.sql"`

## COMPLETENESS MATRIX
| Layer | Complete? | Issues |
|-------|-----------|--------|
| Schema | Has types + constraints | |
| Ingestion | Has error handling + retry | |
| Transformation | Has validation + null handling | |
| Output | Has monitoring + alerts | |

## OUTPUT
```
### Data Quality Report
| Check | Status | Location | Impact |
### Schema Issues
- [table]: [issue]
### Recommendations
- P0: [critical fix]
- P1: [improvement]
```

## Testing Patterns (verify data quality)
1. **Schema Contract**: `pytest tests/contract/test_schema.py` — types, nullability, defaults match ORM/Prisma/DDL
2. **Data Freshness**: `SELECT max(updated_at) FROM table; assert > now() - interval '24h'`
3. **Volume Anomaly**: `pytest tests/data/test_volume.py` — row count within 2σ of 7-day rolling avg
4. **Referential Integrity**: `dbt test --select test_type:relationships` — FK orphan check
5. **Distribution Drift**: KS-test / chi-square vs baseline; alert p-value < 0.01
6. **Null/Anomaly**: `df.select_dtypes(include='number').apply(lambda x: (x-x.mean()).abs()>3*x.std())` — 3σ

## Edge Cases
1. **Late-Arriving Data**: Watermark/lookback windows; `WHERE event_time > watermark AND event_time < now() - grace_period` — backfill strategy doc required
2. **Schema Evolution**: Additive-only (new cols nullable, defaults); breaking → new table + view alias; `alembic revision --autogenerate` must show ADD not DROP
3. **Duplicate Detection**: `ROW_NUMBER() OVER (PARTITION BY pk ORDER BY ingest_ts DESC) = 1` — dedup at ingestion; log dup keys to dead-letter
4. **Referential Integrity in DW**: Dim keys before fact load; `dbt run-operation stage_external_sources` for late-binding dims; surrogate key collisions → hash diff
5. **Timezone/Calendar Drift**: UTC storage mandatory; `grep -rn "timezone\|tz_convert\|astimezone" --include="*.py"`; fiscal calendars versioned

## Rules
1. Schema BEFORE ingestion. 2. Measure data (profiling) not just code (grep). 3. Every finding: file:line + evidence.

## Refs
deep-debugging · code-review-agent · best-practices

## Anti-Patterns (what to STOP doing)
- Skip schema validation → ship contract tests in CI
- Ignore error handling → add retries + dead-letter + alerting
- No data profiling → mandatory GE/Soda checks per pipeline
- Python-only bias → audit SQL, dbt, Spark equally
- Skip dbt/YAML patterns → enforce `dbt test` gate in CI
- Assume ingestion succeeds → validate row counts, checksums at each hop
- Silent schema drift → `alembic check` + `prisma validate` in PR gate
- No late-data strategy → document watermark/grace period per source
- Hard-delete in DW → soft-delete + tombstone; audit trail required
- Magic numbers in transforms → extract to config/params with versioning
