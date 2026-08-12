# 01 — Análisis detallado · H2: guard de colisión `extraPermKeys` (verificación línea a línea)

**Sesión origen**: Unit B (ses_0214c7, adversarial) · **Re-verificación**: Unit D (2026-08-07, read/grep tool output)

## 1. Código vulnerable (antes)

`scripts/lib/generate-opencode-config.js:161-170` (verificado por read):

```js
  if (agentOverrides.extraPermKeys) {
    // Guard against clobbering template permissions
    const templateKeys = ['bash', 'edit', 'read', 'write'];   // ← L163 HARDCODEADO
    const collisions = templateKeys.filter(k => k in agentOverrides.extraPermKeys);
    if (collisions.length > 0) {
      console.error(`ERROR: extraPermKeys for "${agentName}" collides with template keys: ${collisions.join(', ')}`);
      process.exit(1);
    }
    Object.assign(permission, agentOverrides.extraPermKeys);  // ← L169 SHALLOW
  }
```

## 2. Blind spot

El template `auto-sub` (`permission-templates.json:171-178`) y `readonly` (`:38-47`) definen la clave `task`:

```jsonc
"auto-sub": { "bash": { "*": "allow" }, "task": { "*": "deny" } }
"readonly": { "bash": { "*": "deny" }, "edit": "deny", "write": "deny", "task": { "*": "deny" } }
```

`task` NO está en `['bash','edit','read','write']` → el filtro de colisión (L164) no lo matchea.

## 3. Cadena de explotación

```
override.extraPermKeys = { "task": { "*": "allow" } }
  → L164: templateKeys.filter(...) → [] (task no está en la lista) → guard pasa
  → L169: Object.assign(permission, { task: { "*": "allow" } })  // reemplaza task:{*:deny}
  → permission.task = { "*": "allow" }   // ESCALADA: el subagente auto/readonly puede delegar a cualquier agente
```

El fail-closed `task:{"*":"deny"}` de `auto-sub` existe precisamente para impedir delegación desde subagentes (diseño documentado en `docs/mejoras/2026-08-07-modo-auto-herencia-subagentes.md` §5).

## 4. Estado de explotación: LATENTE (verificado)

`scripts/lib/agent-overrides.json` (68 líneas) — 2 usos vivos de `extraPermKeys.task`:

| Override | Líneas | Template | ¿Template tiene `task`? | ¿Escala? |
|---|---|---|---|---|
| `sdd-orchestrator` | 17-35 | `sddorchestrator` {bash,edit,read,write} | NO | NO (deny+allowlist; add puro) |
| `gentleman-vMK-auto` | 48-67 | `auto` {bash} | NO | NO (deny+allowlist; add puro) |

→ Ningún override actual escala. El vector queda abierto para cualquier override futuro o comprometido.

## 5. Fix propuesto (ADR-024, Cycle #2)

```js
    // Guard against clobbering template permissions (dynamic: template keys incluyen task, etc.)
    const templateKeys = Object.keys(template);
```

- Los templates son objetos planos de permisos (verificado: `permission-templates.json` — cada template = mapa de claves de permiso; `_doc`/`_generated` son claves raíz del archivo, no de templates).
- `Object.keys(template)` para `auto-sub` = `['bash','task']` → colisión con `task` detectada → ERROR + exit 1 (fail-closed).
- **Drop-in safe**: ambos overrides vivos colisionarían con `[]` (adds puros) → no rompen el SSoT.
- OJO `_doc`/`_generated`: si en el futuro se añadieran metadatos DENTRO de un template, `Object.keys` los incluiría; el diseño actual los mantiene a nivel raíz del archivo — verificar en el PR de Cycle #2.

## 6. Gap de test (verificado)

`generate-config.Tests.ps1:87-101` — el test de colisión usa `bash` (única clave que el guard ya cubría). NO existe test de colisión con `task`. Fix debe incluir el test nuevo (7/7):

```powershell
It 'exits 1 when extraPermKeys collides with task (auto-sub template)' {
    # fixture con extraPermKeys = @{ task = @{ '*' = 'allow' } } sobre gentleman-quick-sub-auto
    # → expect exit 1 + 'collides with template keys' + 'task'
}
```