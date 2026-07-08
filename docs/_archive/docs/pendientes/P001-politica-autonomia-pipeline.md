# P001 — Política de Autonomía con Pipeline de Análisis

**Estado**: `📌 pendiente` · **Prioridad**: alta · **Creado**: 2026-07-05
**Trigger**: `!analisis` sobre patrones de Engram + solicitud explícita del usuario

---

## Contexto

El usuario ha indicado EN MÚLTIPLES OCASIONES que prefiere autonomía:

> «sigue sin reparos» · «confía en I/R» · «ejecutar sin preguntar» ·  
> «el usuario confía en recomendaciones I/R — ejecutar sin preguntar 'debería continuar'» ·  
> «máxima eficacia de recursos, sin perder calidad... Continue without permission»

Pattern mining de Engram confirma **3+ instancias** donde el usuario corrigió al agente por
pedir permiso cuando ya había contexto suficiente para proceder.

---

## Política Propuesta

### Regla de Oro

> **El agente PUEDE ejecutar cambios sin esperar aprobación explícita CUANDO:**
> 1. El riesgo es LOW o TRIVIAL (según risk-adaptive zones del AGENTS.md)
> 2. Existe un checkpoint de seguridad (backup) antes de la operación
> 3. **SIEMPRE** ejecuta el pipeline de análisis primero (`pipeline-analyze`)

### Lo que NO cambia (excepciones que SÍ requieren aprobación)

| Situación | Motivo |
|-----------|--------|
| Destructive ops (delete/move files) | §E-H del protocolo |
| Cambios en `~/.config/opencode/` | Afecta todos los proyectos |
| Push a upstream | Fork, no upstream contributor |
| Cambios que tocan auth/secrets/schema | HIGH risk |
| Score drop >0.5 en ciclo de mejora | Requiere revert manual |

### Flujo Autónomo Propuesto

```
Usuario indica intención vaga o da permiso implícito
  ↓
╭─ Pipeline de Análisis ─────────────────────────╮
│ 1. Detectar proyecto actual                    │
│ 2. Git status → ¿cambios sin commit?           │
│ 3. Score actual vs histórico                   │
│ 4. Análisis rápido (estructura + patrones)     │
│ 5. ¿Riesgo LOW/MEDIUM/HIGH?                   │
│ 6. Recomendación con I/R score                 │
╰────────────────────────────────────────────────╯
  ↓
¿Riesgo LOW y checkpoint creado?
  ├─ SÍ → Ejecutar + documentar + mem_save
  └─ NO → Escalar al usuario con 1-liner
```

---

## Implementación Futura

- [ ] Crear `pipeline-analyze.ps1` — script autónomo que ejecuta los 6 pasos
- [ ] Integrar con `!batch` para análisis multi-proyecto
- [ ] Modificar AGENTS.md §E-H para reflejar la política de autonomía
- [ ] Test: 3 escenarios (LOW/MEDIUM/HIGH) para validar comportamiento
- [ ] Revisar después de 5 ejecuciones para ajustar thresholds

## Nota

> ⚠️ **Esto es un plan de acción futuro.** No se ejecuta hasta que el usuario
> lo autorice explícitamente o se complete la revisión de comportamiento.
> Por ahora queda documentado como directriz para cuando se active.
