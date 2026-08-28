# Model Cache Frozen — 2026-08-27

**Estado:** CONGELADO hasta indicación manual del usuario.
**Marker global:** `C:\Users\LuisOrozco\.config\opencode\.model-cache.frozen` (contenido: `Frozen 2026-08-27 by user - remove this file + attrib -R to unfreeze`)

## Qué se congeló

| Path | Estado | Método |
|------|--------|--------|
| `C:\Users\LuisOrozco\.config\opencode\.model-cache.frozen` | **Marker global — freeze semántico** | Archivo con `Frozen 2026-08-27 by user...` |
| `C:\Users\LuisOrozco\.local\share\opencode` | **Sin ReadOnly físico** (intencionalmente) | Freeze semántico vía marker |
| `C:\Users\LuisOrozco\.config\opencode` | **Sin ReadOnly físico** (intencionalmente) | Freeze semántico vía marker |
| Cache dedicados (`%USERPROFILE%\.config\opencode\cache`, `%LOCALAPPDATA%\opencode`, `models`) | No existen en este host (verificado 2026-08-27) | N/A |

> **Hallazgo crítico 2026-08-27:** `attrib +R` en directorios **ROMPE** opencode en este host. Bun `mkdir` falla con `EEXIST: file already exists, mkdir '...'` cuando el directorio tiene atributo ReadOnly (probado en `C:\Users\LuisOrozco\.local\share\opencode` y `C:\Users\LuisOrozco\.config\opencode`). Por eso se **revirtió** el `attrib +R` físico para cumplir la constraint `NO romper opencode; debe seguir funcionando offline`. El freeze queda como **semántico** vía marker file + documentación reversible. No se usó `icacls /deny` por el mismo motivo.

## Por qué es seguro

- No se tocó `opencode.json` / `opencode.jsonc` (sin flag `auto_update` detectado; búsqueda `auto|update` vacía).
- No se aplicó denegación ACL ni `attrib +R` físico en directorios (revertido tras comprobar que rompe `opencode --help` con `EEXIST`).
- `opencode --help` y `opencode models` siguen funcionando (ver verificación abajo — exit 0 tras revertir `attrib -R`).
- Scripts que manejan modelos (`scripts/setup-machine.ps1` con `OPENCODE_DISABLE_MODELS_FETCH=true`) no fueron modificados.
- Freeze es **reversible y no destructivo**: basta con `Remove-Item .model-cache.frozen` para descongelar.

## Cómo verificar que está congelado

```powershell
# 1. Marker existe (freeze semántico)
Test-Path "$env:USERPROFILE\.config\opencode\.model-cache.frozen"  # -> True
Get-Content "$env:USERPROFILE\.config\opencode\.model-cache.frozen"
# -> Frozen 2026-08-27 by user - remove this file + attrib -R to unfreeze

# 2. Directorios de cache SIN ReadOnly físico (intencionalmente, para no romper Bun mkdir)
attrib "$env:USERPROFILE\.config\opencode"           # -> sin R (esperado tras revert)
attrib "$env:LOCALAPPDATA\opencode" 2>$null          # -> no existe en este host
attrib "$env:USERPROFILE\.local\share\opencode"      # -> sin R (esperado tras revert)
(Get-Item "$env:USERPROFILE\.local\share\opencode").Attributes  # -> Directory (sin ReadOnly)

# 3. Opencode sigue operativo offline (verificado exit 0)
opencode --help
opencode models  # lista sin intentar fetch si hay cache
```

## Cómo descongelar (reversible)

> **Requiere acción manual explícita del usuario.** No descongelar automáticamente.

```powershell
# 1. Eliminar marker global (única acción necesaria en este host)
Remove-Item -LiteralPath "$env:USERPROFILE\.config\opencode\.model-cache.frozen" -Force

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
# donde $cachePath = "$env:USERPROFILE\.local\share\opencode" (host actual)
#                o "$env:USERPROFILE\.config\opencode\cache" si existiera
# En este host el freeze fue solo semántico, por lo que basta con borrar el marker.
```

## Rollback / Qué hacer si opencode falla

1. Descongelar con los comandos de arriba.
2. Si persiste error de escritura, verificar que `opencode.db-wal` no esté bloqueado: `Get-Item "$env:USERPROFILE\.local\share\opencode\opencode.db*"` y reiniciar opencode.
3. No se hizo commit automático; los cambios están solo en filesystem. `git status` mostrará `docs/operations/MODEL-CACHE-FROZEN.md` como untracked.

## Evidencia de freeze (2026-08-27)

- `Get-ChildItem $env:USERPROFILE\.config\opencode -Force` — sin carpeta `cache`/`models` dedicada; cache real es `.local/share/opencode`.
- `Get-ChildItem $env:LOCALAPPDATA\opencode` — no existe.
- `Select-String "model.*cache|cache.*model"` — solo `OPENCODE_DISABLE_MODELS_FETCH=true` en `scripts/setup-machine.ps1` y tests anti-regression.
- `opencode.json` / `opencode.jsonc` — sin flag `auto_update`; no tocado (paso 5 del plan).

## No commit automático

Preparado para commit pulido final solo con autorización. Para commitear:

```powershell
git add docs/operations/MODEL-CACHE-FROZEN.md
git commit -m "docs(ops): freeze opencode model cache (reversible) — marker semantic freeze (attrib +R reverted: breaks Bun mkdir)"
```

---
*Generado 2026-08-27 — Freeze reversible hasta indicación manual.*
