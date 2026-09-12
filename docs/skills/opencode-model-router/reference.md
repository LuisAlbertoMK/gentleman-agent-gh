# OpenCode Model Router — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/opencode-model-router/SKILL.md) for the core routing table and security gate.

---

## Examples (5)

### Example 1: Security Audit Request
**User**: "Audit our JWT auth for vulnerabilities"
**Route**: Security/vulnerability → DELEGATE → `gentleman-security-sub` (Nemotron 3 Ultra Free)
**Why**: Security tasks need deep analysis; Ultra Free has 1M context for large codebases
**Fallback**: If twin unavailable → `gentleman-deep-sub` → `general`

### Example 2: Implement a Feature Plan
**User**: "Execute the plan in SPEC-042: add rate limiting to API"
**Route**: Implement plan → DELEGATE → `gentleman-implementer-sub` (Muse Spark 1.3 Contributor Free)
**Why**: Precise execution, no over-analysis, fast model for implementation
**Fallback**: `gentleman-quick-sub` → `general`

### Example 3: Deep Debugging Multi-File Bug
**User**: "Root cause: intermittent 500s on /checkout, spans 3 services"
**Route**: Deep debugging → DELEGATE → `gentleman-deep-sub` (Nemotron 3 Ultra Free)
**Why**: Hypothesis-driven debugging needs reasoning depth + large context
**Fallback**: `general` (no twin for deep-debugging beyond first fallback)

### Example 4: Quick One-Line Fix
**User**: "Fix typo in error message at src/api/errors.ts:47"
**Route**: Quick edit → DELEGATE → `gentleman-quick-sub` (Big Pickle)
**Why**: Atomic edit, low risk, fast free model
**Fallback**: `general`

### Example 5: Architecture Decision
**User**: "Should we migrate from REST to gRPC for internal services?"
**Route**: Architecture/code review → DIRECT → `gentleman-vMK`
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
**Resolution**: Route to fast model (Big Pickle / Muse Spark 1.3) even if task type suggests Ultra
**Rule**: Context budget > model preference when 100K-150K

### Edge Case 3: Twin Exists But Hidden (Whitelist Mismatch)
**Scenario**: `gentleman-frontend-sub` exists but not in orchestrator whitelist
**Resolution**: Falls to `general` silently (per RUNTIME REALITY). Fix: regenerate opencode.json
**Detection**: `scripts/regenerate-opencode.ps1 -Yes` then verify `gh api /repos/.../actions/runs`

### Edge Case 4: Free Tier Exhausted Mid-Task
**Scenario**: Nemotron 3 Ultra Free quota hit during `security-sub` delegation
**Resolution**: Automatic fallback chain triggers → `deep-sub` → `general`
**Monitoring**: Check delegation logs for "fallback activated" pattern

---

## Anti-Patterns (6)

1. **Route sensitive data to subagent** — Credentials, PII, secrets must stay in primary agent (DIRECT)
2. **Delegate when context >150K** — Forces DIRECT regardless of task type
3. **Skip fallback chain** — Always define fallback; twins can be unavailable
4. **Pay when free covers it** — Qwen3.7 Max, paid Nemotron — free tier handles 95% of tasks
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
`gentleman-implementer-sub` (Muse Spark 1.3 Contributor Free) — precise execution. No unrequested changes.
**Avoid**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

## Extended — Security Gate, Strategy y notas de catálogo (movido por ADR-048, cycle32-p2)

> Contenido externalizado de .agents/skills/opencode-model-router/SKILL.md para cumplir ≤3200B. Core queda con routing table, IMPLEMENTER, CONTEXT->ACTION.

### Security Gate (movido de SKILL.md)
1. Credentials/secrets/PII? -> **DIRECT**
2. Recurring task (cron/CI)? -> **DIRECT**
3. Context >150K? -> **DIRECT**
4. Otherwise -> route a tabla.

### Strategy (FREE — 2026-09-10, SSoT opencode.json — 4 ids free vigentes, 58 agents)
- **100% Free**: SSoT opencode.json: 4 ids free vigentes (58 agents) — opencode/big-pickle (200K), opencode/muse-spark-1.3-contributor-free (200K code-gen), opencode/nemotron-3-ultra-free (1M), opencode-go/qwen3.6-plus. Sin mimo/ling/1.2 — todos retirados o actualizados a 1.3.
- **1M context**: Nemotron 3 Ultra Free (1M) — único 1M vigente SSoT
- **Vision**: MiMo V2.5 Free retirado 2026-09-10 (pi.dev 404) — sin vision free vigente; fallback Big Pickle para docs/general (SSoT)
- **Code-gen**: Muse Spark 1.3 Contributor Free (200K) para implement/quick/script — SSoT opencode.json (actualizado desde 1.2)
- **Fallback universal**: Big Pickle (always free) — SSoT

### Notas de catálogo (ground truth 2026-09-10 SSoT movido)
Ground truth 2026-09-10 SSoT: opencode/big-pickle (200K reasoning), opencode/muse-spark-1.3-contributor-free (200K code-gen), opencode/nemotron-3-ultra-free (1M reasoning), opencode-go/qwen3.6-plus. Retirados: opencode/mimo-v2.5-free (404 pi.dev), opencode/ling-3.0-flash-fin-free (1M retirado), opencode/muse-spark-1.2-contributor-free (reemplazado por 1.3), opencode/nemotron-3.5-lightning-free (sucesor super-free pero no en SSoT final 4), opencode/deepseek-v4-flash-free y opencode/laguna-s-2.1-free (no SSoT final). Pricing table 6 free explícitos históricos consolidados a 4 SSoT.

* Nemotron 3 Ultra Free es único 1M en SSoT final. Modelos históricos tabla 8 ids migrados/retirados — ningún retired activo en routing table.

> Nota SSoT: 58 agents en opencode.json, 4 modelos free vigentes. Laguna/DeepSeek/MiMo/Ling no asignados — fallback Big Pickle si se estabiliza pi.dev, pero no SSoT.

### Changelog (movido)
- 3.1 (2026-09-02): Sync catálogo free vigente (8 ids). Reemplaza nemotron-3-super-free->3.5-lightning-free, kimi-k2.5-free->mimo-v2.5-free, deepseek->ling/muse-spark según dominio. Añade columna Ctx y nota vigencia. Drift fix cycle32-p2: gentleman-seo -> Nemotron 3 Ultra Free (SSoT opencode.json), gentleman-datascience -> Big Pickle (SSoT opencode.json).
- 3.2 (2026-09-10): Retiro MiMo V2.5 Free (pi.dev 404) — quick/datascience → Big Pickle (SSoT opencode.json/opencode-base.json); implementer prescriptivo → Muse Spark 1.3 Contributor Free. Solo prescriptivo actualizado; historial 2026-09-02 intacto.
