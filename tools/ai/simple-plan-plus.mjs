#!/usr/bin/env node
/**
 * Read BuddyPress scan JSON and output:
 * - docs/PLAN.yaml
 * - docs/BUDDYPRESS-TEST-PLAN.md
 * - PHPUnit Integration stubs (REST, xProfile)
 * - Playwright E2E stubs (member nav tabs + BP mapped pages)
 *
 * Usage:
 *   node tools/ai/simple-plan-plus.mjs --in wp-content/uploads/wbcom-scan --out wp-content/uploads/wbcom-plan --slug buddynext
 */
import fs from 'node:fs';
import path from 'node:path';

const args = process.argv;
const inDir  = args.includes('--in')  ? args[args.indexOf('--in')  + 1] : 'wp-content/uploads/wbcom-scan';
const outDir = args.includes('--out') ? args[args.indexOf('--out') + 1] : 'wp-content/uploads/wbcom-plan';
const slug   = args.includes('--slug')? args[args.indexOf('--slug') + 1] : 'buddynext';

function readJSON(name, def=[]) {
  const p = path.join(inDir, name);
  if (!fs.existsSync(p)) return def;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return def; }
}
function ensure(p){ fs.mkdirSync(p, { recursive: true }); }
function write(file, content){ ensure(path.dirname(file)); fs.writeFileSync(file, content); }

const scan = {
  components: readJSON('components.json', []),
  pages:      readJSON('pages.json', []),
  nav:        readJSON('nav.json', []),
  actions:    readJSON('activity-types.json', []),
  xprofile:   readJSON('xprofile.json', []),
  rest:       readJSON('rest.json', []),
  emails:     readJSON('emails.json', []),
  settings:   (() => {
    const p = path.join(inDir, 'settings.json');
    if (!fs.existsSync(p)) return {};
    try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return {}; }
  })()
};

/* ===============================
   1) PLAN.yaml (prioritized)
   =============================== */
const plan = {
  plugin: slug,
  generated_at: new Date().toISOString(),
  priorities: {
    high: [],
    medium: [],
    low: []
  },
  suites: {
    unit: [],
    integration: [],
    e2e: []
  }
};

// Heuristics for priorities
if (scan.rest?.length) plan.priorities.high.push('REST endpoints');
if (scan.nav?.length)  plan.priorities.high.push('Member nav tabs (visual + functional)');
if (scan.pages?.length) plan.priorities.medium.push('BP page mapping');
if (scan.xprofile?.length) plan.priorities.medium.push('xProfile fields');
if (scan.actions?.length) plan.priorities.low.push('Activity action registrations');
if (scan.emails?.length) plan.priorities.low.push('BP Emails exist/render');

plan.suites.integration.push({ name: 'RestRoutes', items: scan.rest.map(r => r.route) });
plan.suites.integration.push({ name: 'XProfileFields', items: (scan.xprofile||[]).flatMap(g => (g.fields||[]).map(f => `${g.group_name}:${f.name}`)) });
plan.suites.e2e.push({ name: 'MemberNav', items: (scan.nav||[]).map(n => n.slug) });
plan.suites.e2e.push({ name: 'BPPages', items: (scan.pages||[]).map(p => p.slug) });

/* ===============================
   2) Markdown plan
   =============================== */
