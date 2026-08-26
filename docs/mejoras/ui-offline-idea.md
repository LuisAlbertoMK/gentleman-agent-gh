# UI Offline Audit — Fallback sin Ollama

**Fecha**: 2026-08-27
**Branch**: experimento/weak-point-fix-2026-08-27
**Objetivo**: Eliminar dependencia de vision-analyze / Ollama (localhost:11434) para auditorias UI basicas.

## Contexto

`vision-analyze` requiere Ollama corriendo en `localhost:11434`. Cuando Ollama no esta disponible (CI, maquinas limpias, VMs), el skill falla con `ECONNREFUSED`. La solucion es un fallback offline que audite lo mismo via reglas estaticas.

## Archivos relacionados

- `scripts/ui-offline-audit.ps1` — script offline (creado en esta rama)
- `skills/baseline-ui/SKILL.md` — reglas de referencia
- `docs/.vitepress/config.js` — config del sitio
- `docs/index.md` — target de los fixes

---

## Variantes de fix para `docs/index.md`

### Variante A: Spacing 8pt grid

```markdown
# Gentleman Agent GH

<!-- FIX A: 8pt spacing — 2 blank lines after H1 for breathing room -->

Bienvenido a la documentacion de mejoras.

<!-- FIX A: 1 blank line before list for hierarchy clarity -->

- [Priority Verify 2026-08-27](/mejoras/priority-verify-2026-08-27)

- [Pester Verify](/mejoras/pester6-verify-2026-08-27)
```

**Razon**: El H1 esta pegado al parrafo (sin espacio). En VitePress, esto se traduce a margen insuficiente. Separar con linea en blanco simula 8pt de air.

### Variante B: Jerarquia H1/H2 + separador visual

```markdown
# Gentleman Agent GH

Bienvenido a la documentacion de mejoras.

## Documentos recientes

- [Priority Verify 2026-08-27](/mejoras/priority-verify-2026-08-27)
- [Pester Verify](/mejoras/pester6-verify-2026-08-27)
```

**Razon**: Actualmente la lista no tiene encabezado H2, rompiendo la jerarquia semantica. Agregar `## Documentos recientes` establece nivel jerarquico correcto (H1 -> H2 -> lista). Alinea con baseline-ui rule: "text-balance headings".

### Variante C: Typography + meta description

```markdown
---
title: Gentleman Agent GH
description: Documentacion de mejoras, ciclos y arquitectura del agente
---

# Gentleman Agent GH

Bienvenido a la documentacion de mejoras.

## Enlaces

- [Priority Verify 2026-08-27](/mejoras/priority-verify-2026-08-27)
- [Pester Verify](/mejoras/pester6-verify-2026-08-27)
```

**Razon**: Agregar frontmatter VitePress con `title` y `description` habilita SEO meta tags. La seccion `## Enlaces` da contexto semantico a la lista. Opcionalmente, VitePress inyecta `text-balance` via theme defaults para headings con frontmatter.

---

## Matriz de decision

| Variante | Violation resuelta | Esfuerzo | Riesgo |
|----------|-------------------|----------|--------|
| A - Spacing 8pt | `spacing-heading-gap` | Trivial | Nulo |
| B - Jerarquia H2 | `hierarchy-skip` (futuro) | Bajo | Nulo |
| C - Typography | `typography-text-balance` + SEO | Bajo | Nulo |

**Recomendacion**: Combinar A + B + C para cobertura maxima. Todos son no-destructivos (solo markdown).

## Siguiente paso

Ejecutar `scripts/ui-offline-audit.ps1 -Json` en la rama `experimento/weak-point-fix-2026-08-27` y verificar score > 8/10.
