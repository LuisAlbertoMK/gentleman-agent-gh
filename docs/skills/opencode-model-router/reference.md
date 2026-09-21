# OpenCode Model Router — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/opencode-model-router/SKILL.md) for the core routing table and security gate.

---

## Examples (5)

### Example 1: Security Audit Request
**User**: "Audit our JWT auth for vulnerabilities"
**Route**: Security/vulnerability → DELEGATE → `gentleman-security-sub` (DeepSeek V4 Flash)
**Why**: Security tasks need deep analysis; DeepSeek V4 Flash provides strong reasoning
**Fallback**: If twin unavailable → `gentleman-deep-sub` → `general`

### Example 2: Implement a Feature Plan
**User**: "Execute the plan in SPEC-042: add rate limiting to API"
**Route**: Implement plan → DELEGATE → `gentleman-implementer-sub` (MiMo V2.5)
**Why**: Precise execution, no over-analysis, strong code-gen model
**Fallback**: `gentleman-quick-sub` → `general`

### Example 3: Deep Debugging Multi-File Bug
**User**: "Root cause: intermittent 500s on /checkout, spans 3 services"
**Route**: Deep debugging → DELEGATE → `gentleman-deep-sub` (DeepSeek V4 Flash)
**Why**: Hypothesis-driven debugging needs reasoning depth
**Fallback**: `general` (no twin for deep-debugging beyond first fallback)

### Example 4: Quick One-Line Fix
**User**: "Fix typo in error message at src/api/errors.ts:47"
**Route**: Quick edit → DELEGATE → `gentleman-quick-sub` (Muse Spark 1.3 Contributor Free)
**Why**: Atomic edit, low risk, fast model
**Fallback**: `general`

### Example 5: Architecture Decision
**User**: "Should we migrate from REST to gRPC for internal services?"
**Route**: Architecture/code review → DIRECT → `gentle-MK`
**Why**: Strategic decisions need primary agent judgment, not delegation

---

## Testing Patterns (3)

### Pattern 1: Routing Decision Verification
```bash
# Given a task description, verify correct route is chosen
echo "Audit JWT auth" | grep -q "Security" && echo "→ security-sub"
echo "Fix typo" | grep -q "Quick" && echo "→ quick-sub"
echo "Architecture review" | grep -q "DIRECT" && echo "→ vMK"
```

### Pattern 2: Fallback Chain Simulation
```bash
# Simulate twin unavailable → verify fallback resolves
mock_twin_unavailable() { return 1; }
route_task() {
  local primary="$1" fallback1="$2" fallback2="$3"
  $primary || $fallback1 || $fallback2 || echo "general"
}
route_task mock_twin_unavailable "deep-sub" "general"  # Should print "general"
```

### Pattern 3: Security Gate Enforcement
```bash
# Tasks with secrets/recurring/large-context must route DIRECT
assert_direct() {
  local task="$1"
  [[ "$task" =~ (secret|credential|PII) ]] && echo "DIRECT forced" && return
  [[ "$task" =~ (cron|CI|recurring) ]] && echo "DIRECT forced" && return
  echo "Normal routing"
}
assert_direct "Deploy with AWS_SECRET_KEY"  # → DIRECT forced
assert_direct "Nightly cron job"            # → DIRECT forced
```

---

## Edge Cases (4)

### Edge Case 1: Hybrid Task (Security + Implementation)
**Scenario**: "Fix the SQL injection vuln AND implement the patch"
**Resolution**: Split → Security analysis → `security-sub`; Implementation → `implementer-sub`
**Rule**: Never combine analysis + execution in one delegation

### Edge Case 2: Context Near Threshold (140K tokens)
**Scenario**: Large codebase task at 140K context
**Resolution**: Route to fast model (Muse Spark 1.3 Contributor / MiMo V2.5) even if task type suggests stronger model
**Rule**: Context budget > model preference when 100K-150K

### Edge Case 3: Twin Exists But Hidden (Whitelist Mismatch)
**Scenario**: `gentleman-frontend-sub` exists but not in orchestrator whitelist
**Resolution**: Falls to `general` silently (per RUNTIME REALITY). Fix: regenerate opencode.json
**Detection**: `scripts/regenerate-opencode.ps1 -Yes` then verify `gh api /repos/.../actions/runs`

### Edge Case 4: Subagent Unavailable Mid-Task
**Scenario**: Subagent delegation fails or times out during `security-sub` delegation
**Resolution**: Automatic fallback chain triggers → `deep-sub` → `general`
**Monitoring**: Check delegation logs for "fallback activated" pattern

---

## Anti-Patterns (6)

1. **Route sensitive data to subagent** — Credentials, PII, secrets must stay in primary agent (DIRECT)
2. **Delegate when context >150K** — Forces DIRECT regardless of task type
3. **Skip fallback chain** — Always define fallback; twins can be unavailable
4. **Pay when free covers it** — Qwen 3.7 Plus is paid; prefer Muse Spark 1.3 Contributor / MiMo V2.5 for most tasks
5. **Forget security gate** — Check 3 conditions BEFORE consulting routing table
6. **Combine analysis + execution in one delegation** — Split: analyzer understands, implementer executes

## Externalized Sections (ADR-007 compression)
## 📏 CONTEXT → ACTION
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

---

> See [reference.md](docs/skills/opencode-model-router/reference.md) for extended details, examples, and detailed patterns.

