#!/bin/bash
#
# WordPress Testing Framework Setup Script
# 
# This script sets up the complete testing framework with all dependencies
# contained within the wp-testing-framework directory for portability.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}     WordPress Universal Testing Framework - Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "composer.json" ]; then
    echo -e "${RED}❌ Error: Must run from wp-testing-framework directory${NC}"
    echo -e "${YELLOW}Please cd to wp-testing-framework directory and run ./setup.sh${NC}"
    exit 1
fi

echo -e "${GREEN}📍 Setting up in: $(pwd)${NC}"
echo ""

# Step 1: Check Node.js
echo -e "${YELLOW}1️⃣  Checking Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✅ Node.js installed: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+ first${NC}"
    exit 1
fi

# Step 2: Check Composer
echo -e "${YELLOW}2️⃣  Checking Composer...${NC}"
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version --no-ansi | head -1)
    echo -e "${GREEN}✅ Composer installed: $COMPOSER_VERSION${NC}"
else
    echo -e "${RED}❌ Composer not found. Please install Composer first${NC}"
    exit 1
fi

# Step 3: Check WP-CLI
echo -e "${YELLOW}3️⃣  Checking WP-CLI...${NC}"
if command -v wp &> /dev/null; then
    WP_VERSION=$(wp --version)
    echo -e "${GREEN}✅ WP-CLI installed: $WP_VERSION${NC}"
else
    echo -e "${RED}❌ WP-CLI not found. Please install WP-CLI first${NC}"
    exit 1
fi

# Step 4: Install npm dependencies
echo ""
echo -e "${YELLOW}4️⃣  Installing npm dependencies...${NC}"
npm install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ npm dependencies installed${NC}"
else
    echo -e "${RED}❌ npm install failed${NC}"
    exit 1
fi

# Step 5: Install Composer dependencies
echo ""
echo -e "${YELLOW}5️⃣  Installing Composer dependencies...${NC}"
composer install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Composer dependencies installed${NC}"
else
    echo -e "${RED}❌ Composer install failed${NC}"
    exit 1
fi

# Step 6: Install Playwright browsers
echo ""
echo -e "${YELLOW}6️⃣  Installing Playwright browsers...${NC}"
npx playwright install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Playwright browsers installed${NC}"
else
    echo -e "${RED}❌ Playwright install failed${NC}"
    exit 1
fi

# Step 7: Create necessary directories
echo ""
echo -e "${YELLOW}7️⃣  Creating directory structure...${NC}"
mkdir -p tests/generated
mkdir -p tests/functionality
mkdir -p tests/compatibility
mkdir -p reports/ai-analysis
mkdir -p reports/customer-analysis
mkdir -p reports/execution
mkdir -p coverage
echo -e "${GREEN}✅ Directory structure created${NC}"

# Step 8: Check WordPress installation
echo ""
echo -e "${YELLOW}8️⃣  Checking WordPress installation...${NC}"
if wp core is-installed --path="../" 2>/dev/null; then
    WP_VERSION=$(wp core version --path="../")
    echo -e "${GREEN}✅ WordPress $WP_VERSION detected${NC}"
    
    # Check for BuddyPress
    if wp plugin is-active buddypress --path="../" 2>/dev/null; then
        BP_VERSION=$(wp plugin get buddypress --field=version --path="../")
        echo -e "${GREEN}✅ BuddyPress $BP_VERSION is active${NC}"
    else
        echo -e "${YELLOW}⚠️  BuddyPress not active${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  WordPress not found at ../${NC}"
    echo -e "${YELLOW}    Make sure to run from within a WordPress installation${NC}"
fi

# Step 9: Verify scanner plugin
echo ""
echo -e "${YELLOW}9️⃣  Checking scanner plugin...${NC}"
if [ -d "../wp-content/plugins/wbcom-universal-scanner" ]; then
    echo -e "${GREEN}✅ Scanner plugin found${NC}"
else
    echo -e "${YELLOW}⚠️  Scanner plugin not found${NC}"
    echo -e "${YELLOW}    Copy plugins/wbcom-universal-scanner to WordPress plugins directory${NC}"
fi

# Step 10: Create local bin directory
echo ""
echo -e "${YELLOW}🔟 Setting up local tools...${NC}"
mkdir -p bin

# Create a local wrapper for PHPUnit
cat > bin/phpunit << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$DIR/../vendor/bin/phpunit" "$@"
EOF
chmod +x bin/phpunit

# Create a local wrapper for running tests
cat > bin/test << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."

case "$1" in
    unit)
        ./vendor/bin/phpunit -c phpunit-unit.xml
        ;;
    integration)
        ./vendor/bin/phpunit -c phpunit.xml
        ;;
    e2e)
        npx playwright test
        ;;
    bp)
        ./vendor/bin/phpunit -c phpunit-components.xml --testsuite "${2:-all-components}"
        ;;
    *)
        echo "Usage: bin/test [unit|integration|e2e|bp] [component]"
        echo "Examples:"
        echo "  bin/test unit                  # Run unit tests"
        echo "  bin/test bp members            # Test BuddyPress members component"
        echo "  bin/test bp all-components     # Test all BuddyPress components"
        ;;
esac
EOF
chmod +x bin/test

echo -e "${GREEN}✅ Local tools created${NC}"

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Everything is installed within: $(pwd)${NC}"
echo ""
echo -e "${YELLOW}Quick Start Commands:${NC}"
echo -e "  ${BLUE}npm run universal:buddypress${NC}   # Full BuddyPress testing"
echo -e "  ${BLUE}npm run test:bp:all${NC}            # Run all BuddyPress tests"
echo -e "  ${BLUE}./bin/test unit${NC}                # Run unit tests"
echo -e "  ${BLUE}./bin/test bp members${NC}          # Test specific component"
echo ""
echo -e "${YELLOW}All tools are self-contained in:${NC}"
echo -e "  ${GREEN}./vendor/bin/${NC}                  # PHP tools (PHPUnit, etc.)"
echo -e "  ${GREEN}./node_modules/.bin/${NC}           # Node tools (Playwright, etc.)"
echo -e "  ${GREEN}./bin/${NC}                         # Local wrapper scripts"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run ${BLUE}npm run scan:bp${NC} to scan BuddyPress"
echo -e "  2. Run ${BLUE}npm run universal:buddypress${NC} for complete workflow"
echo -e "  3. Check ${BLUE}reports/${NC} directory for generated reports"
echo ""