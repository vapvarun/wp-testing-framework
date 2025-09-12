#!/bin/bash

# ============================================
# WordPress Plugin Check Setup Tool
# Version: 1.0.0
# Purpose: Setup and configure Plugin Check as a data source
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       WordPress Plugin Check Setup Tool                ║${NC}"
echo -e "${BLUE}║   Configure Plugin Check as Testing Data Source        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Find WordPress root
WP_PATH="${WP_PATH:-$(pwd)}"
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    print_error "WordPress not found at $WP_PATH"
    exit 1
fi

PLUGIN_CHECK_PATH="$WP_PATH/wp-content/plugins/plugin-check"

# Step 1: Install Plugin Check
print_info "Step 1: Installing WordPress Plugin Check..."

if [ ! -d "$PLUGIN_CHECK_PATH" ]; then
    wp plugin install plugin-check --path="$WP_PATH" || {
        print_error "Failed to install Plugin Check"
        exit 1
    }
    print_success "Plugin Check installed"
else
    print_success "Plugin Check already installed"
fi

# Step 2: Install Composer dependencies
print_info "Step 2: Installing Composer dependencies..."

if [ -f "$PLUGIN_CHECK_PATH/composer.json" ]; then
    cd "$PLUGIN_CHECK_PATH"
    
    if command -v composer >/dev/null 2>&1; then
        echo "Running: composer install"
        composer install --no-dev --optimize-autoloader || {
            print_warning "Standard install failed. Trying with --ignore-platform-reqs..."
            composer install --no-dev --optimize-autoloader --ignore-platform-reqs || {
                print_error "Composer install failed"
            }
        }
        print_success "Composer dependencies installed"
    else
        print_warning "Composer not found. Installing Composer locally..."
        
        # Install Composer locally
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php
        php -r "unlink('composer-setup.php');"
        
        if [ -f "composer.phar" ]; then
            php composer.phar install --no-dev --optimize-autoloader
            print_success "Composer dependencies installed with local Composer"
        else
            print_error "Failed to install Composer"
        fi
    fi
    
    cd - > /dev/null
else
    print_info "No composer.json found in Plugin Check"
fi

# Step 3: Install npm dependencies
print_info "Step 3: Installing npm dependencies..."

if [ -f "$PLUGIN_CHECK_PATH/package.json" ]; then
    cd "$PLUGIN_CHECK_PATH"
    
    if command -v npm >/dev/null 2>&1; then
        echo "Running: npm install"
        npm install || {
            print_warning "Standard install failed. Trying with --force..."
            npm install --force || {
                print_error "npm install failed"
            }
        }
        
        # Build assets if build script exists
        if grep -q '"build"' package.json; then
            print_info "Building Plugin Check assets..."
            npm run build || print_warning "Build failed, but continuing..."
        fi
        
        print_success "npm dependencies installed"
    else
        print_warning "npm not found. Some features may be limited."
        print_info "To install Node.js/npm, visit: https://nodejs.org/"
    fi
    
    cd - > /dev/null
else
    print_info "No package.json found in Plugin Check"
fi

# Step 4: Activate Plugin Check
print_info "Step 4: Activating Plugin Check..."

if ! wp plugin is-active plugin-check --path="$WP_PATH" 2>/dev/null; then
    wp plugin activate plugin-check --path="$WP_PATH"
    print_success "Plugin Check activated"
else
    print_success "Plugin Check already active"
fi

# Step 5: Verify installation
print_info "Step 5: Verifying Plugin Check installation..."

if wp plugin check --help --path="$WP_PATH" >/dev/null 2>&1; then
    print_success "Plugin Check CLI is working!"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 Plugin Check Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "You can now use Plugin Check as a data source:"
    echo ""
    echo "1. Run checks on any plugin:"
    echo "   wp plugin check <plugin-name>"
    echo ""
    echo "2. Export results in different formats:"
    echo "   wp plugin check <plugin-name> --format=json"
    echo "   wp plugin check <plugin-name> --format=csv"
    echo ""
    echo "3. Run specific checks:"
    echo "   wp plugin check <plugin-name> --checks=late_escaping,i18n_usage"
    echo ""
    echo "4. Include experimental checks:"
    echo "   wp plugin check <plugin-name> --include-experimental"
    echo ""
