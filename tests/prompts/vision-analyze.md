# vision-analyze — golden prompt

**Trigger**: "analyze-ui", "visual-review", "captura"

```
Capture http://localhost:4200 with Playwright and analyze the UI locally via Ollama (moondream/llava).
Report layout, alignment, contrast and broken components in ui mode. Keep it 100% local (127.0.0.1:11434),
RAM-aware model selection, no external APIs.
```

**Expected**: `VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`
