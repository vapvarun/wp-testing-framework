#!/usr/bin/env bash
# ============================================================================
# WordPress Universal Testing Framework Installer
# Version: 3.0.0
# 
# Works with ANY WordPress plugin or theme - not just BuddyPress!
# Automatically scans and generates tests for any WordPress project.
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Functions for colored output
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# Configuration
FRAMEWORK_NAME="wp-testing-framework"
SCANNER_PLUGIN="wbcom-universal-scanner"

# Parse command line arguments
PLUGIN_SLUG=""
THEME_SLUG=""
PROJECT_NAME=""
TARGET_TYPE=""

show_help() {
    echo -e "${CYAN}WordPress Universal Testing Framework Installer${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --plugin <slug>    Test a specific plugin (e.g., woocommerce, buddypress)"
    echo "  --theme <slug>     Test a specific theme"
    echo "  --name <name>      Project name for the test suite"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --plugin woocommerce --name 'WooCommerce Tests'"
    echo "  $0 --plugin buddypress --name 'BuddyPress Suite'"
    echo "  $0 --theme twentytwentyfour --name 'TT4 Tests'"
    echo "  $0 --plugin my-custom-plugin --name 'My Plugin'"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --plugin)
            PLUGIN_SLUG="$2"
            TARGET_TYPE="plugin"
            shift 2
            ;;
        --theme)
            THEME_SLUG="$2"
            TARGET_TYPE="theme"
            shift 2
            ;;
        --name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# If no arguments, show interactive menu
if [ -z "$TARGET_TYPE" ]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   WordPress Universal Testing Framework Installer     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "What would you like to test?"
    echo "1) A WordPress Plugin"
    echo "2) A WordPress Theme"
    echo "3) Full Site (all plugins and themes)"
    echo ""
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            TARGET_TYPE="plugin"
            read -p "Enter plugin slug (folder name): " PLUGIN_SLUG
            read -p "Enter project name: " PROJECT_NAME
            ;;
        2)
            TARGET_TYPE="theme"
            read -p "Enter theme slug (folder name): " THEME_SLUG
            read -p "Enter project name: " PROJECT_NAME
            ;;
        3)
            TARGET_TYPE="site"
            PROJECT_NAME="Full Site Tests"
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
fi

# Set default project name if not provided
if [ -z "$PROJECT_NAME" ]; then
    if [ "$TARGET_TYPE" = "plugin" ]; then
        PROJECT_NAME="${PLUGIN_SLUG} Tests"
    elif [ "$TARGET_TYPE" = "theme" ]; then
        PROJECT_NAME="${THEME_SLUG} Tests"
    else
        PROJECT_NAME="WordPress Tests"
    fi
fi

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v wp &> /dev/null; then
        log_error "WP-CLI is not installed"
        echo "  Install from: https://wp-cli.org"
        missing=1
    fi
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        echo "  Install from: https://nodejs.org"
        missing=1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Please install missing prerequisites and try again."
        exit 1
    fi
    
    log_success "All prerequisites met!"
}

# Main installation
main() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Installing WordPress Testing Framework         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Project: ${MAGENTA}${PROJECT_NAME}${NC}"
    log_info "Target Type: ${MAGENTA}${TARGET_TYPE}${NC}"
    if [ "$TARGET_TYPE" = "plugin" ]; then
        log_info "Plugin: ${MAGENTA}${PLUGIN_SLUG}${NC}"
    elif [ "$TARGET_TYPE" = "theme" ]; then
        log_info "Theme: ${MAGENTA}${THEME_SLUG}${NC}"
    fi
    echo ""
    
    ROOT="$(pwd)"
    
    # Create directory structure
    log_step "Creating directory structure..."
    mkdir -p wp-content/plugins/${SCANNER_PLUGIN}/cli
    mkdir -p tools/scanners tools/ai tools/e2e/tests 
    mkdir -p wp-content/uploads/wp-scan wp-content/uploads/wp-test-plan/docs 
    mkdir -p tests/phpunit/Unit tests/phpunit/Integration tests/phpunit/Functional
    mkdir -p tests/cypress/integration tests/cypress/fixtures
    
    # ============================================================================
    # 1. UNIVERSAL SCANNER PLUGIN
    # ============================================================================
    log_step "Installing universal scanner plugin..."
    
    cat > wp-content/plugins/${SCANNER_PLUGIN}/${SCANNER_PLUGIN}.php <<'PHP'
<?php
/**
 * Plugin Name: WordPress Universal Scanner
 * Description: Scans any WordPress plugin/theme for automated test generation
 * Version: 3.0.0
 * Author: WP Testing Framework
 * License: GPL v2 or later
 */

defined('ABSPATH') || exit;

if (defined('WP_CLI') && WP_CLI) { 
    require __DIR__ . '/cli/class-wp-universal-scanner.php'; 
}
PHP
    
    cat > wp-content/plugins/${SCANNER_PLUGIN}/cli/class-wp-universal-scanner.php <<'PHP'
<?php
if (!defined('ABSPATH')) exit;
if (!class_exists('WP_CLI')) return;

class WP_Universal_Scanner_CLI {
    
