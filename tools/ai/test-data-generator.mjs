#!/usr/bin/env node

/**
 * AI Test Data Generator
 * Analyzes plugin features and generates appropriate test data recommendations
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Get plugin name from args
const pluginName = process.argv[2];
if (!pluginName) {
    console.error('Usage: node test-data-generator.mjs <plugin-name>');
    process.exit(1);
}

// Read analysis results
const scanPath = path.join(process.cwd(), '..', 'wp-content', 'uploads', 'wbcom-scan', pluginName);
let latestScan, analysisPath;
try {
    latestScan = fs.readdirSync(scanPath).sort().pop();
    analysisPath = path.join(scanPath, latestScan);
} catch (e) {
    console.error('Error: Could not find scan directory for', pluginName);
    console.error('Looking in:', scanPath);
    process.exit(1);
}

// Read AST analysis - try both WordPress and generic AST
let astData = {};
try {
    // First try WordPress AST analysis
    let astFile = path.join(analysisPath, 'wordpress-ast-analysis.json');
    if (!fs.existsSync(astFile)) {
        // Fallback to copied AST in reports
        astFile = path.join(analysisPath, 'reports', 'ast-analysis.json');
    }
    if (!fs.existsSync(astFile)) {
        // Final fallback to old location
        astFile = path.join(analysisPath, 'ast-analysis.json');
    }
    if (fs.existsSync(astFile)) {
        astData = JSON.parse(fs.readFileSync(astFile, 'utf8'));
    }
} catch (e) {
    console.error('Warning: Could not read AST analysis');
}

// Read functionality analysis
let features = {
    custom_post_types: [],
    taxonomies: [],
    shortcodes: [],
    ajax_handlers: [],
    rest_endpoints: [],
    hooks: [],
    database_tables: [],
    settings_pages: [],
    widgets: [],
    blocks: []
};

// Extract features from AST
if (astData.details) {
    features = { ...features, ...astData.details };
}

// Read additional analysis files
try {
    const cptFile = path.join(analysisPath, 'reports', 'custom-post-types.txt');
    if (fs.existsSync(cptFile)) {
        const cpts = fs.readFileSync(cptFile, 'utf8').split('\n').filter(Boolean);
        cpts.forEach(cpt => {
            const [name] = cpt.split(',');
            if (name && !features.custom_post_types.find(c => c.name === name)) {
                features.custom_post_types.push({ name });
            }
        });
    }
} catch (e) {}

// Special handling for BBPress plugin
if (pluginName.toLowerCase() === 'bbpress') {
    // BBPress registers post types dynamically at runtime
    features.custom_post_types = [
        { name: 'forum', label: 'Forum', description: 'BBPress Forum post type' },
        { name: 'topic', label: 'Topic', description: 'BBPress Topic post type' },
        { name: 'reply', label: 'Reply', description: 'BBPress Reply post type' }
    ];
    
    // BBPress shortcodes are registered dynamically
    features.shortcodes = [
        { name: 'bbp-forum-index', description: 'Forum Index' },
        { name: 'bbp-forum-form', description: 'Forum Form' },
        { name: 'bbp-single-forum', description: 'Single Forum' },
        { name: 'bbp-topic-index', description: 'Topic Index' },
        { name: 'bbp-topic-form', description: 'Topic Form' },
        { name: 'bbp-single-topic', description: 'Single Topic' },
        { name: 'bbp-topic-tags', description: 'Topic Tags Cloud' },
        { name: 'bbp-single-tag', description: 'Topics of Tag' },
        { name: 'bbp-reply-form', description: 'Reply Form' },
        { name: 'bbp-single-reply', description: 'Single Reply' },
        { name: 'bbp-single-view', description: 'Single View' },
        { name: 'bbp-search-form', description: 'Search Form' },
        { name: 'bbp-search', description: 'Search Results' },
        { name: 'bbp-login', description: 'Login Form' },
        { name: 'bbp-register', description: 'Registration Form' },
        { name: 'bbp-lost-pass', description: 'Lost Password Form' },
        { name: 'bbp-stats', description: 'Forum Statistics' }
    ];
    
    // BBPress taxonomies
    features.taxonomies = [
        { name: 'topic-tag', label: 'Topic Tag', description: 'BBPress topic tags' }
    ];
}

// Extract AJAX handlers from AST
if (astData.total && astData.total.ajax_handlers > 0) {
    // BBPress AJAX handlers detected in AST
    if (!features.ajax_handlers || features.ajax_handlers.length === 0) {
        features.ajax_handlers = [];
        for (let i = 1; i <= Math.min(astData.total.ajax_handlers, 10); i++) {
            features.ajax_handlers.push({
                name: `ajax_handler_${i}`,
                description: `AJAX handler ${i}`
            });
        }
    }
}

// Generate test data recommendations
const testDataPlan = {
    plugin: pluginName,
    generated: new Date().toISOString(),
    test_data: []
};

// Generate data for custom post types
features.custom_post_types.forEach(cpt => {
    // Special handling for BBPress post types
    if (pluginName.toLowerCase() === 'bbpress') {
        if (cpt.name === 'forum') {
            testDataPlan.test_data.push({
                type: 'custom_post_type',
                name: 'forum',
                action: 'create_forums',
                count: 3,
                data: {
                    post_type: 'forum',
                    fields: {
                        post_title: `Test Forum {{index}}`,
                        post_content: `This is test forum {{index}} for comprehensive testing of BBPress functionality.`,
                        post_status: 'publish'
                    },
                    bbpress_meta: {
                        '_bbp_forum_type': 'forum',
                        '_bbp_status': 'open'
                    }
                }
            });
        } else if (cpt.name === 'topic') {
            testDataPlan.test_data.push({
                type: 'custom_post_type',
                name: 'topic',
                action: 'create_topics',
                count: 9,
                data: {
                    post_type: 'topic',
                    fields: {
                        post_title: `Test Topic {{index}}`,
                        post_content: `This is test topic {{index}}. Discussing important test matters with detailed content for proper testing.`,
                        post_status: 'publish'
                    },
                    bbpress_meta: {
                        '_bbp_topic_status': 'publish',
                        '_bbp_stick_topic': '0'
                    },
                    assign_to_forum: true
                }
            });
        } else if (cpt.name === 'reply') {
            testDataPlan.test_data.push({
                type: 'custom_post_type',
                name: 'reply',
                action: 'create_replies',
                count: 27,
                data: {
                    post_type: 'reply',
                    fields: {
                        post_title: `Re: Test Topic`,
                        post_content: `This is test reply {{index}}. Providing thoughtful response to the topic discussion.`,
                        post_status: 'publish'
                    },
                    bbpress_meta: {
                        '_bbp_reply_status': 'publish'
                    },
                    assign_to_topic: true
                }
            });
        }
    } else {
        // Standard custom post type
        testDataPlan.test_data.push({
            type: 'custom_post_type',
            name: cpt.name,
            action: 'create_posts',
            count: 5,
            data: {
                post_type: cpt.name,
                fields: {
                    post_title: `Test ${cpt.name} {{index}}`,
                    post_content: `Test content for ${cpt.name} {{index}}. This is comprehensive test data to verify functionality.`,
                    post_status: 'publish'
                },
                meta_fields: cpt.meta_fields || []
            }
        });
    }
});

// Generate data for taxonomies
features.taxonomies.forEach(tax => {
    testDataPlan.test_data.push({
        type: 'taxonomy',
        name: tax.name,
        action: 'create_terms',
        count: 3,
        data: {
            taxonomy: tax.name,
            terms: [
                `Test ${tax.name} Category 1`,
                `Test ${tax.name} Category 2`,
                `Test ${tax.name} Category 3`
            ]
        }
    });
});

// Generate test pages for shortcodes
features.shortcodes.forEach(sc => {
    testDataPlan.test_data.push({
        type: 'shortcode',
        name: sc.name,
        action: 'create_page',
        data: {
            post_type: 'page',
            post_title: `Test Page: [${sc.name}]`,
            post_content: `<h2>Testing ${sc.name} Shortcode</h2>\n[${sc.name}]`,
            post_status: 'publish'
        }
    });
});

// Generate test data for forms
if (pluginName.includes('form') || pluginName.includes('contact')) {
    testDataPlan.test_data.push({
        type: 'form_submission',
        action: 'test_forms',
        data: {
            test_submissions: 3,
            fields: {
                name: 'Test User {{index}}',
                email: 'test{{index}}@example.com',
                message: 'Test submission {{index}}'
            }
        }
    });
}

// Generate e-commerce test data if relevant
if (features.custom_post_types.find(cpt => cpt.name === 'product' || cpt.name === 'shop_order')) {
    testDataPlan.test_data.push({
        type: 'ecommerce',
        action: 'create_products',
        count: 10,
        data: {
            post_type: 'product',
            fields: {
                post_title: 'Test Product {{index}}',
                post_content: 'High-quality test product with detailed description.',
                post_status: 'publish'
            },
            meta: {
                _price: '{{random:10-500}}',
                _stock: '{{random:0-100}}',
                _sku: 'TEST-SKU-{{index}}'
            }
        }
    });
}

// Generate test users if plugin has user features
if (features.hooks.find(h => h.name && h.name.includes('user'))) {
    testDataPlan.test_data.push({
        type: 'users',
        action: 'create_users',
        count: 3,
        data: {
            roles: ['subscriber', 'contributor', 'author'],
            user_template: {
                user_login: 'test_user_{{index}}',
                user_email: 'test{{index}}@example.com',
                display_name: 'Test User {{index}}'
            }
        }
    });
}

// Generate settings test if plugin has settings
if (features.settings_pages.length > 0) {
    testDataPlan.test_data.push({
        type: 'settings',
        action: 'configure_settings',
        data: {
            enable_features: true,
            test_mode: true,
            sample_settings: features.settings_pages.map(page => ({
                page: page.slug || page.name,
                test_values: true
            }))
        }
    });
}

// Generate widget test data
features.widgets.forEach(widget => {
    testDataPlan.test_data.push({
        type: 'widget',
        name: widget.name,
        action: 'add_widget',
        data: {
            sidebar: 'sidebar-1',
            settings: {
                title: `Test ${widget.name}`,
                content: 'Test widget content'
            }
        }
    });
});

// Generate block test data
features.blocks.forEach(block => {
    testDataPlan.test_data.push({
        type: 'block',
        name: block.name,
        action: 'create_page',
        data: {
            post_title: `Test Block: ${block.name}`,
            post_content: `<!-- wp:${block.name} /-->`,
            post_status: 'publish'
        }
    });
});

// Generate REST API test calls
features.rest_endpoints.forEach(endpoint => {
    testDataPlan.test_data.push({
        type: 'rest_api',
        endpoint: endpoint.route,
        action: 'test_endpoint',
        methods: endpoint.methods || ['GET'],
        test_data: {
            GET: {},
            POST: { test: 'data' }
        }
    });
});

// Generate AJAX test calls
features.ajax_handlers.forEach(handler => {
    testDataPlan.test_data.push({
        type: 'ajax',
        action: handler.name,
        test_data: {
            action: handler.name,
            nonce: '{{generate_nonce}}',
            test_param: 'test_value'
        }
    });
});

// Output test data plan
const outputPath = path.join(analysisPath, 'reports', 'test-data-plan.json');
fs.writeFileSync(outputPath, JSON.stringify(testDataPlan, null, 2));

// Generate executable test data script
const scriptPath = path.join(analysisPath, 'reports', 'generate-test-data.php');
let phpScript = `<?php
/**
 * AI-Generated Test Data Script for ${pluginName}
 * Generated: ${new Date().toISOString()}
 */

