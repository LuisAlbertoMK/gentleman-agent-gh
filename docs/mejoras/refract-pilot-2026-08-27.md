# Piloto Refract — Resultado Real (2026-08-27)

**Branch**: experimento/refract-pilot-2026-08-27 — **Punto seguridad**: punto-seguridad-2026-08-27-priority-verify @a5a1d886
**Protocolo**: PEV + sandbox Temp + read-only

## Veredicto
**Piloto NO viable para este repo** `confidence: high`

## Evidencia Real
- `git clone --depth1 https://github.com/Refractdev/refract-dev.git` → 5.1MB ok `confidence: high`
- Stack: TypeScript/React/Vite/Supabase/Vercel `confidence: high`
- `src/engine/ast.ts` → usa `@typescript-eslint/typescript-estree` y filtra `/.tsx?|.jsx?$/` solo `confidence: high`
- No hay CLI `refract` — es SaaS web (refract.dev), no herramienta local `confidence: high`
- `scripts/score-auto.ps1` → 262 líneas / 1310 words / 11,913 chars / 15 try/catch / 1 función `Add-Dimension` `confidence: high`
- `Invoke-ScriptAnalyzer -Path scripts/score-auto.ps1` → 17 warnings (PowerShell) `confidence: high`

## Análisis
Refract es para TS/JS/JSX production-ready. PowerShell (.ps1) fuera de scope. Nuestra toolchain correcta sigue siendo **PSScriptAnalyzer + StrictMode + param + try/catch** (ya hecho en Cycle 30: CC10 BP10) `confidence: high`.

## Recomendación Verificada
No instalar Refract para PowerShell. Si en el futuro añaden soporte PS, re-evaluar. Mantener pnpm + PSScriptAnalyzer.

**Beneficio medido**: 0 para este stack. Reporte en Temp, sin tocar repo salvo este doc.
