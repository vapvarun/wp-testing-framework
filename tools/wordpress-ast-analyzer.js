#!/usr/bin/env node

/**
 * WordPress Plugin AST Analyzer
 * Specifically optimized for WordPress plugin analysis
 * Detects all WordPress patterns, hooks, APIs, and security issues
 */

const parser = require('php-parser');
const fs = require('fs');
const path = require('path');

// Initialize PHP parser with WordPress-optimized settings
const phpParser = new parser({
    parser: { 
        extractDoc: true, 
        php7: true,
        suppressErrors: true 
    },
    ast: { 
        withPositions: true,
        withSource: true 
    }
});

// WordPress-specific analysis structure
const analysis = {
    files_analyzed: 0,
    total: {
        functions: 0,
        classes: 0,
        methods: 0,
        hooks: 0,
        shortcodes: 0,
        ajax_handlers: 0,
        rest_endpoints: 0,
        database_queries: 0,
        security_issues: 0,
        custom_post_types: 0,
        custom_taxonomies: 0,
        meta_operations: 0,
        nonces: 0,
        capabilities: 0,
        sanitization: 0,
        escaping: 0,
        options: 0,
        transients: 0,
        crons: 0,
        widgets: 0,
        blocks: 0,
        admin_pages: 0,
        settings: 0,
        scripts: 0,
        styles: 0
    },
    details: {
        functions: [],
        classes: [],
        methods: [],
        hooks: [],
        shortcodes: [],
        ajax_handlers: [],
        rest_endpoints: [],
        database_queries: [],
        security_issues: [],
        custom_post_types: [],
        custom_taxonomies: [],
        meta_operations: [],
        forms: [],
        nonces: [],
        capabilities: [],
        sanitization: [],
        escaping: [],
        options: [],
        transients: [],
        crons: [],
        widgets: [],
        blocks: [],
        admin_pages: [],
        settings: [],
        scripts: [],
        styles: []
    },
    wordpress_patterns: {
        uses_hooks: false,
        uses_shortcodes: false,
        uses_ajax: false,
        uses_rest_api: false,
        has_custom_post_types: false,
        has_custom_taxonomies: false,
        uses_database: false,
        has_security_issues: false,
        uses_gutenberg: false,
        uses_widgets: false,
        uses_customizer: false,
        uses_multisite: false,
        uses_user_meta: false,
        uses_options_api: false,
        uses_transients: false,
        uses_cron: false
    }
};

/**
 * Main analyzer function
 */
function analyzeWordPressPlugin(pluginPath) {
    console.log('Analyzing WordPress plugin:', pluginPath);
    console.log('Detecting WordPress patterns, APIs, and potential issues...\n');
    
    const phpFiles = findPHPFiles(pluginPath);
    
    phpFiles.forEach(file => {
        try {
            const code = fs.readFileSync(file, 'utf8');
            const ast = phpParser.parseCode(code);
            
            if (ast) {
                analysis.files_analyzed++;
                traverseAST(ast, analysis);
            }
        } catch (e) {
            console.error(`Error parsing ${file}:`, e.message);
        }
    });
    
    // Set pattern flags based on findings
    updatePatternFlags();
    
    return analysis;
}

/**
 * Find all PHP files in directory
 */
function findPHPFiles(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory() && !file.startsWith('.') && file !== 'vendor' && file !== 'node_modules') {
            findPHPFiles(filePath, fileList);
        } else if (file.endsWith('.php')) {
            fileList.push(filePath);
        }
    });
    
    return fileList;
}

/**
 * Traverse AST and extract WordPress patterns
 */
