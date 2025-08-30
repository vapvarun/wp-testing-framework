#!/usr/bin/env node
/**
 * Dynamic Test Data Generator
 * Analyzes AST findings to identify ALL data entry points and generates appropriate test data
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Get plugin name from command line
const pluginName = process.argv[2];
if (!pluginName) {
    console.error('Usage: node dynamic-test-data-generator.mjs <plugin-name>');
    process.exit(1);
}

// Load AST analysis
const scanDir = path.join(__dirname, '..', '..', '..', 'wp-content', 'uploads', 'wbcom-scan', pluginName, new Date().toISOString().substring(0, 7));
const astFile = path.join(scanDir, 'wordpress-ast-analysis.json');

if (!fs.existsSync(astFile)) {
    console.error(`AST analysis file not found: ${astFile}`);
    process.exit(1);
}

const astData = JSON.parse(fs.readFileSync(astFile, 'utf8'));

console.log(`\n🔍 Analyzing ${pluginName} for data entry points...`);
console.log(`Files analyzed: ${astData.files_analyzed}`);

// Initialize test data plan
const testDataPlan = {
    plugin: pluginName,
    generated: new Date().toISOString(),
    detected_patterns: {},
    test_data: []
};

// 1. Analyze Custom Post Types (CPTs)
if (astData.total.custom_post_types > 0 && astData.details.custom_post_types) {
    testDataPlan.detected_patterns.custom_post_types = astData.details.custom_post_types;
    
    astData.details.custom_post_types.forEach(cpt => {
        testDataPlan.test_data.push({
            type: 'custom_post_type',
            name: cpt.name || 'unknown_cpt',
            action: 'create_posts',
            count: 5,
            data: {
                post_type: cpt.name,
                fields: {
                    post_title: `Test ${cpt.label || cpt.name} {{index}}`,
                    post_content: `Test content for ${cpt.label || cpt.name} {{index}}`,
                    post_status: 'publish'
                }
            }
        });
    });
}

// 2. Analyze Database Operations
if (astData.total.database_queries > 0) {
    console.log(`Found ${astData.total.database_queries} database operations`);
    testDataPlan.detected_patterns.database_operations = astData.total.database_queries;
    
    // Look for insert operations in methods
    const insertMethods = astData.details.methods?.filter(m => 
        m.name && (
            m.name.toLowerCase().includes('insert') ||
            m.name.toLowerCase().includes('add') ||
            m.name.toLowerCase().includes('create') ||
            m.name.toLowerCase().includes('save') ||
            m.name.toLowerCase().includes('submit') ||
            m.name.toLowerCase().includes('register')
        )
    ) || [];
    
    if (insertMethods.length > 0) {
        console.log(`Found ${insertMethods.length} data creation methods`);
        
        // Group by class to understand data models
        const dataModels = {};
        insertMethods.forEach(method => {
            const className = method.class || 'global';
            if (!dataModels[className]) {
                dataModels[className] = [];
            }
            dataModels[className].push(method.name);
        });
        
        // Generate test data for each data model
        Object.entries(dataModels).forEach(([className, methods]) => {
            const entityName = className.replace(/s$/, '').toLowerCase();
            
            testDataPlan.test_data.push({
                type: 'data_model',
                model: className,
                methods: methods,
                action: `create_${entityName}_entries`,
                count: 3,
                data: {
                    entity: entityName,
                    fields: 'auto_detect' // Will be determined based on form analysis
                }
            });
        });
    }
}

// 3. Analyze AJAX Handlers (often handle form submissions)
if (astData.total.ajax_handlers > 0) {
    console.log(`Found ${astData.total.ajax_handlers} AJAX handlers`);
    testDataPlan.detected_patterns.ajax_handlers = astData.total.ajax_handlers;
    
    // Get unique AJAX handler names
    const uniqueHandlers = [...new Set(astData.details.ajax_handlers?.map(h => h.name) || [])];
    
    uniqueHandlers.forEach(handler => {
        // Identify what type of data this handler might process
        const handlerLower = handler.toLowerCase();
        
        if (handlerLower.includes('submit') || 
            handlerLower.includes('save') || 
            handlerLower.includes('create') ||
            handlerLower.includes('add') ||
            handlerLower.includes('post') ||
            handlerLower.includes('register')) {
            
            testDataPlan.test_data.push({
                type: 'ajax_form',
                handler: handler,
                action: `test_ajax_${handler}`,
                count: 1,
                data: {
                    endpoint: handler,
                    method: 'POST',
                    fields: 'auto_detect'
                }
            });
        }
    });
}

// 4. Analyze Shortcodes (may contain forms)
if (astData.total.shortcodes > 0 && astData.details.shortcodes) {
    console.log(`Found ${astData.total.shortcodes} shortcodes`);
    testDataPlan.detected_patterns.shortcodes = astData.details.shortcodes;
    
    astData.details.shortcodes.forEach(shortcode => {
        const name = shortcode.name || shortcode;
        
        // Create test page for each shortcode
        testDataPlan.test_data.push({
            type: 'shortcode_page',
            name: name,
            action: 'create_shortcode_page',
            count: 1,
            data: {
                shortcode: name,
                page_title: `Test Page - ${name}`,
                page_content: `[${name}]`
            }
        });
        
        // If shortcode name suggests a form, add form test
        if (name.includes('form') || 
            name.includes('submit') || 
            name.includes('register') ||
            name.includes('login')) {
            
            testDataPlan.test_data.push({
                type: 'form_submission',
                form: name,
                action: `test_form_${name}`,
                count: 2,
                data: {
                    form_shortcode: name,
                    fields: 'auto_detect'
                }
            });
        }
    });
}

// 5. Analyze Custom Taxonomies
if (astData.total.custom_taxonomies > 0 && astData.details.custom_taxonomies) {
    console.log(`Found ${astData.total.custom_taxonomies} custom taxonomies`);
    testDataPlan.detected_patterns.custom_taxonomies = astData.details.custom_taxonomies;
    
    astData.details.custom_taxonomies.forEach(tax => {
        testDataPlan.test_data.push({
            type: 'taxonomy',
            name: tax.name,
            action: 'create_terms',
            count: 5,
            data: {
                taxonomy: tax.name,
                terms: [
                    `Test ${tax.label || tax.name} 1`,
                    `Test ${tax.label || tax.name} 2`,
                    `Test ${tax.label || tax.name} 3`,
                    `Test ${tax.label || tax.name} 4`,
                    `Test ${tax.label || tax.name} 5`
                ]
            }
        });
    });
}

// 6. Analyze Meta Operations (custom fields)
if (astData.total.meta_operations > 0) {
    console.log(`Found ${astData.total.meta_operations} meta operations`);
    testDataPlan.detected_patterns.meta_operations = astData.total.meta_operations;
    
    // Detect patterns in meta operations
    const metaPatterns = astData.details.meta_operations?.slice(0, 20) || [];
    
    if (metaPatterns.length > 0) {
        testDataPlan.test_data.push({
            type: 'meta_fields',
            action: 'populate_meta_fields',
            count: metaPatterns.length,
            data: {
                meta_keys: 'auto_detect',
                test_values: 'generate'
            }
        });
    }
}

// 7. Analyze Options (plugin settings)
if (astData.total.options > 0) {
    console.log(`Found ${astData.total.options} option operations`);
    testDataPlan.detected_patterns.options = astData.total.options;
    
    testDataPlan.test_data.push({
        type: 'plugin_settings',
        action: 'configure_settings',
        count: 1,
        data: {
            option_keys: 'auto_detect',
            test_values: 'safe_defaults'
        }
    });
}

// 8. Analyze Functions that suggest data operations
const dataFunctions = astData.details.functions?.filter(f => {
    const fname = f.name?.toLowerCase() || '';
    return fname.includes('create') || 
           fname.includes('add') || 
           fname.includes('insert') || 
           fname.includes('save') ||
           fname.includes('submit') ||
           fname.includes('register') ||
           fname.includes('post') ||
           fname.includes('update');
}) || [];

if (dataFunctions.length > 0) {
    console.log(`Found ${dataFunctions.length} data operation functions`);
    
    // Group by operation type
    const operations = {
        create: [],
        add: [],
        save: [],
        submit: [],
        register: [],
        post: [],
        update: []
    };
    
    dataFunctions.forEach(func => {
        const fname = func.name.toLowerCase();
        Object.keys(operations).forEach(op => {
            if (fname.includes(op)) {
                operations[op].push(func.name);
            }
        });
    });
    
    // Add to detected patterns
    testDataPlan.detected_patterns.data_functions = operations;
    
    // Generate test scenarios for significant operations
    Object.entries(operations).forEach(([op, funcs]) => {
        if (funcs.length > 0) {
            testDataPlan.test_data.push({
                type: 'function_test',
                operation: op,
                action: `test_${op}_operations`,
                count: Math.min(funcs.length, 5),
                data: {
                    functions: funcs.slice(0, 5),
                    test_type: op
                }
            });
        }
    });
}

// 9. Special detection for specific plugin patterns
// Detect forum/discussion plugins
const forumIndicators = [
    'forum', 'topic', 'reply', 'thread', 'discussion', 'board', 'post'
];

const isForumPlugin = forumIndicators.some(indicator => {
    const lowerPlugin = pluginName.toLowerCase();
    const hasFunctions = dataFunctions.some(f => f.name.toLowerCase().includes(indicator));
    const hasClasses = astData.details.classes?.some(c => c.name?.toLowerCase().includes(indicator));
    return lowerPlugin.includes(indicator) || hasFunctions || hasClasses;
});

if (isForumPlugin) {
    console.log('📋 Detected forum/discussion plugin patterns');
    testDataPlan.detected_patterns.plugin_type = 'forum';
    
    // Add forum-specific test data
    testDataPlan.test_data.push({
        type: 'forum_content',
        action: 'create_forum_hierarchy',
        count: 1,
        data: {
            structure: {
                forums: 3,
                topics_per_forum: 3,
                replies_per_topic: 3
            }
        }
    });
}

// 10. Detect e-commerce patterns
const ecommerceIndicators = ['product', 'cart', 'order', 'payment', 'checkout', 'shop'];
const isEcommerce = ecommerceIndicators.some(indicator => {
    const lowerPlugin = pluginName.toLowerCase();
    const hasFunctions = dataFunctions.some(f => f.name.toLowerCase().includes(indicator));
    return lowerPlugin.includes(indicator) || hasFunctions;
});

if (isEcommerce) {
    console.log('🛒 Detected e-commerce plugin patterns');
    testDataPlan.detected_patterns.plugin_type = 'ecommerce';
    
    testDataPlan.test_data.push({
        type: 'ecommerce_content',
        action: 'create_shop_data',
        count: 1,
        data: {
            products: 10,
            categories: 3,
            test_orders: 5
        }
    });
}

// 11. Detect form builder patterns
const formIndicators = ['form', 'field', 'submit', 'entry', 'submission'];
const isFormBuilder = formIndicators.some(indicator => {
    const hasFunctions = dataFunctions.some(f => f.name.toLowerCase().includes(indicator));
    const hasAjax = astData.details.ajax_handlers?.some(h => h.name?.toLowerCase().includes(indicator));
    return hasFunctions || hasAjax;
});

if (isFormBuilder) {
    console.log('📝 Detected form builder patterns');
    testDataPlan.detected_patterns.plugin_type = 'forms';
    
    testDataPlan.test_data.push({
        type: 'form_builder',
        action: 'create_test_forms',
        count: 1,
        data: {
            forms: 3,
            fields_per_form: 5,
            test_submissions: 10
        }
    });
}

// Summary
console.log(`\n📊 Test Data Plan Summary:`);
console.log(`   Plugin Type: ${testDataPlan.detected_patterns.plugin_type || 'general'}`);
console.log(`   Total test scenarios: ${testDataPlan.test_data.length}`);
console.log(`   Data entry points detected:`);
if (testDataPlan.detected_patterns.custom_post_types) 
    console.log(`   - Custom Post Types: ${testDataPlan.detected_patterns.custom_post_types.length}`);
if (testDataPlan.detected_patterns.ajax_handlers)
    console.log(`   - AJAX Handlers: ${testDataPlan.detected_patterns.ajax_handlers}`);
if (testDataPlan.detected_patterns.shortcodes)
    console.log(`   - Shortcodes: ${testDataPlan.detected_patterns.shortcodes.length}`);
if (testDataPlan.detected_patterns.database_operations)
    console.log(`   - Database Operations: ${testDataPlan.detected_patterns.database_operations}`);
if (testDataPlan.detected_patterns.data_functions)
    console.log(`   - Data Functions: ${Object.values(testDataPlan.detected_patterns.data_functions).flat().length}`);

// Save test data plan
const outputDir = path.join(scanDir, 'reports');
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

const outputFile = path.join(outputDir, 'dynamic-test-data-plan.json');
fs.writeFileSync(outputFile, JSON.stringify(testDataPlan, null, 2));

console.log(`\n✅ Test data plan saved to: ${outputFile}`);

// Also generate a PHP script for creating the test data
const phpScript = generatePHPScript(testDataPlan);
const phpFile = path.join(outputDir, 'create-test-data.php');
fs.writeFileSync(phpFile, phpScript);

console.log(`✅ PHP script generated: ${phpFile}`);

function generatePHPScript(plan) {
    let script = `<?php
/**
 * Dynamic Test Data Creator for ${plan.plugin}
 * Generated: ${plan.generated}
 * 
 * This script creates test data based on detected plugin patterns
 */

