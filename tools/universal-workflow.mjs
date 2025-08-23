#!/usr/bin/env node
/**
 * Universal WordPress Plugin Testing Workflow
 * 
 * Complete end-to-end testing workflow for ANY WordPress plugin.
 * Orchestrates scanning, analysis, test generation, and execution.
 *
 * Usage:
 *   node tools/universal-workflow.mjs --plugin woocommerce --action scan
 *   node tools/universal-workflow.mjs --plugin woocommerce --action analyze  
 *   node tools/universal-workflow.mjs --plugin woocommerce --action generate
 *   node tools/universal-workflow.mjs --plugin woocommerce --action test
 *   node tools/universal-workflow.mjs --plugin woocommerce --action full
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { spawn, execSync } from 'node:child_process';

// ---------- Configuration ----------
const WORKFLOW_CONFIG = {
  scanDir: '../wp-content/uploads/wbcom-scan',
  planDir: '../wp-content/uploads/wbcom-plan',
  testDir: 'tests/generated',
  templatesDir: 'tests/templates',
  compatibilityDir: 'tests/compatibility',
  reportsDir: 'reports',
  logFile: 'workflow.log',
  
  // Dynamic paths based on plugin
  getPluginScanDir(pluginSlug) {
    return path.join(this.scanDir, pluginSlug);
  },
  
  getPluginTestResultsDir(pluginSlug) {
    return path.join(this.scanDir, pluginSlug, 'test-results');
  },
  
  getLearningModelPath(pluginSlug) {
    return path.join(this.planDir, 'models', 'test-patterns', `${pluginSlug}.json`);
  },
  
  getGenericModelPath() {
    return path.join(this.planDir, 'models', 'test-patterns', 'generic.json');
  }
};

// ---------- CLI args ----------
const args = process.argv;
const pluginSlug = argOf('--plugin', '');
const action = argOf('--action', 'full'); // scan, analyze, generate, test, full
const verbose = args.includes('--verbose');
const dryRun = args.includes('--dry-run');
const scanDirOverride = argOf('--scan-dir', '');

// Override scan directory if provided
if (scanDirOverride) {
  WORKFLOW_CONFIG.scanDir = scanDirOverride;
}

function argOf(flag, def) { 
  return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

// Validate required args
if (!pluginSlug) {
  console.error('❌ Plugin slug is required');
  console.error('Usage: node tools/universal-workflow.mjs --plugin <slug> [--action <action>]');
  console.error('Actions: scan, analyze, generate, test, full');
  console.error('Example: node tools/universal-workflow.mjs --plugin woocommerce --action full');
  process.exit(1);
}

// ---------- Utilities ----------
function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}`;
  console.log(logMessage);
  
  // Write to log file
  try {
    fs.appendFileSync(WORKFLOW_CONFIG.logFile, logMessage + '\\n');
  } catch (e) {
    // Silent fail for logging
  }
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    log(`📁 Created directory: ${dir}`);
  }
}

function fileExists(filePath) {
  return fs.existsSync(filePath);
}

function runCommand(command, description, options = {}) {
  log(`🔄 ${description}...`);
  
  if (dryRun) {
    log(`[DRY RUN] Would execute: ${command}`, 'DEBUG');
    return { success: true, output: 'DRY RUN MODE' };
  }
  
  try {
    const output = execSync(command, { 
      encoding: 'utf8', 
      stdio: verbose ? 'inherit' : 'pipe',
      ...options 
    });
    
    log(`✅ ${description} completed`);
    return { success: true, output };
  } catch (error) {
    log(`❌ ${description} failed: ${error.message}`, 'ERROR');
    return { success: false, error: error.message };
  }
}

async function runWorkflow() {
  log(`🚀 Starting Universal WordPress Plugin Testing Workflow`);
  log(`📦 Plugin: ${pluginSlug}`);
  log(`🎯 Action: ${action}`);
  log(`📁 Working Directory: ${process.cwd()}`);
  
  // Ensure required directories exist
  Object.values(WORKFLOW_CONFIG).forEach(dir => {
    if (dir.includes('/')) ensureDir(dir);
  });
  
  const results = {
    scan: { completed: false, duration: 0 },
    analyze: { completed: false, duration: 0 },
    generate: { completed: false, duration: 0 },
    test: { completed: false, duration: 0 },
    overall: { startTime: Date.now() }
  };
  
  try {
    switch (action) {
      case 'scan':
        await performScan(results);
        break;
      case 'analyze':
        await performAnalyze(results);
        break;
      case 'generate':
        await performGenerate(results);
        break;
      case 'test':
        await performTest(results);
        break;
      case 'full':
        await performFullWorkflow(results);
        break;
      default:
        throw new Error(`Unknown action: ${action}`);
    }
    
    // Generate final report
    await generateWorkflowReport(results);
    
    log(`✅ Workflow completed successfully!`);
    
  } catch (error) {
    log(`❌ Workflow failed: ${error.message}`, 'ERROR');
    process.exit(1);
  }
}

async function performScan(results) {
  const startTime = Date.now();
  log(`🔍 Phase 1: Scanning Plugin - ${pluginSlug}`);
  
  // Basic plugin scan
  const scanCmd = `wp scan plugins --slug=${pluginSlug}`;
  const scanResult = runCommand(
    scanCmd,
    `Scanning plugin ${pluginSlug}`,
    { cwd: process.cwd() }
  );
  
  if (!scanResult.success) {
    throw new Error(`Plugin scan failed: ${scanResult.error}`);
  }
  
  // Advanced code analysis
  const analyzeCmd = `wp scan analyze --slug=${pluginSlug}`;
  const analyzeResult = runCommand(
    analyzeCmd,
    `Performing advanced code analysis for ${pluginSlug}`,
    { cwd: process.cwd() }
  );
  
  if (!analyzeResult.success) {
    log(`⚠️ Advanced analysis failed, continuing with basic scan`, 'WARN');
  }
  
  // Verify scan files exist
  const expectedFiles = [
    `${WORKFLOW_CONFIG.scanDir}/plugin-${pluginSlug}.json`,
    `${WORKFLOW_CONFIG.scanDir}/site.json`
  ];
  
  const missingFiles = expectedFiles.filter(file => !fileExists(file));
  if (missingFiles.length > 0) {
    throw new Error(`Missing scan files: ${missingFiles.join(', ')}`);
  }
  
  results.scan.completed = true;
  results.scan.duration = Date.now() - startTime;
  log(`✅ Scan phase completed in ${results.scan.duration}ms`);
}

async function performAnalyze(results) {
  const startTime = Date.now();
  log(`🔍 Phase 2: Advanced Analysis - ${pluginSlug}`);
  
  const scanFile = `${WORKFLOW_CONFIG.scanDir}/plugin-${pluginSlug}.json`;
  
  if (!fileExists(scanFile)) {
    throw new Error(`Scan file not found: ${scanFile}. Run scan phase first.`);
  }
  
  // Generate compatibility analysis
  const compatCmd = `node tools/ai/compatibility-checker.mjs --plugin ${pluginSlug} --scan ${scanFile} --out ${WORKFLOW_CONFIG.compatibilityDir}`;
  const compatResult = runCommand(
    compatCmd,
    `Generating compatibility analysis for ${pluginSlug}`
  );
  
  if (!compatResult.success) {
    log(`⚠️ Compatibility analysis failed: ${compatResult.error}`, 'WARN');
  }
  
  // Generate functionality analysis
  const functionalityCmd = `node tools/ai/functionality-analyzer.mjs --plugin ${pluginSlug} --scan ${scanFile} --out tests/functionality`;
  const functionalityResult = runCommand(
    functionalityCmd,
    `Performing functionality analysis for ${pluginSlug}`
  );
  
  if (!functionalityResult.success) {
    log(`⚠️ Functionality analysis failed: ${functionalityResult.error}`, 'WARN');
  }
  
  // Generate customer value analysis
  const customerValueCmd = `node tools/ai/customer-value-analyzer.mjs --plugin ${pluginSlug} --scan ${scanFile} --functionality tests/functionality/${pluginSlug}-functionality-report.md --out reports/customer-analysis`;
  const customerValueResult = runCommand(
    customerValueCmd,
    `Performing customer value analysis for ${pluginSlug}`
  );
  
  if (!customerValueResult.success) {
    log(`⚠️ Customer value analysis failed: ${customerValueResult.error}`, 'WARN');
  }
  
  results.analyze.completed = true;
  results.analyze.duration = Date.now() - startTime;
  log(`✅ Analysis phase completed in ${results.analyze.duration}ms`);
}

async function performGenerate(results) {
  const startTime = Date.now();
  log(`🧪 Phase 3: Test Generation - ${pluginSlug}`);
  
  const scanFile = `${WORKFLOW_CONFIG.scanDir}/plugin-${pluginSlug}.json`;
  const outputDir = `${WORKFLOW_CONFIG.testDir}/${pluginSlug}`;
  
  if (!fileExists(scanFile)) {
    throw new Error(`Scan file not found: ${scanFile}. Run scan phase first.`);
  }
  
  // Generate comprehensive test suite
  const generateCmd = `node tools/ai/universal-test-generator.mjs --plugin ${pluginSlug} --scan ${scanFile} --out ${outputDir}`;
  const generateResult = runCommand(
    generateCmd,
    `Generating test suite for ${pluginSlug}`
  );
  
  if (!generateResult.success) {
    throw new Error(`Test generation failed: ${generateResult.error}`);
  }
  
  // Verify generated files
  const expectedFiles = [
    `${outputDir}/TEST-PLAN.md`,
    `${outputDir}/BUG-CHECKLIST.md`,
    `${outputDir}/FEATURE-REPORT.md`
  ];
  
  const missingFiles = expectedFiles.filter(file => !fileExists(file));
  if (missingFiles.length > 0) {
    log(`⚠️ Some generated files missing: ${missingFiles.join(', ')}`, 'WARN');
  }
  
  results.generate.completed = true;
  results.generate.duration = Date.now() - startTime;
  log(`✅ Generation phase completed in ${results.generate.duration}ms`);
}

async function performTest(results) {
  const startTime = Date.now();
  log(`🧪 Phase 4: Test Execution - ${pluginSlug}`);
  
  const testDir = `${WORKFLOW_CONFIG.testDir}/${pluginSlug}`;
  
  if (!fs.existsSync(testDir)) {
    throw new Error(`Test directory not found: ${testDir}. Run generate phase first.`);
  }
  
  // Run PHPUnit tests if they exist
  const phpunitConfig = path.join(testDir, 'phpunit.xml');
  if (fileExists(phpunitConfig)) {
    const phpunitCmd = `./vendor/bin/phpunit --configuration ${phpunitConfig}`;
    const phpunitResult = runCommand(
      phpunitCmd,
      `Running PHPUnit tests for ${pluginSlug}`
    );
    
    if (!phpunitResult.success) {
      log(`⚠️ PHPUnit tests failed: ${phpunitResult.error}`, 'WARN');
    }
  }
  
  // Run Playwright E2E tests if they exist
  const playwrightTests = path.join(testDir, 'e2e');
  if (fs.existsSync(playwrightTests)) {
    const playwrightCmd = `npx playwright test --config ${playwrightTests}/playwright.config.js`;
    const playwrightResult = runCommand(
      playwrightCmd,
      `Running Playwright E2E tests for ${pluginSlug}`
    );
    
    if (!playwrightResult.success) {
      log(`⚠️ Playwright tests failed: ${playwrightResult.error}`, 'WARN');
    }
  }
  
  // Run security tests
  const securityTestCmd = `./vendor/bin/phpunit tests/phpunit/Security/SecurityTestStandalone.php`;
  const securityResult = runCommand(
    securityTestCmd,
    `Running security tests for ${pluginSlug}`
  );
  
  if (!securityResult.success) {
    log(`⚠️ Security tests failed: ${securityResult.error}`, 'WARN');
  }
  
  // Run functionality tests (TRUE/FALSE validation)
  const functionalityTestCmd = `node tools/ai/scenario-test-executor.mjs --plugin ${pluginSlug} --out reports/execution`;
  const functionalityResult = runCommand(
    functionalityTestCmd,
    `Running functionality validation tests for ${pluginSlug}`
  );
  
  if (!functionalityResult.success) {
    log(`⚠️ Functionality tests failed: ${functionalityResult.error}`, 'WARN');
  }
  
  // Generate AI-optimized comprehensive report
  const aiReportCmd = `node tools/ai/ai-optimized-reporter.mjs --plugin ${pluginSlug} --scan ${WORKFLOW_CONFIG.scanDir}/plugin-${pluginSlug}.json --tests ${WORKFLOW_CONFIG.testDir}/${pluginSlug} --out reports/ai-analysis`;
  const aiReportResult = runCommand(
    aiReportCmd,
    `Generating AI-optimized comprehensive report for ${pluginSlug}`
  );
  
  if (!aiReportResult.success) {
    log(`⚠️ AI report generation failed: ${aiReportResult.error}`, 'WARN');
  }
  
  results.test.completed = true;
  results.test.duration = Date.now() - startTime;
  log(`✅ Test phase completed in ${results.test.duration}ms`);
}

async function performFullWorkflow(results) {
  log(`🎯 Running Full Workflow for ${pluginSlug}`);
  
  await performScan(results);
  await performAnalyze(results);
  await performGenerate(results);
  await performTest(results);
  
  log(`✅ Full workflow completed for ${pluginSlug}`);
}

async function generateWorkflowReport(results) {
  log(`📊 Generating workflow report...`);
  
  ensureDir(WORKFLOW_CONFIG.reportsDir);
  
  const totalDuration = Date.now() - results.overall.startTime;
  const reportPath = `${WORKFLOW_CONFIG.reportsDir}/${pluginSlug}-workflow-report.md`;
  
  const report = [];
  report.push(`# Universal WordPress Plugin Testing Workflow Report`);
  report.push(`**Plugin:** ${pluginSlug}`);
  report.push(`**Action:** ${action}`);
  report.push(`**Date:** ${new Date().toISOString()}`);
  report.push(`**Total Duration:** ${totalDuration}ms (${Math.round(totalDuration/1000)}s)`);
  report.push('');
  
  report.push('## 📋 Phase Summary');
  report.push('');
  
  Object.entries(results).forEach(([phase, data]) => {
    if (phase === 'overall') return;
    
    const status = data.completed ? '✅ Completed' : '❌ Not Completed';
    const duration = data.duration > 0 ? `${data.duration}ms` : 'N/A';
    
    report.push(`### ${phase.charAt(0).toUpperCase() + phase.slice(1)} Phase`);
    report.push(`- **Status:** ${status}`);
    report.push(`- **Duration:** ${duration}`);
    report.push('');
  });
  
  // Generated Files
  report.push('## 📁 Generated Files');
  report.push('');
  
  const generatedFiles = [
    { path: `${WORKFLOW_CONFIG.scanDir}/plugin-${pluginSlug}.json`, description: 'Plugin scan data' },
    { path: `${WORKFLOW_CONFIG.testDir}/${pluginSlug}/TEST-PLAN.md`, description: 'Comprehensive test plan' },
    { path: `${WORKFLOW_CONFIG.testDir}/${pluginSlug}/BUG-CHECKLIST.md`, description: 'Automated bug detection checklist' },
    { path: `${WORKFLOW_CONFIG.testDir}/${pluginSlug}/FEATURE-REPORT.md`, description: 'Feature analysis report' },
    { path: `${WORKFLOW_CONFIG.compatibilityDir}/${pluginSlug}-compatibility.md`, description: 'Compatibility testing checklist' },
    { path: `tests/functionality/${pluginSlug}-functionality-report.md`, description: 'Functionality analysis report' },
    { path: `tests/functionality/${pluginSlug}-executable-test-plan.md`, description: 'Executable test cases (TRUE/FALSE)' },
    { path: `reports/customer-analysis/${pluginSlug}-customer-value-report.md`, description: 'Customer value and business impact analysis' },
    { path: `reports/ai-analysis/${pluginSlug}-ai-comprehensive-report.md`, description: 'AI-optimized comprehensive analysis (Claude Code ready)' },
    { path: `reports/execution/${pluginSlug}-execution-report.md`, description: 'Test execution results with evidence' }
  ];
  
  generatedFiles.forEach(file => {
    const exists = fileExists(file.path);
    const status = exists ? '✅' : '❌';
    report.push(`- ${status} **${file.description}**: \`${file.path}\``);
  });
  report.push('');
  
  // Next Steps
  report.push('## 🚀 Next Steps');
  report.push('');
  report.push('1. **Review generated reports** - Check all analysis and recommendations');
  report.push('2. **Address critical issues** - Focus on security and performance issues first');
  report.push('3. **Run manual testing** - Use generated checklists for comprehensive testing');
  report.push('4. **Setup CI/CD pipeline** - Automate testing for future changes');
  report.push('');
  
  // Commands for next steps
  report.push('## 🔧 Useful Commands');
  report.push('');
  report.push(`### Re-run specific phases:`);
  report.push(`\`\`\`bash`);
  report.push(`# Re-scan plugin`);
  report.push(`node tools/universal-workflow.mjs --plugin ${pluginSlug} --action scan`);
  report.push('');
  report.push(`# Re-generate tests`);
  report.push(`node tools/universal-workflow.mjs --plugin ${pluginSlug} --action generate`);
  report.push('');
  report.push(`# Run tests only`);
  report.push(`node tools/universal-workflow.mjs --plugin ${pluginSlug} --action test`);
  report.push(`\`\`\``);
  report.push('');
  
  report.push(`### Manual testing commands:`);
  report.push(`\`\`\`bash`);
  report.push(`# Run PHPUnit tests`);
  report.push(`./vendor/bin/phpunit tests/generated/${pluginSlug}/`);
  report.push('');
  report.push(`# Run Playwright E2E tests`);
  report.push(`npx playwright test tests/generated/${pluginSlug}/e2e/`);
  report.push('');
  report.push(`# Run security tests`);
  report.push(`./vendor/bin/phpunit tests/phpunit/Security/SecurityTestStandalone.php`);
  report.push(`\`\`\``);
  report.push('');
  
  fs.writeFileSync(reportPath, report.join('\\n'));
  log(`📊 Workflow report generated: ${reportPath}`);
}

// ---------- Help and Usage ----------
function showHelp() {
  console.log(`
🚀 Universal WordPress Plugin Testing Workflow

USAGE:
  node tools/universal-workflow.mjs --plugin <slug> [options]

REQUIRED:
  --plugin <slug>    Plugin slug to test

ACTIONS:
  --action scan      Scan plugin and generate analysis data
  --action analyze   Perform advanced analysis and compatibility checking
  --action generate  Generate comprehensive test suites
  --action test      Execute generated tests
  --action full      Run complete workflow (default)

OPTIONS:
  --verbose          Show detailed output
  --dry-run          Show what would be done without executing

EXAMPLES:
  # Full workflow for WooCommerce
  node tools/universal-workflow.mjs --plugin woocommerce

  # Just scan and analyze
  node tools/universal-workflow.mjs --plugin woocommerce --action scan
  node tools/universal-workflow.mjs --plugin woocommerce --action analyze

  # Generate tests for BuddyPress (our model case)
  node tools/universal-workflow.mjs --plugin buddypress --action generate

  # Test specific plugin with verbose output
  node tools/universal-workflow.mjs --plugin contact-form-7 --action test --verbose

OUTPUT:
  📁 wp-content/uploads/wp-scan/     - Scan data and analysis
  📁 tests/generated/<plugin>/       - Generated test suites
  📁 tests/compatibility/            - Compatibility checklists  
  📁 reports/                        - Workflow reports
  📄 workflow.log                    - Detailed execution log

For more information, visit: https://github.com/vapvarun/wp-testing-framework
`);
}

// ---------- Main Execution ----------
if (args.includes('--help') || args.includes('-h')) {
  showHelp();
  process.exit(0);
}

// Initialize and run workflow
runWorkflow().catch(error => {
  log(`💥 Fatal error: ${error.message}`, 'FATAL');
  process.exit(1);
});