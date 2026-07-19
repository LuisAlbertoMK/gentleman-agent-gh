# Dev Environment — Máximo Rendimiento
> Stack: opencode · VSCode · Node.js · pnpm · Angular CLI · Navegador
> Generado: 2026-07-16

---

## Versiones Verificadas (julio 2026)

| Software | Versión Recomendada | Notas |
|---|---|---|
| **Ubuntu LTS** | **24.04** (Noble Numbat) | Estable, soporte hasta 2029 |
| **Ubuntu LTS alt** | **26.04** | Más reciente, kernel 6.14, GNOME 48 |
| **Windows** | **11 24H2** | Mínimo viable con ajustes |
| **Node.js** | **24 LTS** (Krypton) v24.18.0 | Active LTS hasta 2028-05-31 |
| **Node.js alt** | 22 LTS (Jod) v22.22.2 | Mantenimiento hasta 2027-04-30 |
| **pnpm** | **11.12.0** | Requiere Node 22+; reemplaza JSON-store con SQLite |
| **Angular CLI** | **22.0.6** | Alineado con @angular/core 22 |
| **VSCode** | **1.128.1** | Multi-chat agents, Copilot Vision GA |
| **npm** (bundled) | 11.x | Viene con Node 24; usar pnpm en su lugar |

> **pnpm 11 exige Node.js ≥ 22.** No usar Node 20 con pnpm 11.

---

## Ubuntu — Configuración de Máximo Rendimiento

### 1. Versión recomendada

```
Producción estable  → Ubuntu 24.04 LTS
Bleeding edge       → Ubuntu 26.04 LTS
WM ligero           → i3 / Openbox sobre cualquiera de los dos
```

### 2. Parámetros de kernel (`/etc/sysctl.conf`)

```bash
# File watchers — crítico para monorepos (opencode, Angular)
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=256

# VM — reduce swappiness para mantener apps en RAM
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Red — mejora latencia para npm/pnpm registry
net.core.rmem_max=16777216
net.core.wmem_max=16777216
```

Aplicar sin reiniciar:
```bash
sudo sysctl -p
```

### 3. zram (swap en RAM comprimida) — esencial con <16 GB

```bash
sudo apt install zram-config   # Ubuntu 24.04
# o
sudo apt install zram-tools    # Ubuntu 26.04

# Verificar
cat /proc/swaps
```

### 4. Node.js via nvm (recomendado sobre apt)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 24.18.0     # Node 24 LTS (Krypton) — latest patch jul 2026
nvm alias default 24
node -v                 # v24.18.0
```

### 5. pnpm + Angular CLI

```bash
# pnpm via corepack (incluido en Node 24)
corepack enable
corepack use pnpm@11

# Angular CLI global
pnpm add -g @angular/cli@22

# Verificar
ng version
pnpm -v
```

### 6. VSCode — optimización de recursos

```jsonc
// ~/.config/Code/User/settings.json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/**": true,
    "**/dist/**": true,
    "**/.angular/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.angular": true
  },
  "extensions.autoUpdate": false,
  "telemetry.telemetryLevel": "off",
  "editor.minimap.enabled": false,
  "typescript.tsserver.maxTsServerMemory": 3072,
  "editor.renderWhitespace": "none"
}
```

### 7. Variables de entorno para Node/pnpm (`~/.bashrc` o `~/.zshrc`)

```bash
# Limitar workers de compilación TS (ajustar según CPUs)
export UV_THREADPOOL_SIZE=8
export NODE_OPTIONS="--max-old-space-size=4096"

# pnpm store centralizado
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
```

### 8. opencode — ajuste específico

```bash
# Aumentar límite de archivos abiertos
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Validar
ulimit -n   # debe mostrar 65536
```

### 9. Navegador — Firefox vs Chromium en Linux

| Navegador | RAM idle | Recomendación |
|---|---|---|
| Firefox | ~400 MB | ✅ mejor opción en Linux |
| Chromium | ~600 MB | ok para dev tools |
| Chrome | ~800 MB | evitar si <16 GB RAM |

---

## Windows 11 — Configuración de Máximo Rendimiento

> **Contexto:** Windows 11 consume ~3–4 GB base. Optimizar es reducir esa carga, no eliminarla.

### 1. Versión recomendada

```
Windows 11 24H2 (Build 26100.x) — única versión soportada activamente
```

### 2. Desactivar servicios pesados (PowerShell admin)

```powershell
# Telemetría
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
  -Name "AllowTelemetry" -Value 0