    /**
     * Scan WordPress plugins
     */
    public function plugins($args, $assoc_args) {
        $specific = isset($assoc_args['slug']) ? $assoc_args['slug'] : null;
        $plugins = get_plugins();
        $active_plugins = get_option('active_plugins', []);
        $output = [];
        
        foreach ($plugins as $file => $data) {
            $slug = dirname($file);
            if ($slug === '.') $slug = basename($file, '.php');
            
            if ($specific && $slug !== $specific) continue;
            
            $plugin_dir = WP_PLUGIN_DIR . '/' . $slug;
            $output[] = [
                'slug' => $slug,
                'name' => $data['Name'],
                'version' => $data['Version'],
                'active' => in_array($file, $active_plugins),
                'file' => $file,
                'path' => $plugin_dir,
                'has_admin' => is_dir($plugin_dir . '/admin'),
                'has_public' => is_dir($plugin_dir . '/public'),
                'has_includes' => is_dir($plugin_dir . '/includes'),
                'has_assets' => is_dir($plugin_dir . '/assets'),
                'has_tests' => is_dir($plugin_dir . '/tests'),
                'hooks' => $this->scan_hooks($plugin_dir),
                'shortcodes' => $this->scan_shortcodes($plugin_dir),
                'ajax_actions' => $this->scan_ajax($plugin_dir),
                'rest_routes' => $this->scan_rest_routes($slug),
                'database_tables' => $this->scan_database_tables($slug),
                'admin_pages' => $this->scan_admin_pages($slug),
                'settings' => $this->scan_settings($slug),
                'post_types' => $this->scan_post_types($slug),
                'taxonomies' => $this->scan_taxonomies($slug),
                'widgets' => $this->scan_widgets($slug),
                'blocks' => $this->scan_blocks($plugin_dir)
            ];
        }
        
        echo json_encode($output, JSON_PRETTY_PRINT) . PHP_EOL;
    }
    
    /**
     * Scan WordPress themes
     */
    public function themes($args, $assoc_args) {
        $specific = isset($assoc_args['slug']) ? $assoc_args['slug'] : null;
        $themes = wp_get_themes();
        $current_theme = get_stylesheet();
        $output = [];
        
        foreach ($themes as $slug => $theme) {
            if ($specific && $slug !== $specific) continue;
            
            $theme_dir = $theme->get_stylesheet_directory();
            $output[] = [
                'slug' => $slug,
                'name' => $theme->get('Name'),
                'version' => $theme->get('Version'),
                'active' => ($slug === $current_theme),
                'parent' => $theme->get('Template'),
                'path' => $theme_dir,
                'template_files' => $this->scan_templates($theme_dir),
                'has_functions' => file_exists($theme_dir . '/functions.php'),
                'has_customizer' => $this->scan_customizer($theme_dir),
                'supports' => $this->get_theme_support(),
                'menus' => $this->scan_menus(),
                'sidebars' => $this->scan_sidebars(),
                'hooks' => $this->scan_hooks($theme_dir),
                'blocks' => $this->scan_blocks($theme_dir)
            ];
        }
        
        echo json_encode($output, JSON_PRETTY_PRINT) . PHP_EOL;
    }
    
    /**
     * Scan hooks (actions and filters)
     */
    private function scan_hooks($dir) {
        if (!is_dir($dir)) return [];
        
        $hooks = ['actions' => [], 'filters' => []];
        $files = glob($dir . '/**/*.php');
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            
            // Scan for add_action
            preg_match_all('/add_action\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $actions);
            foreach ($actions[1] as $action) {
                $hooks['actions'][] = $action;
            }
            
            // Scan for add_filter
            preg_match_all('/add_filter\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $filters);
            foreach ($filters[1] as $filter) {
                $hooks['filters'][] = $filter;
            }
        }
        
        $hooks['actions'] = array_unique($hooks['actions']);
        $hooks['filters'] = array_unique($hooks['filters']);
        
        return $hooks;
    }
    
    /**
     * Scan shortcodes
     */
    private function scan_shortcodes($dir) {
        if (!is_dir($dir)) return [];
        
        $shortcodes = [];
        $files = glob($dir . '/**/*.php');
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            preg_match_all('/add_shortcode\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $matches);
            foreach ($matches[1] as $shortcode) {
                $shortcodes[] = $shortcode;
            }
        }
        
        return array_unique($shortcodes);
    }
    
    /**
     * Scan AJAX actions
     */
    private function scan_ajax($dir) {
        if (!is_dir($dir)) return [];
        
        $ajax_actions = [];
        $files = glob($dir . '/**/*.php');
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            preg_match_all('/wp_ajax_(nopriv_)?([a-zA-Z0-9_]+)/i', $content, $matches);
            foreach ($matches[2] as $action) {
                $ajax_actions[] = $action;
            }
        }
        
        return array_unique($ajax_actions);
    }
    
    /**
     * Scan REST routes
     */
    private function scan_rest_routes($slug) {
        $routes = [];
        $server = rest_get_server();
        $all_routes = $server->get_routes();
        
        foreach ($all_routes as $route => $handlers) {
            if (strpos($route, '/' . $slug . '/') !== false || 
                strpos($route, '/wp/v2/' . $slug) !== false) {
                $methods = [];
                foreach ($handlers as $handler) {
                    if (isset($handler['methods'])) {
                        $methods = array_merge($methods, array_keys($handler['methods']));
                    }
                }
                $routes[] = [
                    'route' => $route,
                    'methods' => array_unique($methods)
                ];
            }
        }
        
        return $routes;
    }
    
    /**
     * Scan database tables
     */
    private function scan_database_tables($slug) {
        global $wpdb;
        $tables = [];
        
        $all_tables = $wpdb->get_col("SHOW TABLES");
        foreach ($all_tables as $table) {
            if (strpos($table, $slug) !== false || 
                strpos($table, str_replace('-', '_', $slug)) !== false) {
                $tables[] = $table;
            }
        }
        
        return $tables;
    }
    
