# Health Signal Log Example

```markdown
## Health Check: context-watchdog
- Last loaded: 3 sessions ago
- Applied: Yes (compression triggered at 60%)
- Effective: Yes (context reduced 40%)
- Action: None — healthy

## Health Check: bitacora
- Last loaded: 12 sessions ago
- Applied: No (auto-trigger failed?)
- Effective: N/A
- Action: Review trigger — should auto-fire on session end
```

## Regeneration Flow
```
1. Audit: read current SKILL.md + check Engram usage
2. Drift: do triggers still match real queries?
3. Update: fix gaps, tighten triggers
4. Compress: re-Karpathy if >5% new content
5. Bump: major=structural, minor=content
6. Log changelog + commit
```
