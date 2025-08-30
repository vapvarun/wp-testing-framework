#!/bin/bash

# WP Testing Framework - Fresh Installation Script
# Version: 3.0.0
# Purpose: Automated setup for new WordPress installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_REPO="https://github.com/vapvarun/wp-testing-framework.git"
FRAMEWORK_DIR="wp-testing-framework"
MIN_PHP_VERSION="8.0"
MIN_NODE_VERSION="16"

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   WP Testing Framework - Fresh Install     ║${NC}"
    echo -e "${BLUE}║          Universal Plugin Testing          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Compare version numbers
version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Check system requirements
check_requirements() {
    echo -e "${BLUE}📋 Checking System Requirements...${NC}"
    echo "=================================="
    
    local all_good=true
    
    # Check PHP
    if command_exists php; then
        PHP_VERSION=$(php -r "echo PHP_VERSION;")
        if version_ge "$PHP_VERSION" "$MIN_PHP_VERSION"; then
            print_success "PHP $PHP_VERSION"
        else
            print_error "PHP $MIN_PHP_VERSION+ required (found $PHP_VERSION)"
            all_good=false
        fi
        
        # Check PHP extensions
        for ext in mbstring xml curl zip dom json tokenizer pdo_mysql; do
            if php -m | grep -q "^$ext$"; then
                print_success "PHP extension: $ext"
            else
                print_error "Missing PHP extension: $ext"
                all_good=false
            fi
        done
    else
        print_error "PHP not found"
        all_good=false
    fi
    
    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node -v | sed 's/v//')
        if version_ge "$NODE_VERSION" "$MIN_NODE_VERSION"; then
            print_success "Node.js $NODE_VERSION"
        else
            print_error "Node.js $MIN_NODE_VERSION+ required (found $NODE_VERSION)"
            all_good=false
        fi
    else
        print_error "Node.js not found"
        all_good=false
    fi
    
    # Check npm
    if command_exists npm; then
        NPM_VERSION=$(npm -v)
        print_success "npm $NPM_VERSION"
    else
        print_error "npm not found"
        all_good=false
    fi
    
    # Check Composer
    if command_exists composer; then
        COMPOSER_VERSION=$(composer --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_success "Composer $COMPOSER_VERSION"
    else
        print_error "Composer not found"
        all_good=false
    fi
    
    # Check WP-CLI
    if command_exists wp; then
        WP_VERSION=$(wp --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        print_success "WP-CLI $WP_VERSION"
    else
        print_warning "WP-CLI not found (optional but recommended)"
    fi
    
    # Check Git
    if command_exists git; then
        GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        print_success "Git $GIT_VERSION"
    else
        print_warning "Git not found (using download method)"
    fi
    
    # Check MySQL
    if command_exists mysql; then
        print_success "MySQL client found"
    else
        print_warning "MySQL client not found (needed for database setup)"
    fi
    
    echo ""
    if [ "$all_good" = false ]; then
        print_error "Some requirements are missing. Please install them first."
        exit 1
    else
        print_success "All requirements met!"
    fi
}

# Download or clone framework
install_framework() {
    echo ""
    echo -e "${BLUE}📦 Installing Framework...${NC}"
    echo "========================="
    
    if [ -d "$FRAMEWORK_DIR" ]; then
        print_warning "Framework directory already exists"
        read -p "Remove existing directory and reinstall? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$FRAMEWORK_DIR"
        else
            cd "$FRAMEWORK_DIR"
            print_info "Using existing framework directory"
            return
        fi
    fi
    
    if command_exists git; then
        print_info "Cloning framework repository..."
        git clone "$FRAMEWORK_REPO" "$FRAMEWORK_DIR"
    else
        print_info "Downloading framework..."
        curl -L -o framework.zip "$FRAMEWORK_REPO/archive/main.zip"
        unzip -q framework.zip
        mv wp-testing-framework-main "$FRAMEWORK_DIR"
        rm framework.zip
    fi
    
    cd "$FRAMEWORK_DIR"
    print_success "Framework installed"
}

# Install dependencies
install_dependencies() {
    echo ""
    echo -e "${BLUE}📚 Installing Dependencies...${NC}"
    echo "============================"
    
    # PHP dependencies
    print_info "Installing PHP packages..."
    if [ -f "composer.json" ]; then
        COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist
        print_success "PHP packages installed"
    else
        print_warning "composer.json not found"
    fi
    
    # Node dependencies
    print_info "Installing Node packages..."
    if [ -f "package.json" ]; then
        npm ci || npm install
        print_success "Node packages installed"
    else
        print_warning "package.json not found"
    fi
    
    # Playwright browsers
    if command_exists npx; then
        print_info "Installing Playwright browsers..."
        npx playwright install
        print_success "Playwright browsers installed"
    fi
}

# Setup environment configuration
setup_environment() {
    echo ""
    echo -e "${BLUE}⚙️  Setting Up Environment...${NC}"
    echo "==========================="
    
    # Create .env file
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env file from template"
        else
            # Create basic .env
            cat > .env << 'EOF'
# WordPress Configuration
WP_ROOT_DIR=../
WP_TESTS_DIR=/tmp/wordpress-tests-lib
WP_CORE_DIR=../

# Database Configuration
TEST_DB_NAME=wordpress_test
TEST_DB_USER=root
TEST_DB_PASSWORD=
TEST_DB_HOST=localhost

# Site Configuration
WP_TEST_URL=http://localhost
WP_TEST_DOMAIN=localhost
WP_TEST_EMAIL=admin@example.com

# Testing Configuration
SKIP_DB_CREATE=false
TEST_SUITE=all
EOF
            print_success "Created default .env file"
        fi
        print_info "Please edit .env file with your configuration"
    else
        print_info ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p workspace/{reports,logs,coverage,screenshots}
    mkdir -p plugins
    mkdir -p templates
    
    print_success "Directory structure created"
}

# Setup test database
setup_database() {
    echo ""
    echo -e "${BLUE}🗄️  Database Setup...${NC}"
    echo "==================="
    
    if ! command_exists mysql; then
        print_warning "MySQL client not found, skipping database setup"
        print_info "Please create 'wordpress_test' database manually"
        return
    fi
    
    read -p "Setup test database? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping database setup"
        return
    fi
    
    read -p "MySQL username (root): " MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-root}
    
    read -s -p "MySQL password: " MYSQL_PASS
    echo
    
    print_info "Creating test database..."
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" << EOF 2>/dev/null || true
CREATE DATABASE IF NOT EXISTS wordpress_test;
GRANT ALL PRIVILEGES ON wordpress_test.* TO 'wp_test'@'localhost' IDENTIFIED BY 'wp_test';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Test database created"
    else
        print_warning "Could not create database automatically"
    fi
}

