---
name: data-quality
description: "Trigger: data audit, data pipeline audit, schema validation, data governance, ETL audit. Audit data layer quality and reliability."
triggers: "data audit, data pipeline audit, schema validation, data governance, ETL audit, data quality check, data review"
---
## When to Use
Reviewing data pipelines, schemas, ETL processes, analytics. If no data layer → report and stop.

## AUDIT ORDER: Schema → Ingestion → Transformation → Output

## SCAN DIMENSIONS

**Schema**: `grep -rn "CREATE TABLE\|ALTER TABLE\|schema\|migration" --include="*.sql" --include="*.py" --include="*.ts"` → schema definitions
- Validate: types match usage, nullable fields have defaults, indexes on FKs
- Tools: `sqlfluff lint`, `alembic check`, `prisma validate`

**Ingestion**: `grep -rn "pd\.read_\|spark\.read\|requests\.\|httpx\.\|curl" --include="*.py" --include="*.ipynb"` → data sources
- Check: error handling, retries, timeouts, data type validation on load
- `grep -rn "fillna\|dropna\|replace\|interpolate" --include="*.py"` → cleaning patterns

**Transformation**: `grep -rn "concat\|merge\|join\|groupby\|GROUP BY" --include="*.py" --include="*.sql" --include="*.ipynb"` → transforms
- Check: join key integrity, data type coercion, null handling in aggregations

**dbt/YAML**: `grep -rn "tests:\|schema:\|column_name\|data_type" --include="*.yml" --include="*.yaml"` → dbt models, schema tests
- Check: not_null, unique, accepted_values, relationships tests defined

**Data Profiling** (measure, don't just grep):
- Column stats: null %, unique count, min/max, distribution
- Volume: row count anomalies, schema drift
- Integrity: orphaned FKs, constraint violations

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

## Rules
1. Schema BEFORE ingestion. 2. Measure data (profiling) not just code (grep). 3. Every finding: file:line + evidence.

## Refs
deep-debugging · code-review-agent · best-practices

## Anti-Patterns
Skip schema validation · Ignore error handling · No data profiling · Python-only bias · Skip dbt/YAML patterns
