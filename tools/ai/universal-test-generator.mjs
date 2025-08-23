#!/usr/bin/env node
/**
 * Universal WordPress Plugin Test Generator
 * 
 * Automatically generates comprehensive test suites for ANY WordPress plugin
 * based on scan results, with BuddyPress as the comprehensive model case.
 *
 * Usage:
 *   node tools/ai/universal-test-generator.mjs \
 *     --plugin woocommerce \
 *     --scan wp-content/uploads/wp-scan/plugin-woocommerce.json \
 *     --out tests/generated/woocommerce
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ---------- CLI args ----------
const args = process.argv;
const pluginSlug = argOf('--plugin', '');
const scanFile = argOf('--scan', '');
const outDir = argOf('--out', `tests/generated/${pluginSlug}`);
const verbose = args.includes('--verbose');

function argOf(flag, def) { 
  return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

// Validate required args
if (!pluginSlug || !scanFile) {
  console.error('Usage: node universal-test-generator.mjs --plugin <slug> --scan <scan-file>');
  console.error('Example: node universal-test-generator.mjs --plugin woocommerce --scan wp-content/uploads/wp-scan/plugin-woocommerce.json');
  process.exit(1);
}

// ---------- IO helpers ----------
function readJSONSafe(p, def = {}) {
  if (!fs.existsSync(p)) {
    console.error(`❌ Scan file not found: ${p}`);
    console.error('Run: npm run scan -- plugin <plugin-slug>');
    return def;
  }
  try { 
    return JSON.parse(fs.readFileSync(p, 'utf8')); 
  } catch (e) {
    console.error(`❌ Invalid JSON in: ${p}`);
    return def;
  }
}

function ensureDir(p) { 
  fs.mkdirSync(p, { recursive: true }); 
}

function writeFile(dest, content) { 
  ensureDir(path.dirname(dest)); 
  fs.writeFileSync(dest, content); 
  console.log('  ✅ Generated:', dest.replace(process.cwd(), '.')); 
}

// ---------- Load plugin scan data ----------
console.log(`🔍 Loading scan data for plugin: ${pluginSlug}`);
const pluginData = readJSONSafe(scanFile);

if (!pluginData || pluginData.length === 0) {
  console.error(`❌ No plugin data found in scan file`);
  process.exit(1);
}

// Handle array of plugins (get first match) or direct plugin data
let plugin = Array.isArray(pluginData) ? 
  pluginData.find(p => p.slug === pluginSlug) || pluginData[0] : 
  pluginData;

// Handle BuddyPress scan structure (plugin_info at root)
if (plugin.plugin_info && !plugin.name) {
  plugin = {
    name: plugin.plugin_info.name || 'BuddyPress',
    slug: pluginSlug,
    version: plugin.plugin_info.version,
    description: plugin.plugin_info.description || 'BuddyPress adds community features to WordPress',
    ...plugin
  };
}

// Ensure required fields exist
if (!plugin.name) plugin.name = pluginSlug.charAt(0).toUpperCase() + pluginSlug.slice(1);
if (!plugin.slug) plugin.slug = pluginSlug;

if (!plugin) {
  console.error(`❌ Plugin ${pluginSlug} not found in scan data`);
  process.exit(1);
}

verbose && console.log('📊 Plugin data:', JSON.stringify(plugin, null, 2));

// ---------- Universal Test Generator ----------
function generateTestSuite() {
  console.log(`🧪 Generating comprehensive test suite for: ${plugin.name}`);
  
  const testData = analyzePluginFeatures(plugin);
  const testPlan = generateTestPlan(testData);
  const testFiles = generateTestFiles(testData);
  const bugChecklist = generateBugChecklist(testData);
  const featureReport = generateFeatureReport(testData);
  
  return {
    testPlan,
    testFiles,
    bugChecklist,
    featureReport,
    testData
  };
}

function analyzePluginFeatures(plugin) {
  const features = {
    // Core plugin info
    basic: {
      name: plugin.name || 'Unknown',
      slug: plugin.slug || 'unknown',
      version: plugin.version || plugin.plugin_info?.version || '1.0.0',
      active: plugin.active || plugin.plugin_info?.active || false,
      path: plugin.path || plugin.plugin_info?.path || ''
    },
    
    // Architecture analysis
    architecture: {
      has_admin: plugin.has_admin,
      has_public: plugin.has_public,
      has_includes: plugin.has_includes,
      has_assets: plugin.has_assets,
      has_tests: plugin.has_tests,
      file_structure: getFileStructure(plugin)
    },
    
    // Functionality analysis
    functionality: {
      hooks: plugin.hooks || {actions: [], filters: []},
      shortcodes: plugin.shortcodes || [],
      ajax_actions: plugin.ajax_actions || [],
      rest_routes: plugin.rest_routes || [],
      admin_pages: plugin.admin_pages || [],
      post_types: plugin.post_types || [],
      taxonomies: plugin.taxonomies || [],
      widgets: plugin.widgets || [],
      blocks: plugin.blocks || []
    },
    
    // Data management
    data: {
      database_tables: plugin.database_tables || [],
      settings: plugin.settings || []
    },
    
    // Advanced analysis (from enhanced scanner)
    advanced: {
      code_quality: plugin.code_quality || {},
      security_patterns: plugin.security_patterns || {},
      performance_indicators: plugin.performance_indicators || {},
      test_coverage: plugin.test_coverage || {},
      complexity_metrics: plugin.complexity_metrics || {},
      dependency_analysis: plugin.dependency_analysis || {},
      api_usage: plugin.api_usage || {},
      best_practices: plugin.best_practices || {}
    },
    
    // Testing priorities (enhanced with advanced data)
    priorities: calculateTestPriorities(plugin),
    
    // Complexity analysis (enhanced with metrics)
    complexity: calculateComplexity(plugin)
  };
  
  return features;
}

function getFileStructure(plugin) {
  const structure = {
    directories: [],
    key_files: []
  };
  
  if (plugin.has_admin) structure.directories.push('admin');
  if (plugin.has_public) structure.directories.push('public');
  if (plugin.has_includes) structure.directories.push('includes');
  if (plugin.has_assets) structure.directories.push('assets');
  
  return structure;
}

function calculateTestPriorities(plugin) {
  const priorities = {
    critical: [],
    high: [],
    medium: [],
    low: []
  };
  
  // Critical priority: Security issues found
  if (plugin.security_patterns) {
    const securityIssues = plugin.security_patterns;
    if (securityIssues.sql_injection_risks?.length) priorities.critical.push('SQL injection security testing');
    if (securityIssues.xss_vulnerabilities?.length) priorities.critical.push('XSS vulnerability testing');
    if (securityIssues.user_input_sanitization?.length) priorities.critical.push('Input sanitization testing');
    if (securityIssues.capability_checks?.length) priorities.critical.push('Permission/capability testing');
    if (securityIssues.nonce_verification?.length) priorities.critical.push('CSRF/nonce verification testing');
  }
  
  // High priority: Core functionality and performance issues
  if (plugin.active) priorities.high.push('Plugin activation/deactivation');
  if (plugin.admin_pages?.length) priorities.high.push('Admin interface');
  if (plugin.database_tables?.length) priorities.high.push('Database operations');
  if (plugin.rest_routes?.length) priorities.high.push('REST API endpoints');
  
  // Performance-based high priority
  if (plugin.performance_indicators) {
    const perfData = plugin.performance_indicators;
    const totalQueries = Object.values(perfData.database_queries || {}).reduce((a, b) => a + b, 0);
    const totalRemoteRequests = Object.values(perfData.remote_requests || {}).reduce((a, b) => a + b, 0);
    
    if (totalQueries > 10) priorities.high.push('Database performance testing');
    if (totalRemoteRequests > 5) priorities.high.push('External API performance testing');
    if (Object.keys(perfData.caching_usage || {}).length === 0 && totalQueries > 5) {
      priorities.high.push('Caching implementation testing');
    }
  }
  
  // Medium priority: Extended functionality
  if (plugin.shortcodes?.length) priorities.medium.push('Shortcode functionality');
  if (plugin.ajax_actions?.length) priorities.medium.push('AJAX operations');
  if (plugin.post_types?.length) priorities.medium.push('Custom post types');
  if (plugin.widgets?.length) priorities.medium.push('Widget functionality');
  
  // Code quality based medium priority
  if (plugin.complexity_metrics) {
    const complexity = plugin.complexity_metrics.cyclomatic_complexity || 0;
    if (complexity > 50) priorities.medium.push('Code complexity and refactoring testing');
    
    const maxParams = Math.max(...(plugin.complexity_metrics.function_parameters || [0]));
    if (maxParams > 5) priorities.medium.push('Function parameter complexity testing');
  }
  
  // Low priority: Additional features and best practices
  if (plugin.blocks?.length) priorities.low.push('Gutenberg blocks');
  if (plugin.taxonomies?.length) priorities.low.push('Custom taxonomies');
  
  // Best practices based low priority
  if (plugin.best_practices) {
    const practices = plugin.best_practices;
    if (!practices.has_uninstall_hook) priorities.low.push('Uninstall hook testing');
    if (!practices.enqueues_scripts_properly) priorities.low.push('Script enqueuing best practices');
    if (!practices.localizes_scripts) priorities.low.push('Script localization testing');
    if (!practices.has_readme) priorities.low.push('Documentation completeness');
  }
  
  return priorities;
}

function calculateComplexity(plugin) {
  let score = 0;
  let details = {
    functional_complexity: 0,
    code_complexity: 0,
    security_complexity: 0,
    performance_complexity: 0
  };
  
  // Functional complexity points
  const functionalScore = (plugin.hooks?.actions?.length || 0) * 0.5 +
                         (plugin.hooks?.filters?.length || 0) * 0.5 +
                         (plugin.shortcodes?.length || 0) * 2 +
                         (plugin.ajax_actions?.length || 0) * 3 +
                         (plugin.rest_routes?.length || 0) * 4 +
                         (plugin.database_tables?.length || 0) * 5 +
                         (plugin.admin_pages?.length || 0) * 3 +
                         (plugin.post_types?.length || 0) * 4 +
                         (plugin.widgets?.length || 0) * 3 +
                         (plugin.blocks?.length || 0) * 4;
  
  details.functional_complexity = functionalScore;
  score += functionalScore;
  
  // Code complexity from advanced analysis
  if (plugin.complexity_metrics) {
    const codeComplexity = (plugin.complexity_metrics.cyclomatic_complexity || 0) * 0.1 +
                          (plugin.complexity_metrics.function_parameters?.length || 0) * 0.5;
    details.code_complexity = codeComplexity;
    score += codeComplexity;
  }
  
  if (plugin.code_quality) {
    const qualityScore = (plugin.code_quality.functions_count || 0) * 0.1 +
                        (plugin.code_quality.classes_count || 0) * 0.5;
    details.code_complexity += qualityScore;
    score += qualityScore;
  }
  
  // Security complexity
  if (plugin.security_patterns) {
    const securityIssues = Object.values(plugin.security_patterns).flat().length;
    const securityComplexity = securityIssues * 5; // High weight for security issues
    details.security_complexity = securityComplexity;
    score += securityComplexity;
  }
  
  // Performance complexity
  if (plugin.performance_indicators) {
    const perfData = plugin.performance_indicators;
    const dbQueries = Object.values(perfData.database_queries || {}).reduce((a, b) => a + b, 0);
    const remoteRequests = Object.values(perfData.remote_requests || {}).reduce((a, b) => a + b, 0);
    const fileOps = Object.values(perfData.file_operations || {}).reduce((a, b) => a + b, 0);
    
    const performanceComplexity = dbQueries * 0.5 + remoteRequests * 2 + fileOps * 0.3;
    details.performance_complexity = performanceComplexity;
    score += performanceComplexity;
  }
  
  // API usage complexity
  if (plugin.api_usage) {
    const apiComplexity = (plugin.api_usage.wordpress_apis?.length || 0) * 1 +
                         (plugin.api_usage.rest_endpoints?.length || 0) * 3 +
                         (plugin.api_usage.ajax_handlers?.length || 0) * 2 +
                         (plugin.api_usage.cron_jobs?.length || 0) * 4;
    score += apiComplexity;
  }
  
  const finalScore = Math.round(score);
  
  return {
    score: finalScore,
    level: finalScore < 15 ? 'Simple' : 
           finalScore < 35 ? 'Moderate' : 
           finalScore < 70 ? 'Complex' : 
           finalScore < 120 ? 'Very Complex' : 'Extremely Complex',
    details: {
      functional_complexity: Math.round(details.functional_complexity),
      code_complexity: Math.round(details.code_complexity),
      security_complexity: Math.round(details.security_complexity),
      performance_complexity: Math.round(details.performance_complexity)
    },
    recommendations: generateComplexityRecommendations(finalScore, details)
  };
}

function generateComplexityRecommendations(score, details) {
  const recommendations = [];
  
  if (score > 100) {
    recommendations.push('Consider breaking plugin into smaller modules');
    recommendations.push('Implement comprehensive automated testing');
    recommendations.push('Add extensive documentation');
  }
  
  if (details.security_complexity > 20) {
    recommendations.push('Prioritize security testing and code review');
    recommendations.push('Implement automated security scanning');
  }
  
  if (details.performance_complexity > 15) {
    recommendations.push('Add performance monitoring');
    recommendations.push('Implement caching strategies');
    recommendations.push('Optimize database queries');
  }
  
  if (details.code_complexity > 25) {
    recommendations.push('Refactor complex functions');
    recommendations.push('Improve code structure and organization');
    recommendations.push('Add unit tests for complex code paths');
  }
  
  return recommendations;
}

function calculateRiskLevel(testData) {
  let riskScore = 0;
  const breakdown = {
    'Security Risk': 0,
    'Performance Risk': 0,
    'Complexity Risk': 0,
    'Quality Risk': 0
  };
  
  // Security risk calculation
  if (testData.advanced.security_patterns) {
    const security = testData.advanced.security_patterns;
    let securityRisk = 0;
    
    securityRisk += (security.sql_injection_risks?.length || 0) * 25;
    securityRisk += (security.xss_vulnerabilities?.length || 0) * 25;
    securityRisk += (security.user_input_sanitization?.length || 0) * 15;
    securityRisk += (security.capability_checks?.length || 0) * 15;
    securityRisk += (security.nonce_verification?.length || 0) * 10;
    securityRisk += (security.direct_file_access?.length || 0) * 10;
    
    breakdown['Security Risk'] = Math.min(securityRisk, 100);
  }
  
  // Performance risk calculation
  if (testData.advanced.performance_indicators) {
    const perf = testData.advanced.performance_indicators;
    let performanceRisk = 0;
    
    const totalQueries = Object.values(perf.database_queries || {}).reduce((a, b) => a + b, 0);
    const totalRemoteRequests = Object.values(perf.remote_requests || {}).reduce((a, b) => a + b, 0);
    const totalFileOps = Object.values(perf.file_operations || {}).reduce((a, b) => a + b, 0);
    const cachingFiles = Object.keys(perf.caching_usage || {}).length;
    
    if (totalQueries > 20) performanceRisk += 40;
    else if (totalQueries > 10) performanceRisk += 25;
    else if (totalQueries > 5) performanceRisk += 10;
    
    if (totalRemoteRequests > 10) performanceRisk += 30;
    else if (totalRemoteRequests > 5) performanceRisk += 20;
    else if (totalRemoteRequests > 2) performanceRisk += 10;
    
    if (totalFileOps > 20) performanceRisk += 20;
    else if (totalFileOps > 10) performanceRisk += 10;
    
    if (cachingFiles === 0 && (totalQueries > 5 || totalRemoteRequests > 2)) {
      performanceRisk += 20;
    }
    
    breakdown['Performance Risk'] = Math.min(performanceRisk, 100);
  }
  
  // Complexity risk calculation
  const complexityScore = testData.complexity.score;
  if (complexityScore > 120) breakdown['Complexity Risk'] = 90;
  else if (complexityScore > 70) breakdown['Complexity Risk'] = 70;
  else if (complexityScore > 35) breakdown['Complexity Risk'] = 50;
  else if (complexityScore > 15) breakdown['Complexity Risk'] = 30;
  else breakdown['Complexity Risk'] = 10;
  
  // Code quality risk calculation
  if (testData.advanced.best_practices) {
    const practices = testData.advanced.best_practices;
    let qualityRisk = 0;
    
    if (!practices.has_plugin_header) qualityRisk += 10;
    if (!practices.enqueues_scripts_properly) qualityRisk += 15;
    if (!practices.localizes_scripts) qualityRisk += 10;
    if (!practices.has_uninstall_hook) qualityRisk += 15;
    if (!practices.has_readme) qualityRisk += 5;
    if (!practices.follows_directory_structure) qualityRisk += 20;
    
    breakdown['Quality Risk'] = Math.min(qualityRisk, 100);
  }
  
  // Calculate overall risk
  const totalRisk = Object.values(breakdown).reduce((a, b) => a + b, 0) / 4;
  
  return {
    score: Math.round(totalRisk),
    level: totalRisk > 70 ? 'HIGH RISK' : 
           totalRisk > 40 ? 'MEDIUM RISK' : 
           totalRisk > 20 ? 'LOW RISK' : 'MINIMAL RISK',
    breakdown
  };
}

function generateTestPlan(testData) {
  const plan = [];
  plan.push(`# ${testData.basic.name} - Comprehensive Test Plan`);
  plan.push(`**Plugin:** ${testData.basic.slug}`);
  plan.push(`**Version:** ${testData.basic.version}`);
  plan.push(`**Complexity:** ${testData.complexity.level} (${testData.complexity.score} points)`);
  plan.push(`**Generated:** ${new Date().toISOString()}`);
  plan.push('');
  
  // Complexity Analysis
  plan.push('## 📊 Complexity Analysis');
  plan.push('');
  plan.push(`**Overall Score:** ${testData.complexity.score} (${testData.complexity.level})`);
  plan.push('');
  plan.push('### Breakdown:');
  plan.push(`- **Functional Complexity:** ${testData.complexity.details.functional_complexity}`);
  plan.push(`- **Code Complexity:** ${testData.complexity.details.code_complexity}`);
  plan.push(`- **Security Complexity:** ${testData.complexity.details.security_complexity}`);
  plan.push(`- **Performance Complexity:** ${testData.complexity.details.performance_complexity}`);
  plan.push('');
  
  if (testData.complexity.recommendations.length > 0) {
    plan.push('### Recommendations:');
    testData.complexity.recommendations.forEach(rec => {
      plan.push(`- ${rec}`);
    });
    plan.push('');
  }
  
  // Test Strategy
  plan.push('## 🎯 Test Strategy');
  plan.push('');
  
  if (testData.priorities.critical.length > 0) {
    plan.push('### 🚨 CRITICAL Priority Tests');
    testData.priorities.critical.forEach(item => {
      plan.push(`- ❌ ${item}`);
    });
    plan.push('');
  }
  
  plan.push('### ✅ High Priority Tests');
  testData.priorities.high.forEach(item => {
    plan.push(`- ✅ ${item}`);
  });
  plan.push('');
  plan.push('### 🟡 Medium Priority Tests');
  testData.priorities.medium.forEach(item => {
    plan.push(`- 🟡 ${item}`);
  });
  plan.push('');
  plan.push('### 🔵 Low Priority Tests');
  testData.priorities.low.forEach(item => {
    plan.push(`- 🔵 ${item}`);
  });
  plan.push('');
  
  // Functional Areas
  plan.push('## 📋 Functional Test Areas');
  plan.push('');
  
  if (testData.functionality.admin_pages.length > 0) {
    plan.push('### Admin Interface Tests');
    testData.functionality.admin_pages.forEach(page => {
      plan.push(`- **${page.title}** (${page.slug})`);
      plan.push(`  - Capability: ${page.capability}`);
      plan.push(`  - Load test, permission test, functionality test`);
    });
    plan.push('');
  }
  
  if (testData.functionality.rest_routes.length > 0) {
    plan.push('### REST API Tests');
    testData.functionality.rest_routes.forEach(route => {
      plan.push(`- **${route.route}**`);
      plan.push(`  - Methods: ${route.methods.join(', ')}`);
      plan.push(`  - Authentication, validation, response format`);
    });
    plan.push('');
  }
  
  if (testData.functionality.shortcodes.length > 0) {
    plan.push('### Shortcode Tests');
    testData.functionality.shortcodes.forEach(shortcode => {
      plan.push(`- **[${shortcode}]**`);
      plan.push(`  - Rendering, attributes, security`);
    });
    plan.push('');
  }
  
  if (testData.data.database_tables.length > 0) {
    plan.push('### Database Tests');
    testData.data.database_tables.forEach(table => {
      plan.push(`- **${table}**`);
      plan.push(`  - CRUD operations, data integrity, performance`);
    });
    plan.push('');
  }
  
  // Security Tests
  plan.push('## 🔒 Security Test Areas');
  plan.push('- XSS prevention in all inputs');
  plan.push('- SQL injection protection');
  plan.push('- CSRF protection on forms');
  plan.push('- Permission checks for admin functions');
  plan.push('- File upload security (if applicable)');
  plan.push('- Data sanitization and validation');
  plan.push('');
  
  // Performance Tests
  plan.push('## ⚡ Performance Test Areas');
  plan.push('- Plugin activation/deactivation time');
  plan.push('- Admin page load times');
  plan.push('- Database query optimization');
  plan.push('- Memory usage analysis');
  plan.push('- Frontend impact measurement');
  plan.push('');
  
  return plan.join('\n');
}

function generateTestFiles(testData) {
  const files = {};
  
  // Generate Unit Test
  files['Unit/PluginTest.php'] = generateUnitTest(testData);
  
  // Generate Integration Test
  files['Integration/PluginIntegrationTest.php'] = generateIntegrationTest(testData);
  
  // Generate Security Test
  files['Security/PluginSecurityTest.php'] = generateSecurityTest(testData);
  
  // Generate E2E Test
  files['e2e/plugin.spec.ts'] = generateE2ETest(testData);
  
  // Generate Admin Test if has admin pages
  if (testData.functionality.admin_pages.length > 0) {
    files['Integration/AdminTest.php'] = generateAdminTest(testData);
  }
  
  // Generate REST API Test if has REST routes
  // Commented out until generateRestApiTest is implemented
  // if (testData.functionality.rest_routes.length > 0) {
  //   files['Integration/RestApiTest.php'] = generateRestApiTest(testData);
  // }
  
  return files;
}

function generateUnitTest(testData) {
  const className = pascalCase(testData.basic.slug) + 'Test';
  
  return `<?php
/**
 * Unit Tests for ${testData.basic.name}
 * 
 * Tests plugin functionality in isolation (no WordPress dependencies)
 */

