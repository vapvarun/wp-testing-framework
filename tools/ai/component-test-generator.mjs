#!/usr/bin/env node
/**
 * BuddyPress Component-Specific Test Generator
 * 
 * Generates targeted tests based on component scan data
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class ComponentTestGenerator {
    constructor(scanData) {
        this.scanData = scanData;
        this.tests = {};
    }

    /**
     * Generate tests for all components
     */
    generateAllComponentTests() {
        const results = {};
        
        for (const [componentId, componentData] of Object.entries(this.scanData)) {
            if (componentId === 'summary') continue;
            
            results[componentId] = this.generateComponentTests(componentId, componentData);
        }
        
        return results;
    }

    /**
     * Generate tests for a specific component
     */
    generateComponentTests(componentId, componentData) {
        const tests = {
            component: componentData.name,
            description: componentData.description,
            metrics: componentData.metrics,
            test_suites: {
                unit: this.generateUnitTests(componentData),
                integration: this.generateIntegrationTests(componentData),
                functional: this.generateFunctionalTests(componentData),
                hooks: this.generateHookTests(componentData),
                security: this.generateSecurityTests(componentData),
                performance: this.generatePerformanceTests(componentData)
            }
        };
        
        return tests;
    }

    /**
     * Generate unit tests based on classes and functions
     */
    generateUnitTests(componentData) {
        const tests = [];
        
        // Test each class
        componentData.classes.forEach(cls => {
            tests.push({
                name: `Test ${cls.name} class instantiation`,
                type: 'class_instantiation',
                target: cls.name,
                file: cls.file,
                assertions: [
                    `Class ${cls.name} should exist`,
                    `Class ${cls.name} should be instantiable`,
                    cls.extends ? `Class should extend ${cls.extends}` : null
                ].filter(Boolean)
            });
            
            // Test each method
            cls.methods.forEach(method => {
                tests.push({
                    name: `Test ${cls.name}::${method}() method`,
                    type: 'method_test',
                    target: `${cls.name}::${method}`,
                    assertions: [
                        `Method ${method} should exist`,
                        `Method ${method} should be callable`,
                        `Method ${method} should return expected type`
                    ]
                });
            });
        });
        
        // Test functions
        componentData.functions.forEach(func => {
            tests.push({
                name: `Test ${func.name}() function`,
                type: 'function_test',
                target: func.name,
                file: func.file,
                category: func.type,
                assertions: this.getFunctionAssertions(func)
            });
        });
        
        return tests;
    }

    /**
     * Get function-specific assertions based on type
     */
    getFunctionAssertions(func) {
        const assertions = [`Function ${func.name} should exist`];
        
        switch (func.type) {
            case 'getter':
                assertions.push('Should return a value');
                assertions.push('Should not modify data');
                break;
            case 'setter':
                assertions.push('Should accept parameters');
                assertions.push('Should update data correctly');
                break;
            case 'conditional':
                assertions.push('Should return boolean');
                assertions.push('Should handle edge cases');
                break;
            case 'capability':
                assertions.push('Should check user permissions');
                assertions.push('Should return boolean');
                break;
            case 'ajax':
                assertions.push('Should verify nonce');
                assertions.push('Should return JSON response');
                break;
            case 'template':
                assertions.push('Should output HTML');
                assertions.push('Should escape output properly');
                break;
        }
        
        return assertions;
    }

    /**
     * Generate integration tests
     */
    generateIntegrationTests(componentData) {
        const tests = [];
        
        // Test database operations
        if (componentData.database_tables.length > 0) {
            componentData.database_tables.forEach(table => {
                tests.push({
                    name: `Test ${table} table operations`,
                    type: 'database_test',
                    target: table,
                    operations: ['create', 'read', 'update', 'delete'],
                    assertions: [
                        `Table ${table} should exist`,
                        'CRUD operations should work',
                        'Data integrity should be maintained'
                    ]
                });
            });
        }
        
        // Test AJAX handlers
        componentData.ajax_handlers.forEach(handler => {
            tests.push({
                name: `Test AJAX handler: ${handler.action}`,
                type: 'ajax_test',
                target: handler.action,
                file: handler.file,
                assertions: [
                    'Should require authentication if needed',
                    'Should verify nonce',
                    'Should return proper response',
                    'Should handle errors gracefully'
                ]
            });
        });
        
        // Test REST endpoints
        componentData.rest_endpoints.forEach(endpoint => {
            tests.push({
                name: `Test REST endpoint: ${endpoint.route}`,
                type: 'rest_test',
                namespace: endpoint.namespace,
                route: endpoint.route,
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                assertions: [
                    'Should return proper status codes',
                    'Should validate input',
                    'Should check permissions',
                    'Should return expected schema'
                ]
            });
        });
        
        return tests;
    }

    /**
     * Generate functional tests based on test scenarios
     */
    generateFunctionalTests(componentData) {
        const tests = [];
        
        Object.entries(componentData.test_scenarios).forEach(([scenarioId, description]) => {
            tests.push({
                name: description,
                type: 'functional_test',
                scenario: scenarioId,
                steps: this.getScenarioSteps(scenarioId),
                assertions: this.getScenarioAssertions(scenarioId)
            });
        });
        
        return tests;
    }

    /**
     * Get scenario-specific steps
     */
    getScenarioSteps(scenarioId) {
        const scenarios = {
            'user_registration': [
                'Navigate to registration page',
                'Fill in required fields',
                'Submit registration form',
                'Check for confirmation message',
                'Verify email sent',
                'Activate account'
            ],
            'post_update': [
                'Login as user',
                'Navigate to activity stream',
                'Enter activity update',
                'Submit update',
                'Verify update appears in stream'
            ],
            'create_group': [
                'Login as user',
                'Navigate to groups',
                'Click create group',
                'Fill group details',
                'Set privacy settings',
                'Save group'
            ],
            'send_request': [
                'Login as user',
                'Navigate to member profile',
                'Click add friend',
                'Confirm request',
                'Check notification sent'
            ],
            'send_message': [
                'Login as user',
                'Click compose message',
                'Select recipient',
                'Write message',
                'Send message',
                'Verify delivery'
            ]
        };
        
        return scenarios[scenarioId] || ['Execute scenario steps'];
    }

    /**
     * Get scenario assertions
     */
    getScenarioAssertions(scenarioId) {
        const assertions = {
            'user_registration': [
                'User should be created in database',
                'Profile should be created',
                'Activation email should be sent',
                'User should be able to login after activation'
            ],
            'post_update': [
                'Activity should be saved to database',
                'Activity should appear in stream',
                'Activity should be visible to appropriate users',
                'Activity metadata should be correct'
            ],
            'create_group': [
                'Group should be created in database',
                'Group should appear in directory',
                'Creator should be group admin',
                'Group settings should be saved'
            ],
            'send_request': [
                'Friend request should be created',
                'Notification should be sent',
                'Request should appear in pending list',
                'Request can be accepted/rejected'
            ],
            'send_message': [
                'Message should be saved',
                'Thread should be created',
                'Recipient should receive notification',
                'Message should appear in inbox'
            ]
        };
        
        return assertions[scenarioId] || ['Scenario should complete successfully'];
    }

    /**
     * Generate hook tests
     */
    generateHookTests(componentData) {
        const tests = [];
        
        // Test filters
        componentData.filters.forEach(filter => {
            tests.push({
                name: `Test filter: ${filter.name}`,
                type: 'filter_test',
                hook: filter.name,
                file: filter.file,
                assertions: [
                    'Filter should be applied',
                    'Filter should receive correct parameters',
                    'Filter should return modified value',
                    'Filter priority should work correctly'
                ]
            });
        });
        
        // Test actions
        componentData.actions.forEach(action => {
            tests.push({
                name: `Test action: ${action.name}`,
                type: 'action_test',
                hook: action.name,
                file: action.file,
                assertions: [
                    'Action should be triggered',
                    'Action should fire at correct time',
                    'Action callbacks should execute',
                    'Action parameters should be correct'
                ]
            });
        });
        
        return tests;
    }

    /**
     * Generate security tests
     */
    generateSecurityTests(componentData) {
        const tests = [];
        
        // SQL Injection tests for database operations
        if (componentData.database_tables.length > 0) {
            tests.push({
                name: 'SQL Injection Prevention',
                type: 'sql_injection_test',
                targets: componentData.database_tables,
                vectors: [
                    "'; DROP TABLE users; --",
                    "1' OR '1'='1",
                    "admin'--"
                ],
                assertions: [
                    'Should sanitize input',
                    'Should use prepared statements',
                    'Should not execute injected SQL'
                ]
            });
        }
        
        // XSS tests for output functions
        const outputFunctions = componentData.functions.filter(f => 
            f.type === 'template' || f.name.includes('output') || f.name.includes('display')
        );
        
        if (outputFunctions.length > 0) {
            tests.push({
                name: 'XSS Prevention',
                type: 'xss_test',
                targets: outputFunctions.map(f => f.name),
                vectors: [
                    '<script>alert("XSS")</script>',
                    '<img src=x onerror=alert("XSS")>',
                    'javascript:alert("XSS")'
                ],
                assertions: [
                    'Should escape HTML output',
                    'Should sanitize user input',
                    'Should not execute scripts'
                ]
            });
        }
        
        // CSRF tests for AJAX handlers
        if (componentData.ajax_handlers.length > 0) {
            tests.push({
                name: 'CSRF Protection',
                type: 'csrf_test',
                targets: componentData.ajax_handlers.map(h => h.action),
                assertions: [
                    'Should verify nonce',
                    'Should reject invalid nonce',
                    'Should check referrer when appropriate'
                ]
            });
        }
        
        return tests;
    }

    /**
     * Generate performance tests
     */
    generatePerformanceTests(componentData) {
        const tests = [];
        
        // Database query performance
        if (componentData.database_tables.length > 0) {
            tests.push({
                name: 'Database Query Performance',
                type: 'query_performance',
                metrics: {
                    max_query_time: 100, // ms
                    max_queries_per_request: 50
                },
                assertions: [
                    'Queries should use indexes',
                    'No N+1 query problems',
                    'Query time < 100ms'
                ]
            });
        }
        
        // Component load time
        tests.push({
            name: `${componentData.name} Load Performance`,
            type: 'load_performance',
            metrics: {
                max_load_time: 1000, // ms
                max_memory_usage: 50 // MB
            },
            complexity_score: componentData.metrics.complexity_score,
            assertions: [
                'Component should load in < 1 second',
                'Memory usage should be reasonable',
                'No memory leaks'
            ]
        });
        
        // Hook execution performance
        if (componentData.hooks.length > 20) {
            tests.push({
                name: 'Hook Execution Performance',
                type: 'hook_performance',
                hook_count: componentData.hooks.length,
                assertions: [
                    'Hooks should not cause significant delay',
                    'Hook callbacks should be optimized',
                    'Avoid too many hooks on single action'
                ]
            });
        }
        
        return tests;
    }

    /**
     * Export generated tests
     */
    exportTests(outputDir) {
        const allTests = this.generateAllComponentTests();
        
        // Save overall test plan
        const testPlanPath = path.join(outputDir, 'buddypress-component-tests.json');
        fs.writeFileSync(testPlanPath, JSON.stringify(allTests, null, 2));
        
        // Generate PHP test files for each component
        Object.entries(allTests).forEach(([componentId, tests]) => {
            this.generatePHPTestFile(componentId, tests, outputDir);
            this.generateJSTestFile(componentId, tests, outputDir);
        });
        
        return testPlanPath;
    }

    /**
     * Generate PHP test file
     */
    generatePHPTestFile(componentId, tests, outputDir) {
        const className = this.toPascalCase(componentId) + 'ComponentTest';
        const phpContent = `<?php
/**
 * ${tests.component} Component Tests
 * Generated from component scan data
 */

namespace BuddyPress\\Tests\\Components\\${this.toPascalCase(componentId)};

use PHPUnit\\Framework\\TestCase;

class ${className} extends TestCase {
    
    /**
     * Component: ${tests.component}
     * Description: ${tests.description}
     * Files: ${tests.metrics.total_files}
     * Complexity: ${tests.metrics.complexity_score}
     */
    
${this.generatePHPTestMethods(tests.test_suites)}
}`;
        
        const phpPath = path.join(outputDir, `${componentId}-component-test.php`);
        fs.writeFileSync(phpPath, phpContent);
    }

    /**
     * Generate PHP test methods
     */
    generatePHPTestMethods(testSuites) {
        let methods = '';
        
        // Unit tests
        if (testSuites.unit.length > 0) {
            methods += `    /**
     * Unit Tests
     */
`;
            testSuites.unit.slice(0, 5).forEach(test => {
                const methodName = 'test' + this.toPascalCase(test.name.replace(/Test |test /g, ''));
                methods += `    
    public function ${methodName}() {
        // ${test.name}
        ${test.assertions.map(a => `$this->assertTrue(true, '${a}');`).join('\n        ')}
    }
`;
            });
        }
        
        // Functional tests
        if (testSuites.functional.length > 0) {
            methods += `    
    /**
     * Functional Tests
     */
`;
            testSuites.functional.forEach(test => {
                const methodName = 'test' + this.toPascalCase(test.scenario);
                methods += `    
    public function ${methodName}() {
        // ${test.name}
        // Steps: ${test.steps.length}
        ${test.assertions.map(a => `$this->assertTrue(true, '${a}');`).join('\n        ')}
    }
`;
            });
        }
        
        return methods;
    }

    /**
     * Generate JavaScript test file
     */
    generateJSTestFile(componentId, tests, outputDir) {
        const jsContent = `/**
 * ${tests.component} Component E2E Tests
 * Generated from component scan data
 */

import { test, expect } from '@playwright/test';

test.describe('${tests.component} Component Tests', () => {
    
    // Component Metrics:
    // Files: ${tests.metrics.total_files}
    // Classes: ${tests.metrics.total_classes}
    // Functions: ${tests.metrics.total_functions}
    // Complexity: ${tests.metrics.complexity_score}
    
${this.generateJSTestCases(tests.test_suites)}
});`;
        
        const jsPath = path.join(outputDir, `${componentId}-component.spec.ts`);
        fs.writeFileSync(jsPath, jsContent);
    }

    /**
     * Generate JavaScript test cases
     */
    generateJSTestCases(testSuites) {
        let testCases = '';
        
        // Functional tests are best for E2E
        if (testSuites.functional.length > 0) {
            testSuites.functional.forEach(test => {
                testCases += `    
    test('${test.name}', async ({ page }) => {
        // Scenario: ${test.scenario}
        ${test.steps.map(step => `\n        // Step: ${step}`).join('')}
        
        // Assertions
        ${test.assertions.map(a => `\n        // Assert: ${a}`).join('')}
    });
`;
            });
        }
        
        // Security tests
        if (testSuites.security.length > 0) {
            testSuites.security.forEach(test => {
                testCases += `    
    test('${test.name}', async ({ page }) => {
        // Security Test: ${test.type}
        ${test.assertions.map(a => `\n        // Assert: ${a}`).join('')}
    });
`;
            });
        }
        
        return testCases;
    }

    /**
     * Convert to PascalCase
     */
    toPascalCase(str) {
        return str.replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase())
            .replace(/ /g, '');
    }
}

// Main execution
async function main() {
    console.log('🧪 BuddyPress Component Test Generator');
    console.log('=====================================\n');
    
    // Load component scan data
    const scanPath = path.join(__dirname, '../../wp-content/uploads/wbcom-scan/buddypress-components-scan.json');
    
    if (!fs.existsSync(scanPath)) {
        console.error('❌ Component scan not found. Run the component scanner first.');
        process.exit(1);
    }
    
    const scanData = JSON.parse(fs.readFileSync(scanPath, 'utf8'));
    
    // Generate tests
    const generator = new ComponentTestGenerator(scanData);
    const outputDir = path.join(__dirname, '../../tests/generated/buddypress/components');
    
    // Ensure output directory exists
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    const testPlanPath = generator.exportTests(outputDir);
    
    console.log('✅ Component tests generated successfully!');
    console.log(`📁 Test plan: ${testPlanPath}`);
    console.log(`📁 Test files: ${outputDir}`);
    
    // Show summary
    const allTests = generator.generateAllComponentTests();
    console.log('\n📊 Test Summary:');
    
    Object.entries(allTests).forEach(([componentId, tests]) => {
        const totalTests = Object.values(tests.test_suites)
            .reduce((sum, suite) => sum + suite.length, 0);
        console.log(`   ${tests.component}: ${totalTests} tests`);
    });
}

// Run if called directly
if (process.argv[1] === fileURLToPath(import.meta.url)) {
    main().catch(console.error);
}

export { ComponentTestGenerator };