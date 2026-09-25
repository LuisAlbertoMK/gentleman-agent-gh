# Permisos: paridad ESTRICTA con gentle-ai (overlay global)

- Fecha: 2026-09-25
- Rama: `experimento/mejora-permisos-gentle-ai`
- Base (stacked): `experimento/mejora-ronda11-deuda` (`b700098b`)
- Tier RDD: 2
- Estado: propuesto (PR stacked, no mergeado)

## 1. Fuente exacta (evidencia)

- Repo: `Gentleman-Programming/gentle-ai` (Alan)
- Archivo: `internal/components/permissions/inject.go`
- Lineas: `63-101`
- Var: `openCodeOverlayJSON`

Ese overlay es **global** (un solo bloque `permission`): **bash + read**.
NO define `write`, NO define `edit`, y NO hay permisos por-agente.

Bloque de Alan (verbatim):

```json
{
  "permission": {
    "bash": {
      "*": "allow",
      "git commit *": "ask", "git push *": "ask", "git push": "ask",
      "git push --force *": "ask", "git rebase *": "ask", "git reset --hard *": "ask",
      "ssh": "ask", "ssh *": "ask", "scp": "ask", "scp *": "ask",
      "sftp": "ask", "sftp *": "ask", "rsync": "ask", "rsync *": "ask"
    },
    "read": {
      "*": "allow",
      "*.env": "deny", "*.env.*": "deny", "**/.env": "deny", "**/.env.*": "deny",
      "**/secrets/**": "deny", "**/credentials.json": "deny", "**/.ssh/**": "deny",
      "**/.credentials/**": "deny", "**/Library/Keychains/**": "deny",
      "**/.aws/credentials": "deny", "**/.config/gh/hosts.yml": "deny",
      "**/*.pem": "deny", "**/*.key": "deny"
    }
  }
}
```

## 2. Por que esta base (no `origin/main`)

`origin/main` es el mundo viejo de 58 agentes + variantes `-auto` (descartado
para este slice). La linea **single-mode** `experimento/mejora-ronda11-deuda`
(`b700098b`) tiene 44 agentes single-mode, 5 templates. La paridad estricta se
aplica sobre esa linea.

## 3. Cambios

### 3.1 `scripts/lib/opencode-base.json` -> `permission`

El bloque global pasa a ser **exactamente** el de Alan: `bash` + `read`.
Se **eliminan** `write` y `edit` por completo.

| Clave  | Antes (conteo) | Despues (conteo) |
|--------|----------------|------------------|
| bash   | 77 reglas (15 allow / 8 ask / 54 deny) | 15 reglas (1 allow / 14 ask) |
| read   | 29 reglas (1 allow / 28 deny) | 14 reglas (1 allow / 13 deny) |
| write  | 39 reglas (1 allow / 38 deny) | eliminada |
| edit   | 33 reglas (1 allow / 32 deny) | eliminada |

### 3.2 `scripts/lib/permission-templates.json` -> deltas por-agente neutralizados

Objetivo: que **todos** los agentes hereden el overlay global, sin deltas de
bash/read/write/edit por-agente. Solo se conserva la delegacion estructural
(`task` / `delegate`), que no es paridad de permisos.

| Template         | Antes | Despues |
|------------------|-------|---------|
| `orchestrator`   | `bash:{*:ask}` + `task:{...}` | `task:{...}` |
| `readwrite`      | `bash:{*:ask}` | `{}` |
| `readonly`       | `bash:{*:deny}` + `edit:deny` + `write:deny` + `task:{*:deny}` | `task:{*:deny}` |
| `sddorchestrator`| `bash:{*:ask}` + `edit:{*:allow}` + `read:allow` + `write:{*:allow}` | `{}` |
| `reviewer`       | `bash:{*:ask}` + `edit:deny` + `write:deny` | `{}` |

Nota sobre `sddorchestrator`: la instruccion pedia quitar `bash:{*:ask}`. Se
quitan **tambien** `edit`/`write`/`read` porque, al eliminar `write`/`edit` del
global, esos deltas dejarian de ser byte-identicos al root y el generador los
emitiria como permisos **por-agente** en `sdd-orchestrator` y
`gentle-orchestrator` (rompiendo la paridad). `read:allow` tambien se quita por
el mismo motivo.

### 3.3 `opencode.json` (regenerado)

`scripts/regenerate-opencode.ps1 -Yes` -> **OK** (20 checks, 0 failed),
44 agentes, `Test-Json` True. Resultado: root = `bash` + `read`; **ningun**
agente tiene delta de `bash`/`read`/`write`/`edit`.

### 3.4 Self-check del gate tocado (obligatorio y documentado)

