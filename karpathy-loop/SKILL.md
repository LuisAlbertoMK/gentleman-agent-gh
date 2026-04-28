---
name: karpathy-loop
description: >
  Ciclo de optimización Karpathy: escribir, medir, recortar, repetir.
  Trigger: Cuando usuario pide optimizar prompt, reducir tokens,
  mejorar efectividad, o "método Karpathy aplicado".
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## El Método Karpathy Loop

Karpathy no escribe prompts perfectos de entrada.
Itera: **escribir → medir → recortar → repetir**.

```
Write → Measure → Cut → Repeat → Optimal
```

## Las 4 Fases

### Fase 1: WRITE (Escribir)

```
Escribí versión inicial con:
- Rol claro
- Tarea específica
- 1-2 ejemplos
- Output format

NO optimizar aún. Escribí completo primero.
```

### Fase 2: MEASURE (Medir)

```bash
# Medir tokens aproximados
echo "$PROMPT" | wc -c  # chars / 4 ≈ tokens

# Medir efectividad
# - ¿Responde correctamente?
# - ¿Cubre edge cases?
# - ¿Output es usable?

# Score: 1-10 para:
# - Correctitud
# - Concisión
# - Robustez
```

### Fase 3: CUT (Recortar)

```
Preguntas para recortar:
- ¿Puedo eliminar esta frase?
- ¿Este ejemplo es necesario?
- ¿Puedo fusionar estas instrucciones?
- ¿Hay redundancia?

Regla: Si no cambia el resultado, elimínalo.
```

### Fase 4: REPEAT (Repetir)

```
Volver a Medir.
Si score mejora Y tokens bajan → continuar.
Si score baja → revertir último cambio.
Si se estanca → probar otra táctica.
```

## Template de Iteración

```markdown
## Karpathy Loop — Iteración #[N]

### Prompt Actual
```
[copiar prompt actual]
```

### Métricas
| Métrica | Valor |
|---------|-------|
| Tokens | ~X |
| Correctitud | X/10 |
| Concisión | X/10 |
| Robustez | X/10 |

### Cambios Propuestos
- [cambio 1]
- [cambio 2]

### Después de Cambios
| Métrica | Antes | Después |
|---------|-------|---------|
| Tokens | X | Y |
| Correctitud | X | Y |
...
```

## Tácticas de Recorte

### Nivel 1: Fácil (20-30% reducción)
```
□ Eliminar muletillas ("Por supuesto que...")
□ Reducir saludos/despedidas
□ Eliminar "piensa paso a paso"
□ Unificar frases similares
```

### Nivel 2: Medio (30-50% reducción)
```
□ Fusionar instrucciones redundantes
□ Reemplazar párrafos por bullets
□ Eliminar contexto innecesario
□ Combinar ejemplos similares
```

### Nivel 3: Avanzado (50-70% reducción)
```
□ Reemplazar con template structures
□ Usar shortcuts (ej: "Constraints:" en vez de lista)
□ Eliminar identidad verbose ("Eres un experto...")
□ Dejar solo: rol + tarea + output format
```

## Decision Matrix

```
¿Puedo eliminar [elemento]?
├─ ¿Cambia el output?
│   ├─ Sí → NO eliminar
│   └─ No → ¿Mejora concisión?
│       ├─ Sí → eliminar
│       └─ No → ¿Añade claridad?
│           ├─ Sí → mantener
│           └─ No → eliminar
```

## Threshold de Parada

```
Stop si:
□ Tokens < 50 Y funciona
□ 3 iteraciones sin mejora
□ Prompt legible en 1 línea

Nunca stop si:
□ Sacrificás correctitud por tokens
□ Edge cases no cubiertos
```

## Ejemplo Completo

### Iteración 0 (Initial)
```
"Eres un desarrollador senior de Go con más de 10 años de experiencia
especializado en APIs REST. Tu tarea es implementar un endpoint de login
que maneje autenticación JWT. Debes seguir las mejores prácticas de
seguridad incluyendo hash de passwords y validación de input. Además
debes escribir tests para coverage completo. Responde únicamente en
código Go limpio y documentado."
```
Tokens: ~150

### Iteración 1 (After cuts)
```
"Eres dev Go senior. Implementá endpoint login JWT. Tests coverage.
Response: Go code only."
```
Tokens: ~35 | Score: 9/10

### Iteración 2 (Optimal)
```
"Go dev. Login JWT endpoint + tests."
```
Tokens: ~12 | Score: 8/10

**Resultado: 88% reducción manteniendo 8/10**

## Comandos

```bash
# Medir tokens
prompt_tokens() {
  echo "$1" | wc -c | awk '{print int($1/4)}'
}

# Test loop
karpathy_loop() {
  local prompt="$1"
  echo "Tokens: $(prompt_tokens "$prompt")"
  # ... test y scoring
}
```

## Recursos

- Templates: [assets/loop-template.md](assets/loop-template.md)
- Tactics: [assets/cut-tactics.md](assets/cut-tactics.md)
- Examples: [assets/iteration-examples.md](assets/iteration-examples.md)