// Load WordPress
if (!defined('ABSPATH')) {
    require_once(dirname(__FILE__) . '/../../../../../../wp-load.php');
}

echo "Generating test data for ${pluginName}...\\n";
$created_items = [];

`;

// Generate PHP code for each test data item
testDataPlan.test_data.forEach(item => {
    switch(item.type) {
        case 'custom_post_type':
            // Special handling for BBPress post types
            if (item.action === 'create_forums') {
                phpScript += `
// Create BBPress Forums
echo "Creating ${item.count} BBPress forums...\\n";
if (function_exists('bbp_insert_forum')) {
    for ($i = 1; $i <= ${item.count}; $i++) {
        $forum_data = [
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_status' => '${item.data.fields.post_status}'
        ];
        $forum_id = bbp_insert_forum($forum_data);
        if ($forum_id) {
            $created_items['forums'][] = $forum_id;
            echo "  Created Forum ID: $forum_id\\n";
        }
    }
} else {
    // Fallback to standard WordPress post creation
    for ($i = 1; $i <= ${item.count}; $i++) {
        $post_id = wp_insert_post([
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_type' => 'forum',
            'post_status' => '${item.data.fields.post_status}'
        ]);
        if ($post_id) {
            $created_items['forums'][] = $post_id;
            update_post_meta($post_id, '_bbp_forum_type', 'forum');
            update_post_meta($post_id, '_bbp_status', 'open');
            echo "  Created Forum ID: $post_id\\n";
        }
    }
}
`;
            } else if (item.action === 'create_topics') {
                phpScript += `
