#!/usr/bin/env node
/**
 * WordPress Plugin Compatibility Checker
 * 
 * Generates comprehensive compatibility checklists for WordPress plugins
 * based on scan results and known compatibility issues.
 *
 * Usage:
 *   node tools/ai/compatibility-checker.mjs \
 *     --plugin woocommerce \
 *     --scan wp-content/uploads/wp-scan/plugin-woocommerce.json \
 *     --out tests/compatibility
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ---------- CLI args ----------
const args = process.argv;
const pluginSlug = argOf('--plugin', '');
const scanFile = argOf('--scan', '');
const outDir = argOf('--out', `tests/compatibility`);
const verbose = args.includes('--verbose');

function argOf(flag, def) { 
  return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

// Validate required args
if (!pluginSlug || !scanFile) {
  console.error('Usage: node compatibility-checker.mjs --plugin <slug> --scan <scan-file>');
  console.error('Example: node compatibility-checker.mjs --plugin woocommerce --scan wp-content/uploads/wp-scan/plugin-woocommerce.json');
  process.exit(1);
}

// ---------- IO helpers ----------
function readJSONSafe(p, def = {}) {
  if (!fs.existsSync(p)) {
    console.error(`❌ Scan file not found: ${p}`);
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

// ---------- Compatibility definitions ----------
const WORDPRESS_VERSIONS = [
  { version: '6.4', status: 'latest', priority: 'critical' },
  { version: '6.3', status: 'supported', priority: 'high' },
  { version: '6.2', status: 'supported', priority: 'medium' },
  { version: '6.1', status: 'legacy', priority: 'low' }
];

const PHP_VERSIONS = [
  { version: '8.3', status: 'latest', priority: 'high' },
  { version: '8.2', status: 'supported', priority: 'critical' },
  { version: '8.1', status: 'supported', priority: 'critical' },
  { version: '8.0', status: 'supported', priority: 'medium' },
  { version: '7.4', status: 'legacy', priority: 'low' }
];

const POPULAR_THEMES = [
  { name: 'Twenty Twenty-Four', slug: 'twentytwentyfour', priority: 'critical' },
  { name: 'Twenty Twenty-Three', slug: 'twentytwentythree', priority: 'critical' },
  { name: 'Astra', slug: 'astra', priority: 'high' },
  { name: 'GeneratePress', slug: 'generatepress', priority: 'high' },
  { name: 'Neve', slug: 'neve', priority: 'medium' },
  { name: 'OceanWP', slug: 'oceanwp', priority: 'medium' }
];

const POPULAR_PLUGINS = [
  { name: 'WooCommerce', slug: 'woocommerce', priority: 'critical' },
  { name: 'Yoast SEO', slug: 'wordpress-seo', priority: 'critical' },
  { name: 'Jetpack', slug: 'jetpack', priority: 'high' },
  { name: 'Contact Form 7', slug: 'contact-form-7', priority: 'high' },
  { name: 'Elementor', slug: 'elementor', priority: 'high' },
  { name: 'WPBakery', slug: 'js_composer', priority: 'medium' },
  { name: 'Advanced Custom Fields', slug: 'advanced-custom-fields', priority: 'medium' },
  { name: 'WP Rocket', slug: 'wp-rocket', priority: 'medium' }
];

const MULTISITE_TESTS = [
  'Network activation works correctly',
  'Site-specific settings are isolated',
  'Network admin pages function properly',
  'Database operations respect site context',
  'No conflicts with network-wide plugins'
];

// ---------- Main execution ----------
async function main() {
  console.log(`🔍 Generating compatibility checklist for: ${pluginSlug}`);
  
  // Load plugin scan data
  const pluginData = readJSONSafe(scanFile);
  if (!pluginData || pluginData.length === 0) {
    console.error(`❌ No plugin data found`);
    process.exit(1);
  }

  // Handle array of plugins
  const plugin = Array.isArray(pluginData) ? 
    pluginData.find(p => p.slug === pluginSlug) || pluginData[0] : 
    pluginData;

  if (!plugin) {
    console.error(`❌ Plugin ${pluginSlug} not found in scan data`);
    process.exit(1);
  }

  verbose && console.log('📊 Plugin data loaded');

  // Generate compatibility reports
  const reports = {
    main: generateMainCompatibilityChecklist(plugin),
    wordpress: generateWordPressCompatibility(plugin),
    php: generatePHPCompatibility(plugin),
    themes: generateThemeCompatibility(plugin),
    plugins: generatePluginCompatibility(plugin),
    multisite: generateMultisiteCompatibility(plugin),
    performance: generatePerformanceCompatibility(plugin),
    security: generateSecurityCompatibility(plugin)
  };

  // Write all reports
  Object.entries(reports).forEach(([type, content]) => {
    const filename = type === 'main' ? 
      `${plugin.slug}-compatibility.md` : 
      `${plugin.slug}-${type}-compatibility.md`;
    writeFile(path.join(outDir, filename), content);
  });

  console.log(`✅ Compatibility checklist generated for ${plugin.name}`);
}

function generateMainCompatibilityChecklist(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Comprehensive Compatibility Checklist`);
  checklist.push(`**Plugin:** ${plugin.slug} v${plugin.version}`);
  checklist.push(`**Generated:** ${new Date().toISOString()}`);
  checklist.push('');
  
  checklist.push('## 📋 Quick Overview');
  checklist.push('This comprehensive compatibility checklist covers all major compatibility scenarios for your WordPress plugin.');
  checklist.push('Use this as your primary testing guide to ensure maximum compatibility.');
  checklist.push('');
  
  checklist.push('### 🎯 Testing Priority');
  checklist.push('- **Critical:** Must test before any release');
  checklist.push('- **High:** Test for major releases');
  checklist.push('- **Medium:** Test quarterly or for significant updates');
  checklist.push('- **Low:** Test annually or when issues are reported');
  checklist.push('');
  
  checklist.push('## 🚀 Core Compatibility Tests');
  checklist.push('### WordPress Core Versions');
  WORDPRESS_VERSIONS.forEach(wp => {
    const priority = wp.priority.toUpperCase().padEnd(8);
    checklist.push(`- [ ] **[${priority}]** WordPress ${wp.version} (${wp.status})`);
  });
  checklist.push('');
  
  checklist.push('### PHP Versions');
  PHP_VERSIONS.forEach(php => {
    const priority = php.priority.toUpperCase().padEnd(8);
    checklist.push(`- [ ] **[${priority}]** PHP ${php.version} (${php.status})`);
  });
  checklist.push('');
  
  checklist.push('### Popular Themes');
  POPULAR_THEMES.slice(0, 4).forEach(theme => {
    const priority = theme.priority.toUpperCase().padEnd(8);
    checklist.push(`- [ ] **[${priority}]** ${theme.name}`);
  });
  checklist.push('');
  
  checklist.push('### Popular Plugins');
  POPULAR_PLUGINS.slice(0, 4).forEach(plugin => {
    const priority = plugin.priority.toUpperCase().padEnd(8);
    checklist.push(`- [ ] **[${priority}]** ${plugin.name}`);
  });
  checklist.push('');
  
  checklist.push('## 🔧 Environment Tests');
  checklist.push('- [ ] **[CRITICAL]** Single site installation');
  checklist.push('- [ ] **[HIGH]** Multisite network (subdomain)');
  checklist.push('- [ ] **[HIGH]** Multisite network (subdirectory)');
  checklist.push('- [ ] **[MEDIUM]** Localhost development environment');
  checklist.push('- [ ] **[MEDIUM]** Staging environment');
  checklist.push('- [ ] **[CRITICAL]** Production environment');
  checklist.push('');
  
  checklist.push('## 📱 Device & Browser Tests');
  checklist.push('- [ ] **[CRITICAL]** Desktop (Chrome, Firefox, Safari)');
  checklist.push('- [ ] **[HIGH]** Mobile (iOS Safari, Android Chrome)');
  checklist.push('- [ ] **[MEDIUM]** Tablet (iPad, Android tablets)');
  checklist.push('- [ ] **[MEDIUM]** Edge/Internet Explorer (if applicable)');
  checklist.push('');
  
  // Plugin-specific sections based on features
  if (plugin.rest_routes?.length > 0) {
    checklist.push('## 🌐 API Compatibility');
    checklist.push('- [ ] **[CRITICAL]** REST API endpoints work correctly');
    checklist.push('- [ ] **[HIGH]** API authentication methods');
    checklist.push('- [ ] **[HIGH]** API versioning compatibility');
    checklist.push('');
  }
  
  if (plugin.database_tables?.length > 0) {
    checklist.push('## 🗄️ Database Compatibility');
    checklist.push('- [ ] **[CRITICAL]** MySQL 5.7+ compatibility');
    checklist.push('- [ ] **[HIGH]** MySQL 8.0+ compatibility');
    checklist.push('- [ ] **[MEDIUM]** MariaDB compatibility');
    checklist.push('- [ ] **[HIGH]** Database charset/collation issues');
    checklist.push('');
  }
  
  checklist.push('## 📄 Detailed Checklists');
  checklist.push('For detailed testing instructions, refer to:');
  checklist.push(`- [WordPress Compatibility](${plugin.slug}-wordpress-compatibility.md)`);
  checklist.push(`- [PHP Compatibility](${plugin.slug}-php-compatibility.md)`);
  checklist.push(`- [Theme Compatibility](${plugin.slug}-themes-compatibility.md)`);
  checklist.push(`- [Plugin Compatibility](${plugin.slug}-plugins-compatibility.md)`);
  checklist.push(`- [Multisite Compatibility](${plugin.slug}-multisite-compatibility.md)`);
  checklist.push(`- [Performance Compatibility](${plugin.slug}-performance-compatibility.md)`);
  checklist.push(`- [Security Compatibility](${plugin.slug}-security-compatibility.md)`);
  checklist.push('');
  
  return checklist.join('\n');
}

function generateWordPressCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - WordPress Version Compatibility`);
  checklist.push('');
  
  WORDPRESS_VERSIONS.forEach(wp => {
    checklist.push(`## WordPress ${wp.version} (${wp.status} - ${wp.priority.toUpperCase()} priority)`);
    checklist.push('');
    
    checklist.push('### Core Functionality Tests');
    checklist.push('- [ ] Plugin activates without errors');
    checklist.push('- [ ] Plugin deactivates cleanly');
    checklist.push('- [ ] Admin interface loads correctly');
    checklist.push('- [ ] Frontend functionality works');
    checklist.push('- [ ] Settings save and load properly');
    checklist.push('');
    
    checklist.push('### WordPress API Compatibility');
    checklist.push('- [ ] WordPress hooks work correctly');
    checklist.push('- [ ] Database API functions work');
    checklist.push('- [ ] HTTP API functions work');
    checklist.push('- [ ] File system API works');
    checklist.push('');
    
    if (plugin.rest_routes?.length > 0) {
      checklist.push('### REST API Compatibility');
      checklist.push('- [ ] REST endpoints respond correctly');
      checklist.push('- [ ] Authentication works');
      checklist.push('- [ ] Error handling is proper');
      checklist.push('');
    }
    
    if (plugin.blocks?.length > 0) {
      checklist.push('### Gutenberg/Block Editor');
      checklist.push('- [ ] Blocks render correctly');
      checklist.push('- [ ] Block editor integration works');
      checklist.push('- [ ] Block validation passes');
      checklist.push('');
    }
    
    checklist.push('### Specific Tests for WordPress ' + wp.version);
    if (wp.version === '6.4') {
      checklist.push('- [ ] Test with new Twenty Twenty-Four theme');
      checklist.push('- [ ] Verify PHP 8.3 compatibility');
      checklist.push('- [ ] Check new block patterns');
    } else if (wp.version === '6.3') {
      checklist.push('- [ ] Test command palette integration');
      checklist.push('- [ ] Verify new admin design updates');
      checklist.push('- [ ] Check block theme compatibility');
    }
    checklist.push('');
  });
  
  return checklist.join('\n');
}

function generatePHPCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - PHP Version Compatibility`);
  checklist.push('');
  
  PHP_VERSIONS.forEach(php => {
    checklist.push(`## PHP ${php.version} (${php.status} - ${php.priority.toUpperCase()} priority)`);
    checklist.push('');
    
    checklist.push('### Syntax and Function Tests');
    checklist.push('- [ ] No fatal errors on plugin activation');
    checklist.push('- [ ] No deprecated function warnings');
    checklist.push('- [ ] All plugin features work correctly');
    checklist.push('- [ ] Error handling works as expected');
    checklist.push('');
    
    checklist.push('### Performance Tests');
    checklist.push('- [ ] Page load times are acceptable');
    checklist.push('- [ ] Memory usage is within limits');
    checklist.push('- [ ] No performance regressions');
    checklist.push('');
    
    if (php.version.startsWith('8.')) {
      checklist.push('### PHP 8+ Specific Tests');
      checklist.push('- [ ] Named arguments compatibility');
      checklist.push('- [ ] Union types work correctly');
      checklist.push('- [ ] Match expressions (if used)');
      checklist.push('- [ ] Constructor property promotion');
      checklist.push('');
    }
    
    if (php.version === '7.4') {
      checklist.push('### PHP 7.4 Specific Tests');
      checklist.push('- [ ] Arrow functions work correctly');
      checklist.push('- [ ] Typed properties function properly');
      checklist.push('- [ ] Null coalescing assignment works');
      checklist.push('');
    }
  });
  
  return checklist.join('\n');
}

function generateThemeCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Theme Compatibility Testing`);
  checklist.push('');
  
  POPULAR_THEMES.forEach(theme => {
    checklist.push(`## ${theme.name} Theme (${theme.priority.toUpperCase()} priority)`);
    checklist.push('');
    
    checklist.push('### Visual Compatibility');
    checklist.push('- [ ] Plugin frontend elements display correctly');
    checklist.push('- [ ] No CSS conflicts or broken layouts');
    checklist.push('- [ ] Responsive design works on all devices');
    checklist.push('- [ ] Colors and fonts integrate well');
    checklist.push('');
    
    checklist.push('### Functional Compatibility');
    checklist.push('- [ ] All plugin features work correctly');
    checklist.push('- [ ] JavaScript functions properly');
    checklist.push('- [ ] Forms and interactions work');
    checklist.push('- [ ] AJAX requests complete successfully');
    checklist.push('');
    
    if (plugin.shortcodes?.length > 0) {
      checklist.push('### Shortcode Compatibility');
      plugin.shortcodes.forEach(shortcode => {
        checklist.push(`- [ ] [${shortcode}] renders correctly`);
      });
      checklist.push('');
    }
    
    if (plugin.blocks?.length > 0) {
      checklist.push('### Block Compatibility');
      checklist.push('- [ ] Blocks render correctly in theme');
      checklist.push('- [ ] Block styles integrate with theme');
      checklist.push('- [ ] Full-width blocks work properly');
      checklist.push('');
    }
  });
  
  return checklist.join('\n');
}

function generatePluginCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Plugin Compatibility Testing`);
  checklist.push('');
  
  POPULAR_PLUGINS.forEach(otherPlugin => {
    checklist.push(`## ${otherPlugin.name} Plugin (${otherPlugin.priority.toUpperCase()} priority)`);
    checklist.push('');
    
    checklist.push('### Activation/Deactivation Tests');
    checklist.push(`- [ ] Both plugins can be activated simultaneously`);
    checklist.push(`- [ ] No conflicts during activation`);
    checklist.push(`- [ ] Both plugins work correctly together`);
    checklist.push(`- [ ] No JavaScript conflicts`);
    checklist.push('');
    
    checklist.push('### Functional Integration Tests');
    checklist.push(`- [ ] Core features of both plugins work`);
    checklist.push(`- [ ] No database conflicts`);
    checklist.push(`- [ ] No admin interface conflicts`);
    checklist.push(`- [ ] No performance degradation`);
    checklist.push('');
    
    // Special compatibility tests for specific plugins
    if (otherPlugin.slug === 'woocommerce' && plugin.hooks?.actions?.some(hook => hook.includes('woocommerce'))) {
      checklist.push('### WooCommerce Specific Tests');
      checklist.push('- [ ] Product pages render correctly');
      checklist.push('- [ ] Checkout process works');
      checklist.push('- [ ] Cart functionality unaffected');
      checklist.push('- [ ] WooCommerce hooks integrate properly');
      checklist.push('');
    }
    
    if (otherPlugin.slug === 'wordpress-seo') {
      checklist.push('### Yoast SEO Specific Tests');
      checklist.push('- [ ] Meta tags are not duplicated');
      checklist.push('- [ ] SEO analysis works correctly');
      checklist.push('- [ ] XML sitemaps include plugin content');
      checklist.push('');
    }
    
    if (otherPlugin.slug === 'elementor' && plugin.blocks?.length > 0) {
      checklist.push('### Elementor Specific Tests');
      checklist.push('- [ ] Blocks work in Elementor editor');
      checklist.push('- [ ] Widget compatibility');
      checklist.push('- [ ] No editor conflicts');
      checklist.push('');
    }
  });
  
  return checklist.join('\n');
}

function generateMultisiteCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Multisite Compatibility Testing`);
  checklist.push('');
  
  checklist.push('## Network-Wide Activation Tests');
  checklist.push('- [ ] Plugin can be network activated successfully');
  checklist.push('- [ ] Plugin works on all sites in network');
  checklist.push('- [ ] Network admin pages function correctly');
  checklist.push('- [ ] Site-specific settings are properly isolated');
  checklist.push('');
  
  checklist.push('## Individual Site Activation Tests');
  checklist.push('- [ ] Plugin can be activated on individual sites');
  checklist.push('- [ ] Settings are site-specific');
  checklist.push('- [ ] No cross-site data leakage');
  checklist.push('- [ ] Deactivation affects only the specific site');
  checklist.push('');
  
  if (plugin.database_tables?.length > 0) {
    checklist.push('## Database Multisite Tests');
    plugin.database_tables.forEach(table => {
      checklist.push(`- [ ] Table ${table} handles blog_id correctly`);
      checklist.push(`- [ ] Data isolation between sites for ${table}`);
    });
    checklist.push('');
  }
  
  if (plugin.admin_pages?.length > 0) {
    checklist.push('## Admin Interface Multisite Tests');
    plugin.admin_pages.forEach(page => {
      checklist.push(`- [ ] ${page.title} works in network admin`);
      checklist.push(`- [ ] ${page.title} works in site admin`);
      checklist.push(`- [ ] Proper capability checks for ${page.title}`);
    });
    checklist.push('');
  }
  
  checklist.push('## Network Configuration Tests');
  checklist.push('- [ ] Subdomain multisite configuration');
  checklist.push('- [ ] Subdirectory multisite configuration');
  checklist.push('- [ ] Domain mapping compatibility (if applicable)');
  checklist.push('- [ ] Network-wide settings vs site-specific settings');
  checklist.push('');
  
  return checklist.join('\n');
}

function generatePerformanceCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Performance Compatibility Testing`);
  checklist.push('');
  
  checklist.push('## Loading Performance Tests');
  checklist.push('- [ ] Page load time increase < 100ms');
  checklist.push('- [ ] Admin dashboard loads within acceptable time');
  checklist.push('- [ ] No blocking JavaScript on frontend');
  checklist.push('- [ ] CSS files are optimally loaded');
  checklist.push('');
  
  if (plugin.performance_indicators?.database_queries) {
    const totalQueries = Object.values(plugin.performance_indicators.database_queries).reduce((a, b) => a + b, 0);
    checklist.push('## Database Performance Tests');
    checklist.push(`- [ ] Database query count acceptable (currently: ${totalQueries})`);
    checklist.push('- [ ] No slow queries (> 1 second)');
    checklist.push('- [ ] Proper database indexes used');
    checklist.push('- [ ] Query caching implemented where appropriate');
    checklist.push('');
  }
  
  checklist.push('## Memory Usage Tests');
  checklist.push('- [ ] Memory usage increase < 10MB');
  checklist.push('- [ ] No memory leaks during extended use');
  checklist.push('- [ ] Proper resource cleanup on deactivation');
  checklist.push('');
  
  checklist.push('## Caching Compatibility Tests');
  checklist.push('- [ ] Works with WP Rocket');
  checklist.push('- [ ] Works with W3 Total Cache');
  checklist.push('- [ ] Works with WP Super Cache');
  checklist.push('- [ ] Works with object caching (Redis/Memcached)');
  checklist.push('- [ ] CDN compatibility (if applicable)');
  checklist.push('');
  
  return checklist.join('\n');
}

function generateSecurityCompatibility(plugin) {
  const checklist = [];
  checklist.push(`# ${plugin.name} - Security Compatibility Testing`);
  checklist.push('');
  
  checklist.push('## Security Plugin Compatibility');
  checklist.push('- [ ] Works with Wordfence Security');
  checklist.push('- [ ] Works with Sucuri Security');
  checklist.push('- [ ] Works with iThemes Security');
  checklist.push('- [ ] No false positives in security scans');
  checklist.push('');
  
  checklist.push('## Security Feature Tests');
  checklist.push('- [ ] Firewall rules don\'t block plugin functionality');
  checklist.push('- [ ] Malware scans don\'t flag plugin files');
  checklist.push('- [ ] Login security doesn\'t interfere with plugin');
  checklist.push('- [ ] Two-factor authentication compatibility');
  checklist.push('');
  
  if (plugin.security_patterns) {
    checklist.push('## Security Vulnerability Tests');
    const security = plugin.security_patterns;
    
    if (security.sql_injection_risks?.length > 0) {
      checklist.push('- [ ] **CRITICAL**: SQL injection vulnerabilities addressed');
    }
    if (security.xss_vulnerabilities?.length > 0) {
      checklist.push('- [ ] **CRITICAL**: XSS vulnerabilities addressed');
    }
    if (security.user_input_sanitization?.length > 0) {
      checklist.push('- [ ] **HIGH**: Input sanitization implemented');
    }
    if (security.capability_checks?.length > 0) {
      checklist.push('- [ ] **HIGH**: Capability checks implemented');
    }
    if (security.nonce_verification?.length > 0) {
      checklist.push('- [ ] **MEDIUM**: CSRF protection implemented');
    }
    checklist.push('');
  }
  
  checklist.push('## Server Security Compatibility');
  checklist.push('- [ ] Works with ModSecurity rules');
  checklist.push('- [ ] No conflicts with fail2ban');
  checklist.push('- [ ] HTTPS/SSL compatibility');
  checklist.push('- [ ] Content Security Policy compatibility');
  checklist.push('');
  
  return checklist.join('\n');
}

// Run the main function
main().catch(console.error);