# Windows Search Indexer (pesado en SSD con monorepos)
Stop-Service WSearch
Set-Service WSearch -StartupType Disabled

# SysMain (Superfetch) — innecesario con SSD
Stop-Service SysMain
Set-Service SysMain -StartupType Disabled

# Windows Defender Exclusions — CRÍTICO para node_modules
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\projects"
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\AppData\Local\pnpm"
Add-MpPreference -ExclusionProcess "node.exe"
Add-MpPreference -ExclusionProcess "ng.exe"
```

> ⚠️ La exclusión de Defender es **la optimización más impactante en Windows** para Angular/Node. Sin esto, `ng serve` puede ser 2–3x más lento.

### 3. Node.js via nvm-windows

```powershell
# Instalar nvm-windows desde https://github.com/coreybutler/nvm-windows
nvm install 24.15.0
nvm use 24.15.0
node -v
```

### 4. pnpm + Angular CLI (mismo que Linux)

```powershell
corepack enable
corepack use pnpm@11
pnpm add -g @angular/cli@22
```

### 5. Variables de entorno del sistema

```
NODE_OPTIONS=--max-old-space-size=4096
UV_THREADPOOL_SIZE=8
PNPM_HOME=C:\Users\<usuario>\AppData\Local\pnpm
```

Agregar `PNPM_HOME` al PATH del sistema.

### 6. VSCode — mismo `settings.json` que Ubuntu

```jsonc
// %APPDATA%\Code\User\settings.json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/**": true,
    "**/dist/**": true,
    "**/.angular/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.angular": true
  },
  "extensions.autoUpdate": false,
  "telemetry.telemetryLevel": "off",
  "typescript.tsserver.maxTsServerMemory": 3072,
  "editor.minimap.enabled": false
}
```

### 7. WSL2 como alternativa mixta

Si el stack completo en Windows sigue siendo lento:

```powershell
wsl --install -d Ubuntu-24.04
# Luego instalar node/pnpm/ng DENTRO de WSL2
# Editar en VSCode con extensión "Remote - WSL"
```

> WSL2 ofrece ~70% del rendimiento de Linux nativo para I/O de archivos. Mejor opción si no se puede cambiar de SO.

### 8. Límite de file watchers en Windows

```powershell
# En proyectos grandes Angular puede fallar el watcher
# Configurar en .env del proyecto:
# CHOKIDAR_USEPOLLING=false  (default, no cambiar)
# Si hay errores ENOSPC en WSL2:
wsl -e sh -c "echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"
```

---

## opencode — Instalación y Configuración

> **Versión actual:** v1.18.2 (15 jul 2026) · Repo: `anomalyco/opencode` · MIT License
> **Nota:** Desde enero 2026 opencode no puede usar OAuth de Claude. Usar API key directa de Anthropic.

### Versión de opencode

| Campo | Valor |
|---|---|
| Versión estable | **v1.18.2** |
| Proveedores soportados | 75+ (Anthropic API key, OpenAI, Gemini, Groq, Ollama...) |
| Almacenamiento sesiones | SQLite local |
| LSP | Integrado automáticamente |
| Modos | `build` (escritura) · `plan` (solo lectura, Tab para alternar) |

### Ubuntu — Instalar opencode

```bash
# Opción 1: script oficial (recomendado)
curl -fsSL https://opencode.ai/install | bash

# Opción 2: via pnpm (si ya lo tienes)
pnpm add -g opencode-ai@latest

# Opción 3: Arch Linux
paru -S opencode-bin