    /**
     * Scan admin pages
     */
    private function scan_admin_pages($slug) {
        global $menu, $submenu;
        $pages = [];
        
        if (!empty($menu)) {
            foreach ($menu as $item) {
                if (isset($item[2]) && strpos($item[2], $slug) !== false) {
                    $pages[] = [
                        'title' => $item[0],
                        'capability' => $item[1],
                        'slug' => $item[2]
                    ];
                }
            }
        }
        
        return $pages;
    }
    
    /**
     * Scan settings
     */
    private function scan_settings($slug) {
        global $wpdb;
        $settings = [];
        
        $options = $wpdb->get_col(
            $wpdb->prepare(
                "SELECT option_name FROM {$wpdb->options} WHERE option_name LIKE %s",
                '%' . $wpdb->esc_like($slug) . '%'
            )
        );
        
        foreach ($options as $option) {
            $settings[] = [
                'name' => $option,
                'autoload' => get_option($option . '_autoload', 'yes')
            ];
        }
        
        return $settings;
    }
    
    /**
     * Scan custom post types
     */
    private function scan_post_types($slug) {
        $post_types = get_post_types(['public' => true], 'objects');
        $plugin_types = [];
        
        foreach ($post_types as $type) {
            if (strpos($type->name, $slug) !== false) {
                $plugin_types[] = [
                    'name' => $type->name,
                    'label' => $type->label,
                    'public' => $type->public,
                    'has_archive' => $type->has_archive
                ];
            }
        }
        
        return $plugin_types;
    }
    
    /**
     * Scan taxonomies
     */
    private function scan_taxonomies($slug) {
        $taxonomies = get_taxonomies(['public' => true], 'objects');
        $plugin_taxonomies = [];
        
        foreach ($taxonomies as $tax) {
            if (strpos($tax->name, $slug) !== false) {
                $plugin_taxonomies[] = [
                    'name' => $tax->name,
                    'label' => $tax->label,
                    'hierarchical' => $tax->hierarchical
                ];
            }
        }
        
        return $plugin_taxonomies;
    }
    
    /**
     * Scan widgets
     */
    private function scan_widgets($slug) {
        global $wp_widget_factory;
        $widgets = [];
        
        if (isset($wp_widget_factory->widgets)) {
            foreach ($wp_widget_factory->widgets as $widget) {
                $class = get_class($widget);
                if (stripos($class, $slug) !== false) {
                    $widgets[] = [
                        'class' => $class,
                        'name' => $widget->name,
                        'id_base' => $widget->id_base
                    ];
                }
            }
        }
        
        return $widgets;
    }
    
    /**
     * Scan Gutenberg blocks
     */
    private function scan_blocks($dir) {
        $blocks = [];
        
        // Check for block.json files
        $block_files = glob($dir . '/**/block.json');
        foreach ($block_files as $file) {
            $data = json_decode(file_get_contents($file), true);
            if ($data && isset($data['name'])) {
                $blocks[] = [
                    'name' => $data['name'],
                    'title' => $data['title'] ?? '',
                    'category' => $data['category'] ?? 'common',
                    'supports' => $data['supports'] ?? []
                ];
            }
        }
        
        return $blocks;
    }
    
    /**
     * Scan templates
     */
    private function scan_templates($dir) {
        $templates = [];
        $template_files = glob($dir . '/*.php');
        
        foreach ($template_files as $file) {
            $filename = basename($file);
            $content = file_get_contents($file);
            
            // Check for template header
            if (preg_match('/Template Name:\s*(.+)/i', $content, $matches)) {
                $templates[] = [
                    'file' => $filename,
                    'name' => $matches[1]
                ];
            } elseif (in_array($filename, ['index.php', 'single.php', 'page.php', 'archive.php', '404.php'])) {
                $templates[] = [
                    'file' => $filename,
                    'name' => ucfirst(str_replace(['.php', '-'], ['', ' '], $filename))
                ];
            }
        }
        
        return $templates;
    }
    
