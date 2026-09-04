#!/usr/bin/env node
/**
 * generate-opencode-config.js
 *
 * Generates opencode.json from:
 *   - opencode-base.json (agent definitions WITHOUT permission blocks)
 *   - permission-templates.json (7 shared permission patterns)
 *   - agent-overrides.json (agent-specific extra properties: hidden, custom perms)
 *
 * Usage:
 *   node scripts/lib/generate-opencode-config.js           # write opencode.json
 *   node scripts/lib/generate-opencode-config.js --validate # compare only, exit 1 on diff
 *
 * WHY: The original opencode.json had ~1,710 duplicated lines (73% of file)
 * because the same permission block was copied across 22 agents. This generator
 * maintains a single source of truth in permission-templates.json.
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const BASE_PATH = path.join(__dirname, 'opencode-base.json');
const TEMPLATES_PATH = path.join(__dirname, 'permission-templates.json');
const OVERRIDES_PATH = path.join(__dirname, 'agent-overrides.json');
const OUTPUT_PATH = path.join(ROOT, 'opencode.json');

const VALIDATE = process.argv.includes('--validate');

// --- Role keywords for auto-registration (checked when not in explicit map) ---
// Mirrors $RoleKeywords in scripts/lib/template-detection.ps1
const ROLE_KEYWORDS = {
  security:    'readonly',
  infra:       'readonly',
  docs:        'readonly',
  seo:         'readonly',
  frontend:    'readonly',
  performance: 'readonly',
  datascience: 'readonly',
  reviewer:    'reviewer',
  vMK:         'orchestrator',
};

// --- Detect template for an agent name ---
// Resolution order (must mirror Detect-Template in template-detection.ps1 exactly):
//   1. Explicit lookup in TEMPLATE_MAP (SSOT anchor)
//   2. Suffix auto-registration (-sub-auto → auto-sub, -semi → semi, -auto → auto, -sub → recurse)
//   3. Role keyword matching
//   4. Fail-closed — throw
function detectTemplate(agentName) {
  // 1. Explicit lookup — SSOT anchor, always wins
  if (TEMPLATE_MAP[agentName]) {
    return TEMPLATE_MAP[agentName];
  }

  // 2. Suffix auto-registration (longest suffix first)
  if (agentName.endsWith('-sub-auto')) return 'auto-sub';
  if (agentName.endsWith('-semi'))      return 'semi';
  if (agentName.endsWith('-auto'))     return 'auto';
  if (agentName.endsWith('-sub'))      return detectTemplate(agentName.slice(0, -4));

  // 3. Role keyword matching
  for (const [keyword, template] of Object.entries(ROLE_KEYWORDS)) {
    if (agentName.includes(keyword)) {
      return template;
    }
  }

  // 4. Fail-closed
  throw new Error(`No template mapping found for agent '${agentName}'. Add explicit entry to TEMPLATE_MAP or follow naming conventions.`);
}

// --- Agent-to-template mapping (SSOT anchor) ---
// ALL agents should be listed here. New agents following naming conventions are auto-detected.
const TEMPLATE_MAP = {
  // Orchestrator — full bash allow + extra language denials
  'gentleman-vMK': 'orchestrator',
  'gentle-orchestrator': 'sddorchestrator',

  // Read-only specialists — bash deny, no write/edit
  'gentleman-security': 'readonly',
  'gentleman-seo': 'readonly',
  'gentleman-infra': 'readonly',
  'gentleman-frontend': 'readonly',
  'gentleman-performance': 'readonly',
  'gentleman-datascience': 'readonly',
  'gentleman-docs': 'readonly',

   // Read/write agents — bash ask, full edit/write with deny rules
   'gentleman-deep': 'readwrite',
   'gentleman-code-review': 'readwrite',
   'gentleman-initializer': 'readwrite',
   'gentleman-reasoning': 'readwrite',
   'gentleman-quick': 'readwrite',
   'gentleman-codex': 'readwrite',
   'gentleman-implementer': 'readwrite',
   'gentleman-aem': 'readwrite',
   'sdd-apply': 'readwrite',
  'sdd-archive': 'readwrite',
  'sdd-design': 'readwrite',
  'sdd-explore': 'readwrite',
  'sdd-init': 'readwrite',
  'sdd-orchestrator': 'sddorchestrator',
  'sdd-propose': 'readwrite',
  'sdd-spec': 'readwrite',
  'sdd-tasks': 'readwrite',
  'sdd-verify': 'readwrite',

   // Subagent twins (mode: subagent, delegable via Task tool) — mirror primary templates
   'gentleman-deep-sub': 'readwrite',
   'gentleman-quick-sub': 'readwrite',
   'gentleman-implementer-sub': 'readwrite',
   'gentleman-codex-sub': 'readwrite',
   'gentleman-security-sub': 'readonly',
   'gentleman-aem-sub': 'readwrite',
   'gentleman-code-review-sub': 'readwrite',
   'gentleman-initializer-sub': 'readwrite',
   'gentleman-reasoning-sub': 'readwrite',

  // Read-only specialist twins — delegable via Task tool (previously ⚠️ fallback to general)
  'gentleman-seo-sub': 'readonly',
  'gentleman-infra-sub': 'readonly',
  'gentleman-frontend-sub': 'readonly',
  'gentleman-performance-sub': 'readonly',
  'gentleman-datascience-sub': 'readonly',
  'gentleman-docs-sub': 'readonly',

  // Mode variants — AUTO (all auto-approve except push + destructive + network)
  'gentleman-vMK-auto': 'auto',
  'gentleman-deep-auto': 'auto',
  'gentleman-quick-auto': 'auto',
  'gentleman-codex-auto': 'auto',
  'gentleman-implementer-auto': 'auto',
  'gentleman-aem-auto': 'auto',
  'gentleman-initializer-auto': 'auto',

  // Mode variants — AUTO subagent twins (zero-ask, delegable via Task tool in auto mode)
  'gentleman-deep-sub-auto': 'auto-sub',
  'gentleman-quick-sub-auto': 'auto-sub',
  'gentleman-codex-sub-auto': 'auto-sub',
  'gentleman-implementer-sub-auto': 'auto-sub',
  'gentleman-aem-sub-auto': 'auto-sub',
  'gentleman-code-review-sub-auto': 'auto-sub',
  'gentleman-reasoning-sub-auto': 'auto-sub',

  // Mode variants — SEMI RETIRED (ADR-033 implemented 2026-09-04):
  // explicit '-semi' entries removed; '-semi' suffix below + skip still
  // handle the 6 legacy definitions in opencode-base.json until base is
  // cleaned (JD follow-up). Do NOT re-add entries here.

  // Independent evaluator — bash ask, no edit/write
  'gentleman-reviewer': 'reviewer',
  'gentleman-reviewer-sub': 'reviewer',
};

// --- Permission key order (must match original file) ---
// Standard: bash→edit→read→write
// sdd-orchestrator: bash→delegate→delegation_list→delegation_read→edit→read→write→task
const STANDARD_PERM_ORDER = ['bash', 'edit', 'read', 'write'];
const SDD_ORCH_PERM_ORDER = ['bash', 'delegate', 'delegation_list', 'delegation_read', 'edit', 'read', 'write', 'task'];

// --- Load inputs ---
console.log('[1/5] Loading base config, templates, and overrides...');
const base = JSON.parse(fs.readFileSync(BASE_PATH, 'utf8'));
const templates = JSON.parse(fs.readFileSync(TEMPLATES_PATH, 'utf8'));

let overrides = {};
try {
  overrides = JSON.parse(fs.readFileSync(OVERRIDES_PATH, 'utf8'));
} catch (e) {
  console.log('  No agent-overrides.json found, using empty overrides');
}

// --- Deep clone and sort keys in permission objects ---
function sortPermKeys(perm, agentName) {
  // Use agent-specific key order if available, otherwise standard
  const keyOrder = (agentName === 'sdd-orchestrator' || agentName === 'gentle-orchestrator') ? SDD_ORCH_PERM_ORDER : STANDARD_PERM_ORDER;
  const sorted = {};
  for (const key of keyOrder) {
    if (perm[key] !== undefined) sorted[key] = perm[key];
  }
  // Add any extra keys not in the predefined order
  for (const key of Object.keys(perm)) {
    if (!keyOrder.includes(key)) sorted[key] = perm[key];
  }
  return sorted;
}

// --- Merge permissions ---
console.log('[2/5] Merging permission templates into agent definitions...');

const stats = { orchestrator: 0, readwrite: 0, readonly: 0, sddorchestrator: 0, reviewer: 0, auto: 0, 'auto-sub': 0, semi: 0, total: 0 };

const orderedAgents = {};
for (const [agentName, agentDef] of Object.entries(base.agent)) {
  const templateName = detectTemplate(agentName);

  // ADR-033 IMPLEMENTED 2026-09-04 (simplified to manual|auto): 'semi' skipped
  // at build so opencode.json carries 0 *-semi agents. Skip KEPT (not dead-code):
  // opencode-base.json still defines the 6 legacy -semi agents + permission-
  // templates.json still carries the 'semi' template; removing this skip would
  // reintroduce/mis-map them (vMK-semi → orchestrator via keyword). Remove this
  // skip only together with base + template cleanup (JD follow-up).
  if (templateName === 'semi') continue;

  const template = templates[templateName];

  if (!template) {
    console.error(`ERROR: Template "${templateName}" not found for agent "${agentName}"`);
    process.exit(1);
  }

  // Start with template permission (deep clone)
  const permission = JSON.parse(JSON.stringify(template));

  // Apply agent-specific overrides (hidden, custom perm keys, etc.)
  const agentOverrides = overrides[agentName] || {};
  if (agentOverrides.hidden !== undefined) {
    agentDef.hidden = agentOverrides.hidden;
  }
  if (agentOverrides.extraPermKeys) {
    // Guard against clobbering template permissions
    const templateKeys = Object.keys(template);
    const collisions = templateKeys.filter(k => k in agentOverrides.extraPermKeys);
    if (collisions.length > 0) {
      console.error(`ERROR: extraPermKeys for "${agentName}" collides with template keys: ${collisions.join(', ')}`);
      process.exit(1);
    }
    Object.assign(permission, agentOverrides.extraPermKeys);
  }

  // Sort permission keys to match original ordering
  const sortedPerm = sortPermKeys(permission, agentName);

  // Rebuild agent with correct key order
  // sdd-orchestrator: description, model, mode, permission, prompt (permission BEFORE prompt)
  // SDD agents: description, hidden, mode, prompt, permission
  // Others: description, [model], mode, prompt, permission, [tools]
  const rebuilt = {};
  let keyOrder;
  if (agentName === 'sdd-orchestrator') {
    keyOrder = ['description', 'model', 'mode', 'permission', 'prompt'];
  } else if (agentName === 'gentle-orchestrator') {
    keyOrder = ['description', 'model', 'mode', 'permission', 'prompt', 'tools'];
  } else {
    keyOrder = ['description', 'model', 'hidden', 'mode', 'prompt', 'permission', 'tools'];
  }

  for (const key of keyOrder) {
    if (key === 'permission') {
      rebuilt.permission = sortedPerm;
    } else if (key === 'hidden' && agentDef.hidden !== undefined) {
      rebuilt.hidden = agentDef.hidden;
    } else if (agentDef[key] !== undefined) {
      rebuilt[key] = agentDef[key];
    }
  }

  orderedAgents[agentName] = rebuilt;
  stats[templateName]++;
  stats.total++;
}

// --- Enfoque A (experimento/token-reduction-config-2026-08-29): delta-permissions ---
// Reference: the SSoT top-level `permission` (opencode-base.json) carries the
// curated common rules (default for all agents). Emitting full copies per agent
// duplicates those bytes 49x. Strip from each agent every sub-key/array whose
// value is byte-identical to the SSoT root default; the remaining delta is
// behavior-neutral under per-key override merge (root default + agent delta
// reconstructs the exact same effective permission — re-verified against the
// pre-change effective permissions). Non-matching values stay as agent deltas.
const permNames = Object.keys(orderedAgents);
const rootPerm = base.permission || {};
if (permNames.length > 0 && Object.keys(rootPerm).length > 0) {
  let stripped = 0;
  for (const n of permNames) {
    const perm = orderedAgents[n].permission;
    for (const [k, sub] of Object.entries(rootPerm)) {
      if (!perm[k]) continue;
      if (Array.isArray(sub)) {
        if (Array.isArray(perm[k]) && JSON.stringify(perm[k]) === JSON.stringify(sub)) { delete perm[k]; stripped++; }
      } else if (sub && typeof sub === 'object') {
        for (const sk of Object.keys(sub)) {
          if (perm[k][sk] !== undefined && JSON.stringify(perm[k][sk]) === JSON.stringify(sub[sk])) { delete perm[k][sk]; stripped++; }
        }
        if (Object.keys(perm[k]).length === 0) delete perm[k];
      }
    }
  }
  if (stripped > 0) {
    console.log(`  Delta-permissions: stripped ${stripped} per-agent rule(s) matching SSoT root permission (default), agents keep deltas only.`);
  }
}

base.agent = orderedAgents;

console.log(`  Orchestrator:     ${stats.orchestrator} agent(s)`);
console.log(`  Read/Write:       ${stats.readwrite} agent(s)`);
console.log(`  Read-Only:        ${stats.readonly} agent(s)`);
console.log(`  SDD Orchestrator: ${stats.sddorchestrator} agent(s)`);
console.log(`  Reviewer:         ${stats.reviewer} agent(s)`);
  console.log(`  AUTO variants:    ${stats.auto} agent(s)`);
  console.log(`  AUTO-SUB variants: ${stats['auto-sub']} agent(s)`);
  console.log(`  SEMI variants:    ${stats.semi} agent(s)`);

// --- Serialize ---
console.log('[3/5] Serializing output...');
const output = JSON.stringify(base);

// --- Validate or write ---
if (VALIDATE) {
  console.log('[4/5] Validating against existing opencode.json...');

  // SEMANTIC compare (additive, preserving): opencode.json is pretty-printed and
  // carries profile-injected keys (small_model, watcher, snapshot, _resource_profile,
  // agent.default) that the SSoT does not own — a byte/string compare would always
  // report MISMATCH on formatting alone. Parse both sides as JSON and compare the
  // fields that constitute the SSoT contract:
  //   - compaction.reserved / compaction.keep.tokens
  //   - snapshot (only when the SSoT defines it — currently profile-injected)
  //   - non-default agent count
  //   - every top-level key the SSoT defines must exist in opencode.json
  let existing, generated;
  try {
    let raw = fs.readFileSync(OUTPUT_PATH, 'utf8');
    if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
    existing = JSON.parse(raw);
    generated = JSON.parse(output);
  } catch (e) {
    console.log('  MISMATCH — opencode.json is not valid JSON: ' + e.message);
    process.exit(1);
  }

  const issues = [];
  const diffField = (label, a, b) => {
    const sa = JSON.stringify(a), sb = JSON.stringify(b);
    if (sa !== sb) issues.push(`${label}: ${sa} vs ${sb}`);
  };

  diffField('compaction.reserved',
    generated.compaction && generated.compaction.reserved,
    existing.compaction && existing.compaction.reserved);
  diffField('compaction.keep.tokens',
    generated.compaction && generated.compaction.keep && generated.compaction.keep.tokens,
    existing.compaction && existing.compaction.keep && existing.compaction.keep.tokens);
  // snapshot: compared only when the SSoT defines it (absent => profile-injected, allowed)
  if (generated.snapshot !== undefined) diffField('snapshot', generated.snapshot, existing.snapshot);

  // agent count (non-default: 'default' is profile-injected)
  const genAgents = Object.keys(generated.agent || {}).filter((n) => n !== 'default').length;
  const exAgents = Object.keys(existing.agent || {}).filter((n) => n !== 'default').length;
  diffField('agent count (non-default)', genAgents, exAgents);

  // every top-level key the SSoT defines must exist in opencode.json
  for (const k of Object.keys(generated)) {
    if (!(k in existing)) issues.push(`top-level key missing in opencode.json: ${k}`);
  }

  if (issues.length > 0) {
    console.log('  MISMATCH — semantic drift vs SSoT:');
    for (const i of issues) console.log('    ' + i);
    process.exit(1);
  }
  console.log('  VALID — generated output matches existing opencode.json (semantic compare)');
  process.exit(0);
} else {
  console.log(`[4/5] Writing to ${OUTPUT_PATH}...`);

  // Write UTF-8 without BOM (BOM breaks PowerShell ConvertFrom-Json and Node require)
  fs.writeFileSync(OUTPUT_PATH, output, 'utf8');

  console.log('[5/5] Verifying output...');
  const written = fs.readFileSync(OUTPUT_PATH, 'utf8').replace(/^\uFEFF/, '');
  if (written === output) {
    const lineCount = output.split('\n').length;
    console.log(`  Written: ${lineCount} lines — verified OK`);
  } else {
    console.error('  ERROR: Written file does not match generated output!');
    process.exit(1);
  }

  console.log('  Done!');
}
