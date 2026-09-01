# Reasoning Tier (P0-3)

> Tier especializado para debugging multi-paso y síntesis compleja. Extiende gentleman-deep con chain-of-thought explícito.

## Cuando usar
- Debugging con ≥3 hipótesis competidoras
- Síntesis multi-archivo con trade-offs no triviales
- Verificación trial-verify (implementa N enfoques, puntúa, elige ganador)

## Protocolo
1. Enumera hipótesis con confianza: high/medium/low/unvalidated
2. Prueba cada una con evidencia file:line o tool output
3. Sintetiza ganador con 4-field return contract
4. No repitas el error catalogado 2026-08-29 (B 93 files a quick) — descompone en clusters ≤10 files si es T2+

## Modelo
- Usa nemotron-3-ultra-free (reasoning-capable) — no usar laguna-s-2.1-free (404 verificado 2026-09-01)
