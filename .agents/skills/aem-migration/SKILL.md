---
name: aem-migration
description: "Specialized domain knowledge for Adobe Experience Manager site migrations — assessment, content transfer, component/dialog/HTL/Sling-Models migration, Adobe Tags/Launch data-layer migration, Adobe Analytics/Target/Campaign integration, and AEM debugging."
triggers: "aem migration, adobe experience manager migration, migration aem, aem cloud service, adobe launch tags migration, data layer migration, digitaldata, digital data layer, appmeasurement to web sdk, aep web sdk, adobe analytics migration, adobe target migration, content transfer tool, best practices analyzer, extjs to coral3, sling model, datasource migration, aem debugging, aem tags integration, migration readiness"
changelog: docs/agentes/aem-migration/automejora-cycle-log.md
---

# AEM Migration Skill

> Domain expertise for the `gentleman-aem` agent. Kept compact per ADR-007. Deep references: `references/reference.md` and `docs/agentes/aem-migration/knowledge-base.md`.

## When to Use

Any AEM migration task: readiness assessment, content transfer (CTT), component/dialog/code migration to Cloud Service, Adobe Tags (Launch) → AEP Tags migration, digitalData → ACDL/XDM data-layer migration, AppMeasurement → Web SDK migration, Adobe Analytics/Target/Campaign integration, and AEM debugging.

## Domain Model (at-a-glance)

| Layer | Source (6.x/AMS) | Target (Cloud Service) | Key Migration Artifact |
|-------|------------------|------------------------|------------------------|
| **Content** | CRX/DE package, node store | Migration set via CTT v3.0 | `04-migration-set/` |
| **Code** | Felix `system/console` | Cloud Manager CI/CD pipeline | `ui.apps` / `ui.content` archetype |
| **Dialogs** | ExtJS `dialog/` (Coral 2) | Granite UI `_cq_dialog/` (Coral 3) | extjs-to-coral3 mapping |
| **Components** | JSP / Sling taglibs | HTL / Sightly | `@Model` Sling Models |
| **Datasources** | `optionsProvider` servlet | `datasource` + JSON servlet | Sling ResourceType servlet |
| **Data layer** | `digitalData.*` | ACDL / XDM / Web SDK | `adobe.dl`, `datastream` |
| **Tags** | Adobe Launch property | AEP Tags property | Library → Environment → Publish |
| **Analytics** | AppMeasurement.js | Web SDK extension | `data` object ↔ XDM mapping |
| **Debug** | CRXDE Lite, Felix | RDE, Query Perf, AEP Debugger | logs, `/system/console/*`, `arc.*` |

## Workflow Overview

1. **Pre-Flight Assessment** — BPA → CAM → Pattern Detector → Gap inventory + ICE scoring + blast radius. **Stop** on Alto blast-radius gaps.
2. **Content Transfer (CTT)** — Revision cleanup → disk space check → CAM extraction/ingest → max 10 sets/project → verify render.
3. **Code & Component Migration** — ExtJS→Coral 3 dialogs (rename, multifield→composite, optionsProvider→datasource), Sling Models (@Model with injectors, register to resourceTypes).
4. **Tags / Data Layer / Analytics** — Launch→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK (3 paths, no mixed mode).
5. **Debugging** — Logs, bundles, components, Sling Models, Query Perf, remote debug, RDE, AEP Debugger. Slow-query fixes: @Type index, path scoping, jcr:contains.

## Constraints

- CTT does NOT analyze content; published/unpublished distinction NOT preserved → filter manually.
- AEP Debugger requires Experience Cloud auth for non-public data.
- Web SDK migration all-or-nothing per page (no mixed AppMeasurement + Web SDK).
- Extjs-to-coral3 optionsProvider servlet → developer must implement.
- BPA requires admin user; Stage/Clone only, never Prod.

## References
- `references/reference.md` — Deep reference (mappings, JSON schemas, servlet skeletons)
- `docs/agentes/aem-migration/knowledge-base.md` — Synthesized research
- `docs/protocolos/protocolo_mejora_autonoma_v3.md` — Automejora protocol
- `docs/agentes/aem-migration/automejora-cycle-log.md` — Cycle execution log

## Cross-Refs
self-improvement | analysis-mode | deep-debugging | code-generation | security-scanner | quality-gate

---

> See [reference.md](docs/skills/aem-migration/reference.md) for extended details, examples, and detailed patterns.