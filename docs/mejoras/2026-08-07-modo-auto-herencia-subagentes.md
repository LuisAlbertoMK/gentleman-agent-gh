# Mejora: Herencia completa de modo `auto` — orquestador + subagentes sin `ask`

**Fecha**: 2026-08-07 · **Trigger**: "modo auto sigue pidiendo permiso — las sub-delegaciones no deberían bloquearse" (reportado por usuario)
**Pre-Answer Gate**: ✅ Cross-referenciado contra `docs/mejoras/2026-08-01-custom-agents-runtime-fallback.md` (F4 — SDD subagents como patrón de referencia), `docs/mejoras/2026-07-30-auto-permission-analysis.md`, `.agents/skills/opencode-model-router/SKILL.md:11-17` (mode-aware routing); Engram (`mem_search` all_projects) sin resultados previos sobre `auto-sub` heredando `*: allow` sin `ask` → hallazgo NO duplicado.

---

## 1. Summary

El modo `auto` existente aplicaba el template `auto` al orquestador (`gentleman-vMK-auto`) y a los 4 primary agents (`-auto`), pero **no heredaba** el patrón a los subagentes (`-sub-auto`). El protocolo en `AGENTS.md:44-46` dice que en modo auto se appendea `-auto` a los subagent delegables — pero los 4 twins de subagent existentes (`-sub`) eran `mode: subagent` con `*: allow` + `ask` patterns, no el perfil auto-puro. **Resultado**: el orquestador en modo auto delegaba a un subagent que a su vez lanzaba peticiones de permiso (`ask`).

**Fix**: creado template `auto-sub` (`: allow` + `deny` floor, **cero `ask`**) y applied a los 4 subagent twins → `gentleman-{deep,quick,codex,implementer}-sub-auto`. El orquestador `gentleman-vMK-auto` ahora whitelistea `task.*` para estos 4 twins (fail-closed con `"task.*": "deny"` + allowlist).

---

## 2. Findings

| # | Hallazgo | Evidencia | Confidence |
|---|----------|-----------|------------|
| F1 | Template `auto` (orquestador + primaries) heredaba `ask` patterns de `readwrite` base → delegaciones en modo auto sí pedían permiso | `scripts/lib/permission-templates.json` (antes del fix) | high |
| F2 | Los 4 subagent twins (`-sub`) existentes usaban template `readwrite` → `bash.* = ask` → bloqueo en sub-delegación | `opencode.json` (antes del fix) | high |
| F3 | El orchestrator `gentleman-vMK-auto` no tenía whitelist `task` para subagentes → delegación caía a `general` (mismo root cause que `2026-08-01` F1-F3) | `opencode.json` (antes del fix) | high |
| F4 | Template `auto-sub` (`*: allow` + deny floor, 0 ask) no existía — los subagent twins necesitaban su propio template para heredar auto-purity | `permission-templates.json.TEMPLATES` (antes) | high |
| F5 | `mode-gate.ps1` tenía routing para `-sub-auto` en modo auto, pero el redirect de `.gentleman-mode → auto` no incluía los twins `-sub-auto` | `scripts/mode-gate.ps1:L83` (antes) | medium |

---

## 3. Causa raíz

El diseño de modos (`AGENTS.md:44-46`) appende `-auto` a los agentes delegables (primaries y subagents). Para los **primaries**, el template `auto` ya existía. Para los **subagents**, no existía un template `auto-sub` — heredaban `readwrite`/`readonly` que contienen `ask patterns`. Esto significaba que una delegación orquestador→subagent→sub-subagent en modo auto podía bloquearse en el segundo salto. El template `auto-sub` cierra esta brecha: `bash.* = allow` + `deny` floor (network, git push --force, supply chain), **cero `ask`**.

---

## 4. Decisión / Implementación

### Cambios en SSoT (scripts/lib/)
| Archivo | Cambio |
|---------|--------|
| `permission-templates.json` | +template `auto-sub` (`: allow` + deny floor, 0 ask) en `TEMPLATES` y `SEMI` |
| `generate-opencode-config.js` | +4 entries `-sub-auto` en `TEMPLATE_MAP`; `stats['auto-sub']` counter + log línea |
| `opencode-base.json` | +4 definiciones agents `-sub-auto` (`mode: subagent`, `hidden: true`, model heredado) |
| `permission-gate-lib.ps1` | +`AutoForce` switch: en modo auto, el orquestador y subagents usan `*: allow` sin pedir permiso |

### Cambios en wrappers/scripts
| Archivo | Cambio |
|---------|--------|
| `scripts/mode-gate.ps1` | Redirect `.gentleman-mode → auto` incluye los 4 `-sub-auto` twins; verificación `bash.* = allow` + `ask=0` |
| `scripts/permission-gate.ps1` | `-AutoForce` flag propagado al delegate |
| `scripts/use-gentleman.ps1` | +4 entries `-sub-auto = 'auto'` en `$agentTypeMap` |
| `scripts/regenerate-opencode.ps1` | Verifier +4 checks `auto-twin-*` + `orch-auto-task-failclosed`; stats línea `AUTO-SUB variants` |