namespace Tests\\Unit;

use PHPUnit\\Framework\\TestCase;

class ${className} extends TestCase
{
    public function test_plugin_constants_are_defined()
    {
        // Test that plugin constants exist (if plugin defines any)
        $this->assertTrue(true, 'Plugin constants test placeholder');
    }
    
    public function test_plugin_functions_exist()
    {
        // Test that main plugin functions exist
        $this->assertTrue(true, 'Plugin functions test placeholder');
    }
    
    ${generateShortcodeUnitTests(testData.functionality.shortcodes)}
    
    ${generateHookUnitTests(testData.functionality.hooks)}
}`;
}

function generateIntegrationTest(testData) {
  const className = pascalCase(testData.basic.slug) + 'IntegrationTest';
  
  return `<?php
/**
 * Integration Tests for ${testData.basic.name}
 * 
 * Tests plugin functionality with WordPress environment
 */

namespace Tests\\Integration;

use WP_UnitTestCase;

class ${className} extends WP_UnitTestCase
{
    public function setUp(): void
    {
        parent::setUp();
        
        // Activate plugin for testing
        if (!is_plugin_active('${testData.basic.slug}/${testData.basic.slug}.php')) {
            activate_plugin('${testData.basic.slug}/${testData.basic.slug}.php');
        }
    }
    
