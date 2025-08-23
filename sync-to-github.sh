#!/bin/bash
#
# Sync Script: Development -> GitHub Repository
# 
# This script syncs testing framework changes to GitHub repository.
# Set GITHUB_PATH environment variable or edit default below.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current directory (should be wp-testing-framework)
DEV_PATH="$(pwd)"

# GitHub path - use environment variable or default
GITHUB_PATH="${WP_TESTING_GITHUB_PATH:-$HOME/wp-testing-framework}"

echo -e "${GREEN}🔄 Syncing WP Testing Framework to GitHub repository${NC}"
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

# Sync framework directories (permanent data only)
sync_dir "src"
sync_dir "plugins"
sync_dir "templates"
sync_dir "docs"
sync_dir "bin"
sync_dir "tools"

# Don't sync workspace or ephemeral data
# sync_dir "workspace"  # Skip - ephemeral data
# sync_dir "reports"    # Skip - generated reports

# Note: We don't sync vendor/ and node_modules/ as they should be installed locally

# Sync configuration files
sync_file "package.json"
sync_file "composer.json"
sync_file "phpunit.xml"
sync_file "phpunit-unit.xml"
sync_file "phpunit-components.xml"
sync_file "phpunit-modern.xml"

# Sync root documentation
sync_file "README.md"
sync_file "CONTRIBUTING.md"

# Sync essential scripts only
sync_file "setup.sh"
sync_file "sync-to-github.sh"

# Sync git files
sync_file ".gitignore"

echo ""
echo -e "${GREEN}✅ Sync completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. cd $GITHUB_PATH"
echo "2. git status"
echo "3. git add ."
echo "4. git commit -m 'Update from development'"
echo "5. git push"
echo ""
echo -e "${YELLOW}To set custom GitHub path:${NC}"
echo "export WP_TESTING_GITHUB_PATH=/path/to/github/repo"