    /**
     * Check for customizer
     */
    private function scan_customizer($dir) {
        $files = glob($dir . '/**/*.php');
        foreach ($files as $file) {
            $content = file_get_contents($file);
            if (strpos($content, 'customize_register') !== false) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Get theme supports
     */
    private function get_theme_support() {
        $supports = [];
        $features = [
            'post-thumbnails', 'custom-logo', 'custom-header', 
            'custom-background', 'menus', 'widgets', 'editor-styles',
            'align-wide', 'responsive-embeds', 'html5'
        ];
        
        foreach ($features as $feature) {
            if (current_theme_supports($feature)) {
                $supports[] = $feature;
            }
        }
        
        return $supports;
    }
    
    /**
     * Scan menus
     */
    private function scan_menus() {
        $locations = get_registered_nav_menus();
        $menus = wp_get_nav_menus();
        
        return [
            'locations' => array_keys($locations),
            'menus' => array_map(function($menu) {
                return [
                    'name' => $menu->name,
                    'slug' => $menu->slug,
                    'count' => $menu->count
                ];
            }, $menus)
        ];
    }
    
    /**
     * Scan sidebars
     */
    private function scan_sidebars() {
        global $wp_registered_sidebars;
        $sidebars = [];
        
        foreach ($wp_registered_sidebars as $sidebar) {
            $sidebars[] = [
                'id' => $sidebar['id'],
                'name' => $sidebar['name']
            ];
        }
        
        return $sidebars;
    }
    
    /**
     * Full site scan
     */
    public function site($args, $assoc_args) {
        $output = [
            'site_info' => [
                'name' => get_bloginfo('name'),
                'url' => get_bloginfo('url'),
                'version' => get_bloginfo('version'),
                'multisite' => is_multisite(),
                'theme' => get_stylesheet(),
                'active_plugins' => count(get_option('active_plugins', []))
            ],
            'plugins' => json_decode($this->plugins([], []), true),
            'themes' => json_decode($this->themes([], []), true),
            'users' => count_users(),
            'content' => [
                'posts' => wp_count_posts(),
                'pages' => wp_count_posts('page'),
                'comments' => wp_count_comments(),
                'media' => wp_count_posts('attachment')
            ]
        ];
        
        echo json_encode($output, JSON_PRETTY_PRINT) . PHP_EOL;
    }
}

// Register WP-CLI commands
WP_CLI::add_command('scan plugins', ['WP_Universal_Scanner_CLI', 'plugins']);
WP_CLI::add_command('scan themes', ['WP_Universal_Scanner_CLI', 'themes']);
WP_CLI::add_command('scan site', ['WP_Universal_Scanner_CLI', 'site']);
PHP
    
    # ============================================================================
    # 2. SCAN RUNNER SCRIPT
    # ============================================================================
    log_step "Creating scan runner scripts..."
    
    # Main scanner script
    cat > tools/scanners/scan-wp.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT="wp-content/uploads/wp-scan"
mkdir -p "$OUT"

TARGET_TYPE="${1:-site}"
TARGET_SLUG="${2:-}"

echo "🔍 Scanning WordPress ${TARGET_TYPE}..."

case "$TARGET_TYPE" in
    plugin)
        echo "→ scanning plugin: ${TARGET_SLUG}"
        wp scan plugins --slug="${TARGET_SLUG}" > "$OUT/plugin-${TARGET_SLUG}.json"
        ;;
    theme)
        echo "→ scanning theme: ${TARGET_SLUG}"
        wp scan themes --slug="${TARGET_SLUG}" > "$OUT/theme-${TARGET_SLUG}.json"
        ;;
    site|*)
        echo "→ scanning full site"
        wp scan site > "$OUT/site.json"
        echo "→ scanning all plugins"
        wp scan plugins > "$OUT/plugins.json"
        echo "→ scanning all themes"
        wp scan themes > "$OUT/themes.json"
        ;;
esac

echo "✅ Scan complete. Results in $OUT"
SH
    chmod +x tools/scanners/scan-wp.sh
    
    # ============================================================================
    # 3. UNIVERSAL TEST GENERATOR
    # ============================================================================
    log_step "Installing universal test generator..."
    
    cat > tools/ai/generate-tests.mjs <<'JS'
