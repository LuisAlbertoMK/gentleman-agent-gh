# AEM Migration — Actionable Checklists

> Referenced by `aem-migration` skill. Use alongside the Playbook (`playbook.md`) and reference mappings (`reference.md`).

## Checklist 1: Pre-Flight Assessment

- [ ] Run Best Practices Analyzer (BPA) on source AEM (admin user, Stage/Clone not Prod)
- [ ] Upload BPA report to Cloud Acceleration Manager (CAM)
- [ ] Verify Pattern Detector findings
- [ ] Check BPA for Lighthouse Score (v2.1.54+, needs public URL)
- [ ] Get BPA upload key + note expiry (renew near expiry)
- [ ] Inventory custom components (count + list)
- [ ] Inventory dialogs: ExtJS (`dialog/`) vs Coral 3 (`_cq_dialog/`)
- [ ] Inventory datasources + `optionsProvider` servlets
- [ ] Inventory Sling Models (count + `@Model` annotations)
- [ ] Inventory clientlibs (categories + embeds)
- [ ] Inventory workflows + search forms + repoinit scripts
- [ ] Check deprecated features against AEM CS compatibility matrix
- [ ] ICE-score all gaps; flag Alto blast-radius for human checkpoint
- [ ] Define KPIs: page load, error rate, conversion, publish latency
- [ ] Estimate effort + resourcing; set timeline

## Checklist 2: Content Transfer (CTT v3.0)

- [ ] Upgrade source to AEM 6.5+ if on 6.3 or lower
- [ ] Verify Java 8+ on source
- [ ] Calculate disk space: `datastore_size + (nodestore_size × 1.5)` GB free in `crx-quickstart/`
- [ ] Run Revision Cleanup on source
- [ ] Run data store consistency check on source
- [ ] Install/uninstall CTT — ensure v3.0 (uninstall older versions first)
- [ ] Verify CTT install path is `crx-quickstart/cloud-migration` (DO NOT alter)
- [ ] Create CAM project in Cloud Acceleration Manager
- [ ] Create migration set #1 (max 10 per project; plan for 2nd project if >10)
- [ ] Extraction phase: run on source Author
- [ ] Ingestion phase: wipe mode (delete target first) for initial migration
- [ ] Verify content renders on target (project structure must be correct)
- [ ] For top-ups: incremental extraction → merge mode ingestion
- [ ] Post-transfer: verify published/unpublished status (CTT doesn't preserve this — manual filtering needed)

### Rollback Strategy
- **Wipe mode rollback** (EASY): wipe only deletes target repo content → target is empty CS instance → re-ingest from migration set. **If ingest fails, target is empty — no data loss risk.**
- **Merge mode rollback** (HARD): applied on top of existing → must maintain pre-ingest snapshot/backup. Use `repoinit` scripts to revert ACLs. Document before-merge state.
- **Disk space failure during extraction**: CTT writes to `crx-quickstart/cloud-migration` — free space, then re-run extraction (resumes from checkpoint).
- **Content doesn't render post-transfer**: the CTT creates content but NOT code/components. Ensure component migration (Checklist 3) is deployed via Cloud Manager BEFORE content transfer verification.

## Checklist 3: Component Migration (ExtJS → Coral 3)

- [ ] Rename `dialog/` → `dialog.bak/` (DO NOT delete)
- [ ] Create `_cq_dialog/.content.xml` with Coral 3 structure
- [ ] Convert `xtype` widgets → `sling:resourceType` Granite UI components
- [ ] Multifield: set `composite="{Boolean}true"` + `<field>` container for multiple sub-fields; simple for single
- [ ] namePrefix → set `name="./prop"` on field container
- [ ] optionsProvider → create `datasource` child node + implement Sling servlet (return `application/json`)
- [ ] Validation: vtype/regex/regexText → migrate to Coral 3 clientlib `foundation-validation`
- [ ] Sanitize path properties: strip `/libs/` prefix, collapse `//`
- [ ] Update `filter.xml`: add `<exclude pattern=".*/dialog.bak(/.*)?"/>`
- [ ] Design dialog: `design_dialog/` → `_cq_design_dialog/` (skip if editable-templates-in-use)
- [ ] Migrate JSP → HTL (Sightly) for rendering
- [ ] Sling Models: add `@Model` resourceType + `@Exporter` for Cloud Service
- [ ] Clientlibs: audit categories + embeds; remove deprecated (`cq.jquery`, `cq.shared` where possible)
- [ ] Run BPA re-check to confirm no remaining blocking features

## Checklist 4: Tags / Data Layer / Analytics Migration

- [ ] AEP Tags property configured (Company + Environment mapping in IMS config)
- [ ] Adobe IMS configuration for Tags verified in AEM (Tools > Security > Adobe IMS Configurations → Check Health)
- [ ] Create Tags config in AEM (Tools > Cloud Services > Adobe Launch Configurations)
- [ ] Apply Tags config to site root (Site Properties → Advanced → Cloud Configuration)
- [ ] Map data elements: `digitalData.*` → JavaScript Variable data elements (or ACDL type)
- [ ] Migrate rules: Event + Conditions + Actions → Web SDK extension
- [ ] Verify tokenization: `%dataElement%` (client-side) vs `{{dataElement}}` (event-forwarding) vs `arc.event.xdm.*` (Edge)
- [ ] Web SDK migration path chosen (one of: Web SDK tag ext / Analytics→Web SDK / AppMeasurement→Web SDK lib)
- [ ] ⚠️ Verify NO mixed AppMeasurement + Web SDK on the same page
- [ ] Configure Datastream (server-side config for Web SDK)
- [ ] Add Adobe Analytics service to Datastream
- [ ] Test embed code via Adobe Experience Platform Debugger (Chrome)
- [ ] `_satellite.setDebug(true)` for client-side rule order verification
- [ ] Network tab: verify Edge network calls (`/ee/v2/collect`)
- [ ] Data Element validation: `console.log(digitalData.page.pageInfo)` in browser

## Checklist 5: Debugging & Verification

- [ ] Logs: check `error.log` for exceptions post-migration
- [ ] OSGi Bundles: `/system/console/bundles` → all bundles active, no unsatisfied imports
- [ ] OSGi Components: `/system/console/components` → all components satisfied
- [ ] Sling Models: `/system/console/status-Sling-Model` → models registered to correct resource types
- [ ] Query Performance: `/libs/granite/operations/content/maintenance` → EXPLAIN slow queries
- [ ] Slow query remediation: nodetype restriction → path scoping → `jcr:contains` over LIKE → check `evaluatePathRestrictions`
- [ ] Tune: `-Doak.queryLimitInMemory=500000`, `-Doak.queryLimitReads=100000`
- [ ] Remote debugging: IDE JDWP to `:4502` for Java step-through
- [ ] RDE: `aio cloud-service:rde:install` for rapid iteration
- [ ] E2E smoke: all existing pages render, forms submit, personalization works
- [ ] AEP Debugger: Tags build/env correct, Analytics report suites active, Target activities qualify
- [ ] BPA re-run on target to confirm no new blocking findings
