# opencode.json — Diff para Modos Semi/Auto/Manual

**Este archivo documenta los cambios exactos necesarios en opencode.json**
**(archivo protegido contra escritura — debe aplicarse manualmente)**

---

## 1. Nuevos Agents: Gentleman-Quick

Agregar DESPUÉS del bloque `gentleman-quick` existente (line ~295):

```json
"gentleman-quick-semi": {
    "description": "Fast executor — SEMI-AUTO (safe commands auto-approve, writes/network ask/deny)",
    "model": "opencode/mimo-v2.5-free",
    "mode": "primary",
    "prompt": "{file:prompts/gentleman-quick.md}\n\n{file:prompts/shared/_core-behavior-gp.md}",
    "permission": {
        "bash": {
            "*": "ask",
            "git status": "allow",
            "git log *": "allow",
            "git diff *": "allow",
            "git show *": "allow",
            "git branch *": "allow",
            "git stash list": "allow",
            "ls *": "allow",
            "Get-ChildItem *": "allow",
            "Test-Path *": "allow",
            "pwd": "allow",
            "Get-Location": "allow",
            "echo *": "allow",
            "Write-Output *": "allow",
            "cat *": "allow",
            "Get-Content *": "allow",
            "grep *": "allow",
            "rg *": "allow",
            "Select-String *": "allow",
            "which *": "allow",
            "Get-Command *": "allow",
            "npm test *": "allow",
            "pytest *": "allow",
            "go test *": "allow",
            "Invoke-Pester *": "allow",
            "dotnet test *": "allow",
            "rm *": "deny",
            "rm -rf *": "deny",
            "curl *": "deny",
            "wget *": "deny",
            "Invoke-WebRequest *": "deny",
            "Invoke-RestMethod *": "deny",
            "Invoke-Expression *": "deny",
            "irm *": "deny",
            "iwr *": "deny",
            "iex *": "deny",
            "Remove-Item *": "deny",
            "Start-BitsTransfer *": "deny",
            "ssh *": "deny",
            "docker *": "deny",
            "docker-compose *": "deny",
            "python *": "deny",
            "python3 *": "deny",
            "node *": "deny",
            "ruby *": "deny",
            "perl *": "deny",
            "php *": "deny",
            "npx *": "deny",
            "certutil *": "deny",
            "bitsadmin *": "deny",
            "schtasks *": "deny",
            "reg *": "deny",
            "sc *": "deny",
            "icacls *": "deny",
            "cmd /c *": "deny",
            "cmd.exe *": "deny",
            "powershell -c *": "deny",
            "powershell -command *": "deny",
            "powershell -enc *": "deny",
            "powershell -File *": "deny",
            "powershell.exe *": "deny",
            "pwsh *": "deny",
            "pwsh.exe *": "deny",
            "Start-Process *": "deny",
            "Invoke-Command *": "deny",
            "Register-ScheduledTask *": "deny",
            "New-Service *": "deny",
            "net user *": "deny",
            "net localgroup *": "deny",
            "net share *": "deny",
            "net use *": "deny",
            "net session *": "deny",
            "Add-MpPreference *": "deny",
            "Set-MpPreference *": "deny",
            "saps *": "deny",
            "start *": "deny",
            "telnet *": "deny",
            "ncat *": "deny",
            "nc *": "deny",
            "Test-NetConnection *": "deny"
        }
    }
},
"gentleman-quick-auto": {
    "description": "Fast executor — AUTO (all auto-approve except push + destructives + network)",
    "model": "opencode/mimo-v2.5-free",
    "mode": "primary",
    "prompt": "{file:prompts/gentleman-quick.md}\n\n{file:prompts/shared/_core-behavior-gp.md}",
    "permission": {
        "bash": {
            "*": "allow",
            "git push": "ask",
            "git push *": "ask",
            "git push --force *": "deny",
            "git push --delete *": "deny",
            "git push --force-with-lease *": "ask",
            "rm *": "deny",
            "rm -rf *": "deny",
            "curl *": "deny",
            "wget *": "deny",
            "Invoke-WebRequest *": "deny",
            "Invoke-RestMethod *": "deny",
            "Invoke-Expression *": "deny",
            "irm *": "deny",
            "iwr *": "deny",
            "iex *": "deny",
            "Remove-Item *": "deny",
            "Start-BitsTransfer *": "deny",
            "ssh *": "deny",
            "docker *": "deny",
            "docker-compose *": "deny",
            "python *": "deny",
            "python3 *": "deny",
            "node *": "deny",
            "ruby *": "deny",
            "perl *": "deny",
            "php *": "deny",
            "npx *": "deny",
            "certutil *": "deny",
            "bitsadmin *": "deny",
            "schtasks *": "deny",
            "reg *": "deny",
            "sc *": "deny",
            "icacls *": "deny",
            "cmd /c *": "deny",
            "cmd.exe *": "deny",
            "powershell -c *": "deny",
            "powershell -command *": "deny",
            "powershell -enc *": "deny",
            "powershell -File *": "deny",
            "powershell.exe *": "deny",
            "pwsh *": "deny",
            "pwsh.exe *": "deny",
            "Start-Process *": "deny",
            "Invoke-Command *": "deny",
            "Register-ScheduledTask *": "deny",
            "New-Service *": "deny",
            "net user *": "deny",
            "net localgroup *": "deny",
            "net share *": "deny",
            "net use *": "deny",
            "net session *": "deny",
            "Add-MpPreference *": "deny",
            "Set-MpPreference *": "deny",
            "saps *": "deny",
            "start *": "deny",
            "telnet *": "deny",
            "ncat *": "deny",
            "nc *": "deny",
            "Test-NetConnection *": "deny"
        }
    }
}
```