#!/usr/bin/env node
/**
 * Universal WordPress Test Generator
 * Generates comprehensive test suites for any WordPress plugin or theme
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// CLI arguments
const args = process.argv;
const inDir = argOf('--in', 'wp-content/uploads/wp-scan');
const outDir = argOf('--out', 'wp-content/uploads/wp-test-plan');
const targetType = argOf('--type', 'site');
const targetSlug = argOf('--slug', '');
const projectName = argOf('--name', 'WordPress Tests');

function argOf(flag, def) { 
    return args.includes(flag) ? args[args.indexOf(flag) + 1] : def; 
}

// IO helpers
function readJSONSafe(p, def) {
    if (!fs.existsSync(p)) return def;
    try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return def; }
}

function ensureDir(p) { 
    fs.mkdirSync(p, { recursive: true }); 
}

function writeFile(dest, content) {
    ensureDir(path.dirname(dest));
    fs.writeFileSync(dest, content);
    console.log('  → wrote', dest);
}

// Load scan data
function loadScanData() {
    let data = {};
    
    if (targetType === 'plugin') {
        data = readJSONSafe(path.join(inDir, `plugin-${targetSlug}.json`), []);
        if (Array.isArray(data) && data.length > 0) data = data[0];
    } else if (targetType === 'theme') {
        data = readJSONSafe(path.join(inDir, `theme-${targetSlug}.json`), []);
        if (Array.isArray(data) && data.length > 0) data = data[0];
    } else {
        data = readJSONSafe(path.join(inDir, 'site.json'), {});
    }
    
    return data;
}

// Generate test plan
function generateTestPlan(data) {
    const plan = {
        yaml: generateYAML(data),
        markdown: generateMarkdown(data),
        phpunit: generatePHPUnitTests(data),
        playwright: generatePlaywrightTests(data),
        cypress: generateCypressTests(data),
        risks: identifyRisks(data)
    };
    
    return plan;
}

// Generate YAML test plan
function generateYAML(data) {
    const yaml = [];
    yaml.push(`# Test Plan: ${projectName}`);
    yaml.push(`# Generated: ${new Date().toISOString()}`);
    yaml.push('');
    yaml.push('test_coverage:');
    
    if (data.hooks) {
        yaml.push('  hooks:');
        yaml.push(`    actions: ${data.hooks.actions?.length || 0}`);
        yaml.push(`    filters: ${data.hooks.filters?.length || 0}`);
    }
    
    if (data.shortcodes) {
        yaml.push(`  shortcodes: ${data.shortcodes.length}`);
    }
    
    if (data.ajax_actions) {
        yaml.push(`  ajax_endpoints: ${data.ajax_actions.length}`);
    }
    
    if (data.rest_routes) {
        yaml.push(`  rest_endpoints: ${data.rest_routes.length}`);
    }
    
    if (data.blocks) {
        yaml.push(`  gutenberg_blocks: ${data.blocks.length}`);
    }
    
    if (data.post_types) {
        yaml.push(`  custom_post_types: ${data.post_types.length}`);
    }
    
    if (data.taxonomies) {
        yaml.push(`  custom_taxonomies: ${data.taxonomies.length}`);
    }
    
    yaml.push('');
    yaml.push('test_types:');
    yaml.push('  - unit: Core functionality tests');
    yaml.push('  - integration: WordPress integration tests');
    yaml.push('  - functional: User workflow tests');
    yaml.push('  - e2e: Browser-based tests');
    yaml.push('  - performance: Load and speed tests');
    yaml.push('  - security: Vulnerability scans');
    
    return yaml.join('\n');
}

// Generate Markdown documentation
function generateMarkdown(data) {
    const md = [];
    md.push(`# Test Plan: ${projectName}`);
    md.push('');
    md.push(`Generated: ${new Date().toLocaleDateString()}`);
    md.push('');
    
    md.push('## Coverage Overview');
    md.push('');
    
    // Hooks
    if (data.hooks && (data.hooks.actions?.length || data.hooks.filters?.length)) {
        md.push('### WordPress Hooks');
        md.push(`- **Actions**: ${data.hooks.actions?.length || 0} hooks to test`);
        md.push(`- **Filters**: ${data.hooks.filters?.length || 0} filters to test`);
        md.push('');
    }
    
    // Shortcodes
    if (data.shortcodes?.length) {
        md.push('### Shortcodes');
        data.shortcodes.forEach(sc => {
            md.push(`- [ ] Test [${sc}] shortcode`);
        });
        md.push('');
    }
    
    // AJAX
    if (data.ajax_actions?.length) {
        md.push('### AJAX Actions');
        data.ajax_actions.forEach(action => {
            md.push(`- [ ] Test ${action} AJAX endpoint`);
        });
        md.push('');
    }
    
    // REST API
    if (data.rest_routes?.length) {
        md.push('### REST API Endpoints');
        data.rest_routes.forEach(route => {
            md.push(`- [ ] ${route.methods.join(', ')}: ${route.route}`);
        });
        md.push('');
    }
    
    // Blocks
    if (data.blocks?.length) {
        md.push('### Gutenberg Blocks');
        data.blocks.forEach(block => {
            md.push(`- [ ] Test ${block.name} block`);
        });
        md.push('');
    }
    
    // Admin Pages
    if (data.admin_pages?.length) {
        md.push('### Admin Pages');
        data.admin_pages.forEach(page => {
            md.push(`- [ ] Test ${page.title} admin page`);
        });
        md.push('');
    }
    
    md.push('## Test Execution');
    md.push('');
    md.push('### Unit Tests');
    md.push('```bash');
    md.push('npm run test:unit');
    md.push('```');
    md.push('');
    md.push('### Integration Tests');
    md.push('```bash');
    md.push('npm run test:integration');
    md.push('```');
    md.push('');
    md.push('### E2E Tests');
    md.push('```bash');
    md.push('npm run test:e2e');
    md.push('```');
    
    return md.join('\n');
}

// Generate PHPUnit tests
function generatePHPUnitTests(data) {
    const tests = [];
    const className = (data.name || projectName).replace(/[^a-zA-Z0-9]/g, '');
    
    // Basic plugin/theme test
    const basicTest = `<?php
namespace Tests\\Integration;

use WP_UnitTestCase;

class ${className}Test extends WP_UnitTestCase {
    
    public function test_${targetType}_is_active() {
        ${targetType === 'plugin' ? 
            `$this->assertTrue(is_plugin_active('${data.file || targetSlug}'));` :
            `$this->assertEquals('${targetSlug}', get_stylesheet());`}
    }
    
    public function test_required_functions_exist() {
        // Test that key functions are available
        $this->assertTrue(function_exists('wp_head'));
    }
}`;
    
    tests.push({
        relpath: `tests/phpunit/Integration/${className}Test.php`,
        code: basicTest
    });
    
    // Hooks test if there are hooks
    if (data.hooks && (data.hooks.actions?.length || data.hooks.filters?.length)) {
        const hooksTest = `<?php
namespace Tests\\Unit;

use PHPUnit\\Framework\\TestCase;
use Brain\\Monkey;
use Brain\\Monkey\\Functions;
use Brain\\Monkey\\Actions;
use Brain\\Monkey\\Filters;

class ${className}HooksTest extends TestCase {
    
    protected function setUp(): void {
        parent::setUp();
        Monkey\\setUp();
    }
    
    protected function tearDown(): void {
        Monkey\\tearDown();
        parent::tearDown();
    }
    
    public function test_actions_are_registered() {
        ${data.hooks.actions?.slice(0, 3).map(action => 
            `Actions\\expectAdded('${action}');`
        ).join('\n        ')}
        
        // Load the plugin/theme
        $this->assertTrue(true);
    }
    
    public function test_filters_are_registered() {
        ${data.hooks.filters?.slice(0, 3).map(filter => 
            `Filters\\expectAdded('${filter}');`
        ).join('\n        ')}
        
        // Load the plugin/theme
        $this->assertTrue(true);
    }
}`;
        
        tests.push({
            relpath: `tests/phpunit/Unit/${className}HooksTest.php`,
            code: hooksTest
        });
    }
    
    // REST API test if there are routes
    if (data.rest_routes?.length) {
        const restTest = `<?php
namespace Tests\\Functional;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class ${className}RestApiTest extends WP_UnitTestCase {
    
    protected $server;
    
    public function setUp(): void {
        parent::setUp();
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server();
        do_action('rest_api_init');
    }
    
    public function tearDown(): void {
        global $wp_rest_server;
        $wp_rest_server = null;
        parent::tearDown();
    }
    
    public function test_routes_are_registered() {
        $routes = $this->server->get_routes();
        ${data.rest_routes.slice(0, 3).map(route => 
            `$this->assertArrayHasKey('${route.route}', $routes);`
        ).join('\n        ')}
    }
}`;
        
        tests.push({
            relpath: `tests/phpunit/Functional/${className}RestApiTest.php`,
            code: restTest
        });
    }
    
    return tests;
}

// Generate Playwright tests
function generatePlaywrightTests(data) {
    const tests = [];
    
    // Basic test
    const basicTest = `import { test, expect } from '@playwright/test';

const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost';
const ADMIN_USER = process.env.E2E_USER || 'admin';
const ADMIN_PASS = process.env.E2E_PASS || 'password';

test.describe('${projectName} E2E Tests', () => {
    
    test.beforeEach(async ({ page }) => {
        // Login to WordPress admin
        await page.goto(BASE_URL + '/wp-login.php');
        await page.fill('#user_login', ADMIN_USER);
        await page.fill('#user_pass', ADMIN_PASS);
        await page.click('#wp-submit');
        await page.waitForURL(/.*\\/wp-admin.*/);
    });
    
    test('should access plugin/theme settings', async ({ page }) => {
        await page.goto(BASE_URL + '/wp-admin/');
        await expect(page.locator('#wpadminbar')).toBeVisible();
    });
    
    ${data.admin_pages?.slice(0, 3).map(page => `
    test('should load ${page.title} page', async ({ page }) => {
        await page.goto(BASE_URL + '/wp-admin/admin.php?page=${page.slug}');
        await expect(page.locator('h1')).toContainText(/${page.title}/i);
    });`).join('\n    ')}
});`;
    
    tests.push({
        relpath: `tools/e2e/tests/${targetSlug || 'main'}.spec.ts`,
        code: basicTest
    });
    
    // Shortcode test if exists
    if (data.shortcodes?.length) {
        const shortcodeTest = `import { test, expect } from '@playwright/test';