function traverseAST(node, analysis, parentClass = null) {
    if (!node || typeof node !== 'object') return;
    
    // Handle arrays
    if (Array.isArray(node)) {
        node.forEach(n => traverseAST(n, analysis, parentClass));
        return;
    }
    
    switch (node.kind) {
        case 'function':
            analysis.total.functions++;
            analysis.details.functions.push({
                name: node.name.name || node.name,
                line: node.loc?.start?.line,
                params: node.arguments?.length || 0,
                doc: node.leadingComments?.[0]?.value || null
            });
            // Traverse function body
            if (node.body) {
                traverseAST(node.body, analysis, parentClass);
            }
            break;
            
        case 'class':
            const className = node.name.name || node.name;
            analysis.total.classes++;
            analysis.details.classes.push({
                name: className,
                line: node.loc?.start?.line,
                extends: node.extends?.name,
                implements: node.implements?.map(i => i.name),
                isAbstract: node.isAbstract,
                isFinal: node.isFinal
            });
            // Check for WordPress widget/block classes
            checkWordPressClasses(node, analysis);
            // Traverse class body
            if (node.body) {
                node.body.forEach(member => {
                    traverseAST(member, analysis, className);
                });
            }
            break;
            
        case 'method':
            analysis.total.methods++;
            analysis.details.methods.push({
                name: node.name.name || node.name,
                class: parentClass,
                line: node.loc?.start?.line,
                visibility: node.visibility,
                static: node.isStatic,
                abstract: node.isAbstract,
                params: node.arguments?.length || 0
            });
            // Traverse method body
            if (node.body) {
                traverseAST(node.body, analysis, parentClass);
            }
            break;
            
        case 'call':
            analyzeWordPressCall(node, analysis);
            break;
            
        case 'new':
            analyzeClassInstantiation(node, analysis);
            break;
            
        case 'assign':
            analyzeAssignment(node, analysis);
            break;
    }
    
    // Recursively traverse all child nodes
    for (const key in node) {
        if (key !== 'loc' && key !== 'kind' && key !== 'leadingComments' && key !== 'trailingComments') {
            if (typeof node[key] === 'object') {
                traverseAST(node[key], analysis, parentClass);
            }
        }
    }
}

/**
 * Analyze WordPress function calls
 */
