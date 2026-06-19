# Subagent Test Prompts

## gentleman-codex (deepseek-v4-flash-free)

```text
Ejecutá .\scripts\list-skills.ps1 -Json y analizá:
1. Cuáles skills tienen score ≤ 6
2. Por qué tienen score bajo (tamaño, líneas de SKILL.md, referencias, archivos)
3. Sugerí 3 mejoras concretas para subirles el score
Devolvé el análisis en 5 líneas máx, conciso.
```

---

## gentleman-deep (nemotron-3-ultra-free)

```text
Ejecutá .\scripts\list-skills.ps1 y presentame:
1. Las 3 skills con score más alto — ¿qué las hace robustas?
2. Las 3 con score más bajo — ¿qué les falta estructuralmente?
3. ¿Hay un patrón en las skills que tienen references/ y las que no?
4. Recomendación: ¿deberíamos consolidar skills chicas similares?
Analizá con profundidad, pensá en arquitectura del repositorio.
```

---

## gentleman-quick (mimo-v2.5-free)

```text
Corré .\scripts\list-skills.ps1.
Decime cuántas skills hay, el score promedio, y el tamaño promedio.
Una línea, solo datos.
```
