#!/bin/bash
#
# Cleanup Script: Remove duplicate testing files from WordPress root
# 
# This script removes testing framework files from WordPress root that are
# now contained within wp-testing-framework directory
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WP_ROOT="/Users/varundubey/Local Sites/buddynext/app/public"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}     WordPress Root Cleanup - Remove Duplicate Testing Files${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}⚠️  This will remove testing files from WordPress root that are now in wp-testing-framework${NC}"
echo -e "${YELLOW}WordPress Root: $WP_ROOT${NC}"
echo ""

# Confirmation
read -p "Are you sure you want to clean up WordPress root? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cleanup cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"
echo ""

# Function to remove file/directory safely
remove_item() {
    local item="$1"
    local type="$2"
    
    if [ -e "$WP_ROOT/$item" ]; then
        echo -e "${YELLOW}Removing $type: $item${NC}"
        rm -rf "$WP_ROOT/$item"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Removed: $item${NC}"
        else
            echo -e "${RED}❌ Failed to remove: $item${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  Not found (already removed?): $item${NC}"
    fi
}

# Remove duplicate composer files
echo -e "${BLUE}1️⃣  Removing duplicate Composer files...${NC}"
remove_item "composer.json" "file"
remove_item "composer.lock" "file"
remove_item "vendor" "directory"

# Remove duplicate npm files
echo ""
echo -e "${BLUE}2️⃣  Removing duplicate npm files...${NC}"
remove_item "package.json" "file"
remove_item "package-lock.json" "file"
remove_item "node_modules" "directory"

# Remove duplicate PHPUnit config files
echo ""
echo -e "${BLUE}3️⃣  Removing duplicate PHPUnit configs...${NC}"
remove_item "phpunit.xml" "file"
remove_item "phpunit-unit.xml" "file"
remove_item "phpunit-components.xml" "file"
remove_item ".phpunit.cache" "directory"

# Remove duplicate test directories
echo ""
echo -e "${BLUE}4️⃣  Removing duplicate test directories...${NC}"
remove_item "tests" "directory"

# Remove duplicate tools directory
echo ""
echo -e "${BLUE}5️⃣  Removing duplicate tools directory...${NC}"
remove_item "tools" "directory"

# Remove duplicate docs directory if exists
echo ""
echo -e "${BLUE}6️⃣  Removing duplicate docs directory...${NC}"
remove_item "docs" "directory"

# Remove duplicate bin directory if exists
echo ""
echo -e "${BLUE}7️⃣  Removing duplicate bin directory...${NC}"
remove_item "bin" "directory"

# Remove old setup script
echo ""
echo -e "${BLUE}8️⃣  Removing old setup script...${NC}"
remove_item "install-wp-testing-framework.sh" "file"

# Clean up any leftover files
echo ""
echo -e "${BLUE}9️⃣  Checking for other testing-related files...${NC}"

# Check for any .log files
if ls "$WP_ROOT"/*.log 1> /dev/null 2>&1; then
    echo -e "${YELLOW}Found log files in WordPress root${NC}"
    for logfile in "$WP_ROOT"/*.log; do
        filename=$(basename "$logfile")
        echo -e "${YELLOW}  - $filename${NC}"
    done
    read -p "Remove log files? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$WP_ROOT"/*.log
        echo -e "${GREEN}✅ Log files removed${NC}"
    fi
fi

# Remove other non-WordPress files
echo ""
echo -e "${BLUE}🔟 Removing other non-WordPress files...${NC}"
remove_item "local-xdebuginfo.php" "file"
remove_item "install-wbcom-pack.sh" "file"
remove_item ".env.e2e" "file"

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Cleanup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}WordPress root is now clean!${NC}"
echo -e "${GREEN}All testing files are contained in: $WP_ROOT/wp-testing-framework/${NC}"
echo ""

echo -e "${YELLOW}What remains in WordPress root:${NC}"
echo -e "  - WordPress core files (wp-*.php, wp-admin/, wp-includes/)"
echo -e "  - wp-content/ (themes, plugins, uploads)"
echo -e "  - wp-testing-framework/ (all testing tools)"
echo -e "  - .htaccess, wp-config.php (if present)"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. cd wp-testing-framework"
echo -e "  2. npm run universal:buddypress"
echo -e "  3. ./sync-to-github.sh (to sync with GitHub)"
echo ""