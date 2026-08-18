# AEM Migration — Deep Reference

> Externalized per ADR-007. Detailed mappings, JSON schemas, servlet skeletons, code examples. Consulted by `aem-migration` skill.

## Table of Contents
1. [ExtJS Dialog → Coral 3 Mapping](#1-extjs-dialog--coral-3-dialog-mapping)
2. [digitalData → ACDL / Web SDK Mapping](#2-digitaldata--acdl--web-sdk-mapping)
3. [Migration Strategy Decision Tree](#3-migration-strategy-decision-tree)
4. [Slow Query Fix Recipe](#4-slow-query-fix-recipe)
5. [Content Transfer Tool — Disk Space & Mode](#5-content-transfer-tool--disk-space--mode)
6. [Cloud Manager Pipeline Config](#6-cloud-manager-pipeline-config)
7. [RDE Commands](#7-rde-commands)

## 1. ExtJS Dialog → Coral 3 Dialog Mapping

### Widget property mapping

| ExtJS (dialog/...)          | Coral 3 (_cq_dialog/...)                                  | Notes |
|----------------------------|-----------------------------------------------------------|-------|
| `xtype="dialog"`           | `jcr:primaryType="nt:unstructured"` + `sling:resourceType="foundation/components/page"` (root) | Root node stays `nt:unstructured` |
| `xtype="tabpanel"`         | `granite/ui/components/coral/foundation/tabs`             | Tabbed structure |
| `xtype="textfield"`        | `granite/ui/components/coral/foundation/form/text`        | |
| `xtype="textarea"`         | `granite/ui/components/coral/foundation/form/textarea`    | |
| `xtype="numberfield"`      | `granite/ui/components/coral/foundation/form/number`      | |
| `xtype="hidden"`           | `granite/ui/components/coral/foundation/form/hidden`      | |
| `xtype="pathfield"`        | `granite/ui/components/coral/foundation/form/path`      | |
| `xtype="multifield"`       | `granite/ui/components/coral/foundation/form/multifield`  | See §1.2 |
| `xtype="selection"`        | `granite/ui/components/coral/foundation/form/select`     | See §1.3 |
| `xtype="checkbox"`         | `granite/ui/components/coral/foundation/form/checkbox`   | |
| `xtype="datepicker"`       | `granite/ui/components/coral/foundation/form/datepicker`  | |

### 1.2 Multifield — single vs composite

**Single sub-field (simple):**
```xml
<myMultifield
    jcr:primaryType="nt:unstructured"
    sling:resourceType="granite/ui/components/coral/foundation/form/multifield"
    fieldLabel="Tags"
    name="./tags"/>
```

**Composite (multiple sub-fields — `composite="{Boolean}true"` + `field` container):**
```xml
<myMultifield
    jcr:primaryType="nt:unstructured"
    sling:resourceType="granite/ui/components/coral/foundation/form/multifield"
    composite="{Boolean}true"
    fieldLabel="Links">
    <field
        jcr:primaryType="nt:unstructured"
        sling:resourceType="granite/ui/components/coral/foundation/container">
        <items jcr:primaryType="nt:unstructured">
            <title
                jcr:primaryType="nt:unstructured"
                sling:resourceType="granite/ui/components/coral/foundation/form/text"
                name="./title"/>
            <url
                jcr:primaryType="nt:unstructured"
                sling:resourceType="granite/ui/components/coral/foundation/form/path"
                name="./url"/>
        </items>
    </field>
</myMultifield>
```

### 1.3 optionsProvider → datasource + Sling servlet

**Step 1 — dialog shell:**
```xml
<select
    jcr:primaryType="nt:unstructured"
    sling:resourceType="granite/ui/components/coral/foundation/form/select"
    name="./template"
    forced="true">
    <datasource
        jcr:primaryType="nt:unstructured"
        sling:resourceType="NEEDS-DEVELOPER-REVIEW"/>
</select>
```

**Step 2 — Sling servlet (registered to a resourceType you control):**
```java
@Component(
    service = Servlet.class,
    property = {
        "sling.servlet.resourceTypes=my-project/components/options/template-options",
        "sling.servlet.methods=GET",
        "sling.servlet.extensions=json"
    }
)
public class TemplateOptionsServlet extends SlingSafeMethodsServlet {
    @Override
    protected void doGet(SlingSafeMethodsServlet req, HttpServletResponse resp)
            throws ServletException, IOException {
        JSONArray items = new JSONArray();
        // e.g. read from a service, config, or repository
        items.put(new JSONObject().put("value", "hero").put("text", "Hero Banner"));
        items.put(new JSONObject().put("value", "content").put("text", "Content Page"));
        resp.setContentType("application/json");
        resp.getWriter().write(items.toString());
    }
}
```

### 1.4 Validation migration

| ExtJS prop        | Coral 3 equivalent                          | Implementation               |
|------------------|--------------------------------------------|------------------------------|
| `vtype="email"`  | `validation="email"` + clientlib           | `foundation-validation`      |
| `regex="..."`   | `validation="<custom>"` + clientlib        | register validator           |
| `allowBlank=false` | `required="{Boolean}true"`                  | native                       |
| `regexText="..."` | custom error message in clientlib          | `validator.add()` message     |

**Clientlib skeleton (validations.js):**
```js
// /apps/my-project/clientlibs/clientlib-validation/js/validations.js
(function (g, $) {
  'use strict';
  $(g.document).on('foundation-contentloaded', function () {
    $.validator.add('email-or-empty', function (value) {
      return !value || value.includes('@');
    });
    $.validator.messages['email-or-empty'] = 'Invalid email format';
  });
})(Granite.author, jQuery);
```
Register in `jcr:content/clientlibs`: category = `my-project.validation`, dependency `jquery`, embed `granite.jquery`.

## 2. digitalData → ACDL / Web SDK Mapping

### 2.1 W3C digitalData object (source)
```js
window.digitalData = {
  page: {
    pageInfo: {
      pageName: "homepage",
      destinationURL: "https://www.ford.com/home",
      pageType: "HomePage",
      language: "en-US",
      effectiveDate: "2024-01-15"
    },
    attributes: [
      { category: "vehicle", name: "model", value: "mustang" }
    ]
  },
  product: [{
    id: "F-150",
    name: "Ford F-150",
    productInfo: {
      productCategory: "trucks",
      productImageUrl: "https://ford.com/images/f150.jpg"
    }
  }]
};
```

### 2.2 Adobe Client Data Layer (ACDL) — target
```js
// Rendered server-side / injected by AEM clientlibs
adobe.clientDataLayer = adobe.clientDataLayer || [];
adobe.clientDataLayer.push({
  event: 'cmp:show',
  eventInfo: {
    comp: {
      path: '/content/ford/home/jcr:content/root/hero',
      resourceType: 'ford/components/hero'
    },
    page: {
      path: '/content/ford/home/jcr:content',
      title: 'Ford Home'
    }
  }
});
```

### 2.3 Web SDK (XDM) event mapping (datastream)
```js
// Alloy / Web SDK
alloy("sendEvent", {
  xdm: {
    eventType: "web.webpagedetails.pageViews",
    web: {
      webPageDetails: {
        name: "homepage",
        pageViews: { value: 1 }
      },
      webPage: {
        name: "Ford Home",
        pageViews: { value: 1 }
      }
    }
  },
  data: {
    // custom non-XDM data mapped via Data Stream mapping
    vehicleModel: "mustang"
  }
});
```

### 2.4 AEP Tags — Data Element mapping
In Tags UI → Data Elements:
- Name: `pageName` → Type: `JavaScript Variable` → Path: `digitalData.page.pageInfo.pageName`
- Or mapped to ACDL: Name: `pageName` → Type: `Adobe Client Data Layer` → Path: `page.pageInfo.pageName`

Then in **Rules** → Adobe Analytics extension → `pagename` field = `%pageName%`.

## 3. Migration Strategy Decision Tree

```
Source: AEM 6.x / AMS
         │
         ▼
┌─────────────────┐
│ BPA + Pattern   │  → Ice-scored gap list + blast radius
│ Detector run    │  → Alto? → human checkpoint before proceeding
└────┬────────────┘
     ▼
┌─────────────────┐  Yes ┌──────────────────┐
│ Deprecated/     ├─────►│ Refactor code    │ (component rewrite)
│ Blocking feats? │      └────────┬─────────┘
└────┬──────┬────┘               ▼
     │ No   │            ┌─────────────────┐
     ▼      ▼            │ Deploy to RDE   │
┌──────────────────┐    └────────┬────────┘
│ Content Transfer │             ▼
│ (CTT v3.0)       │    ┌─────────────────┐
│ wipe mode        │    │ Component       │
└────────┬─────────┘    │ migration       │
         ▼              │ (ExtJS→Coral3,  │
┌─────────────────┐    │ Sling Models)   │
│ Verify content  │    └────────┬────────┘
│ renders         │             ▼
└────────┬────────┘    ┌─────────────────┐
         ▼              │ Tags/DL migrate │
┌─────────────────┐    │ (Launch→AEP Tags│
│ Code pipeline   │    │  AppMeasurement │
│ (Cloud Manager) │    │  →Web SDK)      │
└────────┬────────┘    └────────┬────────┘
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│ E2E smoke +     │    │ Debugger verify │
│ perf test       │    │ (AEP Debugger)  │
└─────────────────┘    └─────────────────┘
```

## 4. Slow Query Fix Recipe

```
1. Identify slow query in error.log → “The query read more than x nodes”
2. Go to /libs/granite/operations/content/maintenance → Query Performance
3. Run EXPLAIN on query → look for “no index” / “traversal”
4. Fix:
   a. Add nodetype restriction: property = jcr:primaryType, value = cq:Page
   b. Add path restriction: path=/content/my-site/us (tightest possible)
   c. Use jcr:contains over LIKE for fulltext
   d. Index: ensure target index has evaluatePathRestrictions=true
5. Tune: -Doak.queryLimitInMemory=500000, -Doak.queryLimitReads=100000
6. Re-run EXPLAIN → should resolve to an index (cqPageLucene etc.)
```

## 5. Content Transfer Tool — Disk Space & Mode

```
# Disk space requirement (source):
required_gb = datastore_size_gb + (nodestore_size_gb × 1.5)
# e.g. datastore=64 (CTT uses 64GB min), nodestore=20 → 64 + 30 = 94 GB free in crx-quickstart/

# Ingestion modes:
Wipe mode:  delete target repo → apply migration set  (FASTER, for full migration)
Merge mode: apply migration set on top of existing    (SLOWER, for top-ups only)

# Migration set lifecycle:
Extract → (store) → Ingest (wipe) → Verify → Top-up Extract (incremental) → Ingest (merge)
```

## 6. Cloud Manager Pipeline Config (pipeline.yml)

```yaml
# .gitlab/pipeline.yml equivalent / Cloud Manager pipeline
stages:
  - build
  - test
  - deploy

build:
  script:
    - mvn clean package -PautoBuild -DskipTests

test:
  script:
    - mvn test
    - python scripts/run-e2e.py --env staging

deploy:
  script:
    - mvn deploy -PautoBuild
  # Cloud Manager handles CI/CD; code pushed to remote AEM CS via git
```

## 7. RDE (Remote Developer Environment) Commands

```bash
# Install RDE plugin
aio plugins:install @adobe/aio-cli-plugin-cloud-service
aio cloud-service:rde:init   # initialize RDE from a CS environment

# Common operations
aio cloud-service:rde:install --file path/to/bundle.jar
aio cloud-service:rde:install --file path/to/package.zip
aio cloud-service:rde:install --file path/to/config.json
aio cloud-service:rde:logs --tail -f
aio cloud-service:rde:logs --follow --grep "ERROR"
```

---

*Source synthesis: Adobe Experience League docs (2025-2026), Apache Sling, VML/Ford case study, GitHub adobe/skills migration references.*
