#!/usr/bin/env node

/**
 * PHP AST Analyzer using glayzzle/php-parser
 * Provides accurate PHP code analysis using Abstract Syntax Tree parsing
 * Much more accurate than grep-based analysis
 */

const fs = require('fs');
const path = require('path');
const parser = require('php-parser');

// Initialize the parser
const phpParser = new parser({
    parser: {
        extractDoc: true,
        php7: true,
        suppressErrors: false
    },
    ast: {
        withPositions: true
    }
});

/**
 * Analyze a single PHP file
 */
function analyzeFile(filePath) {
    try {
        const code = fs.readFileSync(filePath, 'utf8');
        const ast = phpParser.parseCode(code, filePath);
        
        const analysis = {
            file: filePath,
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
            escaping: []
        };
        
        // Traverse the AST
        traverseAST(ast, analysis);
        
        return analysis;
    } catch (error) {
        console.error(`Error parsing ${filePath}:`, error.message);
        return null;
    }
}

/**
 * Traverse AST and extract information
 */
function traverseAST(node, analysis, parentClass = null) {
    if (!node) return;
    
    // Handle arrays of nodes
    if (Array.isArray(node)) {
        node.forEach(n => traverseAST(n, analysis, parentClass));
        return;
    }
    
    // Process based on node kind
    switch (node.kind) {
        case 'function':
            analysis.functions.push({
                name: node.name.name,
                line: node.loc?.start?.line,
                params: node.arguments?.length || 0,
                doc: node.leadingComments?.[0]?.value
            });
            break;
            
        case 'class':
            const className = node.name.name;
            analysis.classes.push({
                name: className,
                line: node.loc?.start?.line,
                extends: node.extends?.name,
                implements: node.implements?.map(i => i.name),
                abstract: node.isAbstract,
                final: node.isFinal
            });
            
            // Analyze class body
            if (node.body) {
                node.body.forEach(member => {
                    traverseAST(member, analysis, className);
                });
            }
            break;
            
        case 'method':
            analysis.methods.push({
                name: node.name.name,
                class: parentClass,
                line: node.loc?.start?.line,
                visibility: node.visibility,
                static: node.isStatic,
                abstract: node.isAbstract,
                params: node.arguments?.length || 0
            });
            break;
            
        case 'call':
            analyzeCall(node, analysis);
            break;
    }
    
    // Recursively traverse child nodes
    for (const key in node) {
        if (key !== 'loc' && key !== 'kind' && typeof node[key] === 'object') {
            traverseAST(node[key], analysis, parentClass);
        }
    }
}

/**
 * Analyze function calls for WordPress patterns
 */