// Create BBPress Topics
echo "Creating ${item.count} BBPress topics...\\n";
$forums = get_posts(['post_type' => 'forum', 'posts_per_page' => -1, 'post_status' => 'publish']);
if (function_exists('bbp_insert_topic') && !empty($forums)) {
    for ($i = 1; $i <= ${item.count}; $i++) {
        $forum_index = ($i - 1) % count($forums);
        $forum_id = $forums[$forum_index]->ID;
        
        $topic_data = [
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_parent' => $forum_id,
            'post_status' => '${item.data.fields.post_status}'
        ];
        $topic_id = bbp_insert_topic($topic_data, ['forum_id' => $forum_id]);
        if ($topic_id) {
            $created_items['topics'][] = $topic_id;
            echo "  Created Topic ID: $topic_id in Forum ID: $forum_id\\n";
        }
    }
} else {
    // Fallback to standard WordPress post creation
    for ($i = 1; $i <= ${item.count}; $i++) {
        $forum_index = ($i - 1) % max(1, count($forums));
        $forum_id = !empty($forums) ? $forums[$forum_index]->ID : 0;
        
        $post_id = wp_insert_post([
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_type' => 'topic',
            'post_parent' => $forum_id,
            'post_status' => '${item.data.fields.post_status}'
        ]);
        if ($post_id) {
            $created_items['topics'][] = $post_id;
            update_post_meta($post_id, '_bbp_forum_id', $forum_id);
            update_post_meta($post_id, '_bbp_topic_status', 'publish');
            echo "  Created Topic ID: $post_id in Forum ID: $forum_id\\n";
        }
    }
}
`;
            } else if (item.action === 'create_replies') {
                phpScript += `