// Load WordPress
// Script is in: wp-content/uploads/wbcom-scan/[plugin]/[date]/reports/
// Need to go up to root: ../../../../../../../wp-load.php (7 levels)
\$wp_root = dirname(dirname(dirname(dirname(dirname(dirname(dirname(__FILE__)))))));
\$wp_load = \$wp_root . '/wp-load.php';

if (!file_exists(\$wp_load)) {
    echo "ERROR: Could not find wp-load.php at: \$wp_load\\n";
    echo "Current file location: " . __FILE__ . "\\n";
    exit(1);
}

require_once \$wp_load;

echo "Creating test data for ${plan.plugin}...\\n";
echo "Detected patterns: " . implode(", ", array('${Object.keys(plan.detected_patterns).join("', '")}')) . "\\n\\n";

\$created_data = array();
`;

    // Generate PHP code for each test data item
    plan.test_data.forEach(item => {
        script += `
// ${item.type}: ${item.action}
echo "Creating ${item.type}: ${item.action}...\\n";
`;
        
        switch(item.type) {
            case 'custom_post_type':
                script += `
for (\$i = 1; \$i <= ${item.count}; \$i++) {
    \$post_id = wp_insert_post(array(
        'post_type' => '${item.data.post_type}',
        'post_title' => str_replace('{{index}}', \$i, '${item.data.fields.post_title}'),
        'post_content' => str_replace('{{index}}', \$i, '${item.data.fields.post_content}'),
        'post_status' => '${item.data.fields.post_status}'
    ));
    if (\$post_id) {
        \$created_data['${item.type}'][] = \$post_id;
        echo "  Created ${item.data.post_type} #\$i (ID: \$post_id)\\n";
    }
}
`;
                break;
                
            case 'shortcode_page':
                script += `