const md = [];
md.push(`# BuddyPress Test Plan — ${slug}`);
md.push('');
md.push(`Generated: ${plan.generated_at}`);
md.push('');
md.push('## Priorities');
md.push('- High: ' + (plan.priorities.high.join(', ') || '_None_'));
md.push('- Medium: ' + (plan.priorities.medium.join(', ') || '_None_'));
md.push('- Low: ' + (plan.priorities.low.join(', ') || '_None_'));
md.push('');
md.push('## Inventory');
md.push('### Components');
md.push(scan.components?.length ? scan.components.map(c=>`- \`${c.key}\``).join('\n') : '_None_');
md.push('');
md.push('### Pages (BP mapping)');
md.push(scan.pages?.length ? scan.pages.map(p=>`- ${p.component}: ${p.title} (${p.slug})`).join('\n') : '_None_');
md.push('');
md.push('### Member Nav (top-level)');
md.push(scan.nav?.length ? scan.nav.map(n=>`- ${n.name} [${n.slug}]`).join('\n') : '_None_');
md.push('');
md.push('### REST routes');
md.push(scan.rest?.length ? scan.rest.map(r=>`- ${r.route} (${Array.isArray(r.methods)? r.methods.join('|'): r.methods})`).join('\n') : '_None_');
md.push('');
md.push('### xProfile');
md.push(scan.xprofile?.length ? scan.xprofile.map(g=>`- ${g.group_name} → ${(g.fields||[]).length} fields`).join('\n') : '_None_');
md.push('');
md.push('### Activity Actions');
md.push(scan.actions?.length ? scan.actions.map(a=>`- ${a.component} → ${a.key}`).join('\n') : '_None_');
md.push('');
md.push('### Emails (bp-email)');
md.push(scan.emails?.length ? scan.emails.map(e=>`- ${e.slug} (#${e.id})`).join('\n') : '_None_');
md.push('');
md.push('## Checklists');
md.push('### Integration');
md.push(...(scan.rest||[]).map(r=>`- [ ] REST: "${r.route}" is registered; methods ${Array.isArray(r.methods)? r.methods.join('|'): r.methods}`));
for (const g of (scan.xprofile||[])) {
  for (const f of (g.fields||[])) {
    md.push(`- [ ] xProfile: "${f.name}" (${f.type}) exists in group "${g.group_name}"`);
  }
}
md.push('');
md.push('### E2E (Playwright)');
for (const n of (scan.nav||[])) {
  md.push(`- [ ] Nav tab "${n.name}" loads, has key elements, screenshot: \`nav-${n.slug}.png\``);
}
for (const p of (scan.pages||[])) {
  md.push(`- [ ] BP page "${p.slug}" loads and renders, screenshot: \`bp-${p.slug}.png\``);
}
md.push('');
md.push('### Risks & Flakiness');
md.push('- Visual diffs depend on fonts/antialiasing; keep viewport fixed & trust HTTPS cert.');
md.push('- Dynamic timestamps/usernames may cause diffs; hide them or assert presence loosely.');
md.push('- Routes protected by permissions may need auth in tests.');
md.push('');
// Write docs
const docsDir = path.join(outDir, 'docs');
write(path.join(docsDir, 'PLAN.yaml'), yamlString(plan));
write(path.join(docsDir, 'BUDDYPRESS-TEST-PLAN.md'), md.join('\n') + '\n');

/* ===============================
   3) Generate PHPUnit stubs
   =============================== */
// Integration: REST
if (scan.rest?.length) {
  const code = `<?php
declare(strict_types=1);

use PHPUnit\\Framework\\TestCase;

final class RestRoutesTest extends TestCase {
    public function test_routes_registered(): void {
        // This is a smoke test template. For full WP integration, load wp-phpunit and use WP_UnitTestCase.
        $routes = ${phpExport(scan.rest)};
        $this->assertNotEmpty($routes, 'No REST routes found in scan.');
        // TODO: In a WP_UnitTestCase, you would call rest_get_server()->get_routes() and assert keys exist.
    }
}
`;
  write(path.join(process.cwd(), 'tests/phpunit/Integration/RestRoutesTest.php'), code);
}

// Integration: xProfile fields
if (scan.xprofile?.length) {
  const code = `<?php
declare(strict_types=1);

use PHPUnit\\Framework\\TestCase;

final class XProfileFieldsTest extends TestCase {
    public function test_fields_scanned(): void {
        $groups = ${phpExport(scan.xprofile)};
        $count = 0;
        foreach ($groups as $g) { $count += isset($g['fields']) ? count($g['fields']) : 0; }
        $this->assertGreaterThanOrEqual(0, $count);
        // TODO: In WP_UnitTestCase, assert bp_xprofile_get_groups() matches types/names.
    }
}
`;
  write(path.join(process.cwd(), 'tests/phpunit/Integration/XProfileFieldsTest.php'), code);
}

/* ===============================
   4) Generate Playwright stubs
   =============================== */
const e2eDir = path.join(process.cwd(), 'tools/e2e/tests');

