# Ciclos de Mejora — Reportes

Cada ciclo de mejora genera un reporte estructurado en `docs/ciclos/cycle<N>-YYYYMMDD.md`.

Estos reportes están diseñados para:
- **Revisión posterior** por otro agente o humano
- **Ejecución diferida** — otro agente puede leer el reporte y continuar
- **Auditoría** — seguimiento de hallazgos y decisiones por ciclo

## Template de Reporte

```markdown
# Cycle <N>: <Nombre del Ciclo>

**Fecha**: YYYY-MM-DD
**Estado**: 🟢 COMPLETED / 🟡 IN PROGRESS / 🔴 FAILED
**Score inicial**: X.X/10 → **Score final**: X.X/10
**inter**: X/30

## Resumen

[2-3 líneas describiendo el objetivo y resultado del ciclo]

## Hallazgos — 3 Subagentes

### Subagente 1: <Área>

| Gap | Severidad | Archivo | Hallazgo | Acción tomada |
|-----|-----------|---------|----------|---------------|
| Seguridad | Alta/Media/Baja | path | descripción | fix aplicado/no |
| Optimización | ... | ... | ... | ... |

### Subagente 2: <Área>

| Gap | Severidad | Archivo | Hallazgo | Acción tomada |
|-----|-----------|---------|----------|---------------|

### Subagente 3: <Área>

| Gap | Severidad | Archivo | Hallazgo | Acción tomada |
|-----|-----------|---------|----------|---------------|

## Dimensiones evaluadas

| Dimensión | Antes | Después | Δ |
|-----------|-------|---------|---|
| Seguridad | X/10 | X/10 | +X |
| Optimización | X/10 | X/10 | +X |
| Rendimiento | X/10 | X/10 | +X |
| Sintaxis/PSSA | X/10 | X/10 | +X |
| Ortografía | X/10 | X/10 | +X |
| Performance | X/10 | X/10 | +X |
| SEO | X/10 | X/10 | +X |
| ... | ... | ... | ... |

## Archivos modificados

- `path/to/file` — qué cambió y por qué
- `path/to/file` — qué cambió y por qué

## Decisiones técnicas

- **Decisión 1**: [qué se decidió y por qué]
- **Decisión 2**: [qué se decidió y por qué]

## Items pendientes (carry-forward)

- [ ] Item no resuelto 1
- [ ] Item no resuelto 2

## Notas para el próximo ciclo

[Lecciones aprendidas, cambios de dirección, métricas a vigilar]
```

## Reportes generados

| Ciclo | Fecha | Estado | Link |
|-------|-------|--------|------|
| ... | ... | ... | ... |
