#!/bin/bash

# ============================================
# WP Testing Framework - Local WP Specific Setup
# Version: 6.0.0
# Purpose: Optimized setup ONLY for Local by Flywheel/WP Engine
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Header
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     WP Testing Framework - Local WP Setup              ║${NC}"
echo -e "${MAGENTA}║     Optimized for Local by Flywheel/WP Engine          ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect Local WP Installation
detect_local_wp() {
    echo -e "${BLUE}🔍 Detecting Local WP environment...${NC}"
    
    # Check for Local WP indicators
    local is_local_wp=false
    local local_path=""
    
    # Check if we're in Local Sites directory structure
    if [[ "$PWD" == *"/Local Sites/"* ]]; then
        is_local_wp=true
        SITE_NAME=$(echo "$PWD" | sed -n 's/.*\/Local Sites\/\([^\/]*\).*/\1/p')
        local_path="$PWD"
    # Check for app/public structure
    elif [[ "$PWD" == */app/public* ]]; then
        is_local_wp=true
        # Extract site name from path
        if [[ "$PWD" == *"/Local Sites/"* ]]; then
            SITE_NAME=$(echo "$PWD" | sed -n 's/.*\/Local Sites\/\([^\/]*\).*/\1/p')
        else
            SITE_NAME="local-site"
        fi
        local_path="$PWD"
    fi
    
    if [ "$is_local_wp" = false ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  Local WP environment not detected!${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "This script is specifically for Local WP. Your current path:"
        echo "$PWD"
        echo ""
        echo "For general WordPress installations, use:"
        echo -e "${GREEN}./setup.sh${NC}"
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Local WP environment confirmed${NC}"
        echo -e "${GREEN}   Site: $SITE_NAME${NC}"
        echo -e "${GREEN}   Path: $local_path${NC}"
    fi
}

# Get Local WP site configuration
get_local_config() {
    echo ""
    echo -e "${BLUE}📋 Reading Local WP configuration...${NC}"
    
    # Common Local WP settings
    LOCAL_DOMAIN="${SITE_NAME}.local"
    WP_URL="http://${LOCAL_DOMAIN}"
    WP_PATH="$PWD"
    
    # Detect OS for path differences
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        LOCAL_APP_PATH="/Applications/Local.app"
        LOCAL_RUN_PATH="$HOME/Library/Application Support/Local/run"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows (Git Bash/WSL)
        LOCAL_APP_PATH="/c/Program Files/Local"
        LOCAL_RUN_PATH="$LOCALAPPDATA/Local/run"
    else
        # Linux
        LOCAL_APP_PATH="$HOME/.local/share/Local"
        LOCAL_RUN_PATH="$HOME/.config/Local/run"
    fi
    
    # Try to find MySQL socket
    if [ -d "$LOCAL_RUN_PATH" ]; then
        MYSQL_SOCKET=$(find "$LOCAL_RUN_PATH" -name "mysqld.sock" 2>/dev/null | head -1)
        if [ -n "$MYSQL_SOCKET" ]; then
            echo -e "${GREEN}✅ MySQL socket: $MYSQL_SOCKET${NC}"
        fi
    fi
    
    # Local WP database defaults
    DB_HOST="localhost"
    DB_NAME="local"
    DB_USER="root"
    DB_PASSWORD="root"
    
    echo -e "${GREEN}✅ Configuration detected:${NC}"
    echo "   URL: $WP_URL"
    echo "   Database: $DB_NAME"
    echo "   User: $DB_USER"
}

# Check Local WP services
check_local_services() {
    echo ""
    echo -e "${BLUE}🔧 Checking Local WP services...${NC}"
    
    # Check if Local is running (by checking for nginx/apache process)
    if pgrep -f "nginx.*${SITE_NAME}" > /dev/null || pgrep -f "apache.*${SITE_NAME}" > /dev/null; then
        echo -e "${GREEN}✅ Local WP site is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Local WP site might not be running${NC}"
        echo "   Please ensure your site is started in Local WP"
    fi
    
    # Check PHP version
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r "echo PHP_VERSION;")
        echo -e "${GREEN}✅ PHP $PHP_VERSION${NC}"
    fi
    
    # Check WP-CLI (Local includes it)
    if command -v wp >/dev/null 2>&1; then
        WP_VERSION=$(wp core version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ WordPress $WP_VERSION${NC}"
        echo -e "${GREEN}✅ WP-CLI available${NC}"
    else
        echo -e "${YELLOW}⚠️  WP-CLI not found in PATH${NC}"
        echo "   Local WP includes WP-CLI - you may need to use it from Local's shell"
    fi
}

# Setup framework for Local WP
setup_local_framework() {
    echo ""
    echo -e "${BLUE}📁 Setting up framework directories...${NC}"
    
    # Create framework directories
    mkdir -p plugins
    mkdir -p tools
    mkdir -p templates/default
    mkdir -p backup/deprecated-scripts
    
    # Create Local WP specific directories
    mkdir -p ../wp-content/uploads/wbcom-scan
    mkdir -p ../wp-content/uploads/wbcom-plan
    
    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Install dependencies optimized for Local WP
install_local_dependencies() {
    echo ""
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    # Check if Composer is available
    if command -v composer >/dev/null 2>&1; then
        # Create composer.json if needed
        if [ ! -f "composer.json" ]; then
            cat > composer.json << 'EOF'
{
    "name": "wp-testing/local-framework",
    "description": "WordPress Plugin Testing Framework for Local WP",
    "type": "project",
    "require-dev": {
        "phpstan/phpstan": "^1.0",
        "squizlabs/php_codesniffer": "^3.7",
        "wp-coding-standards/wpcs": "^3.0",
        "phpmd/phpmd": "^2.13",
        "sebastian/phpcpd": "^6.0",
        "phploc/phploc": "^7.0",
        "phpstan/extension-installer": "^1.1",
        "szepeviktor/phpstan-wordpress": "^1.0"
    },
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true,
            "phpstan/extension-installer": true
        },
        "optimize-autoloader": true,
        "preferred-install": "dist"
    }
}
EOF
            echo -e "${GREEN}✅ composer.json created${NC}"
        fi
        
        # Install with Local WP optimizations
        composer install --no-interaction --prefer-dist --optimize-autoloader 2>/dev/null || \
        composer install --no-interaction 2>/dev/null || \
        echo -e "${YELLOW}⚠️  Some Composer packages failed to install${NC}"
        
        # Configure PHPCS
        if [ -f "vendor/bin/phpcs" ]; then
            ./vendor/bin/phpcs --config-set installed_paths vendor/wp-coding-standards/wpcs 2>/dev/null || true
            echo -e "${GREEN}✅ PHP analysis tools installed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Composer not found${NC}"
        echo "   Install Composer: https://getcomposer.org"
    fi
}

# Create Local WP specific configuration
create_local_config() {
    echo ""
    echo -e "${BLUE}📝 Creating Local WP configuration...${NC}"
    
    cat > .env.local << EOF
# WP Testing Framework - Local WP Configuration
# Generated: $(date)
# Site: $SITE_NAME

# Local WP Settings
SITE_NAME=$SITE_NAME
LOCAL_DOMAIN=$LOCAL_DOMAIN
WP_URL=$WP_URL
WP_PATH=$WP_PATH

# Database (Local WP defaults)
DB_HOST=$DB_HOST
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SOCKET=$MYSQL_SOCKET

# Local WP Paths
LOCAL_APP_PATH=$LOCAL_APP_PATH
LOCAL_RUN_PATH=$LOCAL_RUN_PATH

# Testing Configuration
TEST_TYPE=full
GENERATE_DOCS=true
VALIDATE_QUALITY=true
MIN_QUALITY_SCORE=70

# Local WP Specific
USE_LOCAL_WP_CLI=true
LOCAL_PHP_VERSION=$PHP_VERSION
EOF
    
    echo -e "${GREEN}✅ Configuration saved to .env.local${NC}"
}

# Create Local WP helper scripts
create_helper_scripts() {
    echo ""
    echo -e "${BLUE}📜 Creating Local WP helper scripts...${NC}"
    
    # Create Local WP test runner
    cat > run-local-test.sh << 'EOF'
#!/bin/bash
# Quick test runner for Local WP

PLUGIN=$1
if [ -z "$PLUGIN" ]; then
    echo "Usage: ./run-local-test.sh plugin-name"
    echo ""
    echo "Available plugins:"
    ls -1 ../wp-content/plugins
    exit 1
fi

echo "Testing $PLUGIN..."
./test-plugin.sh "$PLUGIN"

# Open results in browser
if command -v open >/dev/null 2>&1; then
    REPORT=$(find ../wp-content/uploads/wbcom-scan/$PLUGIN -name "*.html" -type f | head -1)
    if [ -n "$REPORT" ]; then
        open "$REPORT"
    fi
fi
EOF
    
    chmod +x run-local-test.sh
    echo -e "${GREEN}✅ Helper script created: run-local-test.sh${NC}"
}

# Test the setup
test_local_setup() {
    echo ""
    echo -e "${BLUE}🧪 Testing Local WP setup...${NC}"
    
    # Make test-plugin.sh executable
    if [ -f "test-plugin.sh" ]; then
        chmod +x test-plugin.sh
        echo -e "${GREEN}✅ test-plugin.sh ready${NC}"
    fi
    
    # List available plugins
    echo ""
    echo "Available plugins to test:"
    if [ -d "../wp-content/plugins" ]; then
        ls -1 ../wp-content/plugins | grep -v "index.php" | head -10
    fi
}

# Local WP specific tips
show_local_tips() {
    echo ""
    echo -e "${BLUE}💡 Local WP Tips:${NC}"
    echo ""
    echo "1. Use Local's built-in terminal for best compatibility"
    echo "2. Site must be running in Local before testing"
    echo "3. Database credentials are usually root/root"
    echo "4. Access phpMyAdmin via Local's Database tab"
    echo "5. View logs in Local's site settings"
    echo ""
    echo "Common Local WP paths:"
    echo "• Site root: ~/Local Sites/${SITE_NAME}/app/public"
    echo "• Logs: ~/Local Sites/${SITE_NAME}/logs"
    echo "• Config: ~/Local Sites/${SITE_NAME}/conf"
}

# Main execution
main() {
    echo ""
    echo "This script optimizes WP Testing Framework specifically for Local WP."
    echo ""
    
    # Detect Local WP
    detect_local_wp
    
    # Get configuration
    get_local_config
    
    # Check services
    check_local_services
    
    # Setup framework
    setup_local_framework
    
    # Install dependencies
    install_local_dependencies
    
    # Create config
    create_local_config
    
    # Create helpers
    create_helper_scripts
    
    # Test setup
    test_local_setup
    
    # Show tips
    show_local_tips
    
    # Success message
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Local WP Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Site: ${SITE_NAME}"
    echo "URL: ${WP_URL}"
    echo ""
    echo "Quick start:"
    echo -e "${GREEN}./run-local-test.sh [plugin-name]${NC} - Test with browser preview"
    echo -e "${GREEN}./test-plugin.sh [plugin-name]${NC} - Standard test"
    echo ""
    echo "For Windows users:"
    echo "Use ${GREEN}local-wp-setup.ps1${NC} for PowerShell setup"
}

# Run main function
main