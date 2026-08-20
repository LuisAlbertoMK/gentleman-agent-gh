---
name: aem-migration
description: "Specialized domain knowledge for Adobe Experience Manager site migrations — assessment, content transfer, component/dialog/HTL/Sling-Models migration, Adobe Tags/Launch data-layer migration, Adobe Analytics/Target/Campaign integration, and AEM debugging."
triggers: "aem migration, adobe experience manager migration, migration aem, aem cloud service, adobe launch tags migration, data layer migration, digitaldata, digital data layer, appmeasurement to web sdk, aep web sdk, adobe analytics migration, adobe target migration, content transfer tool, best practices analyzer, extjs to coral3, sling model, datasource migration, aem debugging, aem tags integration, migration readiness"
changelog: docs/agentes/aem-migration/automejora-cycle-log.md
---

# AEM Migration Skill

> Domain expertise for `gentleman-aem`. Compact per ADR-007. Deep refs: `references/reference.md`, `docs/agentes/aem-migration/knowledge-base.md`.

## When to Use
Any AEM migration: readiness assessment, content transfer (CTT), component/dialog/code migration to Cloud Service, Tags(Launch)→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK, Analytics/Target/Campaign integration, AEM debugging.

## Domain Model
| Layer | Source (6.x/AMS) | Target (Cloud Service) | Artifact |
|---|---|---|---|
| Content | CRX/DE package, node store | CTT v3.0 migration set | `04-migration-set/` |
| Code | Felix console | Cloud Manager CI/CD | `ui.apps`/`ui.content` |
| Dialogs | ExtJS (Coral 2) | Granite UI `_cq_dialog/` (Coral 3) | extjs-to-coral3 mapping |
| Components | JSP/Sling taglibs | HTL/Sightly | `@Model` Sling Models |
| Datasources | `optionsProvider` servlet | `datasource` + JSON servlet | Sling ResourceType servlet |
| Data layer | `digitalData.*` | ACDL/XDM/Web SDK | `adobe.dl`, `datastream` |
| Tags | Launch property | AEP Tags property | Library→Environment→Publish |
| Analytics | AppMeasurement.js | Web SDK extension | `data`↔XDM mapping |
| Debug | CRXDE, Felix | RDE, Query Perf, AEP Debugger | logs, `/system/console/*`, `arc.*` |

## Workflow
1. **Pre-Flight** — BPA→CAM→Pattern Detector→Gap inventory+ICE+blast radius. STOP on Alto gaps.
2. **CTT** — Revision cleanup→disk check→CAM extract/ingest→max 10 sets/project→verify render.
3. **Code/Migration** — ExtJS→Coral 3 (rename, multifield→composite, optionsProvider→datasource); Sling Models (@Model+injectors, register resourceTypes).
4. **Tags/Data/Analytics** — Launch→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK (3 paths, no mixed mode).
5. **Debugging** — Logs, bundles, components, Models, Query Perf, RDE, AEP Debugger. Slow-query: @Type index, path scoping, jcr:contains.

## Constraints
CTT does NOT analyze content; published/unpublished NOT preserved→filter manually. AEP Debugger needs EC auth for non-public data. Web SDK all-or-nothing per page. BPA needs admin; Stage/Clone only, never Prod.

## Refs
self-improvement | analysis-mode | deep-debugging | code-generation | security-scanner | quality-gate