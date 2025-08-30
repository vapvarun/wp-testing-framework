#!/bin/bash

# WP Testing Framework - Local WP Optimized Setup
# Version: 3.1.0
# Purpose: Streamlined setup for Local WP environments

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Auto-detect Local WP environment
detect_local_wp() {
    echo -e "${BLUE}🔍 Detecting Local WP Environment...${NC}"
    
    # Check if we're in a Local Sites directory
    if [[ "$PWD" == *"/Local Sites/"* ]] || [[ "$PWD" == *"/app/public"* ]]; then
        echo -e "${GREEN}✅ Local WP environment detected${NC}"
        
        # Extract site name and URL
        if [[ "$PWD" == *"/Local Sites/"* ]]; then
            SITE_NAME=$(echo "$PWD" | sed -n 's/.*\/Local Sites\/\([^\/]*\).*/\1/p')
        fi
        
        # Common Local WP URLs
        LOCAL_DOMAIN="${SITE_NAME}.local"
        
        # Set defaults for Local WP
        WP_URL="http://${LOCAL_DOMAIN}"
        WP_PATH="$PWD"
        DB_HOST="localhost"
        DB_SOCKET="/Users/$USER/Library/Application Support/Local/run/*/mysql/mysqld.sock"
        
        echo -e "${GREEN}Site: $SITE_NAME${NC}"
        echo -e "${GREEN}URL: $WP_URL${NC}"
        echo -e "${GREEN}Path: $WP_PATH${NC}"
        
        return 0
    else
        return 1
    fi
}

# Quick setup for Local WP
quick_setup() {
    echo -e "${BLUE}⚡ Quick Setup for Local WP${NC}"
    echo "============================"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing Node packages..."
        npm ci --silent || npm install --silent
    fi
    
    if [ ! -d "vendor" ]; then
        echo "Installing PHP packages..."
        composer install --quiet --no-interaction
    fi
    
    # Create .env with Local WP defaults
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# Local WP Configuration (Auto-detected)
WP_ROOT_DIR=../
WP_TESTS_DIR=/tmp/wordpress-tests-lib
WP_CORE_DIR=../

# Database (Local WP defaults)
TEST_DB_NAME=${SITE_NAME}_test
TEST_DB_USER=root
TEST_DB_PASSWORD=root
TEST_DB_HOST=localhost

# Site Configuration
WP_TEST_URL=${WP_URL}
WP_TEST_DOMAIN=${LOCAL_DOMAIN}
WP_TEST_EMAIL=admin@${LOCAL_DOMAIN}

# Testing
SKIP_DB_CREATE=false
TEST_SUITE=all
EOF
        echo -e "${GREEN}✅ Created .env with Local WP settings${NC}"
    fi
    
    # Create test database using Local WP's MySQL
    echo "Creating test database..."
    wp db create ${SITE_NAME}_test 2>/dev/null || echo "Test database may already exist"
    
    echo -e "${GREEN}✅ Setup complete!${NC}"
}

# Main setup
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    WP Testing Framework - Local WP Setup   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in Local WP
if detect_local_wp; then
    quick_setup
else
    echo -e "${YELLOW}⚠️  Not in Local WP environment${NC}"
    echo "Please run this from your Local WP site's public directory"
    exit 1
fi

# Create directories
mkdir -p workspace/{reports,logs,coverage,screenshots}
mkdir -p plugins

echo ""
echo -e "${GREEN}🎉 Ready to test plugins!${NC}"
echo -e "${BLUE}Usage: npm run test:plugin <plugin-name>${NC}"