// Create BBPress Replies
echo "Creating ${item.count} BBPress replies...\\n";
$topics = get_posts(['post_type' => 'topic', 'posts_per_page' => -1, 'post_status' => 'publish']);
if (function_exists('bbp_insert_reply') && !empty($topics)) {
    for ($i = 1; $i <= ${item.count}; $i++) {
        $topic_index = ($i - 1) % count($topics);
        $topic_id = $topics[$topic_index]->ID;
        $forum_id = get_post_meta($topic_id, '_bbp_forum_id', true);
        
        $reply_data = [
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_parent' => $topic_id,
            'post_status' => '${item.data.fields.post_status}'
        ];
        $reply_id = bbp_insert_reply($reply_data, ['topic_id' => $topic_id, 'forum_id' => $forum_id]);
        if ($reply_id) {
            $created_items['replies'][] = $reply_id;
            echo "  Created Reply ID: $reply_id for Topic ID: $topic_id\\n";
        }
    }
} else {
    // Fallback to standard WordPress post creation
    for ($i = 1; $i <= ${item.count}; $i++) {
        $topic_index = ($i - 1) % max(1, count($topics));
        $topic_id = !empty($topics) ? $topics[$topic_index]->ID : 0;
        $forum_id = get_post_meta($topic_id, '_bbp_forum_id', true);
        
        $post_id = wp_insert_post([
            'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
            'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
            'post_type' => 'reply',
            'post_parent' => $topic_id,
            'post_status' => '${item.data.fields.post_status}'
        ]);
        if ($post_id) {
            $created_items['replies'][] = $post_id;
            update_post_meta($post_id, '_bbp_topic_id', $topic_id);
            update_post_meta($post_id, '_bbp_forum_id', $forum_id);
            update_post_meta($post_id, '_bbp_reply_status', 'publish');
            echo "  Created Reply ID: $post_id for Topic ID: $topic_id\\n";
        }
    }
}
`;
            } else {
                // Standard custom post type
                phpScript += `