# Install WordPress test suite
install_wp_tests() {
    echo ""
    echo -e "${BLUE}🧪 Installing WordPress Test Suite...${NC}"
    echo "===================================="
    
    if [ -f "bin/install-wp-tests.sh" ]; then
        print_info "Running WordPress test installer..."
        bash bin/install-wp-tests.sh wordpress_test root '' localhost latest
        print_success "WordPress test suite installed"
    else
        print_warning "Test installer script not found"
    fi
}

# Run initial setup
run_setup() {
    echo ""
    echo -e "${BLUE}🔧 Running Setup Script...${NC}"
    echo "========================"
    
    if [ -f "setup.sh" ]; then
        chmod +x setup.sh
        ./setup.sh
        print_success "Setup script completed"
    else
        print_warning "setup.sh not found"
    fi
}

# Create quick start script
create_quickstart() {
    cat > quickstart.sh << 'EOF'
#!/bin/bash
# Quick start script for testing plugins

PLUGIN_NAME=$1

if [ -z "$PLUGIN_NAME" ]; then
    echo "Usage: ./quickstart.sh <plugin-name>"
    exit 1
fi

echo "🚀 Testing $PLUGIN_NAME..."

# Create plugin structure
mkdir -p plugins/$PLUGIN_NAME/{data,tests,scanners,models,analysis}

# Run universal test
npm run universal:$PLUGIN_NAME

echo "✅ Testing complete! Check workspace/reports/$PLUGIN_NAME/"
EOF
    
    chmod +x quickstart.sh
    print_success "Created quickstart.sh helper"
}

# Verify installation
verify_installation() {
    echo ""
    echo -e "${BLUE}✨ Verifying Installation...${NC}"
    echo "=========================="
    
    local all_good=true
    
    # Check PHP tools
    if [ -f "vendor/bin/phpunit" ]; then
        print_success "PHPUnit installed"
    else
        print_error "PHPUnit not found"
        all_good=false
    fi
    
    # Check Node modules
    if [ -d "node_modules" ]; then
        print_success "Node modules installed"
    else
        print_error "Node modules not found"
        all_good=false
    fi
    
    # Check directories
    if [ -d "workspace" ] && [ -d "plugins" ]; then
        print_success "Directory structure ready"
    else
        print_error "Directory structure incomplete"
        all_good=false
    fi
    
    # Check configuration
    if [ -f ".env" ]; then
        print_success "Environment configured"
    else
        print_error "Environment not configured"
        all_good=false
    fi
    
    echo ""
    if [ "$all_good" = true ]; then
        print_success "Installation verified successfully!"
    else
        print_warning "Some components need attention"
    fi
}

# Display next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo "======================="
    echo ""
    echo -e "${BLUE}📝 Next Steps:${NC}"
    echo "1. Edit .env file with your configuration"
    echo "2. Test a plugin: npm run universal:<plugin-name>"
    echo "3. Or use: ./quickstart.sh <plugin-name>"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "- Setup Guide: FRESH-INSTALL-SETUP.md"
    echo "- Requirements: REQUIREMENTS.md"
    echo "- Plugin Testing: HOW-TO-TEST-ANY-PLUGIN.md"
    echo ""
    echo -e "${BLUE}🔧 Common Commands:${NC}"
    echo "- Test all: npm run universal:<plugin>"
    echo "- Unit tests: npm run test:unit"
    echo "- Reports: npm run report:<plugin>"
    echo "- Clean: npm run clean:all"
    echo ""
}

# Main installation flow
main() {
    clear
    print_header
    
    # Run installation steps
    check_requirements
    install_framework
    install_dependencies
    setup_environment
    setup_database
    install_wp_tests
    run_setup
    create_quickstart
    verify_installation
    show_next_steps
}

# Handle errors
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"