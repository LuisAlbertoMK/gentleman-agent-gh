# TOPICS-INDEX

> Registro central de topics en curso — espejo estructural de `SKILLS-INDEX.md`, aplicado a temas de trabajo multiagente.
> Schema: §5.3 del protocolo de coordinación multiagente por ramas v1.

| topic_id | objetivo | fase | creado | actualizado | exploracion_paralela_intencional | ramas | dueno_sintesis |
|---|---|---|---|---|---|---|---|
| `experimento/perfiles-zen-go` | Aplicar permisos, sync-global y protocolo multiagente al repo | merged-to-main 2026-09-19 | 2026-09-19 | 2026-09-19 | false | `experimento/perfiles-zen-go` (merged) | orquestador |
| `experimento/sync-global-audit` | Validar sync-global fixeado en copia + proponer cableado audit-log | real-apply done 2026-09-19 | 2026-09-19 | 2026-09-19 | false | `experimento/sync-global-audit` | orquestador |

---

### Bitácora — experimento/perfiles-zen-go

- 2026-09-19: Fase `merged-to-main 2026-09-19` — merge a main completado. Enmiendas E1-E10 del protocolo multiagente aplicadas y aprobadas por owner.

### Bitácora — experimento/sync-global-audit

- 2026-09-19: Topic declarado — copy-test in-progress, audit-proposal in-progress, real-apply PENDIENTE de GO del owner.
- 2026-09-19: `real-apply done` — sync-global.ps1 -Force ejecutado en config global. Invariantes verificados: 3 manual allows preservadas (allow), 58 agentes sin cambios, JSON válido, top-level keys order same. Deltas explicadas: MCPs sincronizados con project SSoT (codegraph removed, chrome-devtools-mcp+headroom added), permission.bash expanded 95→116 keys (SEC-F2 deny-floor ported), permission.read expanded 10→29 keys (full project SSoT). Backup manual en C:\Users\LUISOR~1\AppData\Local\Temp\opencode\presync-20260919\ (SHA-256: 533F5138...). Post SHA-256: 654A2CBF... (b) audit-cableado PENDIENTE.
