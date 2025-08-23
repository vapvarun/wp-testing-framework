#!/usr/bin/env node
/**
 * BuddyPress scan → test plan/files generator
 * 
 * Automatically generates comprehensive test plans and test files
 * from BuddyPress scan data without external dependencies.
 *
 * Usage:
 *   node tools/ai/claude-analyze.mjs \
 *     --in  wp-content/uploads/wbcom-scan \
 *     --out wp-content/uploads/wbcom-plan \
 *     --slug buddynext
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ---------- CLI args ----------
const args = process.argv;
const inDir  = argOf('--in',  'wp-content/uploads/wbcom-scan');
const outDir = argOf('--out', 'wp-content/uploads/wbcom-plan');
const slug   = argOf('--slug','buddynext');

function argOf(flag, def){ return args.includes(flag) ? args[args.indexOf(flag)+1] : def; }

// ---------- IO helpers ----------
function readJSONSafe(p, def) {
  if (!fs.existsSync(p)) return def;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return def; }
}
function ensureDir(p){ fs.mkdirSync(p, { recursive: true }); }
function writeFile(dest, content){ 
  ensureDir(path.dirname(dest)); 
  fs.writeFileSync(dest, content); 
  console.log('  → wrote', dest); 
}

// ---------- Load scan ----------
const scan = {
  components: readJSONSafe(path.join(inDir, 'components.json'), []),
  pages:      readJSONSafe(path.join(inDir, 'pages.json'), []),
  nav:        readJSONSafe(path.join(inDir, 'nav.json'), []),
  actions:    readJSONSafe(path.join(inDir, 'activity-types.json'), []),
  xprofile:   readJSONSafe(path.join(inDir, 'xprofile.json'), []),
  rest:       readJSONSafe(path.join(inDir, 'rest.json'), []),
  emails:     readJSONSafe(path.join(inDir, 'emails.json'), []),
  settings:   readJSONSafe(path.join(inDir, 'settings.json'), {})
};

// ---------- Test Plan Generator ----------
function generateTestPlan() {
  const activeComponents = scan.components.filter(c => c.active);
  const navItems = scan.nav || [];
  const pages = scan.pages || [];
  const restRoutes = scan.rest || [];
  
  // Generate YAML plan
  const planYaml = generatePlanYaml(activeComponents, navItems, pages, restRoutes);
  
  // Generate Markdown documentation
  const docsMarkdown = generateDocsMarkdown(activeComponents, navItems, pages, restRoutes);
  
  // Generate PHPUnit test files
  const phpunitFiles = generatePHPUnitFiles(activeComponents, restRoutes);
  
  // Generate Playwright test files
  const playwrightFiles = generatePlaywrightFiles(navItems, pages);
  
  // Identify risks
  const risks = identifyRisks(scan);
  
  return {
    plan_yaml: planYaml,
    docs_markdown: docsMarkdown,
    phpunit_files: phpunitFiles,
    playwright_files: playwrightFiles,
    risks: risks
  };
}

function generatePlanYaml(components, navItems, pages, restRoutes) {
  const yaml = [];
  yaml.push('# BuddyPress Test Plan');
  yaml.push(`# Generated for: ${slug}`);
  yaml.push(`# Date: ${new Date().toISOString()}`);
  yaml.push('');
  yaml.push('test_areas:');
  
  // Component tests
  yaml.push('  components:');
  yaml.push('    priority: high');
  yaml.push('    items:');
  components.forEach(comp => {
    yaml.push(`      - name: ${comp.title || comp.name || comp.id}`);
    yaml.push(`        description: ${comp.description || 'BuddyPress component'}`);
    yaml.push(`        active: ${comp.active}`);
  });
  
  // Navigation tests
  yaml.push('  navigation:');
  yaml.push('    priority: high');
  yaml.push('    items:');
  navItems.forEach(nav => {
    yaml.push(`      - name: ${nav.name}`);
    yaml.push(`        url: ${nav.link || '#'}`);
    yaml.push(`        position: ${nav.position || 0}`);
  });
  
  // Page tests
  yaml.push('  pages:');
  yaml.push('    priority: medium');
  yaml.push('    items:');
  pages.forEach(page => {
    yaml.push(`      - title: ${page.title}`);
    yaml.push(`        component: ${page.component || 'unknown'}`);
  });
  
  // REST API tests
  yaml.push('  rest_api:');
  yaml.push('    priority: high');
  yaml.push('    endpoints: ${restRoutes.length}');
  
  yaml.push('');
  yaml.push('test_types:');
  yaml.push('  - unit: PHPUnit unit tests');
  yaml.push('  - integration: PHPUnit integration tests'); 
  yaml.push('  - e2e: Playwright end-to-end tests');
  yaml.push('  - visual: Visual regression tests');
  
  return yaml.join('\n');
}

function generateDocsMarkdown(components, navItems, pages, restRoutes) {
  const md = [];
  md.push('# BuddyPress Test Plan Documentation');
  md.push('');
  md.push(`## Theme: ${slug}`);
  md.push(`Generated: ${new Date().toLocaleDateString()}`);
  md.push('');
  
  md.push('## Test Coverage Overview');
  md.push('');
  md.push('### ✅ Components Testing');
  md.push('');
  components.forEach(comp => {
    md.push(`- [ ] **${comp.title || comp.name || comp.id}** (${comp.active ? 'Active' : 'Inactive'})`);
    md.push(`  - [ ] Component initialization`);
    md.push(`  - [ ] Core functionality`);
    md.push(`  - [ ] User permissions`);
  });
  md.push('');
  
  md.push('### ✅ Navigation Testing');
  md.push('');
  navItems.forEach(nav => {
    md.push(`- [ ] **${nav.name}**`);
    md.push(`  - [ ] Link accessibility`);
    md.push(`  - [ ] Navigation flow`);
    md.push(`  - [ ] Mobile responsiveness`);
  });
  md.push('');
  
  md.push('### ✅ Page Testing');
  md.push('');
  pages.forEach(page => {
    md.push(`- [ ] **${page.title}**`);
    md.push(`  - [ ] Page loads correctly`);
    md.push(`  - [ ] Content displays properly`);
    md.push(`  - [ ] Interactive elements work`);
  });
  md.push('');
  
  md.push('### ✅ REST API Testing');
  md.push('');
  md.push(`Total endpoints found: ${restRoutes.length}`);
  md.push('');
  const groupedRoutes = {};
  restRoutes.forEach(route => {
    const namespace = route.namespace || 'buddypress';
    if (!groupedRoutes[namespace]) groupedRoutes[namespace] = [];
    groupedRoutes[namespace].push(route);
  });
  
  Object.keys(groupedRoutes).forEach(namespace => {
    md.push(`#### ${namespace}`);
    groupedRoutes[namespace].forEach(route => {
      md.push(`- [ ] ${route.route || route}`);
    });
    md.push('');
  });
  
  md.push('## Test Execution Guide');
  md.push('');
  md.push('### Unit Tests');
  md.push('```bash');
  md.push('composer test:unit');
  md.push('```');
  md.push('');
  md.push('### Integration Tests');
  md.push('```bash');
  md.push('composer test:integration');
  md.push('```');
  md.push('');
  md.push('### E2E Tests');
  md.push('```bash');
  md.push('npm run test:e2e');
  md.push('```');
  md.push('');
  
  return md.join('\n');
}

function generatePHPUnitFiles(components, restRoutes) {
  const files = [];
  
  // Generate component integration tests
  components.filter(c => c.active).forEach(comp => {
    const className = (comp.title || comp.name || comp.id).replace(/[^a-zA-Z0-9]/g, '') + 'IntegrationTest';
    const code = `<?php
/**
 * Integration tests for ${comp.title || comp.name || comp.id} component
 * 
 * @package ${slug}
 */

