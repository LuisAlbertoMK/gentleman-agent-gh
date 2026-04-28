---
name: skill-testing
description: >
  Testing y verificación de skills creadas.
  Trigger: Después de crear/modificar skill, para verificar
  que funciona correctamente antes de usar en producción.
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## Cuando Usar

- Después de crear nueva skill
- Después de modificar skill existente
- Antes de confiar en una skill para tarea crítica
- Verificación periódica de skills activas

## Framework de Testing

```
Test → Verify → Score → Approve/Reject
```

## Tipos de Test

### 1. Syntax Validation
```
Verificar que:
□ SKILL.md tiene frontmatter completo
□ Estructura de headers correcta
□ Assets referenciados existen
□ Triggers son únicos y claros
```

### 2. Coverage Test
```
Para cada skill, verificar que cubre:
□ Caso de uso principal
□ Edge cases del dominio
□ Templates básicos
□ Anti-patrones documentados
```

### 3. Integration Test
```
Simular触发:
1. Cargar skill basada en trigger
2. Aplicar a caso de prueba
3. Verificar output correcto
```

### 4. Token Test
```
Para skills de prompt:
□ Prompt promedio < X tokens
□ Template más largo < Y tokens
□ Decision tree legible
```

## Checklist por Skill Type

### Prompt Skill
```
□ Frontmatter completo
□ Método/framework documentado
□ Templates por caso de uso
□ Anti-patrones
□ Ejemplos concretos
□ Recursos enlazados
□ Triggers claros
```

### Workflow Skill
```
□ Pasos secuenciales claros
□ Decisiones documentadas
□ Manejo de errores
□ Comandos de ejemplo
□ Casos de prueba
```

### Template Skill
```
□ Estructura completa
□ Placeholders claros
□ Ejemplos de uso
□ Variaciones documentadas
```

## Template de Test Case

```markdown
## Test Case: [nombre]

### Skill
[nombre de skill]

### Trigger
[condición que dispara skill]

### Input
[input de prueba]

### Expected Output
[output esperado]

### Actual Output
[output real]

### Result
✅ PASS / ❌ FAIL

### Notes
[observaciones]
```

## Ejecución de Tests

### Manual
```bash
# Validar skill específica
skill-test validate --skill karpathy-prompt

# Run all tests
skill-test run --all

# Generate report
skill-test report
```

### Auto-trigger
```
Después de crear/modificar skill:
1. Run syntax validation
2. Run coverage test
3. If fail → notify + show issues
4. If pass → skill ready
```

## Scoring

```markdown
## Skill Scorecard

| Criteria | Weight | Score | Notes |
|----------|--------|-------|-------|
| Syntax | 20% | X/10 | |
| Coverage | 30% | X/10 | |
| Integration | 30% | X/10 | |
| Usability | 20% | X/10 | |
| **TOTAL** | 100% | X/10 | |

### Thresholds
- 9-10: ✅ Production ready
- 7-8: ⚠️ Needs improvement
- <7: ❌ Do not use
```

## Test Cases por Defecto

### Para toda skill
```
1. Syntax: frontmatter parsing
2. Structure: required sections exist
3. Links: assets referenced exist
4. Triggers: clear and unique
5. Format: valid markdown
```

### Para prompt skills
```
6. Token budget: templates under limit
7. Templates: at least 3 examples
8. Anti-patterns: documented
9. Decision tree: if applicable
```

### Para workflow skills
```
6. Steps: sequential and clear
7. Errors: handled explicitly
8. Commands: executable
9. Examples: at least 1
```

## Reporte de Salida

```markdown
## Skill Test Report

### Skill: [nombre]
### Date: [ISO timestamp]
### Version: [v1.X]

### Results
| Test | Status | Notes |
|------|--------|-------|
| Syntax | ✅ | |
... |

### Coverage Matrix
| Required | Covered | Missing |
|----------|---------|---------|
| [item] | ✅/❌ | [if missing] |
...

### Recommendations
- [recommendation 1]
- [recommendation 2]

### Verdict
✅ APPROVED / ⚠️ NEEDS WORK / ❌ REJECTED
```

## Recursos

- Templates: [assets/test-case-template.md](assets/test-case-template.md)
- Coverage: [assets/coverage-matrix.md](assets/coverage-matrix.md)
- Reports: [assets/report-template.md](assets/report-template.md)