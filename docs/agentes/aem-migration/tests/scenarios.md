# AEM Migration Agent — Test Harness / Scenarios

> Validation suite for `gentleman-aem` agent. Run the agent prompt against each scenario and verify the output matches the expected behavior. Referenced by automejora-cycle-log.md Cycle 1.

## How to run
1. Load the `aem-migration` skill: `skill aem-migration`
2. Present the scenario prompt to the `gentleman-aem` agent
3. Grade the output against "Expected behavior" + "Pass criteria"
4. Record result: ✅ PASS / ⚠️ PARTIAL / ❌ FAIL

---

## Scenario 1 — Dialog Migration (multifield + optionsProvider + namePrefix + vtype)

**Prompt**: "I have an AEM 6.5 component with a dialog that uses `xtype=multifield` with `namePrefix="./link"` and an `optionsProvider` on a selection field. It also has `vtype="email"` validation. How do I migrate this to Coral 3 for AEM as a Cloud Service?"

**Expected behavior**:
- References `references/reference.md` §1 (dialog mapping)
- Explains: rename `dialog/` → `_cq_dialog/`, backup
- Multifield: `composite="{Boolean}true"` + `<field>` container with `name="./link"`
- optionsProvider → `datasource` child node + Sling servlet skeleton (return `application/json`)
- vtype → Coral 3 clientlib `foundation-validation` (js snippet)
- Path sanitization + filter.xml exclude note

**Pass criteria**: All 4 sub-topics addressed with concrete code/XML examples.
**Confidence**: high

---

## Scenario 2 — Data Layer → Web SDK (Analytics + Target)

**Prompt**: "We have a digitalData layer (page + product) and want to migrate from AppMeasurement to Web SDK. We also use Adobe Target. What's the migration path?"

**Expected behavior**:
- References `knowledge-base.md` §6 + §7
- 3 Web SDK migration paths explained (not mixed on same page)
- ACDL vs XDM decision tree
- Datastream configuration note
- Target: verify no mixed AppMeasurement + Web SDK

**Pass criteria**: 3 paths listed, mixed-impl warning present, ACDL/XDM decision clear.
**Confidence**: high

---

## Scenario 3 — CTT Disk Space Failure

**Prompt**: "My Content Transfer Tool extraction failed with a disk space error. The source nodestore is 20GB and data store is 64GB. How do I calculate the required space and fix?"

**Expected behavior**:
- References `knowledge-base.md` §3.1
- Formula: `datastore_size + (nodestore_size × 1.5)` = 64 + (20 × 1.5) = 94 GB
- Notes CTT uses 64GB minimum for datastore regardless of actual size
- Path: `crx-quickstart/cloud-migration` — DO NOT alter
- Fix: free space, re-run extraction (resumes from checkpoint)

**Pass criteria**: Correct formula + result (94GB) + checkpoint resume note.
**Confidence**: high

---

## Scenario 4 — Slow Query Debugging

**Prompt**: "A JCR query in AEM Cloud Service is slow and throwing 'query read more than x nodes'. What tool do I use and how do I fix it?"

**Expected behavior**:
- References `knowledge-base.md` §8.2
- Tool: Query Performance console at `/libs/granite/operations/content/maintenance`
- EXPLAIN → look for "no index" / "traversal"
- Fix recipe: nodetype restriction → path scoping (`/content/site/us`) → `jcr:contains` over `LIKE` → `evaluatePathRestrictions=true`
- Tune: `-Doak.queryLimitInMemory=500000`, `-Doak.queryLimitReads=100000`

**Pass criteria**: Tool URL + 4-step fix recipe + tune flags.
**Confidence**: high

---

## Scenario 5 — Full Migration Planning (Ford-style)

**Prompt**: "Ford is migrating from AEM 6.5 AMS to AEM as a Cloud Service. They use Adobe Analytics, Adobe Target, Adobe Audience Manager, and Adobe Campaign. Their data layer is digitalData. Plan the full migration."

**Expected behavior**:
- Follows Playbook (`playbook.md`): Step 1 (source/target identified) → Step 2 (3 phases) → Step 3-4 (component + tags decision trees)
- Phase 1: BPA + CAM + Pattern Detector + gap inventory + KPIs
- Phase 2: Infrastructure (CAM, RDE, Cloud Manager) → Content Transfer (CTT wipe) → Code (archetype + CI/CD) → Components (ExtJS→Coral3) → Tags/DL (Launch→AEP Tags, digitalData→ACDL, AppMeasurement→Web SDK)
- Phase 3: Monitoring + top-ups + tuning
- Acknowledges platform-level scope (not just AEM — Analytics, Target, AAM, Campaign all touch)
- References Ford/VML case study pattern (data layer standards, integrated testing)

**Pass criteria**: All 3 phases covered with sub-steps; platform scope acknowledged; Ford case study referenced.
**Confidence**: high
