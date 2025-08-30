#!/bin/bash

# WP Testing Framework - Universal Setup Script
# Version: 4.0.0
# Repository: https://github.com/vapvarun/wp-testing-framework/
# Purpose: Smart setup that auto-detects environment (Local WP or standard)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Header
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    WP Testing Framework - Smart Setup      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Detect environment
detect_environment() {
    if [[ "$PWD" == *"/Local Sites/"* ]] || [[ "$PWD" == *"/app/public"* ]]; then
        echo -e "${GREEN}✅ Local WP environment detected${NC}"
        echo -e "${BLUE}Running optimized Local WP setup...${NC}"
        ./local-wp-setup.sh
        exit 0
    else
        echo -e "${YELLOW}⚠️  Standard WordPress environment detected${NC}"
        echo -e "${BLUE}Running standard setup...${NC}"
    fi
}

# Standard setup
standard_setup() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    # Check for composer
    if [ -f "composer.json" ] && command -v composer >/dev/null 2>&1; then
        composer install --no-interaction
        echo -e "${GREEN}✅ PHP packages installed${NC}"
    fi
    
    # Check for npm
    if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
        npm ci || npm install
        echo -e "${GREEN}✅ Node packages installed${NC}"
    fi
    
    # Create directories
    echo -e "${BLUE}📁 Creating directory structure...${NC}"
    mkdir -p workspace/{reports,logs,coverage,screenshots}
    mkdir -p plugins
    echo -e "${GREEN}✅ Directories created${NC}"
    
    # Create .env if not exists
    if [ ! -f ".env" ]; then
        cat > .env << 'EOF'
# WordPress Configuration
WP_ROOT_DIR=../
WP_TESTS_DIR=/tmp/wordpress-tests-lib

# Database Configuration
TEST_DB_NAME=wordpress_test
TEST_DB_USER=root
TEST_DB_PASSWORD=
TEST_DB_HOST=localhost

# Site Configuration
WP_TEST_URL=http://localhost
WP_TEST_DOMAIN=localhost
EOF
        echo -e "${GREEN}✅ Created .env file${NC}"
        echo -e "${YELLOW}Please edit .env with your database credentials${NC}"
    fi
    
    # Make scripts executable
    chmod +x test-plugin.sh local-wp-setup.sh 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo -e "${BLUE}Next step: Test a plugin with: ./test-plugin.sh plugin-name${NC}"
}

# Main execution
detect_environment
standard_setup