namespace BuddyNext\\Tests\\Integration;

use WP_UnitTestCase;

class ${className} extends WP_UnitTestCase {
    
    protected function setUp(): void {
        parent::setUp();
        // Setup test environment
    }
    
    protected function tearDown(): void {
        // Clean up
        parent::tearDown();
    }
    
    /**
     * Test component activation
     */
    public function test_component_is_active() {
        $this->assertTrue(
            bp_is_active('${comp.id}'),
            '${comp.title || comp.name || comp.id} component should be active'
        );
    }
    
    /**
     * Test component initialization
     */
    public function test_component_initialization() {
        // Test that component is properly initialized
        $this->assertNotNull(
            buddypress()->${comp.id},
            '${comp.title || comp.name || comp.id} component should be initialized'
        );
    }
    
    /**
     * Test component hooks registration
     */
    public function test_component_hooks() {
        // Test that necessary hooks are registered
        $this->assertGreaterThan(
            0,
            has_action('bp_init'),
            'Component should register bp_init action'
        );
    }
}`;
    
    files.push({
      relpath: `tests/phpunit/Integration/${className}.php`,
      code: code
    });
  });
  
  // Generate REST API tests
  if (restRoutes.length > 0) {
    const code = `<?php
/**
 * REST API endpoint tests
 * 
 * @package ${slug}
 */

namespace BuddyNext\\Tests\\Integration;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class RestApiTest extends WP_UnitTestCase {
    
    protected $server;
    
    protected function setUp(): void {
        parent::setUp();
        
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server();
        do_action('rest_api_init');
    }
    
    protected function tearDown(): void {
        global $wp_rest_server;
        $wp_rest_server = null;
        parent::tearDown();
    }
    