---

## 2. Nuevos Agents: Gentleman-Deep

Agregar DESPUÉS de `gentleman-deep` (line ~284):

```json
"gentleman-deep-semi": {
    "description": "Deep reasoning — SEMI-AUTO",
    "model": "opencode/nemotron-3-ultra-free",
    "mode": "primary",
    "prompt": "{file:prompts/gentleman-deep.md}\n\n{file:prompts/shared/_core-behavior-gp.md}",
    "permission": { "bash": { "*": "ask",
        "git status": "allow", "git log *": "allow", "git diff *": "allow",
        "git show *": "allow", "git branch *": "allow", "git stash list": "allow",
        "ls *": "allow", "Get-ChildItem *": "allow", "Test-Path *": "allow",
        "pwd": "allow", "echo *": "allow", "cat *": "allow", "Get-Content *": "allow",
        "grep *": "allow", "rg *": "allow", "Select-String *": "allow",
        "which *": "allow", "Get-Command *": "allow",
        "npm test *": "allow", "pytest *": "allow", "go test *": "allow",
        "Invoke-Pester *": "allow",
        "rm *": "deny", "rm -rf *": "deny", "curl *": "deny",
        "Invoke-WebRequest *": "deny", "Invoke-RestMethod *": "deny",
        "Invoke-Expression *": "deny", "Remove-Item *": "deny",
        "ssh *": "deny", "docker *": "deny",
        "python *": "deny", "node *": "deny",
        "npx *": "deny", "certutil *": "deny", "schtasks *": "deny",
        "reg *": "deny", "sc *": "deny", "cmd /c *": "deny",
        "powershell -c *": "deny", "pwsh *": "deny",
        "Start-Process *": "deny", "Invoke-Command *": "deny"
    }},
    "tools": { "codebase-memory*": true, "engram*": true }
},
"gentleman-deep-auto": {
    "description": "Deep reasoning — AUTO",
    "model": "opencode/nemotron-3-ultra-free",
    "mode": "primary",
    "prompt": "{file:prompts/gentleman-deep.md}\n\n{file:prompts/shared/_core-behavior-gp.md}",
    "permission": { "bash": { "*": "allow",
        "git push": "ask", "git push *": "ask",
        "git push --force *": "deny", "git push --delete *": "deny",
        "rm *": "deny", "rm -rf *": "deny", "curl *": "deny",
        "Invoke-WebRequest *": "deny", "Invoke-RestMethod *": "deny",
        "Invoke-Expression *": "deny", "Remove-Item *": "deny",
        "ssh *": "deny", "docker *": "deny",
        "python *": "deny", "node *": "deny",
        "npx *": "deny", "certutil *": "deny", "schtasks *": "deny",
        "reg *": "deny", "sc *": "deny", "cmd /c *": "deny",
        "powershell -c *": "deny", "pwsh *": "deny",
        "Start-Process *": "deny", "Invoke-Command *": "deny"
    }},
    "tools": { "codebase-memory*": true, "engram*": true }
}
```

