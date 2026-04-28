---
name: karpathy-prompt
description: >
  Método de Karpathy para prompts mínimos de alta calidad.
  Trigger: Cuando usuario pide prompts cortos, eficientes, mínimo token.
  También cuando dice "método Karpathy", "menos tokens", "máximo resultado",
  "LLM Wiki", "context compilation".
license: Apache-2.0
metadata:
  author: mk
  version: "1.1"
---

## Fundamento

**"Write a prompt like you're explaining to a smart junior developer sitting next to you."**

Más contexto ≠ mejor. Menos es más.

## Las 5 Reglas de Oro

### 1. Identidad + Tarea = Suficiente
```
Eres [rol] especializado en [dominio].
Tu tarea: [tarea específica].
```

### 2. Estructura Mínima
- NO listas de 10+ instrucciones
- NO párrafos innecesarios
- SÍ 1-2 ejemplos concretos
- SÍ output esperado (cuando aplique)

### 3. El Formato es Instrucciones
```
Respóndete ÚNICAMENTE en JSON: {"key": "value"}
```

### 4. Constraints = Formato
```
- Máximo X caracteres
- Solo código, sin comentarios
- Ignora todo lo anterior excepto [X]
```

### 5. Chain of Thought Implícito
NO "pensemos paso a paso". Si necesitás razonamiento:
```
Razone SOLO si hay ambigüedad.
```

## LLM Wiki Pattern (v1.1)

Karpathy propone mantener una wiki de conocimiento y usarla como contexto pre-compilado.

### Estructura de 3 Capas
```
Layer 1: Raw sources (notas, docs, código)
Layer 2: LLM-compiled wiki pages (markdown estructurado)
Layer 3: index.md (mapa liviano, ~200 tokens)
```

### index.md Template
```
# Wiki Index
[Topic 1] → topic1.md
[Topic 2] → topic2.md
...
```

### Pre-Compiled Context Generator
```markdown
## Para código: Compilar contexto antes de sesión
```
1. Identificar archivos relevantes (rutas, componentes, deps)
2. Generar structured context map (~3-5K tokens)
3. Usar como input en vez de explorar código

### Structured Context Map Template
```markdown
# Project Context (~3-5K tokens)

## Routes/API
[rutas del proyecto]

## Components
[componentes principales]

## Dependencies
[árbol de dependencias]

## Hot Files
[archivos frecuentemente modificados]

## Env/Middleware
[env vars, middleware activo]

## Schema
[type definitions importantes]
```

## Templates de Referencia

### Micro (20-50 tokens)
```
Traducí al [idioma]: [texto]
```

### Simple (50-100 tokens)
```
Eres [rol]. [tarea clara y concisa].
```

### Con Output (100-200 tokens)
```
[Contexto mínimo]
Tu output: [formato exacto]
```

### Con Ejemplo (150-300 tokens)
```
[Contexto]
Ejemplo: [ejemplo breve]
Genera: [pedido]
```

### Con Constraints (100-200 tokens)
```
[Contexto mínimo]
Constraints:
- [constraint 1]
- [constraint 2]
Output: [formato]
```

## Anti-Patrones

| NO | SÍ |
|----|-----|
| "Sé muy detallista y preciso" | "Sé preciso" |
| "Pensemos paso a paso" | Omitir — ya lo hace |
| Listas de 10+ reglas | 2-3 constraints máximo |
| "Eres experto en..." × 3 | Una identidad clara |
| Context completo en cada query | Pre-compiled wiki |

## Token Budget

| Componente | Tokens aprox |
|------------|--------------|
| Identidad + Tarea | ~20-50 |
| + 1 ejemplo | +100-200 |
| + constraints | +50-100 |
| + output format | +30-50 |
| **TOTAL óptimo** | **50-300** |

## Decision Tree

```
START
├─ ¿Necesita rol?
│   ├─ Sí → "Eres X."
│   └─ No → [skip]
│
├─ ¿Necesita formato?
│   ├─ Sí → "Output: [formato]"
│   └─ No → [skip]
│
├─ ¿Necesita ejemplo?
│   ├─ Sí → 1 ejemplo máximo
│   └─ No → [skip]
│
└─ ¿Constraints?
    ├─ Sí → 2-3 máximo
    └─ No → [done]
```

## Comandos

```bash
# Contar caracteres (aprox tokens = chars/4)
echo "prompt" | wc -c

# Generar context map básico
# Usar: assets/llm-wiki-generator.md
```

## Recursos

- Plantillas: [assets/templates.md](assets/templates.md)
- Cheatsheet: [assets/cheatsheet.md](assets/cheatsheet.md)
- LLM Wiki Generator: [assets/llm-wiki-generator.md](assets/llm-wiki-generator.md)