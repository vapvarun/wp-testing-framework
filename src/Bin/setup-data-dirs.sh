#!/bin/bash

# Setup WBCom Data Directories
# This script creates the necessary wbcom-scan and wbcom-plan directories
# and copies example files to get started

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get WordPress root (parent of wp-testing-framework)
WP_ROOT="$(dirname "$(pwd)")"
FRAMEWORK_DIR="$(pwd)"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                WBCom Data Directories Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}WordPress Root: $WP_ROOT${NC}"
echo -e "${YELLOW}Framework Dir: $FRAMEWORK_DIR${NC}"
echo ""

# Create wbcom-scan directory structure
echo -e "${GREEN}Creating wbcom-scan directory structure...${NC}"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-scan"

# Create wbcom-plan directory structure
echo -e "${GREEN}Creating wbcom-plan directory structure...${NC}"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/models/test-patterns"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/models/demo-data"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/models/bug-patterns"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/templates/test-scenarios"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/templates/user-journeys"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/templates/fix-patterns"
mkdir -p "$WP_ROOT/wp-content/uploads/wbcom-plan/knowledge-base"

# Copy example files if they don't exist
if [ ! -f "$WP_ROOT/wp-content/uploads/wbcom-plan/models/test-patterns/generic.json" ]; then
    echo -e "${GREEN}Copying generic model example...${NC}"
    if [ -f "$FRAMEWORK_DIR/examples/wbcom-plan/generic-model-example.json" ]; then
        cp "$FRAMEWORK_DIR/examples/wbcom-plan/generic-model-example.json" \
           "$WP_ROOT/wp-content/uploads/wbcom-plan/models/test-patterns/generic.json"
    fi
fi

if [ ! -f "$WP_ROOT/wp-content/uploads/wbcom-plan/models/test-patterns/buddypress.json" ]; then
    echo -e "${GREEN}Copying BuddyPress model example...${NC}"
    if [ -f "$FRAMEWORK_DIR/examples/wbcom-plan/buddypress-model-example.json" ]; then
        cp "$FRAMEWORK_DIR/examples/wbcom-plan/buddypress-model-example.json" \
           "$WP_ROOT/wp-content/uploads/wbcom-plan/models/test-patterns/buddypress.json"
    fi
fi

# Create .gitignore files to keep directories but ignore contents
echo -e "${GREEN}Creating .gitignore files...${NC}"

cat > "$WP_ROOT/wp-content/uploads/wbcom-scan/.gitignore" << 'EOF'
# Ignore all scan data (environment-specific)
*
!.gitignore
!README.md
EOF

cat > "$WP_ROOT/wp-content/uploads/wbcom-plan/.gitignore" << 'EOF'
# Ignore local modifications but keep structure
*.local.json
*.backup.json
*.tmp
EOF

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}Created directories:${NC}"
echo "  📁 $WP_ROOT/wp-content/uploads/wbcom-scan/"
echo "  📁 $WP_ROOT/wp-content/uploads/wbcom-plan/"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run a plugin scan: npm run universal:scan --plugin=buddypress"
echo "  2. Analyze results: npm run universal:analyze --plugin=buddypress"
echo "  3. Generate tests: npm run universal:generate --plugin=buddypress"
echo "  4. Execute tests: npm run universal:test --plugin=buddypress"
echo ""

echo -e "${BLUE}For more information, see:${NC}"
echo "  - examples/wbcom-scan/README.md"
echo "  - examples/wbcom-plan/README.md"
echo ""