    public function test_plugin_is_active()
    {
        $this->assertTrue(is_plugin_active('${testData.basic.slug}/${testData.basic.slug}.php'));
    }
    
    ${generateDatabaseIntegrationTests(testData.data.database_tables)}
    
    ${generatePostTypeIntegrationTests(testData.functionality.post_types)}
    
    ${generateSettingsIntegrationTests(testData.data.settings)}
}`;
}

function generateSecurityTest(testData) {
  const className = pascalCase(testData.basic.slug) + 'SecurityTest';
  
  return `<?php
/**
 * Security Tests for ${testData.basic.name}
 */

namespace Tests\\Security;

use Tests\\Security\\SecurityTestBase;

class ${className} extends SecurityTestBase
{
    public function test_admin_pages_require_capabilities()
    {
        ${generateAdminCapabilityTests(testData.functionality.admin_pages)}
    }
    
    public function test_ajax_actions_are_secure()
    {
        ${generateAjaxSecurityTests(testData.functionality.ajax_actions)}
    }
    
    public function test_shortcodes_prevent_xss()
    {
        ${generateShortcodeSecurityTests(testData.functionality.shortcodes)}
    }
    
    public function test_rest_endpoints_are_protected()
    {
        ${generateRestSecurityTests(testData.functionality.rest_routes)}
    }
}`;
}

function generateE2ETest(testData) {
  return `import { test, expect } from '@playwright/test';