## ⚠️ RUNTIME REALITY (opencode 1.18.x)
- `gentleman-*` sin sufijo = `mode: primary` → Task tool NO los expone.
- Twins `-sub` (implementer/security/deep/quick) SÍ: `subagent` + `hidden` + whitelist `task` (template `orchestrator`).
- DELEGATE ✅ = twin. DELEGATE ⚠️ = `general` — NO reportar falla.
- `opencode.json` sync SSoT: `scripts/regenerate-opencode.ps1` (`-Yes` regenera; CI falla si deriva).


## 🔧 IMPLEMENTER
`gentleman-implementer-sub` (MiMo V2.5 — `opencode-go/mimo-v2.5`) — precise execution. No unrequested changes.
**Avoid**: Qwen 3.7 Plus (re-plans, paid), DeepSeek V4 Flash (over-analyzes).

## Extended — Security Gate, Strategy y notas de catálogo (movido por ADR-048, cycle32-p2)

> Contenido externalizado de .agents/skills/opencode-model-router/SKILL.md para cumplir ≤3200B. Core queda con routing table, IMPLEMENTER, CONTEXT->ACTION.

### Security Gate (movido de SKILL.md)
1. Credentials/secrets/PII? -> **DIRECT**
2. Recurring task (cron/CI)? -> **DIRECT**
3. Context >150K? -> **DIRECT**
4. Otherwise -> route a tabla.

### Strategy (SSoT opencode.json — 5 model ids, ~58 agents)

> ⚠️ **Skill is NOT SSoT** — opencode.json is the source of truth. Model assignments below reflect actual config as of 2026-09-18.

- **Model IDs (5 unique)**:
  - `opencode-go/deepseek-v4-flash` — DeepSeek V4 Flash (security, seo, performance, deep, reviewer, aem, reasoning, initializer)
  - `opencode-go/mimo-v2.5` — MiMo V2.5 (codex, infra, implementer, sdd-apply/archive/init/tasks)
  - `opencode-go/muse-spark-1.3-contributor` — Muse Spark 1.3 Contributor (orchestrator, quick, frontend, datascience, docs, sdd-verify)
  - `opencode-go/qwen3.7-plus` — Qwen 3.7 Plus (code-review specialist)
  - `opencode/muse-spark-1.3-contributor-free` — Muse Spark 1.3 Contributor Free (subagents: quick-sub, frontend-sub, datascience-sub, docs-sub)
- **No Nemotron** in current config — retired
- **No big-pickle** in current config — `opencode/big-pickle` not found; docs referenced this as alias but it does not exist in opencode.json
- **Subagent free tier**: `-sub` variants use `opencode/muse-spark-1.3-contributor-free`; primary agents use `opencode-go/` prefix models
- **Vision**: No vision-specific model in current config

### Notas de catálogo (ground truth SSoT 2026-09-18)
Ground truth SSoT opencode.json: 5 model ids, ~58 agents. Actual:
- `opencode-go/deepseek-v4-flash` — deep reasoning, security, seo, performance, aem, reviewer, initializer
- `opencode-go/mimo-v2.5` — code-gen, infra, implementer, sdd
- `opencode-go/muse-spark-1.3-contributor` — orchestrator, quick, frontend, datascience, docs, sdd-verify
- `opencode-go/qwen3.7-plus` — code-review specialist
- `opencode/muse-spark-1.3-contributor-free` — subagent free tier

Retirados (no en config actual): `opencode/big-pickle`, `opencode/nemotron-3-ultra-free`, `opencode-go/qwen3.6-plus`, `opencode/mimo-v2.5-free`, `opencode/ling-3.0-flash-fin-free`, `opencode/muse-spark-1.2-contributor-free`, `opencode/nemotron-3.5-lightning-free`, `opencode/deepseek-v4-flash-free`, `opencode/laguna-s-2.1-free`. No vision free vigente.

* Modelos históricos migrados/retirados — ningún retired activo en routing table.

> Nota SSoT: 5 model ids en opencode.json. No hay free-tier distinction for `opencode-go/` prefix models (all require auth). Only `opencode/muse-spark-1.3-contributor-free` is explicitly free-tier.

### Changelog (movido)
- 3.1 (2026-09-02): Sync catálogo free vigente (8 ids). Reemplaza nemotron-3-super-free->3.5-lightning-free, kimi-k2.5-free->mimo-v2.5-free, deepseek->ling/muse-spark según dominio. Añade columna Ctx y nota vigencia. Drift fix cycle32-p2: gentleman-seo -> Nemotron 3 Ultra Free (SSoT opencode.json), gentleman-datascience -> Big Pickle (SSoT opencode.json).
- 3.2 (2026-09-10): Retiro MiMo V2.5 Free (pi.dev 404) — quick/datascience → Big Pickle (SSoT opencode.json/opencode-base.json); implementer prescriptivo → Muse Spark 1.3 Contributor Free. Solo prescriptivo actualizado; historial 2026-09-02 intacto.
- 3.3 (2026-09-18): Documentation alignment with actual opencode.json. Removed stale "big-pickle", "Nemotron 3 Ultra Free", "qwen3.6-plus" references. Actual 5 model ids: deepseek-v4-flash, mimo-v2.5, muse-spark-1.3-contributor, qwen3.7-plus, muse-spark-1.3-contributor-free. Security/seo/performance → deepseek-v4-flash (was Nemotron); infra/implementer → mimo-v2.5 (was muse-spark-free/big-pickle); frontend/datascience/docs → muse-spark-1.3-contributor (was big-pickle).