else
    print_error "Plugin Check CLI verification failed"
    echo "Please check the installation manually"
    exit 1
fi

# Create integration helper script
HELPER_SCRIPT="$WP_PATH/wp-content/plugins/plugin-check-helper.php"

cat > "$HELPER_SCRIPT" << 'EOF'
<?php
/**
 * Plugin Check Integration Helper
 * 
 * This helper provides programmatic access to Plugin Check results
 */

if (!defined('ABSPATH')) {
    die('Direct access not allowed');
}

class Plugin_Check_Helper {
    
    /**
     * Run Plugin Check and get results as array
     */
    public static function run_check($plugin_slug, $options = []) {
        if (!class_exists('Plugin_Check')) {
            return ['error' => 'Plugin Check not found'];
        }
        
        $defaults = [
            'format' => 'json',
            'checks' => [],
            'exclude_checks' => [],
            'include_experimental' => false
        ];
        
        $options = wp_parse_args($options, $defaults);
        
        // Build command
        $command = sprintf('wp plugin check %s --format=%s', 
            escapeshellarg($plugin_slug),
            escapeshellarg($options['format'])
        );
        
        if (!empty($options['checks'])) {
            $command .= ' --checks=' . escapeshellarg(implode(',', $options['checks']));
        }
        
        if ($options['include_experimental']) {
            $command .= ' --include-experimental';
        }
        
        // Execute command
        $output = shell_exec($command . ' 2>&1');
        
        if ($options['format'] === 'json') {
            return json_decode($output, true);
        }
        
        return $output;
    }
    
    /**
     * Get Plugin Check insights
     */
    public static function get_insights($plugin_slug) {
        $results = self::run_check($plugin_slug, ['format' => 'json']);
        
        if (isset($results['error'])) {
            return $results;
        }
        
        $insights = [
            'total_checks' => 0,
            'errors' => 0,
            'warnings' => 0,
            'categories' => [],
            'critical_issues' => [],
            'recommendations' => []
        ];
        
        if (is_array($results)) {
            foreach ($results as $result) {
                $insights['total_checks']++;
                
                if ($result['type'] === 'ERROR') {
                    $insights['errors']++;
                    $insights['critical_issues'][] = [
                        'code' => $result['code'],
                        'message' => $result['message'],
                        'file' => $result['file'] ?? '',
                        'line' => $result['line'] ?? 0
                    ];
                } elseif ($result['type'] === 'WARNING') {
                    $insights['warnings']++;
                }
                
                if (!empty($result['category'])) {
                    $insights['categories'][$result['category']] = 
                        ($insights['categories'][$result['category']] ?? 0) + 1;
                }
            }
        }
        
        // Generate recommendations
        if ($insights['errors'] > 0) {
            $insights['recommendations'][] = 'Fix all ERROR-level issues before plugin submission';
        }
        
        if ($insights['warnings'] > 10) {
            $insights['recommendations'][] = 'Review and address WARNING-level issues to improve code quality';
        }
        
        return $insights;
    }
}

// Register WP-CLI command if available
if (defined('WP_CLI') && WP_CLI) {
    WP_CLI::add_command('plugin-check-insights', function($args) {
        if (empty($args[0])) {
            WP_CLI::error('Plugin slug required');
        }
        
        $insights = Plugin_Check_Helper::get_insights($args[0]);
        
        if (isset($insights['error'])) {
            WP_CLI::error($insights['error']);
        }
        
        WP_CLI::success('Plugin Check Insights:');
        WP_CLI::log('Errors: ' . $insights['errors']);
        WP_CLI::log('Warnings: ' . $insights['warnings']);
        WP_CLI::log('Categories: ' . implode(', ', array_keys($insights['categories'])));
        
        if (!empty($insights['recommendations'])) {
            WP_CLI::log("\nRecommendations:");
            foreach ($insights['recommendations'] as $rec) {
                WP_CLI::log('- ' . $rec);
            }
        }
    });
}
EOF

print_success "Created helper script at: $HELPER_SCRIPT"

echo ""
echo -e "${BLUE}📚 Additional Resources:${NC}"
echo "- Plugin Check Documentation: https://wordpress.org/plugins/plugin-check/"
echo "- WordPress Coding Standards: https://developer.wordpress.org/coding-standards/"
echo "- Plugin Review Guidelines: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/"
echo ""