# Verificar
opencode --version
```

### Windows — Instalar opencode

```powershell
# Scoop (recomendado)
scoop install opencode

# Chocolatey
choco install opencode

# O directo via npm (desde WSL2 preferiblemente)
npm i -g opencode-ai@latest
```

> **Novedades v1.18.x (jul 2026):** Desktop v2 migration completada, subagents con límite configurable (`subagent_depth`), snapshots de sesión con rollback, tabs arrastrables, shortcut `Mod+N` para nueva tab, yolo auto-approve mode.

> ⚠️ **En Windows, opencode funciona mejor dentro de WSL2.** La documentación oficial lo recomienda explícitamente para máxima compatibilidad y rendimiento.

### Configuración global (`~/.opencode.json`)

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-6",
  "providers": {
    "anthropic": {
      "apiKey": "${ANTHROPIC_API_KEY}"
    },
    "openai": {
      "apiKey": "${OPENAI_API_KEY}"
    }
  }
}
```

### Variables de entorno necesarias (`~/.bashrc` / `~/.zshrc` / PowerShell profile)

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."        # opcional
export GEMINI_API_KEY="..."           # opcional
```

### Inicializar proyecto

```bash
cd ~/tu-proyecto-angular
opencode
# Dentro del TUI:
/init          # genera AGENTS.md con contexto del proyecto
/connect       # vincular providers
# Tab          # alternar build ↔ plan
# /undo        # revertir último cambio
```

### Impacto de recursos con opencode activo

| Componente | RAM aprox |
|---|---|
| opencode TUI + Node runtime | ~150–300 MB |
| LSP servers (tsserver) | ~200–500 MB por proyecto |
| Sesiones paralelas (2+) | +150 MB por sesión adicional |
| **Total stack completo** | **1.5–3 GB activo** |

### Comandos clave TUI

| Comando | Acción |
|---|---|
| `Tab` | Alternar build ↔ plan |
| `/init` | Generar AGENTS.md |
| `/undo` | Revertir cambio |
| `/share` | Link a la sesión actual |
| `/models` | Ver modelos disponibles |
| `@archivo` | Fuzzy-search de archivos del proyecto |

---

## ProtonVPN — Instalación y Configuración para Desarrollo

> **Protocolo recomendado:** WireGuard (UDP) — más rápido, menor latencia
> **Split tunneling:** crítico para desarrollo — excluir tráfico npm/pnpm/API local del túnel

### Comparativa de protocolos

| Protocolo | Velocidad | Latencia | Dev |
|---|---|---|---|
| **WireGuard UDP** | ✅ Máxima | ✅ Baja | ✅ Recomendado |
| WireGuard TCP | Media | Media | Fallback |
| OpenVPN | Baja | Alta | ❌ Evitar para dev |
| Stealth | ~35% más lento que WireGuard | Alta | Solo en redes restrictivas |

### Ubuntu — Instalar ProtonVPN

```bash
# 1. Descargar instalador del repo oficial
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb
sudo dpkg -i protonvpn-stable-release_1.0.8_all.deb

# 2. Instalar GUI (requiere GNOME — Ubuntu 24.04/26.04 lo incluye)
sudo apt update
sudo apt install proton-vpn-gnome-desktop

# 3. Opcional: tray icon
sudo apt install gir1.2-appindicator3-0.1

# 4. Reiniciar y abrir desde apps o:
protonvpn-app
```

> Si usas i3/Openbox (sin GNOME) → usar **CLI** o **WireGuard manual**:

```bash
# CLI alternativa (sin GUI, funciona en cualquier WM)
sudo apt install protonvpn-cli
protonvpn-cli login tu@email.com
protonvpn-cli connect --fastest
protonvpn-cli status
```

### Ubuntu — WireGuard manual (máximo rendimiento, cualquier distro)

```bash
sudo apt install wireguard

# Descargar config desde account.protonvpn.com → Downloads → WireGuard
# Guardar como /etc/wireguard/proton.conf

sudo wg-quick up proton      # conectar
sudo wg-quick down proton    # desconectar