function analyzeWordPressCall(node, analysis) {
    if (!node.what) return;
    
    const funcName = getFunctionName(node.what);
    if (!funcName) return;
    
    // WordPress Hooks
    if (['add_action', 'add_filter', 'do_action', 'apply_filters', 'do_action_ref_array', 'apply_filters_ref_array'].includes(funcName)) {
        const hookName = getStringValue(node.arguments?.[0]);
        if (hookName) {
            analysis.total.hooks++;
            analysis.details.hooks.push({
                type: funcName,
                name: hookName,
                line: node.loc?.start?.line,
                priority: getNumericValue(node.arguments?.[2]) || 10,
                accepted_args: getNumericValue(node.arguments?.[3]) || 1,
                callback: getFunctionName(node.arguments?.[1])
            });
            
            // Check for specific WordPress hooks
            checkSpecialHooks(hookName, node, analysis);
        }
    }
    
    // AJAX handlers
    if (funcName === 'add_action') {
        const hookName = getStringValue(node.arguments?.[0]);
        if (hookName && typeof hookName === 'string' && hookName.startsWith('wp_ajax_')) {
            analysis.total.ajax_handlers++;
            analysis.details.ajax_handlers.push({
                name: hookName.replace('wp_ajax_', '').replace('nopriv_', ''),
                line: node.loc?.start?.line,
                public: hookName.includes('nopriv'),
                callback: getFunctionName(node.arguments?.[1])
            });
        }
    }
    
    // Shortcodes
    if (funcName === 'add_shortcode') {
        const shortcode = getStringValue(node.arguments?.[0]);
        if (shortcode) {
            analysis.total.shortcodes++;
            analysis.details.shortcodes.push({
                name: shortcode,
                line: node.loc?.start?.line,
                callback: getFunctionName(node.arguments?.[1])
            });
        }
    }
    
    // REST API
    if (funcName === 'register_rest_route') {
        const namespace = getStringValue(node.arguments?.[0]);
        const route = getStringValue(node.arguments?.[1]);
        if (namespace && route) {
            analysis.total.rest_endpoints++;
            analysis.details.rest_endpoints.push({
                namespace,
                route,
                line: node.loc?.start?.line,
                methods: extractRestMethods(node.arguments?.[2])
            });
        }
    }
    
    // Custom Post Types
    if (funcName === 'register_post_type') {
        const postType = getStringValue(node.arguments?.[0]);
        if (postType) {
            analysis.total.custom_post_types++;
            analysis.details.custom_post_types.push({
                name: postType,
                line: node.loc?.start?.line,
                args: extractArrayKeys(node.arguments?.[1])
            });
        }
    }
    
    // Custom Taxonomies
    if (funcName === 'register_taxonomy') {
        const taxonomy = getStringValue(node.arguments?.[0]);
        if (taxonomy) {
            analysis.total.custom_taxonomies++;
            analysis.details.custom_taxonomies.push({
                name: taxonomy,
                line: node.loc?.start?.line,
                object_type: getStringValue(node.arguments?.[1]),
                args: extractArrayKeys(node.arguments?.[2])
            });
        }
    }
    
    // Database operations
    if (funcName?.startsWith('wpdb->') || funcName?.includes('$wpdb->')) {
        analysis.total.database_queries++;
        const operation = funcName.split('->').pop();
        analysis.details.database_queries.push({
            type: operation,
            line: node.loc?.start?.line,
            query: getStringValue(node.arguments?.[0])?.toString().substring(0, 100) || null
        });
        
        // Check for security issues
        checkDatabaseSecurity(node, operation, analysis);
    }
    
    // WordPress Options API
    if (['get_option', 'update_option', 'add_option', 'delete_option', 'get_site_option', 'update_site_option'].includes(funcName)) {
        const optionName = getStringValue(node.arguments?.[0]);
        if (optionName) {
            analysis.total.options++;
            analysis.details.options.push({
                type: funcName,
                name: optionName,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Transients API
    if (['get_transient', 'set_transient', 'delete_transient', 'get_site_transient', 'set_site_transient'].includes(funcName)) {
        const transientName = getStringValue(node.arguments?.[0]);
        if (transientName) {
            analysis.total.transients++;
            analysis.details.transients.push({
                type: funcName,
                name: transientName,
                line: node.loc?.start?.line,
                expiration: funcName.includes('set_') ? getNumericValue(node.arguments?.[2]) : null
            });
        }
    }
    
    // User Meta
    if (['get_user_meta', 'update_user_meta', 'add_user_meta', 'delete_user_meta'].includes(funcName)) {
        const metaKey = getStringValue(node.arguments?.[1]);
        if (metaKey) {
            analysis.total.meta_operations++;
            analysis.details.meta_operations.push({
                type: 'user_meta',
                operation: funcName,
                key: metaKey,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Post Meta
    if (['get_post_meta', 'update_post_meta', 'add_post_meta', 'delete_post_meta'].includes(funcName)) {
        const metaKey = getStringValue(node.arguments?.[1]);
        if (metaKey) {
            analysis.total.meta_operations++;
            analysis.details.meta_operations.push({
                type: 'post_meta',
                operation: funcName,
                key: metaKey,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Nonces
    if (['wp_create_nonce', 'wp_verify_nonce', 'check_admin_referer', 'check_ajax_referer'].includes(funcName)) {
        analysis.total.nonces++;
        analysis.details.nonces.push({
            type: funcName,
            action: getStringValue(node.arguments?.[0]),
            line: node.loc?.start?.line
        });
    }
    
    // Capabilities
    if (['current_user_can', 'user_can', 'add_cap', 'remove_cap', 'has_cap'].includes(funcName)) {
        analysis.total.capabilities++;
        analysis.details.capabilities.push({
            type: funcName,
            capability: getStringValue(node.arguments?.[0]),
            line: node.loc?.start?.line
        });
    }
    
    // Sanitization
    if (['sanitize_text_field', 'sanitize_email', 'sanitize_url', 'sanitize_title', 'sanitize_key', 
         'sanitize_html_class', 'sanitize_file_name', 'wp_kses', 'wp_kses_post', 'esc_sql'].includes(funcName)) {
        analysis.total.sanitization++;
        analysis.details.sanitization.push({
            type: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Escaping
    if (['esc_html', 'esc_attr', 'esc_url', 'esc_js', 'esc_textarea', 'esc_html__', 
         'esc_attr__', 'esc_html_e', 'esc_attr_e', 'wp_json_encode'].includes(funcName)) {
        analysis.total.escaping++;
        analysis.details.escaping.push({
            type: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Cron
    if (['wp_schedule_event', 'wp_schedule_single_event', 'wp_unschedule_event', 
         'wp_clear_scheduled_hook', 'wp_next_scheduled'].includes(funcName)) {
        const hook = getStringValue(node.arguments?.[funcName.includes('single') ? 1 : 2]);
        if (hook) {
            analysis.total.crons++;
            analysis.details.crons.push({
                type: funcName,
                hook: hook,
                line: node.loc?.start?.line,
                recurrence: funcName === 'wp_schedule_event' ? getStringValue(node.arguments?.[1]) : null
            });
        }
    }
    
    // Scripts and Styles
    if (['wp_enqueue_script', 'wp_register_script', 'wp_enqueue_style', 'wp_register_style'].includes(funcName)) {
        const handle = getStringValue(node.arguments?.[0]);
        if (handle) {
            const isScript = funcName.includes('script');
            if (isScript) {
                analysis.total.scripts++;
                analysis.details.scripts.push({
                    type: funcName,
                    handle: handle,
                    line: node.loc?.start?.line,
                    src: getStringValue(node.arguments?.[1])
                });
            } else {
                analysis.total.styles++;
                analysis.details.styles.push({
                    type: funcName,
                    handle: handle,
                    line: node.loc?.start?.line,
                    src: getStringValue(node.arguments?.[1])
                });
            }
        }
    }
    
    // Admin pages
    if (['add_menu_page', 'add_submenu_page', 'add_options_page', 'add_theme_page', 
         'add_plugins_page', 'add_users_page', 'add_management_page', 'add_dashboard_page'].includes(funcName)) {
        const title = getStringValue(node.arguments?.[0]);
        if (title) {
            analysis.total.admin_pages++;
            analysis.details.admin_pages.push({
                type: funcName,
                title: title,
                capability: getStringValue(node.arguments?.[2]),
                slug: getStringValue(node.arguments?.[3]),
                line: node.loc?.start?.line
            });
        }
    }
    
    // Settings API
    if (['register_setting', 'add_settings_section', 'add_settings_field'].includes(funcName)) {
        analysis.total.settings++;
        analysis.details.settings.push({
            type: funcName,
            name: getStringValue(node.arguments?.[0]),
            line: node.loc?.start?.line
        });
    }
    
    // Widgets
    if (funcName === 'register_widget') {
        const widgetClass = getStringValue(node.arguments?.[0]);
        if (widgetClass) {
            analysis.total.widgets++;
            analysis.details.widgets.push({
                class: widgetClass,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Gutenberg Blocks
    if (funcName === 'register_block_type') {
        const blockName = getStringValue(node.arguments?.[0]);
        if (blockName) {
            analysis.total.blocks++;
            analysis.details.blocks.push({
                name: blockName,
                line: node.loc?.start?.line,
                args: extractArrayKeys(node.arguments?.[1])
            });
        }
    }
    
    // Security checks
    checkSecurityIssues(funcName, node, analysis);
}

/**
 * Check for WordPress-specific classes
 */
function checkWordPressClasses(node, analysis) {
    const className = node.name.name || node.name;
    const parentClass = node.extends?.name;
    
    // Check for Widget class
    if (parentClass === 'WP_Widget') {
        analysis.total.widgets++;
        analysis.details.widgets.push({
            class: className,
            line: node.loc?.start?.line,
            type: 'class_based'
        });
    }
    
    // Check for REST Controller
    if (parentClass === 'WP_REST_Controller' || className.includes('REST')) {
        analysis.wordpress_patterns.uses_rest_api = true;
    }
    
    // Check for Customizer
    if (parentClass === 'WP_Customize_Control' || className.includes('Customize')) {
        analysis.wordpress_patterns.uses_customizer = true;
    }
}

/**
 * Check for special WordPress hooks
 */
function checkSpecialHooks(hookName, node, analysis) {
    // Admin hooks
    if (hookName.startsWith('admin_')) {
        // Track admin functionality
    }
    
    // Init hooks
    if (hookName === 'init' || hookName === 'wp_loaded') {
        // Common initialization points
    }
    
    // Script/Style hooks
    if (hookName === 'wp_enqueue_scripts' || hookName === 'admin_enqueue_scripts') {
        // Asset loading
    }
    
    // Gutenberg hooks
    if (hookName.includes('block_') || hookName === 'enqueue_block_editor_assets') {
        analysis.wordpress_patterns.uses_gutenberg = true;
    }
    
    // Multisite hooks
    if (hookName.includes('network_') || hookName.includes('ms_')) {
        analysis.wordpress_patterns.uses_multisite = true;
    }
}

/**
 * Check database operations for security issues
 */
function checkDatabaseSecurity(node, operation, analysis) {
    const query = getStringValue(node.arguments?.[0]);
    
    // Check for direct variable interpolation
    if (query && (query.includes('$') || query.includes('%s'))) {
        // Check if using prepare
        const parentCall = findParentCall(node);
        if (!parentCall || getFunctionName(parentCall.what) !== 'prepare') {
            analysis.total.security_issues++;
            analysis.details.security_issues.push({
                type: 'potential_sql_injection',
                operation: operation,
                line: node.loc?.start?.line,
                severity: 'high',
                message: 'Database query may not be properly prepared'
            });
        }
    }
}

/**
 * Check for general security issues
 */
function checkSecurityIssues(funcName, node, analysis) {
    // Direct $_GET, $_POST, $_REQUEST usage without sanitization
    if (funcName === 'echo' || funcName === 'print') {
        // Check if outputting unsanitized variables
        // This would need more complex analysis of the argument chain
    }
    
    // eval() usage
    if (funcName === 'eval') {
        analysis.total.security_issues++;
        analysis.details.security_issues.push({
            type: 'eval_usage',
            line: node.loc?.start?.line,
            severity: 'critical',
            message: 'eval() is dangerous and should be avoided'
        });
    }
    
    // file_get_contents with URLs
    if (funcName === 'file_get_contents') {
        const arg = getStringValue(node.arguments?.[0]);
        if (arg && (arg.startsWith('http://') || arg.startsWith('https://'))) {
            analysis.total.security_issues++;
            analysis.details.security_issues.push({
                type: 'remote_file_access',
                line: node.loc?.start?.line,
                severity: 'medium',
                message: 'Use wp_remote_get() instead of file_get_contents() for remote URLs'
            });
        }
    }
}

/**
 * Analyze class instantiation
 */
function analyzeClassInstantiation(node, analysis) {
    const className = node.what?.name;
    
    // Check for WordPress class instantiations
    if (className === 'WP_Query' || className === 'WP_User_Query' || className === 'WP_Meta_Query') {
        analysis.total.database_queries++;
        analysis.details.database_queries.push({
            type: className,
            line: node.loc?.start?.line
        });
    }
}

/**
 * Analyze assignments for WordPress patterns
 */
function analyzeAssignment(node, analysis) {
    // Check for global variable assignments
    if (node.left?.kind === 'variable' && node.left?.name) {
        const varName = node.left.name;
        
        // Check for WordPress globals
        if (['$wp_filter', '$wp_actions', '$wp_current_filter'].includes(varName)) {
            analysis.total.security_issues++;
            analysis.details.security_issues.push({
                type: 'global_modification',
                variable: varName,
                line: node.loc?.start?.line,
                severity: 'low',
                message: `Modifying WordPress global ${varName}`
            });
        }
    }
}

/**
 * Helper function to get function name from node
 */
function getFunctionName(node) {
    if (!node) return null;
    
    // Direct function name
    if (node.kind === 'name' || node.kind === 'identifier') {
        return node.name;
    }
    
    // Method call like $wpdb->query
    if (node.kind === 'propertylookup') {
        const obj = node.what?.name || '$obj';
        const method = node.offset?.name;
        if (obj === 'wpdb' || obj === '$wpdb') {
            return `wpdb->${method}`;
        }
        return `${obj}->${method}`;
    }
    
    // Static method call
    if (node.kind === 'staticlookup') {
        const className = node.what?.name;
        const method = node.offset?.name;
        return `${className}::${method}`;
    }
    
    // Array notation for callbacks
    if (node.kind === 'array') {
        if (node.items?.length === 2) {
            const obj = getStringValue(node.items[0]);
            const method = getStringValue(node.items[1]);
            if (obj && method) {
                return `${obj}->${method}`;
            }
        }
    }
    
    return null;
}

/**
 * Helper function to get string value from node
 */
function getStringValue(node) {
    if (!node) return null;
    
    if (node.kind === 'string') {
        return node.value;
    }
    
    if (node.kind === 'nowdoc' || node.kind === 'encapsed') {
        return node.value;
    }
    
    // Handle entry nodes in arrays
    if (node.kind === 'entry') {
        return getStringValue(node.value);
    }
    
    return null;
}

/**
 * Helper function to get numeric value
 */
function getNumericValue(node) {
    if (!node) return null;
    
    if (node.kind === 'number') {
        return parseInt(node.value);
    }
    
    if (node.kind === 'entry') {
        return getNumericValue(node.value);
    }
    
    return null;
}

/**
 * Extract array keys from node
 */
function extractArrayKeys(node) {
    if (!node || node.kind !== 'array') return [];
    
    const keys = [];
    if (node.items) {
        node.items.forEach(item => {
            if (item.kind === 'entry' && item.key) {
                const key = getStringValue(item.key);
                if (key) keys.push(key);
            }
        });
    }
    
    return keys;
}

/**
 * Extract REST methods from args array
 */
function extractRestMethods(node) {
    if (!node || node.kind !== 'array') return ['GET'];
    
    const methods = [];
    // Look for 'methods' key in the args array
    if (node.items) {
        node.items.forEach(item => {
            if (item.kind === 'entry' && getStringValue(item.key) === 'methods') {
                const value = getStringValue(item.value);
                if (value) methods.push(value);
            }
        });
    }
    
    return methods.length > 0 ? methods : ['GET'];
}

/**
 * Find parent call node
 */
function findParentCall(node) {
    // This would require maintaining a parent reference during traversal
    // For now, return null
    return null;
}

/**
 * Update pattern flags based on findings
 */
function updatePatternFlags() {
    analysis.wordpress_patterns.uses_hooks = analysis.total.hooks > 0;
    analysis.wordpress_patterns.uses_shortcodes = analysis.total.shortcodes > 0;
    analysis.wordpress_patterns.uses_ajax = analysis.total.ajax_handlers > 0;
    analysis.wordpress_patterns.uses_rest_api = analysis.total.rest_endpoints > 0;
    analysis.wordpress_patterns.has_custom_post_types = analysis.total.custom_post_types > 0;
    analysis.wordpress_patterns.has_custom_taxonomies = analysis.total.custom_taxonomies > 0;
    analysis.wordpress_patterns.uses_database = analysis.total.database_queries > 0;
    analysis.wordpress_patterns.has_security_issues = analysis.total.security_issues > 0;
    analysis.wordpress_patterns.uses_widgets = analysis.total.widgets > 0;
    analysis.wordpress_patterns.uses_options_api = analysis.total.options > 0;
    analysis.wordpress_patterns.uses_transients = analysis.total.transients > 0;
    analysis.wordpress_patterns.uses_cron = analysis.total.crons > 0;
    analysis.wordpress_patterns.uses_user_meta = analysis.details.meta_operations.some(m => m.type === 'user_meta');
}

// Main execution
if (require.main === module) {
    const pluginPath = process.argv[2];
    
    if (!pluginPath) {
        console.error('Usage: node wordpress-ast-analyzer.js <plugin-path>');
        process.exit(1);
    }
    
    if (!fs.existsSync(pluginPath)) {
        console.error('Plugin path does not exist:', pluginPath);
        process.exit(1);
    }
    
    const results = analyzeWordPressPlugin(pluginPath);
    
    // Output analysis
    const outputPath = path.join(process.cwd(), '..', 'wp-content', 'uploads', 'wbcom-scan', 
                                path.basename(pluginPath), 
                                new Date().toISOString().slice(0, 7).replace('-', '-'),
                                'wordpress-ast-analysis.json');
    
    // Create directory if it doesn't exist
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
    console.log('\nAnalysis saved to:', outputPath);
    
    // Print summary
    console.log('\n=== WordPress Plugin Analysis Summary ===');
    console.log('Files analyzed:', results.files_analyzed);
    console.log('Functions:', results.total.functions);
    console.log('Classes:', results.total.classes);
    console.log('Methods:', results.total.methods);
    console.log('\n--- WordPress Features ---');
    console.log('Hooks:', results.total.hooks);
    console.log('Shortcodes:', results.total.shortcodes);
    console.log('AJAX Handlers:', results.total.ajax_handlers);
    console.log('REST Endpoints:', results.total.rest_endpoints);
    console.log('Custom Post Types:', results.total.custom_post_types);
    console.log('Custom Taxonomies:', results.total.custom_taxonomies);
    console.log('Admin Pages:', results.total.admin_pages);
    console.log('Widgets:', results.total.widgets);
    console.log('Gutenberg Blocks:', results.total.blocks);
    console.log('\n--- WordPress APIs ---');
    console.log('Database Queries:', results.total.database_queries);
    console.log('Options:', results.total.options);
    console.log('Transients:', results.total.transients);
    console.log('Meta Operations:', results.total.meta_operations);
    console.log('Cron Jobs:', results.total.crons);
    console.log('Scripts:', results.total.scripts);
    console.log('Styles:', results.total.styles);
    console.log('\n--- Security ---');
    console.log('Security Issues:', results.total.security_issues);
    console.log('Nonces:', results.total.nonces);
    console.log('Capabilities:', results.total.capabilities);
    console.log('Sanitization:', results.total.sanitization);
    console.log('Escaping:', results.total.escaping);
    
    // Output pattern detection
    console.log('\n--- WordPress Patterns Detected ---');
    Object.entries(results.wordpress_patterns).forEach(([pattern, detected]) => {
        if (detected) {
            console.log(`✓ ${pattern.replace(/_/g, ' ')}`);
        }
    });
    
    console.log('\n✅ Analysis complete!');
}

module.exports = analyzeWordPressPlugin;