function analyzeCall(node, analysis) {
    if (!node.what) return;
    
    const funcName = getFunctionName(node.what);
    if (!funcName) return;
    
    // WordPress Hooks
    if (['add_action', 'add_filter', 'do_action', 'apply_filters'].includes(funcName)) {
        const hookName = getStringValue(node.arguments?.[0]);
        if (hookName) {
            analysis.hooks.push({
                type: funcName,
                name: hookName,
                line: node.loc?.start?.line,
                priority: getNumericValue(node.arguments?.[2]) || 10,
                accepted_args: getNumericValue(node.arguments?.[3]) || 1
            });
        }
        
        // Check for AJAX handlers
        if (funcName === 'add_action' && hookName?.startsWith('wp_ajax_')) {
            analysis.ajax_handlers.push({
                name: hookName.replace('wp_ajax_', ''),
                line: node.loc?.start?.line,
                public: hookName.includes('wp_ajax_nopriv_')
            });
        }
    }
    
    // Shortcodes
    if (funcName === 'add_shortcode') {
        const shortcode = getStringValue(node.arguments?.[0]);
        if (shortcode) {
            analysis.shortcodes.push({
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
            analysis.rest_endpoints.push({
                namespace,
                route,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Custom Post Types
    if (funcName === 'register_post_type') {
        const postType = getStringValue(node.arguments?.[0]);
        if (postType) {
            analysis.custom_post_types.push({
                name: postType,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Custom Taxonomies
    if (funcName === 'register_taxonomy') {
        const taxonomy = getStringValue(node.arguments?.[0]);
        if (taxonomy) {
            analysis.custom_taxonomies.push({
                name: taxonomy,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Database Operations
    if (funcName?.includes('wpdb') || ['get_option', 'update_option', 'delete_option'].includes(funcName)) {
        analysis.database_queries.push({
            type: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Meta Operations
    if (['add_post_meta', 'update_post_meta', 'get_post_meta', 'delete_post_meta'].includes(funcName)) {
        const metaKey = getStringValue(node.arguments?.[1]);
        if (metaKey) {
            analysis.meta_operations.push({
                type: funcName,
                key: metaKey,
                line: node.loc?.start?.line
            });
        }
    }
    
    // Security: Nonces
    if (['wp_verify_nonce', 'wp_create_nonce', 'check_admin_referer', 'wp_nonce_field'].includes(funcName)) {
        analysis.nonces.push({
            type: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Security: Capabilities
    if (['current_user_can', 'user_can', 'author_can'].includes(funcName)) {
        const capability = getStringValue(node.arguments?.[0]);
        analysis.capabilities.push({
            function: funcName,
            capability,
            line: node.loc?.start?.line
        });
    }
    
    // Security: Sanitization
    if (funcName?.startsWith('sanitize_')) {
        analysis.sanitization.push({
            function: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Security: Escaping
    if (funcName?.startsWith('esc_')) {
        analysis.escaping.push({
            function: funcName,
            line: node.loc?.start?.line
        });
    }
    
    // Security Issues: eval()
    if (funcName === 'eval') {
        analysis.security_issues.push({
            type: 'eval_usage',
            severity: 'critical',
            line: node.loc?.start?.line,
            message: 'eval() function usage detected'
        });
    }
    
    // Security Issues: Direct $_GET/$_POST usage
    if (node.what?.kind === 'offsetlookup' && 
        ['_GET', '_POST', '_REQUEST'].includes(node.what?.what?.name)) {
        analysis.security_issues.push({
            type: 'direct_input',
            severity: 'warning',
            line: node.loc?.start?.line,
            message: `Direct \$${node.what.what.name} usage - ensure proper sanitization`
        });
    }
}

/**
 * Helper function to get function name from node
 */
function getFunctionName(node) {
    if (!node) return null;
    
    // php-parser uses 'name' not 'identifier'
    if (node.kind === 'name' || node.kind === 'identifier') {
        return node.name;
    }
    
    if (node.kind === 'propertylookup' && node.what?.name === 'wpdb') {
        return `wpdb->${node.offset?.name}`;
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
    
    return null;
}

/**
 * Helper function to get numeric value from node
 */
function getNumericValue(node) {
    if (!node) return null;
    
    if (node.kind === 'number') {
        return parseInt(node.value);
    }
    
    return null;
}

/**
 * Analyze all PHP files in a directory
 */
function analyzeDirectory(dirPath) {
    const results = {
        plugin_path: dirPath,
        analysis_date: new Date().toISOString(),
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
            escaping: 0
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
            escaping: []
        },
        wordpress_patterns: {
            uses_hooks: false,
            uses_shortcodes: false,
            uses_ajax: false,
            uses_rest_api: false,
            has_custom_post_types: false,
            has_custom_taxonomies: false,
            uses_database: false,
            has_security_issues: false
        }
    };
    
    // Find all PHP files
    const phpFiles = findPHPFiles(dirPath);
    results.files_analyzed = phpFiles.length;
    
    // Analyze each file
    phpFiles.forEach(file => {
        const analysis = analyzeFile(file);
        if (analysis) {
            // Aggregate results
            for (const key in analysis) {
                if (Array.isArray(analysis[key]) && analysis[key].length > 0) {
                    results.details[key].push(...analysis[key]);
                    results.total[key] = (results.total[key] || 0) + analysis[key].length;
                }
            }
        }
    });
    
    // Set pattern flags
    results.wordpress_patterns.uses_hooks = results.total.hooks > 0;
    results.wordpress_patterns.uses_shortcodes = results.total.shortcodes > 0;
    results.wordpress_patterns.uses_ajax = results.total.ajax_handlers > 0;
    results.wordpress_patterns.uses_rest_api = results.total.rest_endpoints > 0;
    results.wordpress_patterns.has_custom_post_types = results.total.custom_post_types > 0;
    results.wordpress_patterns.has_custom_taxonomies = results.total.custom_taxonomies > 0;
    results.wordpress_patterns.uses_database = results.total.database_queries > 0;
    results.wordpress_patterns.has_security_issues = results.total.security_issues > 0;
    
    return results;
}

/**
 * Find all PHP files in directory recursively
 */
function findPHPFiles(dir, files = []) {
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules' && item !== 'vendor') {
            findPHPFiles(fullPath, files);
        } else if (stat.isFile() && item.endsWith('.php')) {
            files.push(fullPath);
        }
    }
    
    return files;
}

/**
 * Main execution
 */
function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('Usage: node php-ast-analyzer.js <plugin-path> [output-file]');
        console.log('Example: node php-ast-analyzer.js ../wp-content/plugins/buddypress analysis.json');
        process.exit(1);
    }
    
    const pluginPath = args[0];
    const outputFile = args[1] || null;
    
    if (!fs.existsSync(pluginPath)) {
        console.error(`Error: Path does not exist: ${pluginPath}`);
        process.exit(1);
    }
    
    console.log(`Analyzing PHP files in: ${pluginPath}`);
    console.log('This provides more accurate analysis than grep...');
    
    const results = analyzeDirectory(pluginPath);
    
    // Output results
    if (outputFile) {
        fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
        console.log(`\nAnalysis saved to: ${outputFile}`);
    } else {
        console.log(JSON.stringify(results, null, 2));
    }
    
    // Print summary
    console.log('\n=== Analysis Summary ===');
    console.log(`Files analyzed: ${results.files_analyzed}`);
    console.log(`Functions: ${results.total.functions}`);
    console.log(`Classes: ${results.total.classes}`);
    console.log(`Methods: ${results.total.methods}`);
    console.log(`WordPress Hooks: ${results.total.hooks}`);
    console.log(`Shortcodes: ${results.total.shortcodes}`);
    console.log(`AJAX Handlers: ${results.total.ajax_handlers}`);
    console.log(`REST Endpoints: ${results.total.rest_endpoints}`);
    console.log(`Custom Post Types: ${results.total.custom_post_types}`);
    console.log(`Custom Taxonomies: ${results.total.custom_taxonomies}`);
    console.log(`Security Issues: ${results.total.security_issues}`);
    
    if (results.total.security_issues > 0) {
        console.log('\n⚠️  Security Issues Found:');
        results.details.security_issues.forEach(issue => {
            console.log(`  - ${issue.severity.toUpperCase()}: ${issue.message} (line ${issue.line})`);
        });
    }
}

// Run if executed directly
if (require.main === module) {
    main();
}

// Export for use as module
module.exports = {
    analyzeFile,
    analyzeDirectory,
    phpParser
};