# Autostart con systemd
sudo systemctl enable wg-quick@proton
```

### Ubuntu — Split Tunneling para Dev (excluir tráfico local del túnel)

En la app GUI:
```
Settings → Split tunneling → Enable
→ Modo: Exclude
→ Agregar: node, npm, code (VSCode), opencode
```

O manualmente con WireGuard — editar `proton.conf`:
```ini
[Interface]
# ... (tu config normal)
# Desactivar routing global para hacer split tunneling manual:
# Table = off  # descomentar si quieres control total por rutas

[Peer]
# Cambiar AllowedIPs para excluir rangos locales:
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1
# Excluir tu red local (ej. 192.168.1.0/24) NO incluyéndola en AllowedIPs
```

### Windows — Instalar ProtonVPN

```
1. Descargar desde https://protonvpn.com/download-windows
2. Instalar → ejecutar como usuario normal (no admin)
3. Login con cuenta Proton
4. Settings → Connection → Protocol: WireGuard (UDP)
5. Activar Kill Switch (permanente o solo cuando VPN activa)
6. Activar NetShield → Block malware, ads & trackers
```

### Windows — Split Tunneling para Dev

```
ProtonVPN app → Home → Split tunneling → Enable
→ Modo: Exclude (Standard)
→ Agregar a la lista de exclusión:
   - node.exe
   - Code.exe (VSCode)
   - opencode.exe (si aplica)
   - chrome.exe / firefox.exe (opcional — si dev server es local)
```

> Esto mantiene el tráfico de API (Anthropic, npm registry, GitHub) dentro del VPN, pero el servidor `ng serve` local y el navegador de dev pueden ir directo — sin latencia del túnel.

### Configuración recomendada ProtonVPN para desarrolladores

| Setting | Valor | Motivo |
|---|---|---|
| Protocolo | WireGuard UDP | Menor latencia |
| Kill Switch | Activado | Sin leaks si cae la VPN |
| NetShield | Block malware + ads | Sin ads en dev browser |
| Split tunneling | Activado | node/VSCode fuera del túnel |
| Auto-connect | Activado | Siempre protegido |
| DNS leak protection | Activado | Siempre |

### Impacto de ProtonVPN en el stack dev

| Escenario | Latencia añadida | RAM |
|---|---|---|
| Sin VPN | 0 ms | 0 MB |
| ProtonVPN WireGuard (servidor cercano) | +5–15 ms | ~50–80 MB |
| ProtonVPN OpenVPN | +30–80 ms | ~80–120 MB |
| Con split tunneling (npm/node excluidos) | 0 ms en builds locales | sin cambio |

> **Conclusión:** WireGuard + split tunneling = VPN activa sin impacto perceptible en el flujo de desarrollo local.

---

## Tabla Comparativa Final

| Métrica | Ubuntu 24.04 LTS | Ubuntu 26.04 LTS | Windows 11 24H2 |
|---|---|---|---|
| RAM base del SO | ~400–700 MB | ~500–800 MB | ~3–4 GB |
| File watchers | Nativo, ilimitado* | Nativo, ilimitado* | Limitado sin WSL2 |
| Defender overhead | N/A | N/A | Alto (sin exclusiones) |
| `pnpm install` velocidad | ✅ máxima | ✅ máxima | ~60–70% vs Linux |
| `ng serve` frío | ✅ rápido | ✅ rápido | Lento sin exclusiones |
| opencode (LSP+tsc) | ✅ óptimo | ✅ óptimo | Aceptable |
| Soporte hardware nuevo | Bueno | ✅ Mejor (kernel 6.14) | ✅ Nativo |
| Estabilidad | ✅ LTS probado | Nuevo (abril 2026) | Estable |

*Con `fs.inotify.max_user_watches=524288`

---

## RAM mínima recomendada

| Configuración | RAM mínima |
|---|---|
| VSCode + Angular | 8 GB (justo) |
| + opencode + navegador | 16 GB (recomendado) |
| + múltiples proyectos | 32 GB (óptimo) |
