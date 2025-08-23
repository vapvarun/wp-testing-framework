#!/bin/bash
#
# Sync Script: BuddyNext Development -> GitHub Repository
# 
# This script syncs testing framework changes from the local development
# environment (buddynext.local) to the GitHub repository.
#
# Development: /Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework/
# GitHub Repo: /Users/varundubey/wp-testing-framework/
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
DEV_PATH="/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework"
GITHUB_PATH="/Users/varundubey/wp-testing-framework"

echo -e "${GREEN}🔄 Syncing BuddyNext development to GitHub repository${NC}"
echo -e "${YELLOW}From: $DEV_PATH${NC}"
echo -e "${YELLOW}To:   $GITHUB_PATH${NC}"
echo ""

# Function to sync a directory
sync_dir() {
    local dir=$1
    echo -e "${GREEN}📁 Syncing $dir...${NC}"
    
    if [ -d "$DEV_PATH/$dir" ]; then
        rsync -av --delete \
            --exclude='.DS_Store' \
            --exclude='node_modules' \
            --exclude='vendor' \
            --exclude='.phpunit.cache' \
            --exclude='test-results' \
            --exclude='playwright-report' \
            "$DEV_PATH/$dir/" "$GITHUB_PATH/$dir/"
        echo -e "${GREEN}✅ $dir synced${NC}"
    else
        echo -e "${YELLOW}⚠️  $dir not found in development${NC}"
    fi
}

# Function to sync a file
sync_file() {
    local file=$1
    echo -e "${GREEN}📄 Syncing $file...${NC}"
    
    if [ -f "$DEV_PATH/$file" ]; then
        cp "$DEV_PATH/$file" "$GITHUB_PATH/$file"
        echo -e "${GREEN}✅ $file synced${NC}"
    else
        echo -e "${YELLOW}⚠️  $file not found in development${NC}"
    fi
}

# Sync directories
sync_dir "tools"
sync_dir "tests"
sync_dir "docs"
sync_dir "plugins/wbcom-universal-scanner"
sync_dir "reports"
sync_dir "bin"

# Note: We don't sync vendor/ and node_modules/ as they should be installed locally

# Sync configuration files
sync_file "package.json"
sync_file "composer.json"
sync_file "phpunit.xml"
sync_file "phpunit-unit.xml"
sync_file "phpunit-components.xml"
sync_file "phpunit-modern.xml"

# Sync documentation
sync_file "README.md"
sync_file "CONTRIBUTING.md"
sync_file "DEVELOPMENT-WORKFLOW.md"
sync_file "DOCUMENTATION-VALIDATION.md"

# Sync scripts
sync_file "setup.sh"
sync_file "sync-to-github.sh"
sync_file "cleanup-wordpress-root.sh"

# Sync git files
sync_file ".gitignore"

echo ""
echo -e "${GREEN}✅ Sync completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. cd $GITHUB_PATH"
echo "2. git status"
echo "3. git add ."
echo "4. git commit -m 'Update from buddynext development'"
echo "5. git push"