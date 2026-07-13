# Reporte Consolidado v1+v2+v3 — gentleman-agent-gh

**Fecha:** 2026-07-12
**Método:** Consolidación de tres pasadas de auditoría técnica independientes
**Archivos analizados:** 283 archivos, 58 scripts PowerShell, 58 skills, CI, opencode.json (388 líneas), AGENTS.md (205 líneas)

---

## Resumen Ejecutivo

| Severidad | Cantidad | Impacto |
|---|---|---|
| 🔴 Alta | 5 | Seguridad/funcionalidad comprometida |
| 🟠 Media | 4 | Deuda técnica, gaps de documentación |
| 🟡 Baja | 3 | Inconsistencias menores, legibilidad |

**Patrón central identificado:** El proyecto verifica que las cosas *corran* (exit code 0, sintaxis válida) pero tiene puntos ciegos sistemáticos en verificar que las cosas *funcionen como se pretende*.

---

## Hallazgos Verificados

### 🔴 ALTA SEVERIDAD

#### 1. Instalador Linux/macOS incompleto (v3)
**Archivo:** `scripts/setup-machine.sh` vs `scripts/setup-machine.ps1`
**Impacto:** El agente principal (`gentleman-vMK`) y los 10 agentes SDD no funcionan en Linux/macOS porque no se copia `AGENTS.md` ni se crea la junction de `prompts/sdd/`.

| Paso | Windows (.ps1) | Linux/macOS (.sh) |
|---|---|---|
| Junction `prompts/sdd/` | ✅ Step 6b | ❌ Ausente |
| Copia `AGENTS.md` a config global | ✅ Step 6c | ❌ Ausente |
| Instalación binarios MCP | ✅ Step 7 | ❌ Ausente |

**Fix:** Portar Steps 6b/6c/7 (~70 líneas PowerShell → bash: `ln -s`/`cp` en vez de `New-Item -ItemType Junction`/`Copy-Item`).

#### 2. SkillSpector gate decorativo en CI (v2)
**Archivo:** `scripts/skillspector-gate.ps1`
**Impacto:** Los tres caminos de salida terminan en `exit 0`. El paso se llama "blocking on failures" pero es imposible que falle.

```powershell
# Los tres caminos terminan en exit 0:
if ($sp) { ...; exit 0 }      # CLI disponible
if ($dockerOk) { ...; exit 0 } # Docker disponible
exit 0                          # Ninguno disponible
```

**Fix:** Hacer que `$riskScore -ge $FailOnRisk` retorne `exit 1`, o quitar "blocking" del nombre del step.

#### 3. CHANGELOG.md path roto en release.yml (v1)
**Archivo:** `.github/workflows/release.yml`
**Impacto:** `awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md > release-notes.md` apunta a `CHANGELOG.md` en raíz, pero el archivo está en `docs/CHANGELOG.md`.

**Fix:** Cambiar `CHANGELOG.md` → `docs/CHANGELOG.md`.

#### 4. Permisos contradictorios en agentes analyze-only (v1/v2)
**Archivo:** `opencode.json`
**Impacto:** Agentes "solo análisis" tienen `bash: allow, write: allow` a nivel plataforma pese a que `_analyze-only-protocol.md` prohíbe escritura. Control blando existe, control duro no lo refleja.

**Fix:** Para agentes `_analyze-only-protocol`, usar `"write": "deny"` y `"bash": { "git log *": "allow", "git diff *": "allow", ... }`.

#### 5. SkillSpector no instalado en CI (v2)
**Archivo:** `.github/workflows/quality-gate.yml`
**Impacto:** No hay `pip install` ni `Dockerfile` para SkillSpector. El gate nunca ejecuta escaneo real.

**Fix:** Agregar `pip install git+https://github.com/NVIDIA/SkillSpector.git` como paso previo.

---

### 🟠 MEDIA SEVERIDAD

#### 6. 9 agentes SDD ocultos + sin modelo (v3)
**Archivo:** `opencode.json`, `README.md`
**Impacto:** 9 agentes `sdd-*` existen con permisos completos pero no aparecen documentados. Si heredan modelo de pago, hay costo no garantizado.

**Fix:** Documentar en README + asignar modelo explícito.

#### 7. Auto-score con sesgo documentado (+2-3.3 pts) (v2)
**Archivo:** `.learnings/bias-calibration.json`, `.project.json`
**Impacto:** El 9.3/10 debería leerse con offset de sesgo.

**Fix:** Aplicar corrección: `score - offset_promedio`.

#### 8. Testing casi inexistente (v1/v2)
**Archivo:** `scripts/score-auto.tests.ps1`
**Impacto:** 14 tests cubren 1 función de 1 script. 57 scripts sin cobertura.

**Fix:** Priorizar Pester tests para scripts críticos (skill-graph, setup-machine, check-mcp-security).

#### 9. Score README (8.5) vs .project.json (9.3) desincronizado (v1)
**Archivo:** `README.md`, `.project.json`
**Impacto:** Drift de documentación, mina credibilidad.

**Fix:** Sincronizar o automatizar actualización.

---

### 🟡 BAJA SEVERIDAD

#### 10. `catch {}` vacío en wisdom-stats.ps1 (v1)
**Archivo:** `scripts/wisdom-stats.ps1:98`
**Impacto:** Swallow de errores, contradice Best Practices.

**Fix:** Agregar `Write-Debug` o logging.

#### 11. Dependabot con ecosistema nuget irrelevante (v1)
**Archivo:** `.github/dependabot.yml`
**Impacto:** Genera ruido, no hay archivos .NET en el repo.

**Fix:** Quitar bloque `package-ecosystem: "nuget"`.

#### 12. $skillLookup definición después de uso (v3)
**Archivo:** `scripts/skill-graph.ps1`
**Impacto:** No es bug (PowerShell lazy evaluation), pero dificulta análisis manual.

**Fix:** Mover definición antes de funciones que lo consumen.

---

## Conclusión

El proyecto tiene ingeniería de prompts sobresaliente pero gaps concretos y corregibles en:
1. **Seguridad real** (gate decorativo, permisos no reflejados en plataforma)
2. **Portabilidad** (installer Linux/macOS incompleto)
3. **Verificación** (CI mide "corrió" no "funcionó")

Ningún fix es mayor a ~70 líneas. El más crítico (#1) afecta funcionalidad core en 2/3 plataformas.

---

## Fixes Ejecutados en Esta Sesión

Ver sección inferior para cambios aplicados.