\$page_id = wp_insert_post(array(
    'post_type' => 'page',
    'post_title' => '${item.data.page_title}',
    'post_content' => '${item.data.page_content}',
    'post_status' => 'publish',
    'post_name' => 'test-page-${item.data.shortcode}'
));
if (\$page_id) {
    \$created_data['shortcode_pages'][] = \$page_id;
    echo "  Created shortcode page for [${item.data.shortcode}] (ID: \$page_id)\\n";
}
`;
                break;
                
            case 'taxonomy':
                script += `
\$terms = ${JSON.stringify(item.data.terms)};
foreach (\$terms as \$term) {
    \$term_id = wp_insert_term(\$term, '${item.data.taxonomy}');
    if (!is_wp_error(\$term_id)) {
        \$created_data['taxonomy_terms'][] = \$term_id['term_id'];
        echo "  Created term: \$term\\n";
    }
}
`;
                break;
                
            case 'forum_content':
                script += `
// Check if this is a forum plugin and create appropriate content
if (function_exists('WPF') || class_exists('wpForo') || function_exists('bbp_insert_forum')) {
    echo "  Creating forum structure...\\n";
    // Plugin-specific forum creation will be handled by dedicated scripts
    \$created_data['forum_content'] = 'check_plugin_specific_script';
}
`;
                break;
        }
    });
    
    script += `
// Save created data
\$output_file = dirname(__FILE__) . '/test-data-created.json';
file_put_contents(\$output_file, json_encode(\$created_data, JSON_PRETTY_PRINT));

echo "\\n✅ Test data creation complete!\\n";
echo "Results saved to: \$output_file\\n";
`;
    
    return script;
}

// Export for use in other scripts
export { testDataPlan };