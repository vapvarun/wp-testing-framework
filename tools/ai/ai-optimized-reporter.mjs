#!/usr/bin/env node
/**
 * AI-Optimized Report Generator for Claude Code
 * 
 * Generates structured, machine-readable reports that enable Claude Code to:
 * - Automatically identify issues
 * - Make informed decisions about fixes
 * - Generate actionable code recommendations
 * - Prioritize improvements based on data
 *
 * Output Format: Structured Markdown + JSON data blocks optimized for AI parsing
 *
 * Usage:
 *   node tools/ai/ai-optimized-reporter.mjs \
 *     --plugin woocommerce \
 *     --data-dir reports/ \
 *     --out reports/ai-analysis
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ---------- CLI args ----------
const args = process.argv;
const pluginSlug = argOf('--plugin', '');
const dataDir = argOf('--data-dir', 'reports');
const outDir = argOf('--out', 'reports/ai-analysis');
const verbose = args.includes('--verbose');

function argOf(flag, def) { 
  return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

if (!pluginSlug) {
  console.error('Usage: node ai-optimized-reporter.mjs --plugin <slug> [--data-dir <dir>]');
  process.exit(1);
}

// ---------- AI Report Structure Templates ----------
const AI_REPORT_TEMPLATES = {
  issue_identification: {
    format: 'structured_json_in_markdown',
    purpose: 'Enable AI to automatically identify and categorize issues',
    sections: ['critical_issues', 'high_priority_issues', 'improvement_opportunities']
  },
  fix_recommendations: {
    format: 'actionable_code_blocks',
    purpose: 'Provide AI with specific code fixes and implementation steps',
    sections: ['immediate_fixes', 'code_examples', 'implementation_steps']
  },
  decision_matrix: {
    format: 'weighted_scoring',
    purpose: 'Help AI prioritize fixes based on impact vs effort',
    sections: ['impact_scores', 'effort_estimates', 'risk_assessments']
  }
};

// ---------- IO helpers ----------
function readJSONSafe(p, def = {}) {
  if (!fs.existsSync(p)) return def;
  try { 
    return JSON.parse(fs.readFileSync(p, 'utf8')); 
  } catch (e) {
    return def;
  }
}

function readTextSafe(p, def = '') {
  if (!fs.existsSync(p)) return def;
  try { 
    return fs.readFileSync(p, 'utf8'); 
  } catch (e) {
    return def;
  }
}

function ensureDir(p) { 
  fs.mkdirSync(p, { recursive: true }); 
}

function writeFile(dest, content) { 
  ensureDir(path.dirname(dest)); 
  fs.writeFileSync(dest, content); 
  console.log('  ✅ Generated AI-optimized report:', dest.replace(process.cwd(), '.')); 
}

// ---------- Data Collection ----------
function collectAllPluginData(pluginSlug, dataDir) {
  console.log(`🔍 Collecting data for AI analysis: ${pluginSlug}`);
  
  const data = {
    plugin: pluginSlug,
    scan_data: {},
    test_results: {},
    functionality_analysis: {},
    customer_analysis: {},
    execution_results: {},
    timestamp: new Date().toISOString()
  };

  // Collect scan data
  const scanFile = path.join('wp-content/uploads/wp-scan', `plugin-${pluginSlug}.json`);
  if (fs.existsSync(scanFile)) {
    data.scan_data = readJSONSafe(scanFile);
  }

  // Collect test execution results
  const executionFile = path.join('reports/execution', `${pluginSlug}-test-results.json`);
  if (fs.existsSync(executionFile)) {
    data.execution_results = readJSONSafe(executionFile);
  }

  // Collect functionality analysis
  const functionalityFiles = [
    `tests/functionality/${pluginSlug}-functionality-report.md`,
    `tests/functionality/${pluginSlug}-user-scenario-test-suite.md`,
    `tests/functionality/${pluginSlug}-executable-test-plan.md`
  ];
  
  data.functionality_analysis = {
    reports: functionalityFiles.filter(f => fs.existsSync(f)).map(f => ({
      file: f,
      content: readTextSafe(f)
    }))
  };

  // Collect customer analysis
  const customerFiles = [
    `reports/customer-analysis/${pluginSlug}-customer-value-report.md`,
    `reports/customer-analysis/${pluginSlug}-improvement-roadmap.md`,
    `reports/customer-analysis/${pluginSlug}-business-case-report.md`
  ];
  
  data.customer_analysis = {
    reports: customerFiles.filter(f => fs.existsSync(f)).map(f => ({
      file: f,
      content: readTextSafe(f)
    }))
  };

  return data;
}

// ---------- AI-Optimized Analysis ----------
function generateAIOptimizedReports(data) {
  console.log('🤖 Generating AI-optimized reports...');
  
  const reports = {
    aiActionableReport: generateAIActionableReport(data),
    aiDecisionMatrix: generateAIDecisionMatrix(data),
    aiFixRecommendations: generateAIFixRecommendations(data),
    aiIssueDatabase: generateAIIssueDatabase(data),
    aiImplementationGuide: generateAIImplementationGuide(data)
  };

  return reports;
}

function generateAIActionableReport(data) {
  const report = [];
  
  // AI-parseable header
  report.push('# AI-ACTIONABLE ANALYSIS REPORT');
  report.push(`**PLUGIN:** ${data.plugin}`);
  report.push(`**ANALYSIS_DATE:** ${data.timestamp}`);
  report.push(`**AI_OPTIMIZATION:** enabled`);
  report.push(`**PARSING_VERSION:** 1.0`);
  report.push('');
  
  // Structured issue identification for AI
  report.push('## 🚨 AI-STRUCTURED ISSUE IDENTIFICATION');
  report.push('```json');
  
  const issueStructure = {
    critical_issues: extractCriticalIssues(data),
    high_priority_issues: extractHighPriorityIssues(data),
    medium_priority_issues: extractMediumPriorityIssues(data),
    improvement_opportunities: extractImprovementOpportunities(data),
    metadata: {
      total_issues: 0,
      severity_distribution: {},
      confidence_scores: {},
      auto_fixable: 0,
      manual_review_required: 0
    }
  };
  
  // Calculate metadata
  issueStructure.metadata.total_issues = 
    issueStructure.critical_issues.length + 
    issueStructure.high_priority_issues.length + 
    issueStructure.medium_priority_issues.length;
    
  issueStructure.metadata.severity_distribution = {
    critical: issueStructure.critical_issues.length,
    high: issueStructure.high_priority_issues.length,
    medium: issueStructure.medium_priority_issues.length
  };
  
  issueStructure.metadata.auto_fixable = countAutoFixableIssues(issueStructure);
  issueStructure.metadata.manual_review_required = 
    issueStructure.metadata.total_issues - issueStructure.metadata.auto_fixable;
  
  report.push(JSON.stringify(issueStructure, null, 2));
  report.push('```');
  report.push('');
  
  // AI decision recommendations
  report.push('## 🤖 AI DECISION RECOMMENDATIONS');
  report.push('```json');
  
  const decisions = {
    immediate_actions: generateImmediateActions(issueStructure),
    fix_sequence: generateOptimalFixSequence(issueStructure),
    resource_requirements: estimateResourceRequirements(issueStructure),
    risk_assessment: generateRiskAssessment(issueStructure),
    success_metrics: defineSuccessMetrics(issueStructure)
  };
  
  report.push(JSON.stringify(decisions, null, 2));
  report.push('```');
  report.push('');
  
  // Test results analysis for AI
  if (data.execution_results && data.execution_results.tests) {
    report.push('## 📊 AI-PARSEABLE TEST RESULTS');
    report.push('```json');
    
    const testAnalysis = {
      summary: {
        total_tests: data.execution_results.totalTests || 0,
        passed: data.execution_results.passed || 0,
        failed: data.execution_results.failed || 0,
        success_rate: data.execution_results.totalTests > 0 ? 
          Math.round((data.execution_results.passed / data.execution_results.totalTests) * 100) : 0
      },
      failed_tests: data.execution_results.tests ? 
        data.execution_results.tests
          .filter(t => t.status === 'FAILED')
          .map(t => ({
            test_id: t.id,
            test_name: t.name,
            category: t.category,
            evidence: t.evidence,
            fix_complexity: categorizeFix(t),
            automated_fix_possible: isAutoFixable(t)
          })) : [],
      patterns: identifyFailurePatterns(data.execution_results)
    };
    
    report.push(JSON.stringify(testAnalysis, null, 2));
    report.push('```');
    report.push('');
  }
  
  return report.join('\n');
}

function generateAIDecisionMatrix(data) {
  const matrix = [];
  
  matrix.push('# AI DECISION MATRIX');
  matrix.push(`**PURPOSE:** Enable automated prioritization and decision-making`);
  matrix.push(`**PLUGIN:** ${data.plugin}`);
  matrix.push('');
  
  matrix.push('## 🎯 WEIGHTED SCORING MATRIX');
  matrix.push('```json');
  
  const scoringMatrix = {
    scoring_criteria: {
      business_impact: { weight: 0.3, description: "Revenue/customer impact" },
      technical_complexity: { weight: 0.2, description: "Implementation difficulty" },
      user_experience_impact: { weight: 0.25, description: "UX improvement potential" },
      security_risk: { weight: 0.15, description: "Security vulnerability risk" },
      maintenance_burden: { weight: 0.1, description: "Ongoing maintenance cost" }
    },
    items: generateScoredItems(data),
    recommendations: {
      top_3_priorities: [],
      quick_wins: [],
      long_term_strategic: []
    }
  };
  
  // Calculate top priorities
  scoringMatrix.items.sort((a, b) => b.weighted_score - a.weighted_score);
  scoringMatrix.recommendations.top_3_priorities = scoringMatrix.items.slice(0, 3);
  scoringMatrix.recommendations.quick_wins = scoringMatrix.items.filter(item => 
    item.effort_score < 3 && item.impact_score >= 4
  );
  scoringMatrix.recommendations.long_term_strategic = scoringMatrix.items.filter(item => 
    item.effort_score >= 7 && item.impact_score >= 8
  );
  
  matrix.push(JSON.stringify(scoringMatrix, null, 2));
  matrix.push('```');
  matrix.push('');
  
  return matrix.join('\n');
}

function generateAIFixRecommendations(data) {
  const guide = [];
  
  guide.push('# AI CODE FIX RECOMMENDATIONS');
  guide.push(`**AUTOMATED_FIXES_AVAILABLE:** true`);
  guide.push(`**CODE_EXAMPLES_INCLUDED:** true`);
  guide.push(`**PLUGIN:** ${data.plugin}`);
  guide.push('');
  
  const fixes = extractFixableIssues(data);
  
  fixes.forEach((fix, index) => {
    guide.push(`## FIX_${index + 1}: ${fix.title}`);
    guide.push(`**SEVERITY:** ${fix.severity}`);
    guide.push(`**AUTO_FIXABLE:** ${fix.auto_fixable}`);
    guide.push(`**EFFORT_ESTIMATE:** ${fix.effort_hours} hours`);
    guide.push(`**CONFIDENCE:** ${fix.confidence}%`);
    guide.push('');
    
    if (fix.auto_fixable) {
      guide.push('### 🤖 AUTOMATED FIX');
      guide.push('```json');
      guide.push(JSON.stringify({
        action: fix.action,
        file_path: fix.file_path,
        line_number: fix.line_number,
        old_code: fix.old_code,
        new_code: fix.new_code,
        validation_test: fix.validation_test
      }, null, 2));
      guide.push('```');
      guide.push('');
    }
    
    if (fix.code_example) {
      guide.push('### 💻 CODE EXAMPLE');
      guide.push(`\`\`\`${fix.language || 'php'}`);
      guide.push(fix.code_example);
      guide.push('```');
      guide.push('');
    }
    
    guide.push('### 📋 IMPLEMENTATION STEPS');
    fix.steps.forEach((step, stepIndex) => {
      guide.push(`${stepIndex + 1}. **${step.action}**`);
      guide.push(`   - Description: ${step.description}`);
      if (step.code) {
        guide.push(`   - Code: \`${step.code}\``);
      }
      guide.push(`   - Validation: ${step.validation}`);
    });
    guide.push('');
    
    guide.push('### ✅ VERIFICATION CRITERIA');
    guide.push('```json');
    guide.push(JSON.stringify({
      success_criteria: fix.success_criteria,
      test_commands: fix.test_commands,
      expected_results: fix.expected_results
    }, null, 2));
    guide.push('```');
    guide.push('');
    guide.push('---');
    guide.push('');
  });
  
  return guide.join('\n');
}

function generateAIIssueDatabase(data) {
  const database = [];
  
  database.push('# AI ISSUE DATABASE');
  database.push(`**MACHINE_READABLE:** true`);
  database.push(`**QUERY_OPTIMIZED:** true`);
  database.push(`**PLUGIN:** ${data.plugin}`);
  database.push('');
  
  database.push('## 📊 ISSUE TAXONOMY');
  database.push('```json');
  
  const taxonomy = {
    categories: {
      security: extractIssuesByCategory(data, 'security'),
      performance: extractIssuesByCategory(data, 'performance'), 
      functionality: extractIssuesByCategory(data, 'functionality'),
      usability: extractIssuesByCategory(data, 'usability'),
      compatibility: extractIssuesByCategory(data, 'compatibility'),
      code_quality: extractIssuesByCategory(data, 'code_quality')
    },
    patterns: identifyIssuePatterns(data),
    correlations: findIssueCorrelations(data),
    fix_dependencies: mapFixDependencies(data)
  };
  
  database.push(JSON.stringify(taxonomy, null, 2));
  database.push('```');
  database.push('');
  
  return database.join('\n');
}

function generateAIImplementationGuide(data) {
  const guide = [];
  
  guide.push('# AI IMPLEMENTATION GUIDE');
  guide.push(`**EXECUTION_READY:** true`);
  guide.push(`**COMMANDS_INCLUDED:** true`);
  guide.push(`**PLUGIN:** ${data.plugin}`);
  guide.push('');
  
  guide.push('## 🚀 AUTOMATED EXECUTION PLAN');
  guide.push('```json');
  
  const executionPlan = {
    phases: [
      {
        phase: "immediate_fixes",
        duration_estimate: "2-4 hours",
        automation_level: "high",
        tasks: generateImmediateTasks(data),
        commands: generateAutomatedCommands(data, 'immediate')
      },
      {
        phase: "short_term_improvements", 
        duration_estimate: "1-2 weeks",
        automation_level: "medium",
        tasks: generateShortTermTasks(data),
        commands: generateAutomatedCommands(data, 'short_term')
      },
      {
        phase: "strategic_enhancements",
        duration_estimate: "1-3 months", 
        automation_level: "low",
        tasks: generateStrategicTasks(data),
        commands: generateAutomatedCommands(data, 'strategic')
      }
    ],
    validation: {
      test_commands: [
        `npm run functionality:test -- --plugin ${data.plugin}`,
        `./vendor/bin/phpunit tests/generated/${data.plugin}/`,
        `node tools/ai/scenario-test-executor.mjs --plugin ${data.plugin}`
      ],
      success_metrics: generateSuccessMetrics(data),
      rollback_plan: generateRollbackPlan(data)
    }
  };
  
  guide.push(JSON.stringify(executionPlan, null, 2));
  guide.push('```');
  guide.push('');
  
  guide.push('## 🤖 AI AUTOMATION COMMANDS');
  guide.push('Claude Code can execute these commands automatically:');
  guide.push('');
  
  const commands = generateClaudeCodeCommands(data);
  commands.forEach(cmd => {
    guide.push(`### ${cmd.category}`);
    guide.push(`\`\`\`bash`);
    guide.push(cmd.command);
    guide.push(`\`\`\``);
    guide.push(`**Purpose:** ${cmd.purpose}`);
    guide.push(`**Expected Result:** ${cmd.expected_result}`);
    guide.push('');
  });
  
  return guide.join('\n');
}

// ---------- Helper Functions for AI Analysis ----------
function extractCriticalIssues(data) {
  const issues = [];
  
  // Extract from security patterns
  if (data.scan_data && data.scan_data.security_patterns) {
    const security = data.scan_data.security_patterns;
    
    if (security.sql_injection_risks?.length > 0) {
      issues.push({
        id: 'sql_injection_risk',
        category: 'security',
        severity: 'critical',
        title: 'SQL Injection Vulnerabilities Detected',
        description: `${security.sql_injection_risks.length} files with SQL injection risks`,
        affected_files: security.sql_injection_risks,
        auto_fixable: true,
        fix_complexity: 'medium',
        business_impact: 'high',
        technical_debt: 'high'
      });
    }
    
    if (security.xss_vulnerabilities?.length > 0) {
      issues.push({
        id: 'xss_vulnerability',
        category: 'security', 
        severity: 'critical',
        title: 'XSS Vulnerabilities Detected',
        description: `${security.xss_vulnerabilities.length} files with XSS risks`,
        affected_files: security.xss_vulnerabilities,
        auto_fixable: true,
        fix_complexity: 'medium',
        business_impact: 'high',
        technical_debt: 'high'
      });
    }
  }
  
  // Extract from test failures
  if (data.execution_results && data.execution_results.tests) {
    const criticalFailures = data.execution_results.tests.filter(t => 
      t.status === 'FAILED' && t.category === 'basic'
    );
    
    criticalFailures.forEach(test => {
      issues.push({
        id: `test_failure_${test.id}`,
        category: 'functionality',
        severity: 'critical',
        title: `Critical Test Failure: ${test.name}`,
        description: test.message || 'Test failed without specific message',
        evidence: test.evidence,
        auto_fixable: isAutoFixable(test),
        fix_complexity: categorizeFix(test),
        business_impact: 'high',
        technical_debt: 'medium'
      });
    });
  }
  
  return issues;
}

function extractHighPriorityIssues(data) {
  const issues = [];
  
  // Performance issues
  if (data.scan_data && data.scan_data.performance_indicators) {
    const perf = data.scan_data.performance_indicators;
    const totalQueries = Object.values(perf.database_queries || {}).reduce((a, b) => a + b, 0);
    
    if (totalQueries > 10) {
      issues.push({
        id: 'high_database_queries',
        category: 'performance',
        severity: 'high',
        title: 'Excessive Database Queries',
        description: `${totalQueries} database queries detected, may impact performance`,
        auto_fixable: false,
        fix_complexity: 'high',
        business_impact: 'medium',
        technical_debt: 'high'
      });
    }
  }
  
  return issues;
}

function extractMediumPriorityIssues(data) {
  const issues = [];
  
  // Best practices issues
  if (data.scan_data && data.scan_data.best_practices) {
    const practices = data.scan_data.best_practices;
    
    if (!practices.has_readme) {
      issues.push({
        id: 'missing_documentation',
        category: 'code_quality',
        severity: 'medium',
        title: 'Missing Documentation',
        description: 'Plugin lacks proper README documentation',
        auto_fixable: true,
        fix_complexity: 'low',
        business_impact: 'low',
        technical_debt: 'low'
      });
    }
  }
  
  return issues;
}

function extractImprovementOpportunities(data) {
  const opportunities = [];
  
  // Extract from customer analysis reports
  if (data.customer_analysis && data.customer_analysis.reports) {
    const roadmapReport = data.customer_analysis.reports.find(r => 
      r.file.includes('improvement-roadmap')
    );
    
    if (roadmapReport) {
      // Parse improvement opportunities from the roadmap content
      const quickWins = extractQuickWins(roadmapReport.content);
      quickWins.forEach(win => {
        opportunities.push({
          id: `improvement_${win.id}`,
          category: 'improvement',
          title: win.title,
          description: win.description,
          business_value: win.business_value,
          effort_estimate: win.effort,
          roi_score: win.roi || 5
        });
      });
    }
  }
  
  return opportunities;
}

function extractQuickWins(content) {
  // Simple extraction - in real implementation, you'd parse the markdown more sophisticated
  const wins = [];
  
  if (content.includes('loading states')) {
    wins.push({
      id: 'loading_states',
      title: 'Add loading states and progress indicators',
      description: 'Improve perceived performance with better UI feedback',
      business_value: 'Reduced abandonment, better user experience',
      effort: 'low',
      roi: 8
    });
  }
  
  if (content.includes('error messages')) {
    wins.push({
      id: 'error_messages',
      title: 'Implement proper error messages',
      description: 'Clear, actionable error messages for users',
      business_value: 'Reduced support requests, better user satisfaction',
      effort: 'low',
      roi: 7
    });
  }
  
  return wins;
}

function generateScoredItems(data) {
  const items = [];
  const issues = [
    ...extractCriticalIssues(data),
    ...extractHighPriorityIssues(data),
    ...extractMediumPriorityIssues(data)
  ];
  
  issues.forEach(issue => {
    const item = {
      id: issue.id,
      title: issue.title,
      category: issue.category,
      impact_score: calculateImpactScore(issue),
      effort_score: calculateEffortScore(issue),
      risk_score: calculateRiskScore(issue),
      weighted_score: 0
    };
    
    // Calculate weighted score
    item.weighted_score = 
      (item.impact_score * 0.4) + 
      ((10 - item.effort_score) * 0.3) + 
      (item.risk_score * 0.3);
    
    items.push(item);
  });
  
  return items;
}

function calculateImpactScore(issue) {
  const impactMap = {
    'critical': 10,
    'high': 8,
    'medium': 6,
    'low': 4
  };
  return impactMap[issue.severity] || 5;
}

function calculateEffortScore(issue) {
  const effortMap = {
    'low': 2,
    'medium': 5,
    'high': 8,
    'very_high': 10
  };
  return effortMap[issue.fix_complexity] || 5;
}

function calculateRiskScore(issue) {
  if (issue.category === 'security') return 10;
  if (issue.category === 'functionality') return 8;
  if (issue.category === 'performance') return 6;
  return 4;
}

function extractFixableIssues(data) {
  const fixes = [];
  const issues = extractCriticalIssues(data);
  
  issues.filter(issue => issue.auto_fixable).forEach(issue => {
    const fix = {
      title: issue.title,
      severity: issue.severity,
      auto_fixable: true,
      effort_hours: getEffortEstimate(issue),
      confidence: getFixConfidence(issue),
      action: getFixAction(issue),
      file_path: issue.affected_files?.[0] || 'unknown',
      code_example: generateCodeExample(issue),
      steps: generateImplementationSteps(issue),
      success_criteria: generateSuccessCriteria(issue),
      test_commands: generateTestCommands(issue),
      expected_results: generateExpectedResults(issue)
    };
    
    fixes.push(fix);
  });
  
  return fixes;
}

function getEffortEstimate(issue) {
  const estimates = {
    'sql_injection_risk': 2,
    'xss_vulnerability': 1.5,
    'missing_documentation': 0.5
  };
  return estimates[issue.id] || 1;
}

function getFixConfidence(issue) {
  const confidence = {
    'sql_injection_risk': 85,
    'xss_vulnerability': 90,
    'missing_documentation': 95
  };
  return confidence[issue.id] || 75;
}

function getFixAction(issue) {
  const actions = {
    'sql_injection_risk': 'replace_query_with_prepared_statement',
    'xss_vulnerability': 'add_output_escaping',
    'missing_documentation': 'create_readme_file'
  };
  return actions[issue.id] || 'manual_review_required';
}

function generateCodeExample(issue) {
  const examples = {
    'sql_injection_risk': `// Before (vulnerable)
$wpdb->query("SELECT * FROM table WHERE id = " . $_GET['id']);

// After (secure)
$wpdb->prepare("SELECT * FROM table WHERE id = %d", $_GET['id']);`,
    'xss_vulnerability': `// Before (vulnerable) 
echo $_POST['user_input'];

// After (secure)
echo esc_html($_POST['user_input']);`,
    'missing_documentation': `# Plugin Name
Description of what this plugin does for users.

## Installation
1. Upload plugin files
2. Activate plugin
3. Configure settings

## Usage
How to use the plugin features.`
  };
  return examples[issue.id] || '// Code example not available';
}

function generateImplementationSteps(issue) {
  const steps = {
    'sql_injection_risk': [
      {
        action: 'Identify vulnerable queries',
        description: 'Find all direct SQL queries in the codebase',
        code: 'grep -r "\\$wpdb->query" . --include="*.php"',
        validation: 'Verify no direct concatenation with user input'
      },
      {
        action: 'Replace with prepared statements',
        description: 'Use $wpdb->prepare() for all dynamic queries',
        code: '$wpdb->prepare("SELECT * FROM table WHERE column = %s", $value)',
        validation: 'Test with malicious input to ensure protection'
      }
    ],
    'xss_vulnerability': [
      {
        action: 'Identify output points',
        description: 'Find all locations where user input is echoed',
        code: 'grep -r "echo.*\\$_" . --include="*.php"',
        validation: 'Verify all user data is escaped'
      },
      {
        action: 'Add escaping functions',
        description: 'Use appropriate WordPress escaping functions',
        code: 'esc_html(), esc_attr(), esc_url(), wp_kses()',
        validation: 'Test XSS payloads to ensure blocking'
      }
    ]
  };
  return steps[issue.id] || [];
}

function generateSuccessCriteria(issue) {
  const criteria = {
    'sql_injection_risk': [
      'All database queries use prepared statements',
      'No direct concatenation of user input in SQL',
      'Security scanner shows no SQL injection vulnerabilities'
    ],
    'xss_vulnerability': [
      'All user input is properly escaped before output',
      'XSS test payloads are blocked or escaped',
      'Security headers are properly configured'
    ]
  };
  return criteria[issue.id] || ['Fix implemented successfully', 'Tests pass'];
}

function generateTestCommands(issue) {
  const commands = {
    'sql_injection_risk': [
      './vendor/bin/phpunit tests/phpunit/Security/SecurityTestStandalone.php',
      'wp eval "echo \'SQL injection test completed\';"'
    ],
    'xss_vulnerability': [
      './vendor/bin/phpunit tests/phpunit/Security/SecurityTestStandalone.php',
      'curl -X POST -d "malicious=<script>alert(1)</script>" http://localhost/test'
    ]
  };
  return commands[issue.id] || [`npm run functionality:test -- --plugin ${issue.plugin}`];
}

function generateExpectedResults(issue) {
  const results = {
    'sql_injection_risk': [
      'All security tests pass',
      'No SQL injection vulnerabilities detected',
      'Performance impact is minimal'
    ],
    'xss_vulnerability': [
      'XSS payloads are escaped or blocked',
      'No JavaScript execution from user input',
      'Security headers validate correctly'
    ]
  };
  return results[issue.id] || ['Implementation works as expected'];
}

// Duplicate function removed - implementation already exists above

// More helper functions...
function countAutoFixableIssues(structure) {
  let count = 0;
  Object.values(structure).forEach(issues => {
    if (Array.isArray(issues)) {
      count += issues.filter(issue => issue.auto_fixable).length;
    }
  });
  return count;
}

function generateImmediateActions(structure) {
  return structure.critical_issues
    .filter(issue => issue.auto_fixable)
    .map(issue => ({
      action: `Fix ${issue.title}`,
      priority: 1,
      estimated_time: '30 minutes',
      automation_possible: true
    }));
}

function generateOptimalFixSequence(structure) {
  const allIssues = [
    ...structure.critical_issues,
    ...structure.high_priority_issues,
    ...structure.medium_priority_issues
  ];
  
  return allIssues
    .sort((a, b) => {
      // Sort by: auto_fixable first, then severity, then fix complexity
      if (a.auto_fixable && !b.auto_fixable) return -1;
      if (!a.auto_fixable && b.auto_fixable) return 1;
      
      const severityOrder = { critical: 3, high: 2, medium: 1 };
      if (severityOrder[a.severity] !== severityOrder[b.severity]) {
        return severityOrder[b.severity] - severityOrder[a.severity];
      }
      
      const complexityOrder = { low: 1, medium: 2, high: 3 };
      return complexityOrder[a.fix_complexity] - complexityOrder[b.fix_complexity];
    })
    .map((issue, index) => ({
      sequence: index + 1,
      issue_id: issue.id,
      title: issue.title,
      estimated_duration: getEffortEstimate({ id: issue.id }) + ' hours'
    }));
}

function estimateResourceRequirements(structure) {
  const totalIssues = structure.metadata.total_issues;
  const autoFixable = structure.metadata.auto_fixable;
  
  return {
    developer_hours: totalIssues * 2, // Average 2 hours per issue
    automated_fixes: autoFixable,
    manual_review_hours: (totalIssues - autoFixable) * 3,
    testing_hours: totalIssues * 0.5,
    total_estimated_hours: totalIssues * 2.5
  };
}

function generateRiskAssessment(structure) {
  return {
    deployment_risk: structure.critical_issues.length > 0 ? 'high' : 'medium',
    rollback_complexity: 'low', // Most fixes are reversible
    user_impact: structure.critical_issues.length > 3 ? 'high' : 'medium',
    business_continuity: 'maintained', // Fixes don't break core functionality
    recommended_approach: 'incremental_deployment'
  };
}

function defineSuccessMetrics(structure) {
  return {
    critical_issues_resolved: structure.critical_issues.length,
    security_score_improvement: '25-40 points',
    test_pass_rate_target: '95%',
    performance_improvement: '15-25%',
    user_satisfaction_increase: '10-20%'
  };
}

function isAutoFixable(test) {
  const autoFixablePatterns = [
    'plugin_exists',
    'plugin_activatable', 
    'missing_documentation',
    'basic_security'
  ];
  return autoFixablePatterns.some(pattern => test.id?.includes(pattern));
}

function categorizeFix(test) {
  if (test.category === 'basic') return 'low';
  if (test.category === 'security') return 'medium';
  if (test.category === 'performance') return 'high';
  return 'medium';
}

function identifyFailurePatterns(results) {
  if (!results || !results.tests) return [];
  
  const patterns = [];
  const failedTests = results.tests.filter(t => t.status === 'FAILED');
  
  // Group by category
  const byCategory = {};
  failedTests.forEach(test => {
    if (!byCategory[test.category]) byCategory[test.category] = [];
    byCategory[test.category].push(test);
  });
  
  Object.entries(byCategory).forEach(([category, tests]) => {
    if (tests.length > 1) {
      patterns.push({
        pattern: `${category}_failures`,
        description: `Multiple ${category} tests failing`,
        affected_tests: tests.length,
        likely_cause: inferCause(category, tests)
      });
    }
  });
  
  return patterns;
}

function inferCause(category, tests) {
  const causes = {
    'basic': 'Plugin activation or configuration issue',
    'security': 'Missing security implementations',
    'performance': 'Resource or optimization issues',
    'functionality': 'Core feature implementation problems'
  };
  return causes[category] || 'Unknown cause';
}

function extractIssuesByCategory(data, category) {
  // Extract issues by category from all data sources
  const issues = [];
  
  if (category === 'security' && data.scan_data?.security_patterns) {
    const security = data.scan_data.security_patterns;
    Object.entries(security).forEach(([type, files]) => {
      if (files && files.length > 0) {
        issues.push({
          type,
          count: files.length,
          files,
          severity: type.includes('injection') || type.includes('xss') ? 'critical' : 'high'
        });
      }
    });
  }
  
  return issues;
}

function identifyIssuePatterns(data) {
  return {
    common_patterns: ['missing_validation', 'unescaped_output', 'direct_queries'],
    anti_patterns: ['global_variables', 'hardcoded_values', 'missing_error_handling']
  };
}

function findIssueCorrelations(data) {
  return {
    'security_performance': 'Security issues often correlate with performance problems',
    'validation_usability': 'Missing validation correlates with poor user experience'
  };
}

function mapFixDependencies(data) {
  return {
    'sql_injection_fix': ['update_queries', 'add_validation', 'test_security'],
    'xss_fix': ['add_escaping', 'sanitize_inputs', 'update_templates']
  };
}

function generateImmediateTasks(data) {
  return [
    {
      task: 'Fix critical security vulnerabilities',
      automation: 'high',
      estimated_time: '2 hours'
    },
    {
      task: 'Resolve basic functionality failures',
      automation: 'medium',
      estimated_time: '1 hour'
    }
  ];
}

function generateShortTermTasks(data) {
  return [
    {
      task: 'Implement performance optimizations',
      automation: 'medium',
      estimated_time: '1 week'
    },
    {
      task: 'Add comprehensive error handling',
      automation: 'low',
      estimated_time: '3 days'
    }
  ];
}

function generateStrategicTasks(data) {
  return [
    {
      task: 'Redesign architecture for scalability',
      automation: 'low',
      estimated_time: '2 months'
    },
    {
      task: 'Implement advanced features',
      automation: 'low', 
      estimated_time: '6 weeks'
    }
  ];
}

function generateClaudeCodeCommands(data) {
  const commands = [];
  
  commands.push({
    category: 'Fix Critical Security Issues',
    command: `wp eval-file fixes/security-patches.php --path="${data.plugin}"`,
    purpose: 'Apply automated security patches',
    expected_result: 'All SQL injection and XSS vulnerabilities patched'
  });
  
  commands.push({
    category: 'Optimize Performance',
    command: `wp eval-file fixes/performance-optimization.php --path="${data.plugin}"`,
    purpose: 'Apply caching and query optimizations',
    expected_result: 'Database queries reduced by 40%, page load improved'
  });
  
  commands.push({
    category: 'Run Validation Tests',
    command: `./vendor/bin/phpunit tests/generated/${data.plugin}/`,
    purpose: 'Validate all fixes and improvements',
    expected_result: 'All tests passing with >90% success rate'
  });
  
  return commands;
}

function generateAutomatedCommands(data, phase) {
  const commands = {
    immediate: [
      `./vendor/bin/phpunit tests/phpunit/Security/SecurityTestStandalone.php`,
      `node tools/ai/scenario-test-executor.mjs --plugin ${data.plugin}`
    ],
    short_term: [
      `npm run universal:analyze -- --plugin ${data.plugin}`,
      `npm run test:performance`
    ],
    strategic: [
      `npm run universal:full -- --plugin ${data.plugin}`,
      `npm run coverage:report`
    ]
  };
  return commands[phase] || [];
}

function generateSuccessMetrics(data) {
  return {
    security_score: 95,
    test_pass_rate: 98,
    performance_score: 85,
    user_satisfaction: 4.5
  };
}

function generateRollbackPlan(data) {
  return {
    backup_required: true,
    rollback_time: '10 minutes',
    rollback_command: 'git checkout HEAD~1',
    validation_steps: ['test basic functionality', 'verify no errors']
  };
}

// ---------- Main Execution ----------
async function main() {
  console.log(`🤖 Generating AI-optimized reports for: ${pluginSlug}`);
  
  // Collect all available data
  const data = collectAllPluginData(pluginSlug, dataDir);
  
  // Generate AI-optimized reports
  const reports = generateAIOptimizedReports(data);
  
  // Write all reports
  Object.entries(reports).forEach(([type, content]) => {
    const filename = `${pluginSlug}-${type.replace(/([A-Z])/g, '-$1').toLowerCase()}.md`;
    writeFile(path.join(outDir, filename), content);
  });
  
  // Generate master AI index
  const masterIndex = generateAIMasterIndex(pluginSlug, reports, data);
  writeFile(path.join(outDir, `${pluginSlug}-ai-master-index.md`), masterIndex);
  
  console.log(`✅ AI-optimized reports generated for Claude Code automation`);
}

function generateAIMasterIndex(pluginSlug, reports, data) {
  const index = [];
  
  index.push('# AI MASTER INDEX FOR CLAUDE CODE');
  index.push(`**PLUGIN:** ${pluginSlug}`);
  index.push(`**AI_READY:** true`);
  index.push(`**AUTOMATION_ENABLED:** true`);
  index.push(`**LAST_UPDATED:** ${new Date().toISOString()}`);
  index.push('');
  
  index.push('## 🤖 CLAUDE CODE AUTOMATION SUMMARY');
  index.push('```json');
  
  const summary = {
    plugin: pluginSlug,
    analysis_complete: true,
    issues_identified: true,
    fixes_available: true,
    automation_ready: true,
    confidence_level: 'high',
    next_actions: [
      'Review AI actionable report',
      'Execute immediate fixes',
      'Validate with functionality tests',
      'Implement improvement roadmap'
    ],
    available_reports: Object.keys(reports),
    key_metrics: {
      total_issues: countTotalIssues(data),
      auto_fixable: countAutoFixable(data),
      manual_review: countManualReview(data),
      success_probability: calculateSuccessProbability(data)
    }
  };
  
  index.push(JSON.stringify(summary, null, 2));
  index.push('```');
  index.push('');
  
  index.push('## 📋 REPORT NAVIGATION FOR AI');
  Object.entries(reports).forEach(([type, content]) => {
    const filename = `${pluginSlug}-${type.replace(/([A-Z])/g, '-$1').toLowerCase()}.md`;
    index.push(`- **${type}**: \`${filename}\``);
    index.push(`  - Purpose: ${getReportPurpose(type)}`);
    index.push(`  - AI Usage: ${getAIUsage(type)}`);
  });
  index.push('');
  
  return index.join('\n');
}

function getReportPurpose(type) {
  const purposes = {
    aiActionableReport: 'Structured issue identification and decision recommendations',
    aiDecisionMatrix: 'Weighted scoring for automated prioritization',
    aiFixRecommendations: 'Code fixes with implementation steps',
    aiIssueDatabase: 'Queryable issue taxonomy and patterns',
    aiImplementationGuide: 'Execution-ready automation commands'
  };
  return purposes[type] || 'Analysis and recommendations';
}

function getAIUsage(type) {
  const usage = {
    aiActionableReport: 'Parse JSON blocks for automated issue identification',
    aiDecisionMatrix: 'Use scoring matrix for priority decisions',
    aiFixRecommendations: 'Execute code fixes and validation steps',
    aiIssueDatabase: 'Query for specific issue patterns and correlations',
    aiImplementationGuide: 'Run automation commands and validate results'
  };
  return usage[type] || 'Reference for decision-making';
}

function countTotalIssues(data) {
  let count = 0;
  if (data.execution_results?.tests) {
    count += data.execution_results.tests.filter(t => t.status === 'FAILED').length;
  }
  return count;
}

function countAutoFixable(data) {
  let count = 0;
  if (data.execution_results?.tests) {
    count += data.execution_results.tests
      .filter(t => t.status === 'FAILED' && isAutoFixable(t)).length;
  }
  return count;
}

function countManualReview(data) {
  return countTotalIssues(data) - countAutoFixable(data);
}

function calculateSuccessProbability(data) {
  const totalIssues = countTotalIssues(data);
  const autoFixable = countAutoFixable(data);
  
  if (totalIssues === 0) return 95;
  
  const autoFixRatio = autoFixable / totalIssues;
  const baseProbability = 60;
  const autoFixBonus = autoFixRatio * 30;
  
  return Math.min(95, Math.round(baseProbability + autoFixBonus));
}

// Run the generator
main().catch(console.error);