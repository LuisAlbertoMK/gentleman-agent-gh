# Quickstart — gentleman-agent-gh en 5 minutos

## 1. Instalar

```bash
# Clonar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh

# Windows (PowerShell 7+):
.\scripts\install.ps1

# Linux/macOS:
./scripts/install.sh
```

## 2. Abrir OpenCode

```bash
# Usando el shortcut global (creado por install):
opencode-vmk

# O directamente:
opencode --agent gentleman-vMK
```

## 3. Comandos básicos

| Shortcut | Qué hace |
|----------|----------|
| `!score` | Ver puntuación actual del proyecto |
| `!health` | Estado: git, drift, score |
| `!setup` | Re-configurar en máquina nueva |
| `!close` | Cerrar sesión (BITACORA + resumen) |
| `!ponytail lite` | Modo perezoso (menos ceremony) |
| `!ponytail full` | Modo completo (más gates) |
| `!analisis` | Análisis multi-agente profundo |
| `!gentleman` | Aplicar config a otro proyecto |

## 4. Flujo típico

```
1. opencode-vmk                ← abrir agente
2. "haz X"                     ← pedir tarea
3. el agente resuelve solo     ← cambios triviales = sin ceremony
4. !score                      ← opcional: medir resultado
5. !close                      ← cerrar sesión
```

## 5. Tips

- **Ponytail `lite`** = default. Solo chequea si algo es necesario antes de codear.
- **Ponytail `full`** = para cambios complejos. Activa más gates de calidad.
- **No necesitas** acordarte de todo — el agente sabe cuándo aplicar cada cosa.
- **Dudas**: `!health` para diagnóstico, `!manifest` para ver el ciclo actual.
