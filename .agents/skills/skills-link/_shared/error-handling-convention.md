# Error Handling Convention

> Shared reference for all skills. Skills MUST follow these patterns for error handling.

## Standard Table Format

Every skill that performs operations SHOULD include an error handling table:

| Error | Symptom | Handler |
|-------|---------|---------|
| Command not found | Exit code 127 / "not found" | Check PATH, suggest install command |
| Permission denied | Exit code 1 / "permission denied" | Suggest `chmod +x` or admin shell |
| Timeout | Process hangs >30s | Set timeout, kill process, suggest retry |
| Network error | DNS failure / connection refused | Retry with backoff, check connectivity |
| Invalid input | Parse error / validation failure | Show expected format, log invalid input |
| Unexpected error | Non-zero exit / cryptic error | Log full output, suggest manual inspection |

## Try/Catch Pattern

```powershell
try {
    # operation
} catch {
    Write-Debug "[skill-name] $($_.Exception.Message)"
    throw  # or handle gracefully
}
```

## Error Response Format

When a skill encounters an error, respond with:
1. **What failed**: one-line description
2. **Why**: root cause (if known)
3. **Suggested fix**: actionable next step
4. **Fallback**: what happens if not fixed

## Gates

- If a critical operation fails → STOP, report, do NOT continue
- If a non-critical operation fails → WARN, log, continue if safe
- If 3 consecutive non-critical operations fail → STOP and escalate
