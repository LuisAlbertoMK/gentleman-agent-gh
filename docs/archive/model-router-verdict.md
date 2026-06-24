# Model Router — Veredicto y Workflow

> Resumen del análisis cruzado de `opencode-free-specialities-v3.md` + `v3(1).md`
> Generado: Jun 20, 2026 | Agente: Big Pickle

---

## 1. Diagnóstico

### v3 (original)
- **Contradicción frontal**: tabla Frontend decía Big Pickle, sección decía DeepSeek
- Sin fallbacks explícitos — el lector debía cruzar mentalmente riesgo + recomendación
- Conclusión no alineada con el cuerpo del doc

### v3(1) (complemento)
- **Corrige contradicciones**: unifica DeepSeek como 🥇 en 6/7 áreas
- **Añade fallback chains**: cada disciplina tiene 🥈 con trigger condicional
- **Ranking Final**: 3 escenarios de contingencia (ambos disponibles, Flash cae, Pickle cae)

### Gaps remanentes (ambos docs)
- North Mini Code en risk table sin use case
- Sin tertiary fallback (si Flash Y MiMo caen)
- Sin health-check de disponibilidad de trial models
- Debugging, data analysis, documentación, DevOps, seguridad no cubiertos
- Benchmarks sin fuentes
- Big Pickle sin benchmarks propios

---

## 2. Workflow (Agente Big Pickle)

### Context Gate
```
contexto > 200K → manejo DIRECTO (solo Big Pickle puede)
contexto ≤ 200K → evaluar routing
```

### Security Gate (SIEMPRE primero)
```
tarea con credenciales/datos sensibles?
  → SÍ: manejo DIRECTO. NUNCA delegar a trial models
  → NO: continuar

tarea recurrente/cron?
  → SÍ: manejo DIRECTO. No depender de modelos que pueden desaparecer
  → NO: continuar
```

### Routing Table

| Tipo tarea | Acción primaria | Fallback | Skill a cargar |
|---|---|---|---|
| UI/UX • CSS • Tailwind | Delegar a Flash* | Manejo directo | `baseline-ui` |
| React • Frontend (<100K) | Delegar a Flash* | Manejo directo | `baseline-ui` |
| E2E Testing | Delegar a Flash* | Manejo directo | según stack |
| Performance • Core Web Vitals | Delegar a Flash* | Manejo directo | `performance` |
| Syntax • Linting | Delegar a Flash* | Manejo directo | `code-review-agent` |
| SEO • Content • Metadata | Delegar a MiMo* | Manejo directo | `seo` |
| **Architecture • Best Practices** | **MANEJO DIRECTO 🏆** | — | `senior-engineer` |
| **Codebase Audit >150K** | **MANEJO DIRECTO 🏆** | — | `project-mapper` |
| **Code Review** | **MANEJO DIRECTO 🏆** | — | `code-review-agent` |
| **Full Feature Set** | **MANEJO DIRECTO 🏆** | — | `sdd-*` |
| **Recurrentes / Cron** | **MANEJO DIRECTO 🏆** | — | según tarea |
| **Default (no match)** | **MANEJO DIRECTO** | — | `skill-graph` → resolver |

\* *Delegación vía subagente. Si el subagente falla o el modelo no está disponible, el fallback es manejo directo.*

### Fallback Chain Universal
```
DeepSeek V4 Flash (trial, riesgo medio) → Big Pickle (estable)
MiMo-V2.5 (trial, riesgo alto) → Big Pickle (estable, SEO básico)
Big Pickle (estable) → fondo de cadena, no hay más fallback
```

---

## 3. Implementación

- [x] Análisis de ambos documentos
- [x] Definición del workflow con security gates
- [x] Skill `opencode-model-router` creado con el decision tree
- [x] Registro en SKILLS-INDEX.md
- [ ] Verificación: el skill carga sin errores

---

## 4. Próximos Pasos (futuro)

| Pendiente | Prioridad |
|---|---|
| Health-check de disponibilidad de trial models | Alta |
| Cobertura de categorías faltantes (debug, data, doc, devops, security) | Media |
| Benchmarks con fuentes para todos los modelos | Media |
| Big Pickle benchmarks propios | Baja |
| Tertiary fallback chain | Baja |
