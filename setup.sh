#!/bin/bash

# ============================================
# WP Testing Framework - General WordPress Setup
# Version: 5.0.0
# Purpose: Setup for ANY WordPress installation (standard hosting, Docker, etc.)
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   WP Testing Framework - General WordPress Setup       ║${NC}"
echo -e "${BLUE}║   For: Standard hosting, Docker, XAMPP, MAMP, etc.     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Local WP and suggest appropriate script
check_environment() {
    if [[ "$PWD" == *"/Local Sites/"* ]] || [[ -d "/Applications/Local.app" && "$PWD" == *"/app/public"* ]]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  Local WP Detected!${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "You appear to be using Local WP. For optimized setup, use:"
        echo -e "${GREEN}./local-wp-setup.sh${NC}"
        echo ""
        read -p "Continue with general setup anyway? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Switching to Local WP setup..."
            exec ./local-wp-setup.sh
        fi
    fi
}

# Function to find WordPress root
find_wp_root() {
    echo -e "${BLUE}🔍 Finding WordPress root...${NC}"
    
    # Check current directory
    if [ -f "wp-config.php" ] || [ -f "wp-config-sample.php" ]; then
        WP_ROOT="$PWD"
    # Check parent directory
    elif [ -f "../wp-config.php" ]; then
        WP_ROOT="$(dirname "$PWD")"
    # Check if we're in wp-content
    elif [[ "$PWD" == */wp-content* ]]; then
        WP_ROOT="$(echo "$PWD" | sed 's/\/wp-content.*//')"
    else
        echo -e "${RED}❌ WordPress installation not found!${NC}"
        echo "Please run this script from your WordPress root directory."
        exit 1
    fi
    
    echo -e "${GREEN}✅ WordPress root: $WP_ROOT${NC}"
}

# Function to detect WordPress environment type
detect_wp_environment() {
    echo -e "${BLUE}🔍 Detecting WordPress environment...${NC}"
    
    # Check for Docker
    if [ -f "docker-compose.yml" ] || [ -f "Dockerfile" ]; then
        ENV_TYPE="Docker"
        echo -e "${GREEN}✅ Docker environment detected${NC}"
    # Check for XAMPP
    elif [[ "$PWD" == */xampp/* ]] || [[ "$PWD" == */htdocs/* ]]; then
        ENV_TYPE="XAMPP"
        echo -e "${GREEN}✅ XAMPP environment detected${NC}"
    # Check for MAMP
    elif [[ "$PWD" == */MAMP/* ]] || [[ "$PWD" == */mamp/* ]]; then
        ENV_TYPE="MAMP"
        echo -e "${GREEN}✅ MAMP environment detected${NC}"
    # Check for standard hosting
    elif [[ "$PWD" == */public_html/* ]] || [[ "$PWD" == */www/* ]]; then
        ENV_TYPE="Standard Hosting"
        echo -e "${GREEN}✅ Standard hosting environment detected${NC}"
    else
        ENV_TYPE="Unknown"
        echo -e "${YELLOW}⚠️  Environment type unknown - using defaults${NC}"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo ""
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    local missing=0
    
    # Check PHP
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r "echo PHP_VERSION;")
        echo -e "${GREEN}✅ PHP $PHP_VERSION${NC}"
    else
        echo -e "${RED}❌ PHP not found${NC}"
        missing=$((missing + 1))
    fi
    
    # Check MySQL/MariaDB
    if command -v mysql >/dev/null 2>&1; then
        echo -e "${GREEN}✅ MySQL/MariaDB available${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL client not found (may still work)${NC}"
    fi
    
    # Check WP-CLI
    if command -v wp >/dev/null 2>&1; then
        WP_CLI_VERSION=$(wp --version | cut -d' ' -f2)
        echo -e "${GREEN}✅ WP-CLI $WP_CLI_VERSION${NC}"
        HAS_WP_CLI=true
    else
        echo -e "${YELLOW}⚠️  WP-CLI not found (optional but recommended)${NC}"
        HAS_WP_CLI=false
    fi
    
    # Check Composer
    if command -v composer >/dev/null 2>&1; then
        COMPOSER_VERSION=$(composer --version | cut -d' ' -f3)
        echo -e "${GREEN}✅ Composer $COMPOSER_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Composer not found (optional)${NC}"
    fi
    
    # Check Git
    if command -v git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        echo -e "${GREEN}✅ Git $GIT_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Git not found (optional)${NC}"
    fi
    
    if [ $missing -gt 0 ]; then
        echo ""
        echo -e "${RED}Missing required components. Please install them first.${NC}"
        exit 1
    fi
}

# Function to setup framework directories
setup_directories() {
    echo ""
    echo -e "${BLUE}📁 Setting up framework directories...${NC}"
    
    # Create necessary directories
    mkdir -p plugins
    mkdir -p tools
    mkdir -p templates/default
    mkdir -p backup/deprecated-scripts
    
    # Create uploads directories if they don't exist
    if [ -d "../wp-content" ]; then
        mkdir -p ../wp-content/uploads/wbcom-scan
        mkdir -p ../wp-content/uploads/wbcom-plan
        echo -e "${GREEN}✅ Upload directories created${NC}"
    fi
    
    echo -e "${GREEN}✅ Directory structure ready${NC}"
}

# Function to install PHP dependencies
install_php_dependencies() {
    echo ""
    echo -e "${BLUE}📦 Installing PHP dependencies...${NC}"
    
    if command -v composer >/dev/null 2>&1; then
        # Create composer.json if it doesn't exist
        if [ ! -f "composer.json" ]; then
            cat > composer.json << 'EOF'
{
    "name": "wp-testing/framework",
    "description": "WordPress Plugin Testing Framework",
    "type": "project",
    "require-dev": {
        "phpstan/phpstan": "^1.0",
        "squizlabs/php_codesniffer": "^3.7",
        "wp-coding-standards/wpcs": "^3.0",
        "phpmd/phpmd": "^2.13",
        "sebastian/phpcpd": "^6.0",
        "phploc/phploc": "^7.0"
    },
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true
        }
    }
}
EOF
            echo -e "${GREEN}✅ composer.json created${NC}"
        fi
        
        # Install dependencies
        composer install --no-interaction --quiet
        
        # Configure PHPCS with WordPress standards
        if [ -f "vendor/bin/phpcs" ]; then
            ./vendor/bin/phpcs --config-set installed_paths vendor/wp-coding-standards/wpcs 2>/dev/null || true
            echo -e "${GREEN}✅ PHP tools installed and configured${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Composer not available - skipping PHP tools${NC}"
    fi
}

# Function to configure for specific environments
configure_environment() {
    echo ""
    echo -e "${BLUE}⚙️  Configuring for $ENV_TYPE environment...${NC}"
    
    case "$ENV_TYPE" in
        "Docker")
            echo "Docker-specific configuration:"
            echo "- Database host: Usually 'db' or 'mysql' (check docker-compose.yml)"
            echo "- Use container names for service connections"
            ;;
        "XAMPP")
            echo "XAMPP-specific configuration:"
            echo "- Database host: localhost"
            echo "- Default MySQL port: 3306"
            echo "- phpMyAdmin: http://localhost/phpmyadmin"
            ;;
        "MAMP")
            echo "MAMP-specific configuration:"
            echo "- Database host: localhost"
            echo "- Default MySQL port: 8889 (MAMP) or 3306 (MAMP PRO)"
            echo "- phpMyAdmin: http://localhost:8888/phpMyAdmin"
            ;;
        "Standard Hosting")
            echo "Standard hosting configuration:"
            echo "- Check hosting provider for database details"
            echo "- May need to use specific PHP version selector"
            ;;
        *)
            echo "Using default configuration"
            ;;
    esac
}

# Function to test plugin functionality
test_framework() {
    echo ""
    echo -e "${BLUE}🧪 Testing framework setup...${NC}"
    
    # Check if test script exists
    if [ -f "test-plugin.sh" ]; then
        chmod +x test-plugin.sh
        echo -e "${GREEN}✅ test-plugin.sh is executable${NC}"
        
        # List available plugins
        if [ -d "../wp-content/plugins" ]; then
            echo ""
            echo "Available plugins to test:"
            ls -1 ../wp-content/plugins | head -5
            echo ""
            echo "To test a plugin, run:"
            echo -e "${GREEN}./test-plugin.sh plugin-name${NC}"
        fi
    else
        echo -e "${RED}❌ test-plugin.sh not found${NC}"
    fi
}

# Function to create environment config file
create_config_file() {
    echo ""
    echo -e "${BLUE}📝 Creating environment configuration...${NC}"
    
    cat > .env.testing << EOF
# WP Testing Framework Configuration
# Generated: $(date)
# Environment: $ENV_TYPE

WP_ROOT=$WP_ROOT
ENV_TYPE=$ENV_TYPE
HAS_WP_CLI=$HAS_WP_CLI

# Database Configuration (update as needed)
DB_HOST=localhost
DB_NAME=wordpress
DB_USER=root
DB_PASSWORD=

# Testing Configuration
TEST_TYPE=full
GENERATE_DOCS=true
VALIDATE_QUALITY=true
MIN_QUALITY_SCORE=70
EOF
    
    echo -e "${GREEN}✅ Configuration saved to .env.testing${NC}"
}

# Main execution
main() {
    echo ""
    echo "This script will set up WP Testing Framework for general WordPress installations."
    echo ""
    
    # Check environment
    check_environment
    
    # Find WordPress root
    find_wp_root
    
    # Detect environment type
    detect_wp_environment
    
    # Check prerequisites
    check_prerequisites
    
    # Setup directories
    setup_directories
    
    # Install dependencies
    install_php_dependencies
    
    # Configure for environment
    configure_environment
    
    # Create config file
    create_config_file
    
    # Test framework
    test_framework
    
    # Success message
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ WP Testing Framework Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Environment: $ENV_TYPE"
    echo "WordPress Root: $WP_ROOT"
    echo ""
    echo "Next steps:"
    echo "1. Review .env.testing and update database credentials if needed"
    echo "2. Run: ${GREEN}./test-plugin.sh [plugin-name]${NC} to test a plugin"
    echo "3. Check generated documentation in plugins/[plugin-name]/"
    echo ""
    echo "For help: ${GREEN}./test-plugin.sh --help${NC}"
}

# Run main function
main