En `scripts/regenerate-opencode.ps1` existia el check **`readonly-bash-deny`**:
exigia que 14 agentes read-only resolvieran `bash.* = deny`. Con paridad
estricta eso es **imposible** (Alan no tiene agentes read-only; el global es
`bash.* = allow`). Consecuencia legitima de la paridad.

- **Retirado**: `readonly-bash-deny`.
- **Reemplazado por**: `permission-parity-global` — verifica que **ningun**
  agente defina `bash`/`read`/`write`/`edit` (paridad estricta) y que cada
  agente resuelva su `bash.*` efectivo al default global. Falla si se
  reintroduce un delta de write/edit o un override que no matchee el root.
- **`orch-task-failclosed`**: sin cambios, sigue pasando (el task whitelist del
  orquestador se conserva).

## 4. IMPACTO (leer antes de mergear)

1. **Se van 54 denies de bash.** El runtime pasa de una allowlist curada a
   `bash.* = allow` + 14 asks (git commit/push/force/rebase/reset --hard y
   ssh/scp/sftp/rsync). Ya **no** se deniegan `curl`, `wget`, `ftp`,
   `Invoke-WebRequest`, `Remove-Item`, `rm`, `bun/yarn`, etc.
2. **Los sub-agentes read-only dejan de serlo.** `gentleman-security(-sub)`,
   `-seo`, `-infra`, `-frontend`, `-performance`, `-datascience`, `-docs` y sus
   twins pasan de `bash:deny` + `edit/write:deny` a heredar el global
   (`bash:allow`, sin write/edit). La read-only queda **solo** por prompt
   (`_analyze-only-protocol.md`), no por gate de permisos.
3. **Se pierden `write` y `edit` como claves de permisos.** Sus denies (p.ej.
   `edit`/`write` de `opencode.json`, `AGENTS.md`, `prompts/**`,
   `.config/opencode/**`) **ya no se aplican**. Quien pueda editar puede editar
   esos archivos (sujeto a los defaults de opencode, no a nuestro overlay).
4. **`gentleman-reviewer`** deja de tener `edit/write:deny`.
5. Divergencia gate-vs-runtime: el **gate** (`shared-deny-rules.json`) conserva
   sus denies (`ftp/scp/rsync=deny`, `git clone=ask`), que ya no reflejan el
   runtime. Queda como deuda explicita (archivo fuera del write-scope de este
   slice).

## 5. Variante segura (NO aplicada)

Documentada para el reviewer; **no** se aplico:

- Conservar `readonly` y `reviewer` con `bash:deny` + `edit/write:deny` (los
  agentes de analisis siguen siendo verdaderamente read-only y el reviewer no
  edita).
- Conservar `write`/`edit` globales (con sus denies de secretos/config).
- Mantener los denies de red de R10-S4 (`curl/wget/ftp/scp/rsync=deny`).

Tradeoff: **no** es paridad estricta con gentle-ai (Alan no tiene esas
restricciones), pero conserva las defensas que el repo venia arrastrando.
Elegir esta variante si la prioridad es seguridad local por encima de la
paridad exacta.

## 6. Verificacion

- `node scripts/lib/generate-opencode-config.js --validate` -> `VALID`
  (in-sync, semantic compare).
- `Get-Content opencode.json -Raw | Test-Json` -> `True`.
- Agentes: **44**.
- `scripts/regenerate-opencode.ps1 -Yes` -> `OK - 20 checks, 0 failed`
  (incluye `permission-parity-global`).
- `Invoke-Pester tests/permission-rules-consistency.Tests.ps1` -> **19/19 PASS**
  (se actualizaron las aserciones que codificaban los denies viejos).

## 7. Deuda / residual (fuera de este slice)

Estas suites aun codifican los denies viejos y **fallaran** si se ejecutan (no
estan en el write-scope de este slice; el pre-commit gate solo corre tests
staged, por eso no bloquea este commit):

- `tests/contract-permission.Tests.ps1` -> 3 fails
  (`readonly ... bash/task deny, no edit/write`; `readwrite minimal`;
  `orchestrator denies task ...`).
- `tests/opencode-json-validation.Tests.ps1` -> 1 fail (`git push --force is denied`).
- `scripts/tests/generate-config.Tests.ps1` -> usa fixtures `readonly` propias;
  revisar si su expectativa sigue vigente.

Follow-up sugerido: actualizar esas suites a la paridad (o aplicar la variante
segura si se decide revertir la paridad).

## 8. Rollback

```
git revert <sha_del_commit_de_paridad>
node scripts/lib/generate-opencode-config.js      # o scripts/regenerate-opencode.ps1 -Yes
```

El revert restaura `opencode-base.json`, `permission-templates.json`,
`regenerate-opencode.ps1` y el test; luego regenerar `opencode.json` para dejar
el runtime consistente con el SSoT revertido.
