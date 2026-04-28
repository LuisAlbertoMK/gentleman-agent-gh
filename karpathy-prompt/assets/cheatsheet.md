# Cheatsheet — Prompts Mínimos de Alto Impacto

## La Regla Universal

> "Write as if explaining to a smart junior dev who just got hired."

## Quick Reference

| Necesidad | Template |
|-----------|----------|
| Rol + tarea | `Eres X. Haz Y.` |
| Con output | `Eres X. Haz Y. Output: Z.` |
| Con ejemplo | `Eres X. Ejemplo: Y. Generá: Z.` |
| Con constraints | `Eres X. Constraints: Y. Output: Z.` |

## Decision Tree

```
START
├─ ¿Necesita rol específico?
│   ├─ Sí → "Eres [rol]. [tarea]."
│   └─ No → [tarea directa]
│
├─ ¿Necesita formato?
│   ├─ Sí → Agregar "Output: [formato]"
│   └─ No → Omitir
│
├─ ¿Necesita ejemplo?
│   ├─ Sí → Agregar 1 ejemplo máximo
│   └─ No → Omitir
│
└─ ¿Necesita constraints?
    ├─ Sí → 2-3 máximo
    └─ No → Omitir
```

## Anti-Patterns

### ❌ Demasiado largo
```
Eres un experto en programación con más de 20 años de experiencia,
que ha trabajado en Google, Meta, Amazon y Microsoft, especializado
en Python, JavaScript, TypeScript, Go, Rust, C++, y muchos otros...
```
### ✅ Minimalista
```
Eres un dev senior Python. Refactorizá esto:
[código]
```

## Token Budget

| Componente | Tokens |
|------------|--------|
| Identidad | 5-10 |
| Separador | 1-2 |
| Tarea | 10-30 |
| Formato | 5-15 |
| Ejemplo | 50-200 |
| **TOTAL óptimo** | **50-150** |

## Casos de Uso Comunes

| Caso | Prompt |
|------|--------|
| Traducción | `Traducí al español: [texto]` |
| Código | `Reescribí en [lenguaje]: [código]` |
| Resumen | `Resumí: [texto]` |
| Bug fix | `Bug: [código]\nFix:` |
| Explicación | `Explicá: [concepto]` |
| Lista | `Dame 5 [tema]` |