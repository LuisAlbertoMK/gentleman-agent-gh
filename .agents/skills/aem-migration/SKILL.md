---
name: aem-migration
description: "Adobe Experience Manager site migrations — assessment, content transfer, component/dialog/HTL/Sling-Models migration, Tags/Launch data-layer, Analytics/Target/Campaign integration, AEM debugging."
triggers: "aem migration, adobe experience manager migration, migration aem, aem cloud service, adobe launch tags migration, data layer migration, digitaldata, appmeasurement to web sdk, aep web sdk, adobe analytics migration, adobe target migration, content transfer tool, best practices analyzer, extjs to coral3, sling model, datasource migration, aem debugging"
changelog: docs/agentes/aem-migration/automejora-cycle-log.md
token_budget: 2555
---
# AEM Migration Skill
> Domain expertise for `gentleman-aem`. Compact per ADR-007.
## When to Use
AEM migrations: readiness (BPA/CAM), CTT, component/code→Cloud Service, Tags→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK, Analytics/Target/Campaign, debugging.
## Workflow
1. **Pre-Flight** — BPA→CAM→Pattern Detector→Gap inventory+ICE+blast radius. STOP on Alto gaps.
2. **CTT** — Revision cleanup→disk check→CAM extract/ingest→max 10 sets/project→verify render.
3. **Code/Migration** — ExtJS→Coral 3 (rename, multifield→composite, optionsProvider→datasource); Sling Models (@Model+injectors, register resourceTypes).
4. **Tags/Data/Analytics** — Launch→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK (3 paths, no mixed mode).
5. **Debugging** — Logs, bundles, components, Models, Query Perf, RDE, AEP Debugger. Slow-query: @Type index, path scoping.
## Constraints
CTT does NOT analyze content; published/unpublished NOT preserved→filter manually. AEP Debugger needs EC auth. Web SDK all-or-nothing per page. BPA needs admin; Stage/Clone only, never Prod.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "AEM migration is copy-paste" | No component/dialog mapping | aem-migration skill checklist |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- No component/dialog mapping → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- aem-migration skill checklist
- cross-ref-check.ps1 → SKILL.md OK
## Refs
self-improvement | analysis-mode | deep-debugging | code-generation | security-scanner | quality-gate
## Reference
Domain Model table + deep refs → docs/skills/aem-migration/reference.md

