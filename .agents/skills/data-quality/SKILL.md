---
name: data-quality
description: "Trigger: data audit, pipeline audit, schema validation, data governance, ETL. Audit data quality and reliability."
triggers: "data audit, data pipeline audit, schema validation, data governance, ETL audit, data quality check, data review"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Reviewing data pipelines, schemas, ETL, analytics. No data layer → report and stop.

## AUDIT ORDER: Schema → Ingestion → Transformation → Output

## SCAN DIMENSIONS
**Schema**: `grep -rn "CREATE TABLE\|ALTER TABLE\|schema\|migration" --include="*.sql" --include="*.py" --include="*.ts"` — types match usage, nullable have defaults, indexes on FKs. Tools: `sqlfluff lint --rules L010,L014,L016`, `alembic check`, `prisma validate`.
**Ingestion**: `grep -rn "pd\.read_\|spark\.read\|requests\.\|httpx\.\|curl" --include="*.py" --include="*.ipynb"` — error handling, retries, timeouts, dtype validation. Cleaning: `fillna\|dropna\|replace\|interpolate`. Actionable: `try:\|except\|retry\|timeout`, validate `df.dtypes`.
**Transformation**: `grep -rn "concat\|merge\|join\|groupby\|GROUP BY" --include="*.py" --include="*.sql" --include="*.ipynb"` — join key integrity, dtype coercion, null handling. Actionable: `on=\|how=\|suffixes=`, `coalesce\|IFNULL\|COALESCE`.
**dbt/YAML**: `grep -rn "tests:\|schema:\|column_name\|data_type" --include="*.yml" --include="*.yaml"` — not_null, unique, accepted_values, relationships. Actionable: `dbt test --select tag:schema`, `severity:\|warn_if:`.
**Profiling** (measure, don't just grep): Python `df.describe()`, `df.isnull().sum()/len(df)`, `df.nunique()` · SQL `COUNT(*), COUNT(DISTINCT col), MIN/MAX, SUM(CASE WHEN col IS NULL...)` · Tools: `great_expectations suite new`, `soda scan` · Drift: `schema_evolution\|alter_column\|rename_column`.

## COMPLETENESS MATRIX
Schema: types+constraints | Ingestion: error handling+retry | Transformation: validation+null handling | Output: monitoring+alerts.

## OUTPUT
`DQ-REPORT:<date> Checks:<n> Schema:[table]:[issue] P0:[critical fix] P1:[improvement]`

## Rules
1. Schema BEFORE ingestion. 2. Measure (profiling) not just grep. 3. Every finding: file:line + evidence.

## Anti-Patterns
Skip schema validation · Ignore error handling · No profiling · Python-only bias · Skip dbt/YAML · Assume ingestion succeeds · Silent schema drift · No late-data strategy · Hard-delete in DW · Magic numbers in transforms