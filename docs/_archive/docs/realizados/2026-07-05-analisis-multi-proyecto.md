# Resumen de Análisis Multi-Proyecto — D:\ 2026-07-05

## Pipeline y Artefactos Creados

| Artefacto | Ruta | Propósito |
|-----------|------|-----------|
| ✅ Safety checkpoint | `.backup-session-20260705-150321/` | 47 archivos respaldados |
| ✅ Política autonomía | `docs/pendientes/P001-politica-autonomia-pipeline.md` | Autonomía con pipeline obligatorio |
| ✅ Pipeline script | `scripts/pipeline-analyze.ps1` | Gather + report multi-proyecto |
| ✅ Resumen | `docs/realizados/2026-07-05-analisis-multi-proyecto.md` | Este documento |

## Proyectos Analizados (9/9)

| # | Proyecto | Score | Tipo | Estado | Hallazgo Principal |
|---|----------|-------|------|--------|-------------------|
| 1 | **gentleman-agent-gh** | 9.2 | Agent config/skills | ✅ | Backup + pipeline creados |
| 2 | **opencode** | 9.2 | AI CLI platform | ⚠️ | 763 dirty files (migración) |
| 3 | **erp-talleres** | 8.0 | ERP SaaS (NestJS/Angular) | ⚠️ | Coverage 35%, frontend 0 tests |
| 4 | **monomkservices** | 9.3 | Full-stack (Express/Angular) | ✅ | 449 tests, 0 failures |
| 5 | **automatizacion** | 8.0 | Python automation | ⚠️ | Screenshots en root, tests huérfanos |
| 6 | **arturo (KitchenOS)** | **9.9** | Backend API | ✅ | Proyecto más pulido del ecosistema |
| 7 | **json-convert** | 9.5 | Python CLI | ⚠️ | 28 cambios sin commit |
| 8 | **experimento (APPUTOS)** | ~7.0 | ERP NestJS/Angular | ⚠️ | Mid-migration npm→pnpm, require() bug |
| 9 | **event-landing** | ~5.0 | React/Express | 🔴 | **Credenciales en git**, 0 tests |

## Ranking por Score

```
1. arturo (KitchenOS)       9.9  ← 🏆 Mejor proyecto
2. json-convert             9.5
3. monomkservices           9.3
4. gentleman-agent-gh       9.2
5. opencode                 9.2
6. erp-talleres             8.0
7. automatizacion           8.0
8. experimento (APPUTOS)    7.0
9. event-landing            5.0  ← Peor (credenciales expuestas)
```

## Patrones Transversales (de Engram a todos los proyectos)

### Patrones que se repiten en 3+ proyectos

| Patrón | Proyectos Afectados |
|--------|---------------------|
| **Cambios sin commit** | opencode (763), json-convert (28), experimento (12) |
| **Sin .project.json** | experimento, event-landing |
| **Cobertura de tests baja** | erp-talleres (35%), event-landing (0) |
| **Sin TypeScript** | arturo (JS), event-landing (JS) |
| **Encoding corruption** | erp-talleres (BITACORA.md) |
| **Docker presente** | 8/9 proyectos tienen Docker |
| **GitHub Actions CI** | 8/9 proyectos tienen CI |

### Recomendaciones Transversales

1. **pipeline-analyze.ps1** como pre-session check para cualquier proyecto — detecta score drift, dirty state, encoding issues
2. **Score tracking** para proyectos sin .project.json (experimento, event-landing)
3. **Commit semanal** — opencode (763 dirty), json-convert (28 dirty) necesitan commit frecuente
4. **Security scan** — event-landing necesita rotación de credenciales URGENTE

## Próximos Pasos (Futuros)

1. ⏳ Revisar P001 (política de autonomía) y definir thresholds
2. ⏳ Ejecutar `pipeline-analyze.ps1 -Mode full` como pre-check en !health
3. ⏳ Analizar D:\leandro\ (8 sub-proyectos sin git)
4. ⏳ Cross-reference de patrones entre proyectos (ej: ¿qué patrones de arturo 9.9 se pueden exportar?)

---

*Generado por pipeline-analyze.ps1 + !analisis multi-agente · @gentleman-vMK*