test.describe('${testData.basic.name} E2E Tests', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://localhost';
  
  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto(\`\${baseUrl}/wp-login.php\`);
    await page.fill('#user_login', 'admin');
    await page.fill('#user_pass', 'password');
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
  });

  ${generateAdminE2ETests(testData.functionality.admin_pages)}
  
  ${generateFrontendE2ETests(testData.functionality.shortcodes)}
  
  test('plugin should not break site functionality', async ({ page }) => {
    await page.goto(\`\${baseUrl}/\`);
    await expect(page.locator('body')).toBeVisible();
    
    // Check for JavaScript errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    
    await page.reload();
    expect(errors.length).toBe(0);
  });
});`;
}

// Helper functions for generating specific test sections
function generateShortcodeUnitTests(shortcodes) {
  if (!shortcodes.length) return '';
  
  return shortcodes.map(shortcode => `
    public function test_${shortcode}_shortcode_exists()
    {
        $this->assertTrue(shortcode_exists('${shortcode}'));
    }`).join('\n');
}

function generateHookUnitTests(hooks) {
  if (!hooks.actions?.length && !hooks.filters?.length) return '';
  
  let tests = '';
  
  if (hooks.actions?.length > 0) {
    tests += `
    public function test_action_hooks_are_registered()
    {
        $actions = [${hooks.actions.map(a => `'${a}'`).join(', ')}];
        foreach ($actions as $action) {
            $this->assertTrue(has_action($action) !== false, "Action $action should be registered");
        }
    }`;
  }
  
  if (hooks.filters?.length > 0) {
    tests += `
    public function test_filter_hooks_are_registered()
    {
        $filters = [${hooks.filters.map(f => `'${f}'`).join(', ')}];
        foreach ($filters as $filter) {
            $this->assertTrue(has_filter($filter) !== false, "Filter $filter should be registered");
        }
    }`;
  }
  
  return tests;
}

function generateDatabaseIntegrationTests(tables) {
  if (!tables.length) return '';
  
  return `
    public function test_database_tables_exist()
    {
        global $wpdb;
        $tables = [${tables.map(t => `'${t}'`).join(', ')}];
        
        foreach ($tables as $table) {
            $result = $wpdb->get_var("SHOW TABLES LIKE '$table'");
            $this->assertEquals($table, $result, "Table $table should exist");
        }
    }`;
}

function generatePostTypeIntegrationTests(postTypes) {
  if (!postTypes.length) return '';
  
  return `
    public function test_custom_post_types_are_registered()
    {
        $post_types = [${postTypes.map(pt => `'${pt.name}'`).join(', ')}];
        
        foreach ($post_types as $post_type) {
            $this->assertTrue(post_type_exists($post_type), "Post type $post_type should be registered");
        }
    }`;
}

function generateSettingsIntegrationTests(settings) {
  if (!settings.length) return '';
  
  return `
    public function test_plugin_settings_exist()
    {
        $settings = [${settings.map(s => `'${s.name}'`).join(', ')}];
        
        foreach ($settings as $setting) {
            $this->assertNotNull(get_option($setting), "Setting $setting should exist");
        }
    }`;
}

function generateAdminCapabilityTests(adminPages) {
  if (!adminPages.length) return '';
  
  return adminPages.map(page => `
        // Test ${page.title} requires ${page.capability}
        $this->assertUserCanAccess('${page.slug}', '${page.capability}');`).join('\n');
}

function generateAjaxSecurityTests(ajaxActions) {
  if (!ajaxActions.length) return '';
  
  return ajaxActions.map(action => `
        // Test AJAX action ${action} is secure
        $this->assertAjaxActionRequiresNonce('${action}');`).join('\n');
}

function generateShortcodeSecurityTests(shortcodes) {
  if (!shortcodes.length) return '';
  
  return shortcodes.map(shortcode => `
        // Test shortcode ${shortcode} prevents XSS
        $this->assertShortcodeEscapesOutput('${shortcode}');`).join('\n');
}

function generateRestSecurityTests(restRoutes) {
  if (!restRoutes.length) return '';
  
  return restRoutes.map(route => `
        // Test REST route ${route.route} is protected
        $this->assertRestRouteRequiresAuth('${route.route}');`).join('\n');
}

function generateAdminE2ETests(adminPages) {
  if (!adminPages.length) return '';
  
  return adminPages.map(page => `
  test('${page.title.toLowerCase()} admin page should load', async ({ page }) => {
    await page.goto(\`\${baseUrl}/wp-admin/admin.php?page=${page.slug}\`);
    await expect(page.locator('h1')).toContainText('${page.title}');
  });`).join('\n');
}

function generateFrontendE2ETests(shortcodes) {
  if (!shortcodes.length) return '';
  
  return shortcodes.map(shortcode => `
  test('[${shortcode}] shortcode should render', async ({ page }) => {
    // Create a test post with the shortcode
    const postId = await page.evaluate(() => {
      return wp.ajax.post('create-test-post', {
        title: 'Test ${shortcode} Shortcode',
        content: '[${shortcode}]'
      });
    });
    
    await page.goto(\`\${baseUrl}/?p=\${postId}\`);
    await expect(page.locator('article')).toBeVisible();
  });`).join('\n');
}

function generateBugChecklist(testData) {
  const checklist = [];
  checklist.push(`# ${testData.basic.name} - Automated Bug Detection Checklist`);
  checklist.push(`**Plugin:** ${testData.basic.slug} v${testData.basic.version}`);
  checklist.push(`**Complexity Level:** ${testData.complexity.level}`);
  checklist.push(`**Generated:** ${new Date().toISOString()}`);
  checklist.push('');
  
  // Critical security issues first
  if (testData.priorities.critical.length > 0) {
    checklist.push('## 🚨 CRITICAL Security Issues (Fix Immediately)');
    
    // Specific security issues detected
    if (testData.advanced.security_patterns) {
      const security = testData.advanced.security_patterns;
      
      if (security.sql_injection_risks?.length > 0) {
        checklist.push('- [ ] **SQL Injection Risk Detected**');
        checklist.push(`  - Files affected: ${security.sql_injection_risks.join(', ')}`);
        checklist.push('  - Test: Verify all database queries use prepared statements');
        checklist.push('  - Test: Try SQL injection payloads in all input fields');
      }
      
      if (security.xss_vulnerabilities?.length > 0) {
        checklist.push('- [ ] **XSS Vulnerability Detected**');
        checklist.push(`  - Files affected: ${security.xss_vulnerabilities.join(', ')}`);
        checklist.push('  - Test: All user input must be escaped before output');
        checklist.push('  - Test: Try XSS payloads: <script>alert(1)</script>, javascript:alert(1)');
      }
      
      if (security.user_input_sanitization?.length > 0) {
        checklist.push('- [ ] **Input Sanitization Issues**');
        checklist.push(`  - Files affected: ${security.user_input_sanitization.join(', ')}`);
        checklist.push('  - Test: Verify sanitize_text_field, sanitize_email, wp_kses usage');
        checklist.push('  - Test: Submit malicious input to all forms');
      }
      
      if (security.capability_checks?.length > 0) {
        checklist.push('- [ ] **Missing Capability Checks**');
        checklist.push(`  - Files affected: ${security.capability_checks.join(', ')}`);
        checklist.push('  - Test: Try accessing admin functions as non-admin user');
        checklist.push('  - Test: Verify current_user_can() usage in all sensitive operations');
      }
      
      if (security.nonce_verification?.length > 0) {
        checklist.push('- [ ] **CSRF Protection Missing**');
        checklist.push(`  - Files affected: ${security.nonce_verification.join(', ')}`);
        checklist.push('  - Test: Submit forms without nonce verification');
        checklist.push('  - Test: Try CSRF attacks on AJAX endpoints');
      }
      
      if (security.direct_file_access?.length > 0) {
        checklist.push('- [ ] **Direct File Access Vulnerability**');
        checklist.push(`  - Files affected: ${security.direct_file_access.join(', ')}`);
        checklist.push('  - Test: Try accessing PHP files directly via URL');
        checklist.push('  - Test: Verify ABSPATH checks in all PHP files');
      }
    }
    checklist.push('');
  }
  
  checklist.push('## ✅ Basic Functionality Tests');
  checklist.push('- [ ] Plugin activates without errors');
  checklist.push('- [ ] Plugin deactivates cleanly');
  checklist.push('- [ ] No PHP errors/warnings in logs');
  checklist.push('- [ ] No JavaScript console errors');
  checklist.push('- [ ] Settings save correctly');
  checklist.push('- [ ] Plugin doesn\'t break site when activated');
  checklist.push('');
  
  // Enhanced security checklist based on analysis
  checklist.push('## 🔒 Security Testing (Based on Code Analysis)');
  checklist.push('- [ ] All user inputs are properly sanitized');
  checklist.push('- [ ] SQL queries use prepared statements ($wpdb->prepare)');
  checklist.push('- [ ] CSRF protection on all forms and AJAX calls');
  checklist.push('- [ ] Capability checks on all admin functions');
  checklist.push('- [ ] File uploads are secured and validated');
  checklist.push('- [ ] Direct file access is blocked (ABSPATH check)');
  checklist.push('- [ ] Output is escaped to prevent XSS');
  checklist.push('');
  
  if (testData.functionality.admin_pages.length > 0) {
    checklist.push('## 👑 Admin Interface');
    testData.functionality.admin_pages.forEach(page => {
      checklist.push(`- [ ] ${page.title} page loads correctly`);
      checklist.push(`- [ ] ${page.title} requires ${page.capability} capability`);
      checklist.push(`- [ ] ${page.title} forms work properly`);
    });
    checklist.push('');
  }
  
  if (testData.functionality.rest_routes.length > 0) {
    checklist.push('## 🌐 REST API');
    testData.functionality.rest_routes.forEach(route => {
      checklist.push(`- [ ] ${route.route} responds correctly`);
      checklist.push(`- [ ] ${route.route} validates permissions`);
      checklist.push(`- [ ] ${route.route} handles errors gracefully`);
    });
    checklist.push('');
  }
  
  if (testData.functionality.shortcodes.length > 0) {
    checklist.push('## 📝 Shortcodes');
    testData.functionality.shortcodes.forEach(shortcode => {
      checklist.push(`- [ ] [${shortcode}] renders correctly`);
      checklist.push(`- [ ] [${shortcode}] handles invalid attributes`);
      checklist.push(`- [ ] [${shortcode}] escapes output properly`);
    });
    checklist.push('');
  }
  
  // Performance issues based on analysis
  checklist.push('## ⚡ Performance Testing (Based on Code Analysis)');
  
  if (testData.advanced.performance_indicators) {
    const perf = testData.advanced.performance_indicators;
    
    // Database query analysis
    const totalQueries = Object.values(perf.database_queries || {}).reduce((a, b) => a + b, 0);
    if (totalQueries > 10) {
      checklist.push('- [ ] **High Database Query Count Detected**');
      checklist.push(`  - Total queries: ${totalQueries}`);
      checklist.push('  - Test: Measure page load time before/after plugin activation');
      checklist.push('  - Test: Use Query Monitor to check for slow queries');
    }
    
    // Remote request analysis
    const totalRemoteRequests = Object.values(perf.remote_requests || {}).reduce((a, b) => a + b, 0);
    if (totalRemoteRequests > 3) {
      checklist.push('- [ ] **Multiple External API Calls Detected**');
      checklist.push(`  - Total remote requests: ${totalRemoteRequests}`);
      checklist.push('  - Test: Check if external APIs timeout gracefully');
      checklist.push('  - Test: Verify caching of external API responses');
    }
    
    // File operation analysis
    const totalFileOps = Object.values(perf.file_operations || {}).reduce((a, b) => a + b, 0);
    if (totalFileOps > 5) {
      checklist.push('- [ ] **High File I/O Operations Detected**');
      checklist.push(`  - Total file operations: ${totalFileOps}`);
      checklist.push('  - Test: Monitor disk I/O during plugin operations');
      checklist.push('  - Test: Check for unnecessary file reads/writes');
    }
    
    // Caching analysis
    const cachingUsage = Object.keys(perf.caching_usage || {}).length;
    if (cachingUsage === 0 && (totalQueries > 5 || totalRemoteRequests > 2)) {
      checklist.push('- [ ] **No Caching Implementation Found**');
      checklist.push('  - Recommendation: Implement wp_cache_* or transient caching');
      checklist.push('  - Test: Verify repeated operations are cached');
    }
  }
  
  checklist.push('- [ ] Plugin doesn\'t slow down site significantly (< 100ms impact)');
  checklist.push('- [ ] Database queries are optimized and use proper indexes');
  checklist.push('- [ ] Assets are minified and cached properly');
  checklist.push('- [ ] No memory leaks detected during extended usage');
  checklist.push('- [ ] Plugin loads only necessary assets on each page');
  checklist.push('');
  
  // Code quality and best practices issues
  checklist.push('## 🏗️ Code Quality Issues (Based on Analysis)');
  
  if (testData.advanced.best_practices) {
    const practices = testData.advanced.best_practices;
    
    if (!practices.has_plugin_header) {
      checklist.push('- [ ] **Missing Plugin Header**');
      checklist.push('  - Test: Plugin should have proper header with name, version, description');
    }
    
    if (!practices.enqueues_scripts_properly) {
      checklist.push('- [ ] **Improper Script Enqueuing**');
      checklist.push('  - Test: Scripts should use wp_enqueue_script, not hardcoded includes');
      checklist.push('  - Test: Check for script conflicts with other plugins');
    }
    
    if (!practices.localizes_scripts) {
      checklist.push('- [ ] **Missing Script Localization**');
      checklist.push('  - Test: JavaScript should access WordPress data via wp_localize_script');
      checklist.push('  - Test: Check for hardcoded AJAX URLs or admin paths');
    }
    
    if (!practices.has_uninstall_hook) {
      checklist.push('- [ ] **Missing Uninstall Hook**');
      checklist.push('  - Test: Plugin should clean up data when uninstalled');
      checklist.push('  - Test: Verify register_uninstall_hook or uninstall.php exists');
    }
    
    if (!practices.has_readme) {
      checklist.push('- [ ] **Missing Documentation**');
      checklist.push('  - Test: Plugin should have readme.txt or README.md');
      checklist.push('  - Test: Documentation should be clear and complete');
    }
    
    if (!practices.follows_directory_structure) {
      checklist.push('- [ ] **Poor Directory Structure**');
      checklist.push('  - Test: Plugin should follow WordPress plugin structure');
      checklist.push('  - Test: Check for proper separation of admin, public, includes');
    }
  }
  
  // Complexity-based issues
  if (testData.advanced.complexity_metrics) {
    const complexity = testData.advanced.complexity_metrics.cyclomatic_complexity || 0;
    if (complexity > 100) {
      checklist.push('- [ ] **High Cyclomatic Complexity Detected**');
      checklist.push(`  - Complexity score: ${complexity}`);
      checklist.push('  - Test: Focus testing on complex code paths');
      checklist.push('  - Test: Verify edge cases in complex functions');
    }
    
    const maxParams = Math.max(...(testData.advanced.complexity_metrics.function_parameters || [0]));
    if (maxParams > 7) {
      checklist.push('- [ ] **Functions with Too Many Parameters**');
      checklist.push(`  - Max parameters: ${maxParams}`);
      checklist.push('  - Test: Check for parameter validation in complex functions');
    }
  }
  
  checklist.push('');
  
  checklist.push('## 🌍 Compatibility Testing');
  checklist.push('- [ ] Works with latest WordPress version');
  checklist.push('- [ ] Compatible with popular themes (Twenty Twenty-Three, Astra, etc.)');
  checklist.push('- [ ] Works with other common plugins (WooCommerce, Yoast SEO, etc.)');
  checklist.push('- [ ] Mobile-responsive if applicable');
  checklist.push('- [ ] Works in multisite environment');
  checklist.push('- [ ] Compatible with different PHP versions (7.4+)');
  checklist.push('- [ ] Works with different MySQL versions');
  checklist.push('');
  
  return checklist.join('\n');
}

function calculateTestingEffort(testData) {
  let effort = {
    critical: 0,
    core: 0,
    integration: 0,
    performance: 0,
    security: 0
  };
  
  // Critical issues require immediate attention
  if (testData.priorities.critical) {
    effort.critical = testData.priorities.critical.length * 4; // 4 hours per critical issue
  }
  
  // Core functionality testing
  effort.core += testData.functionality.admin_pages.length * 2; // 2 hours per admin page
  effort.core += testData.functionality.rest_routes.length * 3; // 3 hours per REST route
  effort.core += testData.functionality.shortcodes.length * 1; // 1 hour per shortcode
  effort.core += testData.functionality.ajax_actions.length * 2; // 2 hours per AJAX action
  effort.core += testData.data.database_tables.length * 3; // 3 hours per database table
  
  // Integration testing effort based on complexity
  const complexityMultiplier = testData.complexity.score > 70 ? 2 : testData.complexity.score > 35 ? 1.5 : 1;
  effort.integration = Math.round((effort.core * 0.5) * complexityMultiplier);
  
  // Performance testing
  if (testData.advanced.performance_indicators) {
    const perf = testData.advanced.performance_indicators;
    const totalQueries = Object.values(perf.database_queries || {}).reduce((a, b) => a + b, 0);
    const totalRemoteRequests = Object.values(perf.remote_requests || {}).reduce((a, b) => a + b, 0);
    
    effort.performance = Math.round((totalQueries * 0.25) + (totalRemoteRequests * 0.5) + 4); // Base 4 hours
  } else {
    effort.performance = 4; // Base performance testing
  }
  
  // Security testing based on detected issues
  if (testData.advanced.security_patterns) {
    const securityIssues = Object.values(testData.advanced.security_patterns).flat().length;
    effort.security = Math.max(8, securityIssues * 2); // Minimum 8 hours, 2 hours per issue
  } else {
    effort.security = 8; // Base security testing
  }
  
  effort.total = effort.critical + effort.core + effort.integration + effort.performance + effort.security;
  
  return effort;
}

function generateFeatureReport(testData) {
  const report = [];
  report.push(`# ${testData.basic.name} - Comprehensive Feature Analysis Report`);
  report.push(`**Plugin:** ${testData.basic.slug} v${testData.basic.version}`);
  report.push(`**Analysis Date:** ${new Date().toISOString()}`);
  report.push(`**Complexity Level:** ${testData.complexity.level} (${testData.complexity.score} points)`);
  report.push('');
  
  // Executive Summary
  report.push('## 📋 Executive Summary');
  report.push('This comprehensive analysis evaluates all aspects of the plugin including:');
  report.push('- ✅ **Functional Features** - Core plugin capabilities');
  report.push('- 🔍 **Code Quality** - Technical implementation analysis');
  report.push('- 🔒 **Security Assessment** - Vulnerability and risk analysis');
  report.push('- ⚡ **Performance Impact** - Resource usage and optimization');
  report.push('- 🏗️ **Architecture Review** - Structure and best practices');
  report.push('- 📊 **Testing Strategy** - Recommended testing approach');
  report.push('');
  
  // Risk Assessment
  const riskLevel = calculateRiskLevel(testData);
  report.push('## 🚨 Risk Assessment');
  report.push(`**Overall Risk Level:** ${riskLevel.level}`);
  report.push(`**Risk Score:** ${riskLevel.score}/100`);
  report.push('');
  report.push('### Risk Breakdown:');
  Object.entries(riskLevel.breakdown).forEach(([category, score]) => {
    const level = score > 70 ? 'HIGH' : score > 40 ? 'MEDIUM' : 'LOW';
    report.push(`- **${category}:** ${score}/100 (${level})`);
  });
  report.push('');
  
  // Plugin Overview
  report.push('## 📊 Plugin Overview');
  report.push(`- **Name:** ${testData.basic.name}`);
  report.push(`- **Slug:** ${testData.basic.slug}`);
  report.push(`- **Version:** ${testData.basic.version}`);
  report.push(`- **Status:** ${testData.basic.active ? '✅ Active' : '❌ Inactive'}`);
  report.push(`- **Path:** ${testData.basic.path}`);
  report.push('');
  
  // Complexity Analysis (Enhanced)
  report.push('## 🧮 Complexity Analysis');
  report.push(`- **Overall Score:** ${testData.complexity.score} (${testData.complexity.level})`);
  report.push(`- **Functional Complexity:** ${testData.complexity.details.functional_complexity}`);
  report.push(`- **Code Complexity:** ${testData.complexity.details.code_complexity}`);
  report.push(`- **Security Complexity:** ${testData.complexity.details.security_complexity}`);
  report.push(`- **Performance Complexity:** ${testData.complexity.details.performance_complexity}`);
  report.push('');
  
  if (testData.complexity.recommendations.length > 0) {
    report.push('### 💡 Complexity Recommendations:');
    testData.complexity.recommendations.forEach(rec => {
      report.push(`- ${rec}`);
    });
    report.push('');
  }
  
  // Architecture Analysis (Enhanced)
  report.push('## 🏗️ Architecture Analysis');
  report.push(`- **Admin Interface:** ${testData.architecture.has_admin ? '✅ Yes' : '❌ No'}`);
  report.push(`- **Public Interface:** ${testData.architecture.has_public ? '✅ Yes' : '❌ No'}`);
  report.push(`- **Include Files:** ${testData.architecture.has_includes ? '✅ Yes' : '❌ No'}`);
  report.push(`- **Assets Directory:** ${testData.architecture.has_assets ? '✅ Yes' : '❌ No'}`);
  report.push(`- **Existing Tests:** ${testData.architecture.has_tests ? '✅ Yes' : '❌ No'}`);
  report.push('');
  
  // Code Quality Analysis
  if (testData.advanced.code_quality && Object.keys(testData.advanced.code_quality).length > 0) {
    report.push('## 📝 Code Quality Analysis');
    const cq = testData.advanced.code_quality;
    report.push(`- **Total Files:** ${cq.total_files || 0}`);
    report.push(`- **PHP Files:** ${cq.php_files || 0}`);
    report.push(`- **JavaScript Files:** ${cq.js_files || 0}`);
    report.push(`- **CSS Files:** ${cq.css_files || 0}`);
    report.push(`- **Total Lines of Code:** ${cq.total_lines || 0}`);
    report.push(`- **Commented Lines:** ${cq.commented_lines || 0} (${Math.round(((cq.commented_lines || 0) / (cq.total_lines || 1)) * 100)}%)`);
    report.push(`- **Functions:** ${cq.functions_count || 0}`);
    report.push(`- **Classes:** ${cq.classes_count || 0}`);
    report.push('');
  }
  
  // Security Analysis
  if (testData.advanced.security_patterns && Object.keys(testData.advanced.security_patterns).length > 0) {
    report.push('## 🔒 Security Analysis');
    const security = testData.advanced.security_patterns;
    
    const totalIssues = Object.values(security).reduce((total, issues) => {
      return total + (Array.isArray(issues) ? issues.length : 0);
    }, 0);
    
    if (totalIssues > 0) {
      report.push(`**⚠️ Total Security Issues Found:** ${totalIssues}`);
      report.push('');
      
      if (security.sql_injection_risks?.length > 0) {
        report.push(`- **🚨 SQL Injection Risks:** ${security.sql_injection_risks.length}`);
        report.push(`  - Files: ${security.sql_injection_risks.join(', ')}`);
      }
      if (security.xss_vulnerabilities?.length > 0) {
        report.push(`- **🚨 XSS Vulnerabilities:** ${security.xss_vulnerabilities.length}`);
        report.push(`  - Files: ${security.xss_vulnerabilities.join(', ')}`);
      }
      if (security.user_input_sanitization?.length > 0) {
        report.push(`- **⚠️ Input Sanitization Issues:** ${security.user_input_sanitization.length}`);
        report.push(`  - Files: ${security.user_input_sanitization.join(', ')}`);
      }
      if (security.capability_checks?.length > 0) {
        report.push(`- **⚠️ Missing Capability Checks:** ${security.capability_checks.length}`);
        report.push(`  - Files: ${security.capability_checks.join(', ')}`);
      }
      if (security.nonce_verification?.length > 0) {
        report.push(`- **⚠️ Missing CSRF Protection:** ${security.nonce_verification.length}`);
        report.push(`  - Files: ${security.nonce_verification.join(', ')}`);
      }
      if (security.direct_file_access?.length > 0) {
        report.push(`- **⚠️ Direct File Access Risks:** ${security.direct_file_access.length}`);
        report.push(`  - Files: ${security.direct_file_access.join(', ')}`);
      }
    } else {
      report.push('**✅ No obvious security issues detected in code analysis**');
    }
    report.push('');
  }
  
  // Performance Analysis
  if (testData.advanced.performance_indicators && Object.keys(testData.advanced.performance_indicators).length > 0) {
    report.push('## ⚡ Performance Analysis');
    const perf = testData.advanced.performance_indicators;
    
    const totalQueries = Object.values(perf.database_queries || {}).reduce((a, b) => a + b, 0);
    const totalRemoteRequests = Object.values(perf.remote_requests || {}).reduce((a, b) => a + b, 0);
    const totalFileOps = Object.values(perf.file_operations || {}).reduce((a, b) => a + b, 0);
    const cachingFiles = Object.keys(perf.caching_usage || {}).length;
    
    report.push(`- **Database Queries:** ${totalQueries} ${totalQueries > 10 ? '⚠️ HIGH' : totalQueries > 5 ? '🟡 MEDIUM' : '✅ LOW'}`);
    report.push(`- **Remote API Calls:** ${totalRemoteRequests} ${totalRemoteRequests > 5 ? '⚠️ HIGH' : totalRemoteRequests > 2 ? '🟡 MEDIUM' : '✅ LOW'}`);
    report.push(`- **File Operations:** ${totalFileOps} ${totalFileOps > 10 ? '⚠️ HIGH' : totalFileOps > 5 ? '🟡 MEDIUM' : '✅ LOW'}`);
    report.push(`- **Caching Implementation:** ${cachingFiles > 0 ? '✅ Yes' : '❌ No'} (${cachingFiles} files)`);
    report.push('');
    
    if (Object.keys(perf.database_queries || {}).length > 0) {
      report.push('### Database Query Distribution:');
      Object.entries(perf.database_queries).forEach(([file, count]) => {
        report.push(`- **${file}:** ${count} queries`);
      });
      report.push('');
    }
  }
  
  // Feature Analysis
  report.push('## 🎯 Feature Analysis');
  
  const features = testData.functionality;
  
  if (features.hooks.actions.length || features.hooks.filters.length) {
    report.push(`### WordPress Hooks`);
    report.push(`- **Actions:** ${features.hooks.actions.length}`);
    report.push(`- **Filters:** ${features.hooks.filters.length}`);
    report.push('');
  }
  
  if (features.shortcodes.length) {
    report.push(`### Shortcodes (${features.shortcodes.length})`);
    features.shortcodes.forEach(sc => report.push(`- [${sc}]`));
    report.push('');
  }
  
  if (features.ajax_actions.length) {
    report.push(`### AJAX Actions (${features.ajax_actions.length})`);
    features.ajax_actions.forEach(action => report.push(`- ${action}`));
    report.push('');
  }
  
  if (features.rest_routes.length) {
    report.push(`### REST API Routes (${features.rest_routes.length})`);
    features.rest_routes.forEach(route => {
      report.push(`- **${route.route}** (${route.methods.join(', ')})`);
    });
    report.push('');
  }
  
  if (features.admin_pages.length) {
    report.push(`### Admin Pages (${features.admin_pages.length})`);
    features.admin_pages.forEach(page => {
      report.push(`- **${page.title}** (${page.capability})`);
    });
    report.push('');
  }
  
  if (features.post_types.length) {
    report.push(`### Custom Post Types (${features.post_types.length})`);
    features.post_types.forEach(pt => {
      report.push(`- **${pt.label}** (${pt.name})`);
    });
    report.push('');
  }
  
  if (features.widgets.length) {
    report.push(`### Widgets (${features.widgets.length})`);
    features.widgets.forEach(widget => {
      report.push(`- **${widget.name}** (${widget.class})`);
    });
    report.push('');
  }
  
  if (features.blocks.length) {
    report.push(`### Gutenberg Blocks (${features.blocks.length})`);
    features.blocks.forEach(block => {
      report.push(`- **${block.title}** (${block.name})`);
    });
    report.push('');
  }
  
  // Data Management
  if (testData.data.database_tables.length || testData.data.settings.length) {
    report.push('## 💾 Data Management');
    
    if (testData.data.database_tables.length) {
      report.push(`### Database Tables (${testData.data.database_tables.length})`);
      testData.data.database_tables.forEach(table => report.push(`- ${table}`));
      report.push('');
    }
    
    if (testData.data.settings.length) {
      report.push(`### Settings (${testData.data.settings.length})`);
      testData.data.settings.forEach(setting => report.push(`- ${setting.name}`));
      report.push('');
    }
  }
  
  // API Usage Analysis
  if (testData.advanced.api_usage && Object.keys(testData.advanced.api_usage).length > 0) {
    report.push('## 🔌 API Usage Analysis');
    const api = testData.advanced.api_usage;
    
    if (api.wordpress_apis?.length > 0) {
      report.push(`### WordPress APIs Used (${api.wordpress_apis.length})`);
      api.wordpress_apis.forEach(apiName => {
        report.push(`- ${apiName}`);
      });
      report.push('');
    }
    
    if (api.rest_endpoints?.length > 0) {
      report.push(`### Custom REST Endpoints (${api.rest_endpoints.length})`);
      api.rest_endpoints.forEach(endpoint => {
        report.push(`- ${endpoint}`);
      });
      report.push('');
    }
    
    if (api.ajax_handlers?.length > 0) {
      report.push(`### AJAX Handlers (${api.ajax_handlers.length})`);
      api.ajax_handlers.forEach(handler => {
        report.push(`- wp_ajax_${handler}`);
      });
      report.push('');
    }
    
    if (api.cron_jobs?.length > 0) {
      report.push(`### Scheduled Tasks (${api.cron_jobs.length})`);
      api.cron_jobs.forEach(job => {
        report.push(`- ${job}`);
      });
      report.push('');
    }
  }
  
  // Best Practices Analysis
  if (testData.advanced.best_practices && Object.keys(testData.advanced.best_practices).length > 0) {
    report.push('## 📋 WordPress Best Practices Compliance');
    const practices = testData.advanced.best_practices;
    
    const practiceItems = [
      { key: 'has_plugin_header', label: 'Plugin Header', critical: true },
      { key: 'enqueues_scripts_properly', label: 'Proper Script Enqueuing', critical: true },
      { key: 'localizes_scripts', label: 'Script Localization', critical: false },
      { key: 'has_uninstall_hook', label: 'Uninstall Hook', critical: false },
      { key: 'has_readme', label: 'Documentation (README)', critical: false },
      { key: 'follows_directory_structure', label: 'Standard Directory Structure', critical: false }
    ];
    
    practiceItems.forEach(item => {
      const status = practices[item.key];
      const icon = status ? '✅' : (item.critical ? '❌' : '⚠️');
      report.push(`- ${icon} **${item.label}:** ${status ? 'Compliant' : 'Non-compliant'}`);
    });
    report.push('');
  }
  
  // Testing Strategy Recommendations
  report.push('## 🎯 Comprehensive Testing Strategy');
  report.push('');
  
  if (testData.priorities.critical && testData.priorities.critical.length > 0) {
    report.push('### 🚨 CRITICAL Priority Tests (Fix Immediately)');
    testData.priorities.critical.forEach(item => report.push(`- ${item}`));
    report.push('');
  }
  
  report.push('### ✅ High Priority Tests');
  testData.priorities.high.forEach(item => report.push(`- ${item}`));
  report.push('');
  
  report.push('### 🟡 Medium Priority Tests');
  testData.priorities.medium.forEach(item => report.push(`- ${item}`));
  report.push('');
  
  report.push('### 🔵 Low Priority Tests');
  testData.priorities.low.forEach(item => report.push(`- ${item}`));
  report.push('');
  
  // Testing Tools Recommendations
  report.push('## 🛠️ Recommended Testing Tools & Approaches');
  report.push('');
  
  report.push('### Unit & Integration Testing');
  report.push('- **PHPUnit** - For PHP unit and integration tests');
  report.push('- **WP_UnitTestCase** - For WordPress-specific testing');
  report.push('- **Mockery** - For mocking dependencies');
  report.push('');
  
  if (features.rest_routes.length > 0) {
    report.push('### API Testing');
    report.push('- **Postman/Newman** - For REST API testing');
    report.push('- **WP-CLI** - For command-line testing');
    report.push('- **PHPUnit HTTP Tests** - For programmatic API testing');
    report.push('');
  }
  
  if (features.blocks.length > 0 || testData.architecture.has_public) {
    report.push('### End-to-End Testing');
    report.push('- **Playwright** - For cross-browser E2E testing');
    report.push('- **BackstopJS** - For visual regression testing');
    report.push('- **Lighthouse CI** - For performance testing');
    report.push('');
  }
  
  if (testData.advanced.security_patterns && Object.values(testData.advanced.security_patterns).some(issues => Array.isArray(issues) && issues.length > 0)) {
    report.push('### Security Testing');
    report.push('- **WPScan** - For WordPress vulnerability scanning');
    report.push('- **OWASP ZAP** - For web application security testing');
    report.push('- **PHP Security Checker** - For dependency vulnerability scanning');
    report.push('');
  }
  
  // Estimated Testing Effort
  report.push('## ⏱️ Estimated Testing Effort');
  const effort = calculateTestingEffort(testData);
  report.push(`- **Total Estimated Hours:** ${effort.total}`);
  report.push(`- **Critical Issues:** ${effort.critical} hours`);
  report.push(`- **Core Functionality:** ${effort.core} hours`);
  report.push(`- **Integration Testing:** ${effort.integration} hours`);
  report.push(`- **Performance Testing:** ${effort.performance} hours`);
  report.push(`- **Security Testing:** ${effort.security} hours`);
  report.push('');
  
  // Next Steps
  report.push('## 🚀 Next Steps & Action Items');
  report.push('');
  
  if (testData.priorities.critical && testData.priorities.critical.length > 0) {
    report.push('### Immediate Actions Required:');
    report.push('1. **Address all CRITICAL security issues** - These pose immediate risks');
    report.push('2. **Review and fix security vulnerabilities** - Before any public release');
    report.push('3. **Implement proper input validation** - For all user inputs');
    report.push('');
  }
  
  report.push('### Short Term (1-2 weeks):');
  report.push('1. Implement automated unit testing suite');
  report.push('2. Set up continuous integration pipeline');
  report.push('3. Address high-priority functional issues');
  report.push('4. Implement performance monitoring');
  report.push('');
  
  report.push('### Medium Term (1-2 months):');
  report.push('1. Complete comprehensive test coverage');
  report.push('2. Implement end-to-end testing');
  report.push('3. Conduct thorough compatibility testing');
  report.push('4. Optimize performance bottlenecks');
  report.push('');
  
  report.push('### Long Term (Ongoing):');
  report.push('1. Regular security audits and updates');
  report.push('2. Performance monitoring and optimization');
  report.push('3. Compatibility testing with new WordPress versions');
  report.push('4. User feedback integration and testing');
  report.push('');
  
  return report.join('\n');
}

// Utility functions
function pascalCase(str) {
  if (!str) return 'Unknown';
  return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function(word, index) {
    return index === 0 ? word.toLowerCase() : word.toUpperCase();
  }).replace(/\s+/g, '').replace(/[-_]/g, '');
}