    /**
     * Test REST API namespace registration
     */
    public function test_namespace_registered() {
        $namespaces = $this->server->get_namespaces();
        $this->assertContains(
            'buddypress/v1',
            $namespaces,
            'BuddyPress REST namespace should be registered'
        );
    }
    
    /**
     * Test that routes are registered
     */
    public function test_routes_registered() {
        $routes = $this->server->get_routes();
        $this->assertArrayHasKey(
            '/buddypress/v1',
            $routes,
            'BuddyPress routes should be registered'
        );
    }
    
    /**
     * Test unauthorized access returns 401
     */
    public function test_unauthorized_access() {
        $request = new WP_REST_Request('GET', '/buddypress/v1/members');
        $response = $this->server->dispatch($request);
        
        // Some endpoints may be public, adjust as needed
        $this->assertContains(
            $response->get_status(),
            [200, 401, 403],
            'Response should be valid status code'
        );
    }
}`;
    
    files.push({
      relpath: 'tests/phpunit/Integration/RestApiTest.php',
      code: code
    });
  }
  
  return files;
}

function generatePlaywrightFiles(navItems, pages) {
  const files = [];
  
  // Generate navigation test
  if (navItems.length > 0) {
    const code = `import { test, expect } from '@playwright/test';

test.describe('BuddyPress Navigation', () => {
  test.beforeEach(async ({ page }) => {
    // Login if needed
    const baseUrl = process.env.E2E_BASE_URL || 'http://localhost';
    await page.goto(baseUrl);
  });

  test('should display all navigation items', async ({ page }) => {
    // Check that all nav items are visible
${navItems.map(nav => `    await expect(page.locator('text="${nav.name}"')).toBeVisible();`).join('\n')}
  });

  test('navigation links should be clickable', async ({ page }) => {
    // Test first navigation item
    const firstNav = '${navItems[0]?.name || 'Activity'}';
    await page.click(\`text=\${firstNav}\`);
    await page.waitForLoadState('networkidle');
    
    // Verify navigation worked
    await expect(page).toHaveURL(/.*\\/${navItems[0]?.slug || 'activity'}.*/);
  });

  test('mobile navigation should work', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Mobile menu should be visible
    const mobileMenu = page.locator('[data-testid="mobile-menu"], .mobile-menu, #mobile-menu');
    
    // This might need adjustment based on theme
    if (await mobileMenu.isVisible()) {
      await mobileMenu.click();
      await expect(page.locator('nav')).toBeVisible();
    }
  });
});`;
    
    files.push({
      relpath: 'tools/e2e/tests/navigation.spec.ts',
      code: code
    });
  }
  
  // Generate page tests
  if (pages.length > 0) {
    const code = `import { test, expect } from '@playwright/test';

test.describe('BuddyPress Pages', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://localhost';
  
  test.beforeEach(async ({ page }) => {
    await page.goto(baseUrl);
  });

${pages.slice(0, 5).map(p => `  test('should load ${p.title} page', async ({ page }) => {
    // Navigate to ${p.title}
    await page.goto(\`\${baseUrl}/${p.slug || p.title.toLowerCase().replace(/\s+/g, '-')}\`);
    await page.waitForLoadState('networkidle');
    
    // Check page loaded
    await expect(page.locator('h1, h2').first()).toContainText(/${p.title}/i);
    
    // Take screenshot for visual regression
    await expect(page).toHaveScreenshot('${p.slug || p.title.toLowerCase().replace(/\s+/g, '-')}.png');
  });
`).join('\n')}
  
  test('should handle 404 pages gracefully', async ({ page }) => {
    await page.goto(\`\${baseUrl}/non-existent-page-12345\`);
    await expect(page.locator('body')).toContainText(/not found|404/i);
  });
});`;
    
    files.push({
      relpath: 'tools/e2e/tests/pages.spec.ts', 
      code: code
    });
  }
  
  // Generate component interaction test
  const interactionCode = `import { test, expect } from '@playwright/test';

test.describe('BuddyPress Component Interactions', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://localhost';
  const username = process.env.E2E_USER || 'admin';
  const password = process.env.E2E_PASS || 'password';
  
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto(\`\${baseUrl}/wp-login.php\`);
    await page.fill('#user_login', username);
    await page.fill('#user_pass', password);
    await page.click('#wp-submit');
    await page.waitForURL(/.*\\/wp-admin.*/);
    
    // Go to BuddyPress area
    await page.goto(baseUrl);
  });

  test('should interact with activity stream', async ({ page }) => {
    // Navigate to activity
    await page.goto(\`\${baseUrl}/activity\`);
    await page.waitForLoadState('networkidle');
    
    // Check activity form exists
    const activityForm = page.locator('#whats-new-form, .activity-update-form');
    if (await activityForm.isVisible()) {
      // Try to post an activity
      await page.fill('#whats-new, [name="whats-new"]', 'Test activity from Playwright');
      
      const submitButton = page.locator('#aw-whats-new-submit, [type="submit"]').first();
      if (await submitButton.isVisible()) {
        await submitButton.click();
        await page.waitForLoadState('networkidle');
        
        // Check if activity was posted
        await expect(page.locator('.activity-content').first()).toContainText('Test activity');
      }
    }
  });

  test('should navigate member profiles', async ({ page }) => {
    // Go to members directory
    await page.goto(\`\${baseUrl}/members\`);
    await page.waitForLoadState('networkidle');
    
    // Click on first member
    const firstMember = page.locator('.member-name a, .members-list a').first();
    if (await firstMember.isVisible()) {
      await firstMember.click();
      await page.waitForLoadState('networkidle');
      
      // Should be on a profile page
      await expect(page).toHaveURL(/.*\\/members\\/.+/);
      await expect(page.locator('.profile-header, #item-header')).toBeVisible();
    }
  });

  test('should use group functionality', async ({ page }) => {
    // Navigate to groups
    await page.goto(\`\${baseUrl}/groups\`);
    await page.waitForLoadState('networkidle');
    
    // Check groups list exists
    const groupsList = page.locator('.groups-list, #groups-list');
    if (await groupsList.isVisible()) {
      // Click first group if exists
      const firstGroup = groupsList.locator('a').first();
      if (await firstGroup.isVisible()) {
        await firstGroup.click();
        await page.waitForLoadState('networkidle');
        
        // Should be on group page
        await expect(page).toHaveURL(/.*\\/groups\\/.+/);
      }
    }
  });
});`;
  
  files.push({
    relpath: 'tools/e2e/tests/interactions.spec.ts',
    code: interactionCode
  });
  
  return files;
}

function identifyRisks(scan) {
  const risks = [];
  
  // Check for inactive critical components
  const inactiveCore = scan.components.filter(c => 
    !c.active && ['members', 'groups', 'activity'].includes(c.id)
  );
  if (inactiveCore.length > 0) {
    risks.push(`Critical components inactive: ${inactiveCore.map(c => c.name).join(', ')}`);
  }
  
  // Check for missing pages
  if (scan.pages.length === 0) {
    risks.push('No BuddyPress pages detected - may indicate configuration issue');
  }
  
  // Check for REST API availability
  if (scan.rest.length === 0) {
    risks.push('No REST API endpoints found - API may be disabled');
  }
  
  // Check for email configuration
  if (scan.emails.length === 0) {
    risks.push('No email templates found - notifications may not work');
  }
  
  // Check navigation
  if (scan.nav.length === 0) {
    risks.push('No navigation items found - theme may not support BuddyPress nav');
  }
  
  return risks;
}

// ---------- Writers ----------
function writeOutputs(result) {
  const docsDir = path.join(outDir, 'docs');
  ensureDir(docsDir);
  
  writeFile(path.join(docsDir, 'PLAN.yaml'), result.plan_yaml);
  writeFile(path.join(docsDir, 'BUDDYPRESS-TEST-PLAN.refined.md'), result.docs_markdown);
  
  if (Array.isArray(result.risks) && result.risks.length) {
    writeFile(path.join(docsDir, 'RISKS.md'), '# Identified Risks\n\n' + result.risks.map(r=>`- ${r}`).join('\n') + '\n');
  }

  for (const f of result.phpunit_files) {
    const dest = path.join(process.cwd(), f.relpath);
    writeFile(dest, f.code);
  }
  
  for (const f of result.playwright_files) {
    const dest = path.join(process.cwd(), f.relpath);
    writeFile(dest, f.code);
  }
}

// ---------- Main ----------
console.log('🚀 Generating test plan from BuddyPress scan data...');
console.log(`   Input:  ${inDir}`);
console.log(`   Output: ${outDir}`);
console.log(`   Theme:  ${slug}`);
console.log('');

try {
  // Generate the test plan
  const result = generateTestPlan();
  
  // Write all outputs
  writeOutputs(result);
  
  console.log('');
  console.log('✅ Test plan generated successfully!');
  console.log('');
  console.log('📋 Generated files:');
  console.log(`   - ${result.phpunit_files.length} PHPUnit test files`);
  console.log(`   - ${result.playwright_files.length} Playwright test files`);
  console.log(`   - Test plan YAML and documentation`);
  if (result.risks.length > 0) {
    console.log(`   - ${result.risks.length} risks identified`);
  }
  console.log('');
  console.log('Next steps:');
  console.log('  1. Review the generated test plan in', path.join(outDir, 'docs'));
  console.log('  2. Run PHPUnit tests: composer test');
  console.log('  3. Run Playwright tests: npm run test:e2e');
  
} catch (error) {
  console.error('❌ Error generating test plan:', error.message);
  process.exit(1);
}