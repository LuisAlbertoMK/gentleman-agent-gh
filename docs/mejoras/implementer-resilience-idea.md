# Implementer Resilience — Retry Narrow Scope

**Fecha**: 2026-08-27
**Debilidad**: Si un subagente falla 2x, el orquestador para y pide al humano
**Solucion**: Retry con scope progresivamente mas estrecho + fallback a delivery-harness

## Flujo

```
Subagente falla
  → Invoke-WithRetry: reintenta 2x con scope reducido (1-2 archivos)
    → Exito: continuar pipeline
    → Fallo 2x: escalar a humano con mensaje claro
  → Si scope >5 archivos: usar delivery-harness completo
```

## Presupuesto

- **Tool calls**: max 25 por tarea
- **Tiempo**: max 5 min wall-clock
- **Retry**: max 2 intentos por scope, despues escalar

## Scope Progressivo

| Intento | Archivos | Descripcion |
|---------|----------|-------------|
| 1 | 3 archivos | Scope normal reducido |
| 2 | 1 archivo | Scope minimo — 1 solo archivo |

## Fallback a Delivery-Harness

Cuando la tarea requiere >5 archivos:
- Usar `delivery-harness.ps1` (multi-agente con aislamiento)
- El harness maneja distribucion, coleccion de resultados, y fallos
- El retry narrow scope NO aplica — el harness tiene su propia resiliencia

## Implementacion

- Script: `scripts/delivery-harness-retry.ps1`
- Funcion: `Invoke-WithRetry -ScriptBlock {} -MaxRetries 2 -NarrowScope {}`
- Output: JSON estructurado con cada intento, scope, y resultado