### Cambios en root
| Archivo | Cambio |
|---------|--------|
| `opencode.json` | Regenerado: 2695 líneas (de 2760 — -13 `ask` lines), 86341 B (budget 98304 B) |
| `README.md` | +4 filas tabla `-sub-auto` (L61-64) |

### Whitelist fail-closed (orquestador)
`gentleman-vMK-auto.permission.task`:
```
"*": "deny"  ← fail-closed
gentleman-deep-sub-auto: "allow"
gentleman-quick-sub-auto: "allow"
gentleman-codex-sub-auto: "allow"
gentleman-implementer-sub-auto: "allow"
```

---

## 5. Especificaciones técnicas

### template `auto-sub` (SSoT: `permission-templates.json`)
```jsonc
"auto-sub": {
  "mode": "subagent",
  "permission": {
    "bash": { "*": "allow" },
    "task": { "*": "deny" }
  }
}
```
- `bash.* = allow` → subagentes en auto NO piden permiso
- `task.* deny` → subagentes en auto NO pueden delegar (fail-closed)
- El `deny floor` (network, git push --force, supply-chain) se aplica como override de `shared-deny-rules.json`

### Permisos heredados (deny floor aplicado encima de `auto-sub`)
| Categoría | Patterns |
|-----------|----------|
| Network | curl, wget, ssh, telnet, nc, nmap, dig, nslookup, ping, git clone/fetch upstream |
| git push --force | `git push --force`, `git push --force-with-lease`, `git push --delete` |
| Supply chain | npm install, npm i, npm exec, npx, pip install, yarn add, bun install |
| Destructive | git clean -fdx (evasión), rm -rf /, shred |
| Zero-width evasión | U+200B, tabs múltiples, triple space |
```

---

## 6. Verificación

### Pipeline de generación + cross-ref
```bash
$ scripts/regenerate-opencode.ps1 -Yes
[regenerate-opencode] OK - 21 checks, 0 failed
```

| Check | Result |
|-------|--------|
| `auto-twin-gentleman-deep-sub-auto` | subagent hidden:true bash:*=allow ask=0 |
| `auto-twin-gentleman-quick-sub-auto` | subagent hidden:true bash:*=allow ask=0 |
| `auto-twin-gentleman-codex-sub-auto` | subagent hidden:true bash:*=allow ask=0 |
| `auto-twin-gentleman-implementer-sub-auto` | subagent hidden:true bash:*=allow ask=0 |
| `orch-auto-task-failclosed` | vMK-auto fail-closed with 4 auto-sub twins allowed |
| `readonly-bash-deny` | 14 read-only agents deny bash.* |
| `cross-ref-check` README | OK (39 agents match) |
| `config-size-budget` | 86341 B ≤ 98304 B |

### Tests Pester
| Suite | Result |
|-------|--------|
| `mode-gate.Integration` | 18/18 PASS |
| `permission-gate` | 108/108 PASS |
| `expand-config` | 5/5 PASS |
| `route-agent` | 7/7 PASS |

### Verificación post-delegation (subagent output)
```
$ a = cfg.agent."gentleman-deep-sub-auto"
$ a.mode        → "subagent"
$ a.hidden      → true
$ a.permission.bash."*" → "allow"
(PS: 0 ask entries)
```

---

## 7. Recomendaciones

1. **✅ Ejecutado**: los 4 subagent twins ahora heredan `auto` purity (`: allow`, 0 `ask`).
2. **Pendiente (opcional)**: los 6 especialistas read-only sin twin (`-security-sub`, `-seo-sub`, `-infra-sub`, `-frontend-sub`, `-performance-sub`, `-datascience-sub`, `-docs-sub`) siguen usando template `readonly` en modo auto → heredan `bash.* = ask`. Si se requiere auto-purity para estos también, aplicar el mismo patrón (`auto-sub-readonly` template o override). Actualmente aceptable: los read-only specialists NO son delegables con side-effects destructivos, el `ask` es un control de seguridad adicional.
3. **CI/CD**: el `quality-gate.yml` ya corre `node --validate` + `cross-ref-check` — el drift se detecta automáticamente.
4. `gentleman-codex-sub-auto` y `gentleman-implementer-sub-auto` usan DeepSeek V4 Flash (no codex ni implementer primary) porque el model routing del twin hereda del `-sub` base, no del primary. Verificado consistente con `.project.json`.

---

## 8. Confidence

- **`ask=0` en todos los agents `-auto`**: `confidence: high` (verificado con `opencode.json` JSON parse + grep directo en bash permissions + 4 checks de verifier + tests Pester `permission-gate` con 108 assertions).
- **`deny floor` (network/supply-chain/git force)**: `confidence: high` (`permission-gate.Tests.ps1` 108 PASS incluyen supply-chain deny + zero-width evasión).
- **Template `auto-sub` heredado correctamente**: `confidence: high` (generated output match en regenerate-opencode + post-write-validate).
- **`orch-auto-task-failclosed`**: `confidence: high` (verifier explícito + mode-gate integration test 18 PASS).
- **Recomendación pendiente sobre read-only specialists**: `confidence: medium` (inferencia — los read-only no tienen twin auto, pero no es un bloqueo funcional documentado en AGENTS.md:48 como `denied`).
```