// ---------- Main Execution ----------
console.log(`🚀 Universal WordPress Plugin Test Generator`);
console.log(`📦 Plugin: ${plugin.name} (${plugin.slug})`);
console.log(`📁 Output: ${outDir}`);

const testSuite = generateTestSuite();

// Write all generated files
Object.entries(testSuite.testFiles).forEach(([filename, content]) => {
  writeFile(path.join(outDir, filename), content);
});

// Write documentation files
writeFile(path.join(outDir, 'TEST-PLAN.md'), testSuite.testPlan);
writeFile(path.join(outDir, 'BUG-CHECKLIST.md'), testSuite.bugChecklist);
writeFile(path.join(outDir, 'FEATURE-REPORT.md'), testSuite.featureReport);

// Write test data for reference
writeFile(path.join(outDir, 'plugin-analysis.json'), 
  JSON.stringify(testSuite.testData, null, 2));

console.log('');
console.log('🎉 Universal test suite generated successfully!');
console.log('');
console.log('📋 Generated Files:');
console.log('  - TEST-PLAN.md (comprehensive test strategy)');
console.log('  - BUG-CHECKLIST.md (manual testing checklist)');
console.log('  - FEATURE-REPORT.md (plugin analysis report)');
console.log('  - Unit/PluginTest.php (unit tests)');
console.log('  - Integration/PluginIntegrationTest.php (WordPress integration tests)');
console.log('  - Security/PluginSecurityTest.php (security tests)');
console.log('  - e2e/plugin.spec.ts (end-to-end tests)');
console.log('');
console.log('📊 Plugin Analysis:');
console.log(`  - Complexity: ${testSuite.testData.complexity.level} (${testSuite.testData.complexity.score} points)`);
console.log(`  - High Priority Tests: ${testSuite.testData.priorities.high.length}`);
console.log(`  - Total Features: ${Object.values(testSuite.testData.functionality).flat().length}`);
console.log('');
console.log('🧪 Next Steps:');
console.log('  1. Review generated test plan and customize as needed');
console.log('  2. Run: npm run test:unit');
console.log('  3. Run: npm run test:integration');
console.log('  4. Run: npm run test:e2e');
console.log('  5. Use BUG-CHECKLIST.md for manual testing');
console.log('');