---

## 3. Nuevos Agents: Gentleman-Codex

Agregar DESPUÉS de `gentleman-codex` (line ~306). Mismos patrones que quick pero con `mode: "primary"` y modelo `opencode/deepseek-v4-flash-free`.

---

## 4. Nuevos Agents: Gentleman-Implementer

Agregar DESPUÉS de `gentleman-implementer` (line ~408). Mismos patrones de permisos.

---

## 5. Cambio en SHORTCUTS.md

Agregar sección "Permission Modes" después de Verification Modes:

```markdown
## Permission Modes

| Shortcut | Action |
|----------|--------|
| `!auto` | Switch to AUTO — all commands auto-approved except push + deletes |
| `!semi` | Switch to SEMI-AUTO — safe commands auto-approved, rest ask |
| `!manual` | Switch to MANUAL — every command asks (default) |
| `!mode` | Show current permission mode |
```

---

## 6. Cambio en prompts/gentleman-vMK.md

Agregar en la sección de Routing, después del Pre-Answer Evidence Gate:

```markdown
## Mode-Aware Routing

1. Read `.gentleman-mode` → `manual`, `semi`, or `auto`
2. If mode is `semi` or `auto`, append suffix to delegation target:
   - `gentleman-quick` → `gentleman-quick-semi` (or `-auto`)
   - `gentleman-deep` → `gentleman-deep-semi` (or `-auto`)
   - `gentleman-codex` → `gentleman-codex-semi` (or `-auto`)
   - `gentleman-implementer` → `gentleman-implementer-semi` (or `-auto`)
3. Fallback: if mode-specific agent doesn't exist → use base agent
4. Read-only specialists (security, seo, infra, etc.) → NO suffix (always `*: deny`)
```

---

## 7. Comportamiento Esperado

| Comando | manual | semi | auto |
|---------|--------|------|------|
| `git status` | ask | ✅ allow | ✅ allow |
| `git diff` | ask | ✅ allow | ✅ allow |
| `git log` | ask | ✅ allow | ✅ allow |
| `ls` / `Get-ChildItem` | ask | ✅ allow | ✅ allow |
| `pwd` / `Get-Location` | ask | ✅ allow | ✅ allow |
| `echo` / `Write-Output` | ask | ✅ allow | ✅ allow |
| `npm test` / `pytest` | ask | ✅ allow | ✅ allow |
| `grep` / `Select-String` | ask | ✅ allow | ✅ allow |
| `cat` / `Get-Content` | ask | ✅ allow | ✅ allow |
| `git commit` | ask | ask | ✅ allow |
| `git add` | ask | ask | ✅ allow |
| `New-Item` | ask | ask | ✅ allow |
| `mkdir` | ask | ask | ✅ allow |
| `git push` | ask | ask | ❌ ask |
| `git push --force` | ask | ask | ❌ deny |
| `rm -rf` | ❌ deny | ❌ deny | ❌ deny |
| `Remove-Item` | ❌ deny | ❌ deny | ❌ deny |
| `curl` | ❌ deny | ❌ deny | ❌ deny |
| `ssh` | ❌ deny | ❌ deny | ❌ deny |
| `python` / `node` | ❌ deny | ❌ deny | ❌ deny |

---

*Documento generado como especificación de cambios en archivos protegidos.*
*Confidence: high — basado en tool output directo de opencode.json y tests de switch-mode.ps1*