// Member nav tabs
for (const n of (scan.nav||[])) {
  const fname = `nav.${safeSlug(n.slug||n.name||'tab')}.spec.ts`;
  const code = `import { test, expect } from '@playwright/test';
const USER = process.env.E2E_USER || 'admin';
const PASS = process.env.E2E_PASS || 'password';

test('${n.name} tab loads & visual', async ({ page }) => {
  await page.goto('/wp-login.php');
  await page.fill('#user_login', USER);
  await page.fill('#user_pass', PASS);
  await page.click('#wp-submit');
  await page.waitForLoadState('networkidle');

  // Go to your own profile (adjust if you seed more members)
  await page.goto('/members/admin/');
  await page.waitForLoadState('networkidle');

  // Open the tab
  await page.getByRole('link', { name: '${escapeQuote(n.name)}' }).click();
  await page.waitForLoadState('networkidle');

  await expect(page).toHaveScreenshot('nav-${safeSlug(n.slug||n.name)}.png');
});
`;
  write(path.join(e2eDir, fname), code);
}

// BP pages (directories)
for (const p of (scan.pages||[])) {
  if (!p.slug) continue;
  const fname = `pages.${safeSlug(p.component||p.slug)}.spec.ts`;
  const url = p.url ? new URL(p.url).pathname : `/${p.slug}/`;
  const code = `import { test, expect } from '@playwright/test';
const USER = process.env.E2E_USER || 'admin';
const PASS = process.env.E2E_PASS || 'password';

test('BP page ${p.component} (${p.slug}) loads & visual', async ({ page }) => {
  await page.goto('/wp-login.php');
  await page.fill('#user_login', USER);
  await page.fill('#user_pass', PASS);
  await page.click('#wp-submit');
  await page.waitForLoadState('networkidle');

  await page.goto('${url}');
  await page.waitForLoadState('networkidle');

  await expect(page).toHaveScreenshot('bp-${safeSlug(p.slug)}.png');
});
`;
  write(path.join(e2eDir, fname), code);
}

console.log('✅ simple-plan-plus wrote:');
console.log(' -', path.join(docsDir, 'PLAN.yaml'));
console.log(' -', path.join(docsDir, 'BUDDYPRESS-TEST-PLAN.md'));
console.log(' - tests/phpunit/Integration/* and tools/e2e/tests/*.spec.ts');

function yamlString(obj){
  // tiny YAML emitter good enough for our structure
  const lines = [];
  function emit(key, val, indent=0){
    const pad = '  '.repeat(indent);
    if (Array.isArray(val)) {
      lines.push(`${pad}${key}:`);
      for (const v of val) {
        if (typeof v === 'object' && v !== null) {
          lines.push(`${pad}-`);
          for (const [k2,v2] of Object.entries(v)) emit(k2, v2, indent+2);
        } else {
          lines.push(`${pad}- ${String(v)}`);
        }
      }
    } else if (typeof val === 'object' && val !== null) {
      lines.push(`${pad}${key}:`);
      for (const [k,v] of Object.entries(val)) emit(k, v, indent+1);
    } else {
      lines.push(`${pad}${key}: ${String(val)}`);
    }
  }
  for (const [k,v] of Object.entries(obj)) emit(k, v, 0);
  return lines.join('\n') + '\n';
}
function safeSlug(s){ return String(s).toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,''); }
function escapeQuote(s){ return String(s).replace(/'/g, "\\'"); }
function phpExport(jsVal){
  // Minimal PHP array exporter
  if (Array.isArray(jsVal)) {
    return 'array(' + jsVal.map(v=>phpExport(v)).join(', ') + ')';
  }
  if (jsVal && typeof jsVal === 'object') {
    const pairs = Object.entries(jsVal).map(([k,v])=> `'${k.replace(/'/g,"\\'")}' => ${phpExport(v)}`);
    return 'array(' + pairs.join(', ') + ')';
  }
  if (typeof jsVal === 'string') return `'${jsVal.replace(/'/g,"\\'")}'`;
  if (typeof jsVal === 'number') return String(jsVal);
  if (typeof jsVal === 'boolean') return jsVal ? 'true' : 'false';
  return 'NULL';
}
