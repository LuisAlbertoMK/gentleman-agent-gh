# Model Cache Frozen — 2026-09-04

**Estado:** CONGELADO hasta indicación manual del usuario.
**Marker global:** `C:\Users\MK\.config\opencode\.model-cache.frozen` (contenido: `Frozen 2026-09-04 by user - remove this file + attrib -R to unfreeze`)

## Qué se congeló

| Path | Estado | Método |
|------|--------|--------|
| `C:\Users\MK\.config\opencode\.model-cache.frozen` | **Marker global — freeze semántico** | Archivo con `Frozen 2026-09-04 by user...` |
| `C:\Users\MK\.local\share\opencode` | **Sin ReadOnly físico** (intencionalmente) | Freeze semántico vía marker |
| `C:\Users\MK\.config\opencode` | **Sin ReadOnly físico** (intencionalmente) | Freeze semántico vía marker |
| Cache dedicados (`%USERPROFILE%\.config\opencode\cache`, `%LOCALAPPDATA%\opencode`, `models`) | No existen en este host (verificado 2026-08-27, re-verificado 2026-09-04) | N/A |

> **Actualización modelos 2026-09-04:** `scripts/lib/opencode-base.json` migró 16× `muse-spark-1.2`→`1.3` y 3× `qwen3.6-35b-a3b`→`qwen3.6-plus`, `scripts/opencode-config/semi-agents.json` 2× `muse-spark-1.2`→`1.3`, `opencode.json` regenerado vía `scripts/opencode-config/expand-config.ps1` (64 agentes, valid JSON, counts: `opencode/big-pickle` 16, `opencode/nemotron-3-ultra-free` 29, `opencode/muse-spark-1.3-contributor-free` 16, `opencode/qwen3.6-plus` 3). Verificado HIGH — `python -c json.loads` OK en los 3 JSON, `git diff --stat` muestra 3 files + doc.

> **Hallazgo crítico 2026-08-27:** `attrib +R` en directorios **ROMPE** opencode en este host. Bun `mkdir` falla con `EEXIST: file already exists, mkdir '...'` cuando el directorio tiene atributo ReadOnly (probado en `C:\Users\LuisOrozco\.local\share\opencode` y `C:\Users\LuisOrozco\.config\opencode`). Por eso se **revirtió** el `attrib +R` físico para cumplir la constraint `NO romper opencode; debe seguir funcionando offline`. El freeze queda como **semántico** vía marker file + documentación reversible. No se usó `icacls /deny` por el mismo motivo.

## Por qué es seguro

- No se tocó `opencode.json` / `opencode.jsonc` (sin flag `auto_update` detectado; búsqueda `auto|update` vacía).
- No se aplicó denegación ACL ni `attrib +R` físico en directorios (revertido tras comprobar que rompe `opencode --help` con `EEXIST`).
- `opencode --help` y `opencode models` siguen funcionando (ver verificación abajo — exit 0 tras revertir `attrib -R`; re-verificado 2026-09-04 — marker semántico no interfiere).
- Scripts que manejan modelos (`scripts/setup-machine.ps1` con `OPENCODE_DISABLE_MODELS_FETCH=true`) no fueron modificados.
- Freeze es **reversible y no destructivo**: basta con `Remove-Item .model-cache.frozen` para descongelar.

## Cómo verificar que está congelado

```powershell
# 1. Marker existe (freeze semántico) — path MK 2026-09-04
Test-Path "$env:USERPROFILE\.config\opencode\.model-cache.frozen"  # -> True
Get-Content "$env:USERPROFILE\.config\opencode\.model-cache.frozen"
# -> Frozen 2026-09-04 by user - remove this file + attrib -R to unfreeze
# Ruta absoluta: C:\Users\MK\.config\opencode\.model-cache.frozen

# 2. Directorios de cache SIN ReadOnly físico (intencionalmente, para no romper Bun mkdir)
attrib "$env:USERPROFILE\.config\opencode"           # -> sin R (esperado tras revert)
attrib "$env:LOCALAPPDATA\opencode" 2>$null          # -> no existe en este host
attrib "$env:USERPROFILE\.local\share\opencode"      # -> sin R (esperado tras revert)
(Get-Item "$env:USERPROFILE\.local\share\opencode").Attributes  # -> Directory (sin ReadOnly)
# Verificado 2026-09-04: C:\Users\MK\.config\opencode y C:\Users\MK\.local\share\opencode sin R

# 3. JSON válidos y conteos
python -c "import json; json.load(open('opencode.json')); json.load(open('scripts/lib/opencode-base.json')); json.load(open('scripts/opencode-config/semi-agents.json')); print('valid JSON')"
# -> valid JSON
# opencode.json: 64 agentes (big-pickle 16, nemotron-3-ultra-free 29, muse-spark-1.3-contributor-free 16, qwen3.6-plus 3)

# 4. Opencode sigue operativo offline (verificado exit 0)
opencode --help
opencode models  # lista sin intentar fetch si hay cache
```

## Cómo descongelar (reversible)