// Create ${item.name} posts
echo "Creating ${item.count} ${item.name} posts...\\n";
for ($i = 1; $i <= ${item.count}; $i++) {
    $post_id = wp_insert_post([
        'post_title' => str_replace('{{index}}', $i, '${item.data.fields.post_title}'),
        'post_content' => str_replace('{{index}}', $i, '${item.data.fields.post_content}'),
        'post_type' => '${item.data.post_type}',
        'post_status' => '${item.data.fields.post_status}'
    ]);
    if ($post_id) {
        $created_items['${item.name}'][] = $post_id;
        echo "  Created ${item.name} ID: $post_id\\n";
    }
}
`;
            }
            break;
            
        case 'shortcode':
            phpScript += `
// Create test page for shortcode [${item.name}]
$page_id = wp_insert_post([
    'post_title' => '${item.data.post_title}',
    'post_content' => '${item.data.post_content}',
    'post_type' => '${item.data.post_type}',
    'post_status' => '${item.data.post_status}'
]);
if ($page_id) {
    $created_items['shortcode_pages'][] = $page_id;
    echo "Created shortcode test page: " . get_permalink($page_id) . "\\n";
}
`;
            break;
            
        case 'taxonomy':
            phpScript += `
// Create ${item.name} terms
echo "Creating ${item.name} terms...\\n";
${item.data.terms.map(term => 
    `$term = wp_insert_term('${term}', '${item.data.taxonomy}');
if (!is_wp_error($term)) {
    $created_items['${item.name}_terms'][] = $term['term_id'];
    echo "  Created term: ${term}\\n";
}`).join('\n')}
`;
            break;
    }
});

phpScript += `
// Summary
echo "\\n=== Test Data Generation Complete ===\\n";
foreach ($created_items as $type => $ids) {
    echo "$type: " . count($ids) . " items created\\n";
}

// Save created items for cleanup
file_put_contents(__DIR__ . '/test-data-created.json', json_encode($created_items));
?>`;

fs.writeFileSync(scriptPath, phpScript);

// Output summary
console.log(`✅ Test Data Plan Generated for ${pluginName}`);
console.log(`   Found ${features.custom_post_types.length} custom post types`);
console.log(`   Found ${features.shortcodes.length} shortcodes`);
console.log(`   Found ${features.ajax_handlers.length} AJAX handlers`);
console.log(`   Found ${features.rest_endpoints.length} REST endpoints`);
console.log(`   Generated ${testDataPlan.test_data.length} test data items`);
console.log(`   Test data plan saved to: ${outputPath}`);
console.log(`   PHP script saved to: ${scriptPath}`);

// Output the plan for use by the main script
console.log(JSON.stringify(testDataPlan, null, 2));