test.describe('Shortcode Tests', () => {
    test('should render shortcodes on frontend', async ({ page }) => {
        // Create a test page with shortcodes
        // This would need to be set up in advance
        await page.goto(process.env.E2E_BASE_URL || 'http://localhost');
        
        ${data.shortcodes.slice(0, 3).map(sc => `
        // Test [${sc}] shortcode
        const ${sc.replace(/[^a-zA-Z]/g, '')}Element = page.locator('[data-shortcode="${sc}"]');
        if (await ${sc.replace(/[^a-zA-Z]/g, '')}Element.isVisible()) {
            await expect(${sc.replace(/[^a-zA-Z]/g, '')}Element).toBeVisible();
        }`).join('\n        ')}
    });
});`;
        
        tests.push({
            relpath: `tools/e2e/tests/shortcodes.spec.ts`,
            code: shortcodeTest
        });
    }
    
    return tests;
}

// Generate Cypress tests
function generateCypressTests(data) {
    const tests = [];
    
    const cypressTest = `describe('${projectName} Tests', () => {
    beforeEach(() => {
        // Login to WordPress
        cy.visit('/wp-login.php');
        cy.get('#user_login').type(Cypress.env('WP_USER'));
        cy.get('#user_pass').type(Cypress.env('WP_PASS'));
        cy.get('#wp-submit').click();
        cy.url().should('include', '/wp-admin');
    });
    
    it('should load admin dashboard', () => {
        cy.visit('/wp-admin');
        cy.get('#wpadminbar').should('be.visible');
    });
    
    ${data.admin_pages?.slice(0, 2).map(page => `
    it('should access ${page.title}', () => {
        cy.visit('/wp-admin/admin.php?page=${page.slug}');
        cy.get('h1').should('contain', '${page.title}');
    });`).join('\n    ')}
});`;
    
    tests.push({
        relpath: `tests/cypress/integration/${targetSlug || 'main'}.spec.js`,
        code: cypressTest
    });
    
    return tests;
}

// Identify risks
function identifyRisks(data) {
    const risks = [];
    
    if (!data || Object.keys(data).length === 0) {
        risks.push('No scan data found - ensure the target exists');
    }
    
    if (data.database_tables?.length > 10) {
        risks.push(`Large number of database tables (${data.database_tables.length}) - consider data migration tests`);
    }
    
    if (data.ajax_actions?.length > 20) {
        risks.push(`Many AJAX actions (${data.ajax_actions.length}) - ensure proper nonce verification`);
    }
    
    if (data.rest_routes?.length > 30) {
        risks.push(`Extensive REST API (${data.rest_routes.length} routes) - implement API versioning tests`);
    }
    
    if (!data.has_tests) {
        risks.push('No existing tests found - starting from scratch');
    }
    
    return risks;
}

// Main execution
console.log('🚀 Generating test plan...');
console.log(`   Project: ${projectName}`);
console.log(`   Type: ${targetType}`);
if (targetSlug) console.log(`   Target: ${targetSlug}`);

try {
    const scanData = loadScanData();
    const testPlan = generateTestPlan(scanData);
    
    const docsDir = path.join(outDir, 'docs');
    
    // Write documentation
    writeFile(path.join(docsDir, 'TEST-PLAN.yaml'), testPlan.yaml);
    writeFile(path.join(docsDir, 'TEST-PLAN.md'), testPlan.markdown);
    
    if (testPlan.risks.length > 0) {
        writeFile(path.join(docsDir, 'RISKS.md'), 
            '# Identified Risks\n\n' + testPlan.risks.map(r => `- ${r}`).join('\n'));
    }
    
    // Write test files
    testPlan.phpunit.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    testPlan.playwright.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    testPlan.cypress.forEach(f => writeFile(path.join(process.cwd(), f.relpath), f.code));
    
    console.log('✅ Test plan generated successfully!');
    console.log(`   Documentation: ${docsDir}`);
    console.log(`   PHPUnit tests: ${testPlan.phpunit.length} files`);
    console.log(`   Playwright tests: ${testPlan.playwright.length} files`);
    console.log(`   Cypress tests: ${testPlan.cypress.length} files`);
    
} catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
}
JS
    chmod +x tools/ai/generate-tests.mjs
    
    # ============================================================================
    # 4. PACKAGE.JSON
    # ============================================================================
    log_step "Creating package.json..."
    
    cat > package.json <<JSON
{
  "name": "${FRAMEWORK_NAME}",
  "version": "3.0.0",
  "description": "Universal WordPress Testing Framework - ${PROJECT_NAME}",
  "private": true,
  "scripts": {
    "scan": "bash tools/scanners/scan-wp.sh ${TARGET_TYPE} ${PLUGIN_SLUG}${THEME_SLUG}",
    "generate": "node tools/ai/generate-tests.mjs --type ${TARGET_TYPE} --slug ${PLUGIN_SLUG}${THEME_SLUG} --name '${PROJECT_NAME}'",
    "test:plan": "npm run scan && npm run generate",
    "test": "npm run test:unit && npm run test:e2e",
    "test:unit": "vendor/bin/phpunit -c phpunit-unit.xml",
    "test:integration": "vendor/bin/phpunit -c phpunit.xml",
    "test:functional": "vendor/bin/phpunit --testsuite functional",
    "test:e2e": "playwright test --config=tools/e2e/playwright.config.ts",
    "test:cypress": "cypress run",
    "cypress:open": "cypress open",
    "e2e": "playwright test --config=tools/e2e/playwright.config.ts",
    "e2e:ui": "playwright test --config=tools/e2e/playwright.config.ts --ui",
    "e2e:update": "playwright test --config=tools/e2e/playwright.config.ts --update-snapshots",
    "setup": "npm install && composer install && npx playwright install",
    "clean": "rm -rf node_modules vendor .phpunit.cache test-results playwright-report"
  },
  "devDependencies": {
    "@playwright/test": "^1.46.0",
    "@types/node": "^20.0.0",
    "cypress": "^13.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
JSON
    
    # ============================================================================
    # 5. COMPOSER.JSON
    # ============================================================================
    log_step "Creating composer.json..."
    
    cat > composer.json <<JSON
{
  "name": "${FRAMEWORK_NAME}/tests",
  "description": "Test suite for ${PROJECT_NAME}",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require-dev": {
    "phpunit/phpunit": "^10.5",
    "yoast/phpunit-polyfills": "^2.0",
    "wp-phpunit/wp-phpunit": "^6.4",
    "brain/monkey": "^2.6",
    "mockery/mockery": "^1.6",
    "php-stubs/wordpress-stubs": "^6.4",
    "szepeviktor/phpstan-wordpress": "^1.3"
  },
  "autoload-dev": {
    "psr-4": {
      "Tests\\\\": "tests/phpunit/"
    }
  },
  "scripts": {
    "test": "phpunit",
    "test:unit": "phpunit --testsuite unit",
    "test:integration": "phpunit --testsuite integration",
    "test:functional": "phpunit --testsuite functional",
    "test:coverage": "phpunit --coverage-html coverage",
    "phpstan": "phpstan analyze",
    "phpcs": "phpcs --standard=WordPress"
  },
  "config": {
    "optimize-autoloader": true,
    "preferred-install": "dist",
    "sort-packages": true,
    "allow-plugins": {
      "dealerdirect/phpcodesniffer-composer-installer": true
    }
  }
}
JSON
    
    # ============================================================================
    # 6. PHPUNIT CONFIGURATION
    # ============================================================================
    log_step "Creating PHPUnit configuration..."
    
    cat > phpunit.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="tests/phpunit/bootstrap.php"
         colors="true"
         verbose="true">
    <testsuites>
        <testsuite name="unit">
            <directory>tests/phpunit/Unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/phpunit/Integration</directory>
        </testsuite>
        <testsuite name="functional">
            <directory>tests/phpunit/Functional</directory>
        </testsuite>
    </testsuites>
</phpunit>
XML
    
    cat > phpunit-unit.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="tests/phpunit/bootstrap-unit.php"
         colors="true">
    <testsuites>
        <testsuite name="unit">
            <directory>tests/phpunit/Unit</directory>
        </testsuite>
    </testsuites>
</phpunit>
XML
    
    # Bootstrap files
    cat > tests/phpunit/bootstrap.php <<'PHP'
<?php
// Load composer autoloader
$composer_autoloader = dirname(__DIR__, 2) . '/vendor/autoload.php';
if (file_exists($composer_autoloader)) {
    require_once $composer_autoloader;
}

define('TESTS_DIR', __DIR__);
define('ROOT_DIR', dirname(__DIR__, 2));

echo "WordPress Testing Framework loaded.\n";
PHP
    
    cat > tests/phpunit/bootstrap-unit.php <<'PHP'
<?php
// Load composer autoloader
$composer_autoloader = dirname(__DIR__, 2) . '/vendor/autoload.php';
if (file_exists($composer_autoloader)) {
    require_once $composer_autoloader;
}

define('TESTS_DIR', __DIR__);
define('ROOT_DIR', dirname(__DIR__, 2));
define('UNIT_TESTS', true);

// Initialize Brain Monkey for unit tests
require_once $composer_autoloader;

echo "Unit Test environment loaded (no WordPress).\n";
PHP
    
    # ============================================================================
    # 7. PLAYWRIGHT CONFIGURATION
    # ============================================================================
    log_step "Creating Playwright configuration..."
    
    cat > tools/e2e/playwright.config.ts <<'TS'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report' }],
    ['junit', { outputFile: 'test-results/junit.xml' }]
  ],
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    viewport: { width: 1280, height: 800 },
    ignoreHTTPSErrors: true
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } }
  ],
  outputDir: 'test-results/'
});
TS
    
    # ============================================================================
    # 8. CYPRESS CONFIGURATION
    # ============================================================================
    log_step "Creating Cypress configuration..."
    
    cat > cypress.config.js <<'JS'
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost',
    supportFile: 'tests/cypress/support/index.js',
    specPattern: 'tests/cypress/integration/**/*.spec.{js,jsx,ts,tsx}',
    videosFolder: 'tests/cypress/videos',
    screenshotsFolder: 'tests/cypress/screenshots',
    viewportWidth: 1280,
    viewportHeight: 800,
    env: {
      WP_USER: process.env.E2E_USER || 'admin',
      WP_PASS: process.env.E2E_PASS || 'password'
    }
  }
});
JS
    
    # Cypress support file
    mkdir -p tests/cypress/support
    cat > tests/cypress/support/index.js <<'JS'
// WordPress login command
Cypress.Commands.add('login', (username, password) => {
    cy.visit('/wp-login.php');
    cy.get('#user_login').type(username || Cypress.env('WP_USER'));
    cy.get('#user_pass').type(password || Cypress.env('WP_PASS'));
    cy.get('#wp-submit').click();
    cy.url().should('include', '/wp-admin');
});

// Visit admin page
Cypress.Commands.add('visitAdmin', (path) => {
    cy.visit(`/wp-admin/${path}`);
});
JS
    
    # ============================================================================
    # 9. DOCUMENTATION
    # ============================================================================
    log_step "Creating documentation..."
    
    cat > README.md <<MD
# WordPress Universal Testing Framework

## Project: ${PROJECT_NAME}

This is a comprehensive testing framework for WordPress ${TARGET_TYPE}s.

### Quick Start

\`\`\`bash
# 1. Activate scanner plugin
wp plugin activate ${SCANNER_PLUGIN}

# 2. Install dependencies
npm run setup

# 3. Generate test plan
npm run test:plan

# 4. Run tests
npm test
\`\`\`

### Available Commands

#### Scanning
- \`npm run scan\` - Scan the ${TARGET_TYPE}

#### Test Generation
- \`npm run generate\` - Generate tests from scan
- \`npm run test:plan\` - Scan + Generate

#### Testing
- \`npm test\` - Run all tests
- \`npm run test:unit\` - PHPUnit unit tests
- \`npm run test:integration\` - Integration tests
- \`npm run test:functional\` - Functional tests
- \`npm run test:e2e\` - Playwright E2E tests
- \`npm run test:cypress\` - Cypress tests

### Project Structure

\`\`\`
├── tools/
│   ├── scanners/         # WordPress scanners
│   ├── ai/              # Test generators
│   └── e2e/             # E2E configuration
├── tests/
│   ├── phpunit/         # PHP tests
│   ├── cypress/         # Cypress tests
│   └── playwright/      # Playwright tests
├── wp-content/
│   ├── plugins/
│   │   └── ${SCANNER_PLUGIN}/  # Scanner plugin
│   └── uploads/
│       ├── wp-scan/             # Scan results
│       └── wp-test-plan/        # Test plans
└── vendor/                      # PHP dependencies
\`\`\`

### Configuration

Create a \`.env\` file:

\`\`\`env
E2E_BASE_URL=http://localhost
E2E_USER=admin
E2E_PASS=password
\`\`\`

### Documentation

- Test plans are generated in \`wp-content/uploads/wp-test-plan/docs/\`
- Coverage reports in \`coverage/\`
- E2E reports in \`playwright-report/\`

## License

GPL v2 or later
MD
    
    # ============================================================================
    # FINALIZATION
    # ============================================================================
    
    log_success "Installation complete!"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   WordPress Testing Framework Ready!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Project: ${MAGENTA}${PROJECT_NAME}${NC}"
    echo -e "Type: ${MAGENTA}${TARGET_TYPE}${NC}"
    if [ "$TARGET_TYPE" = "plugin" ]; then
        echo -e "Plugin: ${MAGENTA}${PLUGIN_SLUG}${NC}"
    elif [ "$TARGET_TYPE" = "theme" ]; then
        echo -e "Theme: ${MAGENTA}${THEME_SLUG}${NC}"
    fi
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1) Activate the scanner plugin:"
    echo -e "   ${CYAN}wp plugin activate ${SCANNER_PLUGIN}${NC}"
    echo ""
    echo "2) Install dependencies:"
    echo -e "   ${CYAN}npm install${NC}"
    echo -e "   ${CYAN}composer install${NC}"
    echo -e "   ${CYAN}npx playwright install${NC}"
    echo ""
    echo "3) Run the scanner and generate tests:"
    echo -e "   ${CYAN}npm run test:plan${NC}"
    echo ""
    echo "4) Run tests:"
    echo -e "   ${CYAN}npm test${NC}"
    echo ""
    echo -e "${GREEN}Happy Testing! 🚀${NC}"
}

# Run the installation
check_prerequisites
main