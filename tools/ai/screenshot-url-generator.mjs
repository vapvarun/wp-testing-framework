#!/usr/bin/env node

/**
 * AI-Enhanced Screenshot URL Generator
 * Intelligently determines which URLs to capture based on plugin analysis
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Get plugin name from args
const pluginName = process.argv[2];
const siteUrl = process.argv[3] || 'http://wptesting.local';

if (!pluginName) {
    console.error('Usage: node screenshot-url-generator.mjs <plugin-name> [site-url]');
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
    process.exit(1);
}

// Read WordPress AST analysis
let astData = {};
try {
    const astFile = path.join(analysisPath, 'wordpress-ast-analysis.json');
    if (fs.existsSync(astFile)) {
        astData = JSON.parse(fs.readFileSync(astFile, 'utf8'));
    }
} catch (e) {
    console.error('Warning: Could not read WordPress AST analysis');
}

// Read test data plan
let testDataPlan = {};
try {
    const planFile = path.join(analysisPath, 'reports', 'test-data-plan.json');
    if (fs.existsSync(planFile)) {
        testDataPlan = JSON.parse(fs.readFileSync(planFile, 'utf8'));
    }
} catch (e) {
    console.error('Warning: Could not read test data plan');
}

// Generate intelligent URL list
const urlPlan = {
    plugin: pluginName,
    generated: new Date().toISOString(),
    siteUrl: siteUrl,
    urls: []
};

// Priority 1: Essential WordPress pages
urlPlan.urls.push({
    url: `${siteUrl}/wp-admin/`,
    name: 'dashboard',
    description: 'WordPress Dashboard',
    priority: 1,
    category: 'admin'
});

urlPlan.urls.push({
    url: `${siteUrl}/wp-admin/plugins.php`,
    name: 'plugins-list',
    description: 'Plugins List (verify plugin is active)',
    priority: 1,
    category: 'admin'
});

// Priority 2: Custom Post Types (from test data)
if (testDataPlan.test_data) {
    const cpts = testDataPlan.test_data.filter(item => item.type === 'custom_post_type');
    const uniqueCPTs = [...new Set(cpts.map(cpt => cpt.name))];
    
    uniqueCPTs.forEach(cptName => {
        // Admin list page
        urlPlan.urls.push({
            url: `${siteUrl}/wp-admin/edit.php?post_type=${cptName}`,
            name: `admin-list-${cptName}`,
            description: `Admin: ${cptName} list`,
            priority: 2,
            category: 'admin-cpt'
        });
        
        // Add new page
        urlPlan.urls.push({
            url: `${siteUrl}/wp-admin/post-new.php?post_type=${cptName}`,
            name: `admin-new-${cptName}`,
            description: `Admin: Add new ${cptName}`,
            priority: 3,
            category: 'admin-cpt'
        });
        
        // Frontend archive (if exists)
        if (cptName !== 'reply') { // BBPress replies don't have archives
            urlPlan.urls.push({
                url: `${siteUrl}/${cptName}s/`,
                name: `archive-${cptName}`,
                description: `Frontend: ${cptName} archive`,
                priority: 2,
                category: 'frontend-cpt'
            });
        }
    });
}

// Priority 3: Shortcode test pages
if (testDataPlan.test_data) {
    const shortcodes = testDataPlan.test_data.filter(item => item.type === 'shortcode');
    
    shortcodes.forEach(sc => {
        const pageName = sc.name.replace(/[\[\]]/g, '');
        const pageSlug = sc.data.post_title.toLowerCase()
            .replace(/\[|\]/g, '')
            .replace(/\s+/g, '-')
            .replace(/:/g, '');
        
        urlPlan.urls.push({
            url: `${siteUrl}/${pageSlug}/`,
            name: `shortcode-${pageName}`,
            description: `Shortcode test: [${pageName}]`,
            priority: 2,
            category: 'shortcode'
        });
    });
}

// Priority 4: Plugin-specific pages based on detected features
if (pluginName.toLowerCase() === 'bbpress') {
    // BBPress specific URLs
    urlPlan.urls.push({
        url: `${siteUrl}/forums/`,
        name: 'bbpress-forums-index',
        description: 'BBPress Forums Index',
        priority: 1,
        category: 'bbpress-frontend'
    });
    
    urlPlan.urls.push({
        url: `${siteUrl}/topics/`,
        name: 'bbpress-topics-index',
        description: 'BBPress Topics Index',
        priority: 2,
        category: 'bbpress-frontend'
    });
    
    // Admin settings
    urlPlan.urls.push({
        url: `${siteUrl}/wp-admin/options-general.php?page=bbpress`,
        name: 'bbpress-settings',
        description: 'BBPress Settings',
        priority: 2,
        category: 'bbpress-admin'
    });
}

// Priority 5: Settings pages (if detected)
if (astData.total && astData.total.admin_pages > 0) {
    // Try common settings page patterns
    urlPlan.urls.push({
        url: `${siteUrl}/wp-admin/admin.php?page=${pluginName}`,
        name: `${pluginName}-settings`,
        description: `${pluginName} Settings Page`,
        priority: 3,
        category: 'settings'
    });
}

// Priority 6: Widget areas (if widgets detected)
if (astData.total && astData.total.widgets > 0) {
    urlPlan.urls.push({
        url: `${siteUrl}/wp-admin/widgets.php`,
        name: 'widgets-admin',
        description: 'Widgets Admin Page',
        priority: 4,
        category: 'widgets'
    });
}

// Priority 7: User profile (if user features detected)
if (astData.total && astData.total.meta_operations > 100) {
    urlPlan.urls.push({
        url: `${siteUrl}/wp-admin/profile.php`,
        name: 'user-profile',
        description: 'User Profile (check for plugin additions)',
        priority: 4,
        category: 'user'
    });
}

// Sort URLs by priority
urlPlan.urls.sort((a, b) => a.priority - b.priority);

// Generate wait times based on content type
urlPlan.urls = urlPlan.urls.map(url => ({
    ...url,
    waitTime: url.category.includes('frontend') ? 3000 : 2000,
    waitForSelector: determineWaitSelector(url.category, pluginName)
}));

// Add specific test scenarios based on detected features
if (astData.total && astData.total.ajax_handlers > 0) {
    urlPlan.testScenarios = urlPlan.testScenarios || [];
    urlPlan.testScenarios.push({
        name: 'AJAX Testing',
        description: `Test ${astData.total.ajax_handlers} AJAX handlers detected`,
        urls: [] // These would be tested differently
    });
}

// Output the URL plan
const outputPath = path.join(analysisPath, 'reports', 'screenshot-urls.json');
fs.writeFileSync(outputPath, JSON.stringify(urlPlan, null, 2));

// Also create a simple list for the screenshot tool
const urlList = urlPlan.urls.map(u => `${u.url}\t${u.name}\t${u.description}`).join('\n');
fs.writeFileSync(path.join(analysisPath, 'reports', 'screenshot-urls.txt'), urlList);

// Summary output
console.log(`📋 Screenshot URL Plan Generated for ${pluginName}`);
console.log(`   Total URLs: ${urlPlan.urls.length}`);

// Group by category
const categories = {};
urlPlan.urls.forEach(url => {
    categories[url.category] = (categories[url.category] || 0) + 1;
});

console.log(`   Categories:`);
Object.entries(categories).forEach(([cat, count]) => {
    console.log(`     - ${cat}: ${count} URLs`);
});

console.log(`   Saved to: ${outputPath}`);

// Output JSON for use by screenshot tool
console.log(JSON.stringify(urlPlan, null, 2));

// Helper function to determine wait selectors
function determineWaitSelector(category, pluginName) {
    const selectors = {
        'admin-cpt': '.wp-list-table',
        'frontend-cpt': '.post, .hentry, article',
        'shortcode': '[class*="bbp-"], [class*="shortcode-"]',
        'bbpress-frontend': '.bbp-forums, .bbp-topics',
        'admin': '#wpcontent',
        'settings': '.wrap form',
        'widgets': '#widgets-right'
    };
    
    return selectors[category] || 'body';
}