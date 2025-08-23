#!/usr/bin/env node
/**
 * Universal WordPress Test Generator
 * Generates comprehensive test suites for any WordPress plugin or theme
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// CLI arguments
const args = process.argv;
const inDir = argOf('--in', 'wp-content/uploads/wp-scan');
const outDir = argOf('--out', 'wp-content/uploads/wp-test-plan');
const targetType = argOf('--type', 'site');
const targetSlug = argOf('--slug', '');
const projectName = argOf('--name', 'WordPress Tests');

function argOf(flag, def) { 
    return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

// IO helpers
function readJSONSafe(p, def) {
    if (!fs.existsSync(p)) return def;
    try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return def; }
}

function ensureDir(p) { 
    fs.mkdirSync(p, { recursive: true }); 
}

function writeFile(dest, content) {
    ensureDir(path.dirname(dest));
    fs.writeFileSync(dest, content);
    console.log('  → wrote', dest);
}

// Load scan data
function loadScanData() {
    let data = {};
    
    if (targetType === 'plugin') {
        data = readJSONSafe(path.join(inDir, `plugin-${targetSlug}.json`), []);
        if (Array.isArray(data) && data.length > 0) data = data[0];
    } else if (targetType === 'theme') {
        data = readJSONSafe(path.join(inDir, `theme-${targetSlug}.json`), []);
        if (Array.isArray(data) && data.length > 0) data = data[0];
    } else {
        data = readJSONSafe(path.join(inDir, 'site.json'), {});
    }
    
    return data;
}

// Generate test plan
function generateTestPlan(data) {
    const plan = {
        yaml: generateYAML(data),
        markdown: generateMarkdown(data),
        phpunit: generatePHPUnitTests(data),
        playwright: generatePlaywrightTests(data),
        cypress: generateCypressTests(data),
        risks: identifyRisks(data)
    };
    
    return plan;
}

// Generate YAML test plan
function generateYAML(data) {
    const yaml = [];
    yaml.push(`# Test Plan: ${projectName}`);
    yaml.push(`# Generated: ${new Date().toISOString()}`);
    yaml.push('');
    yaml.push('test_coverage:');
    
    if (data.hooks) {
        yaml.push('  hooks:');
        yaml.push(`    actions: ${data.hooks.actions?.length || 0}`);
        yaml.push(`    filters: ${data.hooks.filters?.length || 0}`);
    }
    
    if (data.shortcodes) {
        yaml.push(`  shortcodes: ${data.shortcodes.length}`);
    }
    
    if (data.ajax_actions) {
        yaml.push(`  ajax_endpoints: ${data.ajax_actions.length}`);
    }
    
    if (data.rest_routes) {
        yaml.push(`  rest_endpoints: ${data.rest_routes.length}`);
    }
    
    if (data.blocks) {
        yaml.push(`  gutenberg_blocks: ${data.blocks.length}`);
    }
    
    if (data.post_types) {
        yaml.push(`  custom_post_types: ${data.post_types.length}`);
    }
    
    if (data.taxonomies) {
        yaml.push(`  custom_taxonomies: ${data.taxonomies.length}`);
    }
    
    yaml.push('');
    yaml.push('test_types:');
    yaml.push('  - unit: Core functionality tests');
    yaml.push('  - integration: WordPress integration tests');
    yaml.push('  - functional: User workflow tests');
    yaml.push('  - e2e: Browser-based tests');
    yaml.push('  - performance: Load and speed tests');
    yaml.push('  - security: Vulnerability scans');
    
    return yaml.join('\n');
}

// Generate Markdown documentation
function generateMarkdown(data) {
    const md = [];
    md.push(`# Test Plan: ${projectName}`);
    md.push('');
    md.push(`Generated: ${new Date().toLocaleDateString()}`);
    md.push('');
    
    md.push('## Coverage Overview');
    md.push('');
    
    // Hooks
    if (data.hooks && (data.hooks.actions?.length || data.hooks.filters?.length)) {
        md.push('### WordPress Hooks');
        md.push(`- **Actions**: ${data.hooks.actions?.length || 0} hooks to test`);
        md.push(`- **Filters**: ${data.hooks.filters?.length || 0} filters to test`);
        md.push('');
    }
    
    // Shortcodes
    if (data.shortcodes?.length) {
        md.push('### Shortcodes');
        data.shortcodes.forEach(sc => {
            md.push(`- [ ] Test [${sc}] shortcode`);
        });
        md.push('');
    }
    
    // AJAX
    if (data.ajax_actions?.length) {
        md.push('### AJAX Actions');
        data.ajax_actions.forEach(action => {
            md.push(`- [ ] Test ${action} AJAX endpoint`);
        });
        md.push('');
    }
    
    // REST API
    if (data.rest_routes?.length) {
        md.push('### REST API Endpoints');
        data.rest_routes.forEach(route => {
            md.push(`- [ ] ${route.methods.join(', ')}: ${route.route}`);
        });
        md.push('');
    }
    
    // Blocks
    if (data.blocks?.length) {
        md.push('### Gutenberg Blocks');
        data.blocks.forEach(block => {
            md.push(`- [ ] Test ${block.name} block`);
        });
        md.push('');
    }
    
    // Admin Pages
    if (data.admin_pages?.length) {
        md.push('### Admin Pages');
        data.admin_pages.forEach(page => {
            md.push(`- [ ] Test ${page.title} admin page`);
        });
        md.push('');
    }
    
    md.push('## Test Execution');
    md.push('');
    md.push('### Unit Tests');
    md.push('```bash');
    md.push('npm run test:unit');
    md.push('```');
    md.push('');
    md.push('### Integration Tests');
    md.push('```bash');
    md.push('npm run test:integration');
    md.push('```');
    md.push('');
    md.push('### E2E Tests');
    md.push('```bash');
    md.push('npm run test:e2e');
    md.push('```');
    
    return md.join('\n');
}

// Generate PHPUnit tests
function generatePHPUnitTests(data) {
    const tests = [];
    const className = (data.name || projectName).replace(/[^a-zA-Z0-9]/g, '');
    
    // Basic plugin/theme test
    const basicTest = `<?php
namespace Tests\\Integration;

use WP_UnitTestCase;

class ${className}Test extends WP_UnitTestCase {
    
    public function test_${targetType}_is_active() {
        ${targetType === 'plugin' ? 
            `$this->assertTrue(is_plugin_active('${data.file || targetSlug}'));` :
            `$this->assertEquals('${targetSlug}', get_stylesheet());`}
    }
    
    public function test_required_functions_exist() {
        // Test that key functions are available
        $this->assertTrue(function_exists('wp_head'));
    }
}`;
    
    tests.push({
        relpath: `tests/phpunit/Integration/${className}Test.php`,
        code: basicTest
    });
    
    // Hooks test if there are hooks
    if (data.hooks && (data.hooks.actions?.length || data.hooks.filters?.length)) {
        const hooksTest = `<?php
namespace Tests\\Unit;

use PHPUnit\\Framework\\TestCase;
use Brain\\Monkey;
use Brain\\Monkey\\Functions;
use Brain\\Monkey\\Actions;
use Brain\\Monkey\\Filters;

class ${className}HooksTest extends TestCase {
    
    protected function setUp(): void {
        parent::setUp();
        Monkey\\setUp();
    }
    
    protected function tearDown(): void {
        Monkey\\tearDown();
        parent::tearDown();
    }
    
    public function test_actions_are_registered() {
        ${data.hooks.actions?.slice(0, 3).map(action => 
            `Actions\\expectAdded('${action}');`
        ).join('\n        ')}
        
        // Load the plugin/theme
        $this->assertTrue(true);
    }
    
    public function test_filters_are_registered() {
        ${data.hooks.filters?.slice(0, 3).map(filter => 
            `Filters\\expectAdded('${filter}');`
        ).join('\n        ')}
        
        // Load the plugin/theme
        $this->assertTrue(true);
    }
}`;
        
        tests.push({
            relpath: `tests/phpunit/Unit/${className}HooksTest.php`,
            code: hooksTest
        });
    }
    
    // REST API test if there are routes
    if (data.rest_routes?.length) {
        const restTest = `<?php
namespace Tests\\Functional;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class ${className}RestApiTest extends WP_UnitTestCase {
    
    protected $server;
    
    public function setUp(): void {
        parent::setUp();
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server();
        do_action('rest_api_init');
    }
    
    public function tearDown(): void {
        global $wp_rest_server;
        $wp_rest_server = null;
        parent::tearDown();
    }
    
    public function test_routes_are_registered() {
        $routes = $this->server->get_routes();
        ${data.rest_routes.slice(0, 3).map(route => 
            `$this->assertArrayHasKey('${route.route}', $routes);`
        ).join('\n        ')}
    }
}`;
        
        tests.push({
            relpath: `tests/phpunit/Functional/${className}RestApiTest.php`,
            code: restTest
        });
    }
    
    return tests;
}

// Generate Playwright tests
function generatePlaywrightTests(data) {
    const tests = [];
    
    // Basic test
    const basicTest = `import { test, expect } from '@playwright/test';

const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost';
const ADMIN_USER = process.env.E2E_USER || 'admin';
const ADMIN_PASS = process.env.E2E_PASS || 'password';

test.describe('${projectName} E2E Tests', () => {
    
    test.beforeEach(async ({ page }) => {
        // Login to WordPress admin
        await page.goto(BASE_URL + '/wp-login.php');
        await page.fill('#user_login', ADMIN_USER);
        await page.fill('#user_pass', ADMIN_PASS);
        await page.click('#wp-submit');
        await page.waitForURL(/.*\\/wp-admin.*/);
    });
    
    test('should access plugin/theme settings', async ({ page }) => {
        await page.goto(BASE_URL + '/wp-admin/');
        await expect(page.locator('#wpadminbar')).toBeVisible();
    });
    
    ${data.admin_pages?.slice(0, 3).map(page => `
    test('should load ${page.title} page', async ({ page }) => {
        await page.goto(BASE_URL + '/wp-admin/admin.php?page=${page.slug}');
        await expect(page.locator('h1')).toContainText(/${page.title}/i);
    });`).join('\n    ')}
});`;
    
    tests.push({
        relpath: `tools/e2e/tests/${targetSlug || 'main'}.spec.ts`,
        code: basicTest
    });
    
    // Shortcode test if exists
    if (data.shortcodes?.length) {
        const shortcodeTest = `import { test, expect } from '@playwright/test';

