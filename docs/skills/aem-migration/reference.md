# AEM Migration — Extended Reference

> This file contains verbose workflow steps, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/aem-migration/SKILL.md) for the core domain model and workflow overview.

---

## Detailed Workflow Steps

### 1. Pre-Flight Assessment
```
BPA (Best Practices Analyzer) → CAM (Cloud Acceleration Manager) → Pattern Detector
↓
Gap inventory: components, dialogs, datasources, clientlibs, workflows, searches
↓
ICE scoring (Impact × Confidence × Effort) + blast radius (Bajo/Medio/Alto)
```
**Stop**: Alto blast-radius gaps require human checkpoint before Phase 2.

### 2. Content Transfer (CTT)
```
Pre-flight: Revision Cleanup + dataStore consistency
Disk space ≥ datastore_size + nodestore_size × 1.5
↓
CAM project: extraction → migration set → ingest (wipe mode = faster)
↓
Max 10 migration sets/project → split to 2nd project if >10
↓
Post: verify content renders (project structure must be correct)
```

### 3. Code & Component Migration
**Dialog (ExtJS → Coral 3):**
- `dialog/` → `_cq_dialog/` (rename, do NOT delete until backup)
- `multifield` → `composite="{Boolean}true"` + `<field>` container
- `optionsProvider` → `datasource` child node, `sling:resourceType` → dev implements servlet
- `namePrefix` → `name="./prop"` on field container
- Validation (`vtype`, `regex`, `allowBlank`) → Coral 3 clientlib `foundation-validation`

**Sling Models**: `@Model(adaptables={Resource.class, SlingHttpServletRequest.class})`, injectors (`@ValueMapValue`, `@ChildResource`, `@ScriptVariable`), register to `sling:resourceTypes`, export-ready for Cloud Service.

### 4. Tags / Data Layer / Analytics
```
Launch property → AEP Tags property (Company/Env mapping in IMS config)
↓
digitalData.* → ACDL (adobe.dataLayer) OR XDM schema
↓
Data elements: map js vars → report suite / XDM fields
↓
Rules: Event+Conditions+Actions → Web SDK extension
  Client-side: %dataElement%  |  Event-forwarding: {{dataElement}}
  Edge: arc.event.xdm.*
↓
AppMeasurement → Web SDK: 3 paths
  1. Web SDK tag ext (recommended)
  2. Analytics ext → Web SDK ext (grace period, uses `data` obj)
  3. AppMeasurement → Web SDK lib (manual, no tags)
  ⚠️ No mixed Web-SDK+AppMeasurement on same page
```

### 5. Debugging
| Tool | URL / Location | Use |
|------|---------------|-----|
| Logs | `error.log`, `access.log` | Frontline debugging (needs adequate logging config) |
| Bundles | `/system/console/bundles` | Validate bundle present + active, unsatisfied imports |
| Components | `/system/console/components` | Component lifecycle, PID for OSGi config |
| Sling Models | `/system/console/status-Sling-Model` | Registered resource types, adaptables |
| Query Perf | `/libs/granite/operations/content/maintenance` | Explain slow queries, traversal detection |
| Remote debug | IDE JDWP to `:4502` (JDWP) | Step-through live Java code |
| RDE | `aio cli` | Rapid dev-iteration cycle |
| AEP Debugger | Chrome extension | Tags build/env, Analytics report suites, Target activities |

**Slow-query fix**: nodetype restriction → `@Type` index; path scoping (`path=/content/site/us`); `jcr:contains` over `LIKE`; tune `oak.queryLimitInMemory`/`oak.queryLimitReads`.

---

## Testing Patterns

### Pattern 1: ExtJS to Coral 3 Dialog Mapping Validation
```bash
# Verify all ExtJS dialogs have Coral 3 equivalents
find ui.apps -name "dialog.xml" -type f | while read f; do
  coral="${f/dialog/_cq_dialog}"
  [ -f "$coral" ] || echo "MISSING: $coral"
done
```

### Pattern 2: Sling Model Registration Check
```bash
# Verify all Sling Models are registered to resource types
grep -r "@Model" --include="*.java" core/src/main/java/ | \
  grep -v "adaptables.*Resource.class" && echo "MISSING Resource adaptable"
grep -r "sling:resourceTypes" --include="*.java" core/src/main/java/ | \
  wc -l  # Should match model count
```

### Pattern 3: Data Layer Migration Completeness
```bash
# Verify digitalData.* mapped to ACDL/XDM
grep -r "digitalData\." --include="*.js" --include="*.html" | \
  grep -v "adobe.dataLayer" | grep -v "xdm" && echo "UNMAPPED digitalData found"
```

### Pattern 4: CTT Migration Set Validation
```bash
# Verify migration set structure before ingest
[ -d "04-migration-set/jcr_root/content" ] || echo "MISSING content root"
[ -d "04-migration-set/jcr_root/conf" ] || echo "MISSING conf root"
find 04-migration-set -name "*.xml" -exec xmllint --noout {} \; || echo "XML validation failed"
```

---

## Edge Cases

| Edge Case | Behavior | Handling |
|-----------|----------|----------|
| **CTT content published/unpublished** | Not preserved by CTT | Filter manually via `cq:lastModified` or workflow status before migration |
| **AEP Debugger auth required** | Non-public data needs auth | Keep Experience Cloud tab open; use Chrome extension with valid session |
| **Mixed Web SDK + AppMeasurement** | Not supported on same page | All-or-nothing migration per page; phase by template/component |
| **optionsProvider servlet** | Cannot auto-convert | Developer must implement Sling ResourceType servlet with JSON response |
| **BPA on Prod** | Not recommended | Run on Stage/Clone only; requires admin user |

---

## Anti-Patterns (Extended)

### 1. Skipping Pre-Flight Assessment
```
❌ Jumping straight to CTT without BPA/CAM/Pattern Detector
✅ Always run full assessment → gap inventory → ICE scoring
Rationale: Unidentified gaps cause failed migrations and rework
```

### 2. Ignoring Blast Radius on High-Impact Gaps
```
❌ Proceeding with Alto blast-radius gaps
✅ Human checkpoint required before Phase 2
Rationale: High-impact changes (auth, navigation, search) affect entire site
```

### 3. Deleting ExtJS Dialogs Before Backup
```
❌ rm dialog.xml before verifying _cq_dialog works
✅ Rename, verify, then archive old dialogs
Rationale: Rollback capability essential for complex dialog migrations
```

### 4. Assuming CTT Analyzes Content
```
❌ Expecting CTT to filter published vs unpublished
✅ Manual filter via workflow status or cq:lastModified
Rationale: CTT is a transfer tool, not an analysis tool
```

---

## Deep Reference Materials (in `references/reference.md`)

- ExtJS → Coral 3 field mapping table (50+ fields)
- Sling Model injector reference (`@ValueMapValue`, `@ChildResource`, `@ScriptVariable`, `@Self`)
- ACDL / XDM schema examples for common components
- Servlet skeleton for `optionsProvider` → `datasource` migration
- AppMeasurement → Web SDK migration decision tree
- Query optimization patterns (oak:index definitions)