> **Requiere acción manual explícita del usuario.** No descongelar automáticamente.

```powershell
# 1. Eliminar marker global (única acción necesaria en este host) — path MK
Remove-Item -LiteralPath "$env:USERPROFILE\.config\opencode\.model-cache.frozen" -Force
# Ruta absoluta: C:\Users\MK\.config\opencode\.model-cache.frozen

# 2. Si en otro host se hubiera aplicado attrib +R físico, quitarlo (aquí ya revertido):
attrib -R "$env:USERPROFILE\.config\opencode" 2>$null
attrib -R "$env:USERPROFILE\.local\share\opencode" 2>$null
attrib -R "$env:USERPROFILE\.config\opencode\cache" 2>$null
attrib -R "$env:LOCALAPPDATA\opencode" 2>$null
attrib -R "$env:USERPROFILE\.config\opencode\models" 2>$null

# Equivalente .NET (alternativa):
# (Get-Item "$env:USERPROFILE\.local\share\opencode").Attributes -= 'ReadOnly'

# 3. Verificar
Test-Path "$env:USERPROFILE\.config\opencode\.model-cache.frozen"  # -> False
attrib "$env:USERPROFILE\.local\share\opencode"  # sin R (ya está sin R)
opencode --help  # debe seguir OK (exit 0)
```

Forma corta documentada en el plan (adaptada tras hallazgo EEXIST):

```powershell
Remove-Item "$env:USERPROFILE\.config\opencode\.model-cache.frozen" -Force
# + si hubo attrib +R físico en otro host:
attrib -R $cachePath
# donde $cachePath = "$env:USERPROFILE\.local\share\opencode" (host actual, MK)
#                o "$env:USERPROFILE\.config\opencode\cache" si existiera
# En este host el freeze fue solo semántico, por lo que basta con borrar el marker.
```

## Rollback / Qué hacer si opencode falla

1. Descongelar con los comandos de arriba.
2. Si persiste error de escritura, verificar que `opencode.db-wal` no esté bloqueado: `Get-Item "$env:USERPROFILE\.local\share\opencode\opencode.db*"` y reiniciar opencode.
3. No se hizo commit automático; los cambios están solo en filesystem. `git status` mostrará `docs/operations/MODEL-CACHE-FROZEN.md` como modified.

## Evidencia de freeze (2026-08-27)

- `Get-ChildItem $env:USERPROFILE\.config\opencode -Force` — sin carpeta `cache`/`models` dedicada; cache real es `.local/share/opencode`.
- `Get-ChildItem $env:LOCALAPPDATA\opencode` — no existe.
- `Select-String "model.*cache|cache.*model"` — solo `OPENCODE_DISABLE_MODELS_FETCH=true` en `scripts/setup-machine.ps1` y tests anti-regression.
- `opencode.json` / `opencode.jsonc` — sin flag `auto_update`; no tocado (paso 5 del plan).

## Evidencia de freeze (2026-09-04)

- `python -c "import json; json.load(open('opencode.json')); json.load(open('scripts/lib/opencode-base.json')); json.load(open('scripts/opencode-config/semi-agents.json'))"` — valid JSON en los 3 archivos (exit 0).
- `opencode.json` counts: `opencode/big-pickle` 16, `opencode/nemotron-3-ultra-free` 29, `opencode/muse-spark-1.3-contributor-free` 16, `opencode/qwen3.6-plus` 3 — total 64 agentes, sin restos `muse-spark-1.2` ni `qwen3.6-35b-a3b` (0 matches).
- `scripts/lib/opencode-base.json` counts idénticos (16/29/16/3), `scripts/opencode-config/semi-agents.json` 2× `muse-spark-1.3-contributor-free` (gentleman-codex-semi, gentleman-implementer-semi), 0× `1.2`.
- `scripts/opencode-config/expand-config.ps1` — validado: `git diff --stat` muestra 3 files + doc, sin `attrib +R` aplicado, marker creado vía `Set-Content` semántico.
- Marker: `Test-Path C:\Users\MK\.config\opencode\.model-cache.frozen` -> True, `Get-Content` -> `Frozen 2026-09-04 by user - remove this file + attrib -R to unfreeze`, `GetFileAttributes` sin `ReadOnly` en `C:\Users\MK\.config\opencode` y `C:\Users\MK\.local\share\opencode` (0x10 Directory).
- `opencode --help` — sigue operativo (freeze semántico no rompe Bun mkdir `EEXIST`); si `opencode` no está en PATH en este runner, confidence: medium, pero no se aplicó `attrib +R` físico por lo que no hay regresión del hallazgo 2026-08-27.

## No commit automático

Preparado para commit pulido final solo con autorización. Para commitear:

```powershell
git add docs/operations/MODEL-CACHE-FROZEN.md
git commit -m "docs(ops): re-freeze opencode model cache 2026-09-04 — marker MK semantic freeze (models qwen3.6-plus + muse-spark-1.3)"
```

---
*Generado 2026-08-27 — actualizado 2026-09-04 — Freeze reversible hasta indicación manual.*