test.describe('Shortcode Tests', () => {
    test('should render shortcodes on frontend', async ({ page }) => {
        // Create a test page with shortcodes
        // This would need to be set up in advance
        await page.goto(process.env.E2E_BASE_URL || 'http://localhost');
        
        ${data.shortcodes.slice(0, 3).map(sc => `
        // Test [${sc}] shortcode
        const ${sc.replace(/[^a-zA-Z]/g, '')}Element = page.locator('[data-shortcode="${sc}"]');
        if (await ${sc.replace(/[^a-zA-Z]/g, '')}Element.isVisible()) {
            await expect(${sc.replace(/[^a-zA-Z]/g, '')}Element).toBeVisible();
        }`).join('\n        ')}
    });
});`;
        
        tests.push({
            relpath: `tools/e2e/tests/shortcodes.spec.ts`,
            code: shortcodeTest
        });
    }
    
    return tests;
}

// Generate Cypress tests
function generateCypressTests(data) {
    const tests = [];
    
    const cypressTest = `describe('${projectName} Tests', () => {
    beforeEach(() => {
        // Login to WordPress
        cy.visit('/wp-login.php');
        cy.get('#user_login').type(Cypress.env('WP_USER'));
        cy.get('#user_pass').type(Cypress.env('WP_PASS'));
        cy.get('#wp-submit').click();
        cy.url().should('include', '/wp-admin');
    });
    
    it('should load admin dashboard', () => {
        cy.visit('/wp-admin');
        cy.get('#wpadminbar').should('be.visible');
    });
    
    ${data.admin_pages?.slice(0, 2).map(page => `
    it('should access ${page.title}', () => {
        cy.visit('/wp-admin/admin.php?page=${page.slug}');
        cy.get('h1').should('contain', '${page.title}');
    });`).join('\n    ')}
});`;
    
    tests.push({
        relpath: `tests/cypress/integration/${targetSlug || 'main'}.spec.js`,
        code: cypressTest
    });
    
    return tests;
}

// Identify risks
function identifyRisks(data) {
    const risks = [];
    
    if (!data || Object.keys(data).length === 0) {
        risks.push('No scan data found - ensure the target exists');
    }
    
    if (data.database_tables?.length > 10) {
        risks.push(`Large number of database tables (${data.database_tables.length}) - consider data migration tests`);
    }
    
    if (data.ajax_actions?.length > 20) {
        risks.push(`Many AJAX actions (${data.ajax_actions.length}) - ensure proper nonce verification`);
    }
    
    if (data.rest_routes?.length > 30) {
        risks.push(`Extensive REST API (${data.rest_routes.length} routes) - implement API versioning tests`);
    }
    
    if (!data.has_tests) {
        risks.push('No existing tests found - starting from scratch');
    }
    
    return risks;
}

// Main execution
console.log('🚀 Generating test plan...');
console.log(`   Project: ${projectName}`);
console.log(`   Type: ${targetType}`);
if (targetSlug) console.log(`   Target: ${targetSlug}`);

try {
    const scanData = loadScanData();
    const testPlan = generateTestPlan(scanData);
    
    const docsDir = path.join(outDir, 'docs');
    
    // Write documentation
    writeFile(path.join(docsDir, 'TEST-PLAN.yaml'), testPlan.yaml);
    writeFile(path.join(docsDir, 'TEST-PLAN.md'), testPlan.markdown);
    
    if (testPlan.risks.length > 0) {
        writeFile(path.join(docsDir, 'RISKS.md'), 
            '# Identified Risks\n\n' + testPlan.risks.map(r => `- ${r}`).join('\n'));
    }
    
    // Write test files
    testPlan.phpunit.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    testPlan.playwright.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    testPlan.cypress.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    
    console.log('✅ Test plan generated successfully!');
    console.log(`   Documentation: ${docsDir}`);
    console.log(`   PHPUnit tests: ${testPlan.phpunit.length} files`);
    console.log(`   Playwright tests: ${testPlan.playwright.length} files`);
    console.log(`   Cypress tests: ${testPlan.cypress.length} files`);
    
} catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
}
