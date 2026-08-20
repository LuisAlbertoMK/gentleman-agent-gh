# data-quality — Reference Materials

> **Externalized from** .agents/skills/data-quality/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains dbt/YAML and profiling scan detail.

## dbt/YAML
`grep -rn "tests:\|schema:\|column_name\|data_type" --include="*.yml" --include="*.yaml"` — not_null, unique, accepted_values, relationships. Actionable: `dbt test --select tag:schema`, `severity:\|warn_if:`.

## Profiling (measure, don't just grep)
Python `df.describe()`, `df.isnull().sum()/len(df)`, `df.nunique()` · SQL `COUNT(*), COUNT(DISTINCT col), MIN/MAX, SUM(CASE WHEN col IS NULL...)` · Tools: `great_expectations suite new`, `soda scan` · Drift: `schema_evolution\|alter_column\|rename_column`.