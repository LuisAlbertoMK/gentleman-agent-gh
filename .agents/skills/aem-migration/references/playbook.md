# AEM Migration Playbook — Decision Tree

> Referenced by `aem-migration` skill. Use to determine which migration phase to run based on source/target context.

## When to use this playbook

Start here for any AEM migration engagement to determine the assessment scope and migration path.

## Step 1: Identify Source & Target

| Question | Answer | Implication |
|----------|--------|-------------|
| Is source AEM On-Premise or AMS (6.x)? | → Yes | Full 3-phase migration (Planning → Execution → Post Go-live) |
| Is source already AEM as a Cloud Service? | → Yes | Incremental modernization only — skip content transfer, focus on component/data-layer modernization |
| Is target AEM as a Cloud Service? | → Yes | Full Cloud Service migration |
| Is target Edge Delivery Services (EDS) / AEM Go? | → Yes | Headless + EDS path — see Step 5 |
| Is target a competitor (e.g. WordPress, Contentful, Drupal)? | → Yes | Off-platform migration — extract content via AEM APIs, transform, import |

## Step 2: Assessment Scope (Adobe 3-phase model)

### Phase 1 — Planning (confidence: high)
Run if source ≠ target architecture. Activities:
1. Run BPA on source → CAM upload → Pattern Detector report
2. Inventory: components (count), dialogs (ExtJS vs Coral), datasources, Sling Models, clientlibs, workflows, search forms, repoinit scripts
3. Map deprecated features → AEM CS compatibility matrix
4. Effort estimation (ICE-scored) + resource planning
5. KPIs: page load time, error rate, conversion, publish latency

### Phase 2 — Execution
Run sub-phases in order:
1. **Infrastructure**: Provision CAM project → RDE → Cloud Manager pipelines
2. **Content Transfer**: CTT v3.0 → wipe mode (initial) → merge top-ups
3. **Code Migration**: Archetype → Maven build → Cloud Manager CI/CD
4. **Component Migration**: ExtJS→Coral3, JSP→HTL, Sling Models + Exporter
5. **Tags/Data Layer**: Launch→AEP Tags, digitalData→ACDL/XDM, AppMeasurement→Web SDK

### Phase 3 — Post Go-live
1. Monitor: error logs, query performance, Edge network
2. Top-up: incremental CTT extractions
3. Tune: query indexes, cache layers, lazy loading

## Step 3: Component Migration Decision Tree

```
Has custom components?
├── No → Skip to Tags migration (Step 4)
└── Yes → Has ExtJS dialogs (xtype=...)?
    ├── No → Is code JSP-based?
    │   ├── Yes → Migrate JSP → HTL (template language migration)
    │   └── No → Review Sling Models for Cloud Service exporter compat
    └── Yes → Run dialog migration:
        ├── multifield present? → composite="{Boolean}true" + field container
        ├── optionsProvider? → datasource + Sling servlet (dev implements)
        ├── namePrefix? → name="./prop" on container
        ├── validation (vtype/regex)? → Coral 3 clientlib foundation-validation
        └── Path props with /libs? → strip leading /libs/, collapse //
```

## Step 4: Tags / Data Layer Migration Decision Tree

```
Using Adobe Launch?
├── Yes → AEP Tags (same product, re-author in new UI)
└── No → Custom script tags → migrate to AEP Tags property

Data layer on page?
├── No → Implement ACDL or XDM from scratch (see reference §6)
└── Yes → Is it digitalData (W3C DDL)?
    ├── Yes → digitalData → ACDL (minimal change) OR → XDM (full AEP integration)
    └── No (custom) → Map custom DL → ACDL/XDM fields

Analytics on page?
├── No → Skip
└── Yes → AppMeasurement.js present?
    ├── Yes → Web SDK migration (3 paths, see knowledge-base §7)
    └── No (already Web SDK) → Verify datastream config

Personalization?
├── Adobe Target at.js? → Target Web SDK migration
└── Yes → Verify no mixed AppMeasurement + Web SDK on same page
```

## Step 5: Off-Platform / EDS Path

If target is NOT AEM Cloud Service:
- **Content extraction**: AEM Translation API or Query Builder → JSON/CSV
- **Component mapping**: Map AEM components → target CMS blocks
- **Data layer**: Export digitalData → target platform data model
- **Assets**: AEM Assets API → target DAM
- **Tags**: AEP Tags → target platform tags (GA4, etc.)

For **Edge Delivery Services (AIS/Helix)**:
- Migrate AEM page properties → AEP Data Layer / XDM
- Migrate components → Universal Editor blocks (Markdown + JSON)
- Migrate authoring → Page Authoring in AEM CS (headless) + Universal Editor

## Step 6: Rollback Decision Points

| Phase | Rollback triggers | Rollback action |
|-------|-------------------|-----------------|
| Planning | BPA finds >10 Alto blast-radius gaps without mitigation plan | Stop → human checkpoint |
| Content Transfer | Ingestion fails OR content doesn't render post-transfer | Wipe mode: revert to snapshot of empty CS repo (easy). Merge mode: manual diff (hard). |
| Code Migration | Cloud Manager pipeline fails 3x OR bundle doesn't start | git revert on last commit; redeploy previous pipeline |
| Tags Migration | Web SDK breaks data collection on >5% of pages | Re-publish previous Tags library (1-click revert in Publishing Flow) |
| Data Layer | Tracking data incorrect for >2 conversion events | Re-publish Tags library + update datastream mapping |

---

*Confidence: high for Adobe-official phases. Medium for off-platform/EDS paths (less documented in research window).*
