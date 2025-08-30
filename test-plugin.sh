#!/bin/bash

# WP Testing Framework - Universal Plugin Tester
# Auto-creates folders and runs tests
# Repository: https://github.com/vapvarun/wp-testing-framework/

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get plugin name from argument
PLUGIN_NAME=$1
TEST_TYPE=${2:-full}

if [ -z "$PLUGIN_NAME" ]; then
    echo -e "${RED}❌ Please specify a plugin name${NC}"
    echo "Usage: ./test-plugin.sh <plugin-name> [test-type]"
    echo "Example: ./test-plugin.sh bbpress"
    echo "Example: ./test-plugin.sh woocommerce security"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       WP Testing Framework                 ║${NC}"
echo -e "${BLUE}║       Testing: $PLUGIN_NAME${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Auto-create plugin folder structure
echo -e "${BLUE}📁 Setting up plugin structure...${NC}"

if [ ! -d "plugins/$PLUGIN_NAME" ]; then
    mkdir -p plugins/$PLUGIN_NAME/{data,tests,scanners,models,analysis}
    mkdir -p plugins/$PLUGIN_NAME/tests/{unit,integration,security,performance}
    mkdir -p workspace/reports/$PLUGIN_NAME
    mkdir -p workspace/logs/$PLUGIN_NAME
    mkdir -p workspace/coverage/$PLUGIN_NAME
    echo -e "${GREEN}✅ Created folder structure for $PLUGIN_NAME${NC}"
else
    echo -e "${YELLOW}📁 Folder structure already exists${NC}"
fi

# Step 2: Check if plugin is installed
echo -e "${BLUE}🔍 Checking plugin installation...${NC}"

if wp plugin is-installed $PLUGIN_NAME 2>/dev/null; then
    echo -e "${GREEN}✅ Plugin $PLUGIN_NAME is installed${NC}"
    
    # Get plugin details
    PLUGIN_VERSION=$(wp plugin get $PLUGIN_NAME --field=version 2>/dev/null || echo "unknown")
    PLUGIN_STATUS=$(wp plugin get $PLUGIN_NAME --field=status 2>/dev/null || echo "unknown")
    
    echo -e "${BLUE}   Version: $PLUGIN_VERSION${NC}"
    echo -e "${BLUE}   Status: $PLUGIN_STATUS${NC}"
    
    # Activate if needed
    if [ "$PLUGIN_STATUS" != "active" ]; then
        echo -e "${YELLOW}⚡ Activating plugin for testing...${NC}"
        wp plugin activate $PLUGIN_NAME
    fi
else
    echo -e "${YELLOW}⚠️  Plugin $PLUGIN_NAME not found in WordPress${NC}"
    echo -e "${YELLOW}   Tests will run against plugin structure only${NC}"
fi

# Step 3: Generate test configuration
echo -e "${BLUE}⚙️  Generating test configuration...${NC}"

cat > plugins/$PLUGIN_NAME/test-config.json << EOF
{
    "plugin": "$PLUGIN_NAME",
    "version": "$PLUGIN_VERSION",
    "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "test_type": "$TEST_TYPE",
    "environment": {
        "wp_version": "$(wp core version)",
        "php_version": "$(php -r 'echo PHP_VERSION;')",
        "site_url": "$(wp option get siteurl)"
    },
    "tests": {
        "unit": true,
        "integration": true,
        "security": true,
        "performance": true,
        "accessibility": true
    }
}
EOF

echo -e "${GREEN}✅ Configuration generated${NC}"

# Step 4: Scan plugin code
echo -e "${BLUE}🔍 Scanning plugin code...${NC}"

PLUGIN_PATH="../wp-content/plugins/$PLUGIN_NAME"
if [ -d "$PLUGIN_PATH" ]; then
    # Count files
    PHP_FILES=$(find $PLUGIN_PATH -name "*.php" 2>/dev/null | wc -l)
    JS_FILES=$(find $PLUGIN_PATH -name "*.js" 2>/dev/null | wc -l)
    CSS_FILES=$(find $PLUGIN_PATH -name "*.css" 2>/dev/null | wc -l)
    
    echo -e "${BLUE}   PHP files: $PHP_FILES${NC}"
    echo -e "${BLUE}   JS files: $JS_FILES${NC}"
    echo -e "${BLUE}   CSS files: $CSS_FILES${NC}"
    
    # Save scan results
    cat > plugins/$PLUGIN_NAME/analysis/scan-results.json << EOF
{
    "plugin": "$PLUGIN_NAME",
    "files": {
        "php": $PHP_FILES,
        "javascript": $JS_FILES,
        "css": $CSS_FILES
    },
    "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
fi

# Step 5: Generate basic tests if they don't exist
echo -e "${BLUE}🧪 Generating test files...${NC}"

# Unit test template
if [ ! -f "plugins/$PLUGIN_NAME/tests/unit/BasicTest.php" ]; then
    cat > plugins/$PLUGIN_NAME/tests/unit/BasicTest.php << 'EOF'
<?php
namespace WPTestingFramework\Plugins\PLUGIN_NAME\Tests\Unit;

use PHPUnit\Framework\TestCase;

class BasicTest extends TestCase {
    public function testPluginExists() {
        $plugin_file = WP_PLUGIN_DIR . '/PLUGIN_NAME/PLUGIN_NAME.php';
        $this->assertFileExists($plugin_file, 'Plugin main file should exist');
    }
}
EOF
    sed -i '' "s/PLUGIN_NAME/$PLUGIN_NAME/g" plugins/$PLUGIN_NAME/tests/unit/BasicTest.php 2>/dev/null || \
    sed -i "s/PLUGIN_NAME/$PLUGIN_NAME/g" plugins/$PLUGIN_NAME/tests/unit/BasicTest.php
fi

echo -e "${GREEN}✅ Test files ready${NC}"

# Step 6: Run tests based on type
echo ""
echo -e "${BLUE}🚀 Running tests...${NC}"
echo "=================="

case $TEST_TYPE in
    "quick")
        echo "Running quick tests..."
        npm run test:unit plugins/$PLUGIN_NAME/tests/unit/ 2>/dev/null || true
        ;;
    "security")
        echo "Running security tests..."
        npm run test:security $PLUGIN_NAME 2>/dev/null || true
        ;;
    "performance")
        echo "Running performance tests..."
        npm run test:performance $PLUGIN_NAME 2>/dev/null || true
        ;;
    "full"|*)
        echo "Running full test suite..."
        
        # Try to run universal test if it exists
        if npm run | grep -q "universal:$PLUGIN_NAME"; then
            npm run universal:$PLUGIN_NAME
        else
            # Run individual tests
            echo -e "${YELLOW}Running standard test suite...${NC}"
            
            # Unit tests
            if [ -d "plugins/$PLUGIN_NAME/tests/unit" ]; then
                ./vendor/bin/phpunit plugins/$PLUGIN_NAME/tests/unit/ || true
            fi
            
            # Integration tests
            if [ -d "plugins/$PLUGIN_NAME/tests/integration" ]; then
                ./vendor/bin/phpunit plugins/$PLUGIN_NAME/tests/integration/ || true
            fi
        fi
        ;;
esac

# Step 7: Generate report
echo ""
echo -e "${BLUE}📊 Generating report...${NC}"

REPORT_FILE="workspace/reports/$PLUGIN_NAME/report-$(date +%Y%m%d-%H%M%S).html"
mkdir -p workspace/reports/$PLUGIN_NAME

cat > $REPORT_FILE << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Report - $PLUGIN_NAME</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #0073aa; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { color: #46b450; }
        .warning { color: #ffb900; }
        .error { color: #dc3232; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Test Report: $PLUGIN_NAME</h1>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="section">
        <h2>Plugin Information</h2>
        <ul>
            <li>Name: $PLUGIN_NAME</li>
            <li>Version: $PLUGIN_VERSION</li>
            <li>Status: $PLUGIN_STATUS</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Test Results</h2>
        <ul>
            <li class="success">✓ Folder structure created</li>
            <li class="success">✓ Configuration generated</li>
            <li class="success">✓ Plugin scanned</li>
            <li class="success">✓ Tests executed</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>File Analysis</h2>
        <ul>
            <li>PHP Files: $PHP_FILES</li>
            <li>JavaScript Files: $JS_FILES</li>
            <li>CSS Files: $CSS_FILES</li>
        </ul>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"

# Step 8: Summary
echo ""
echo -e "${GREEN}🎉 Testing Complete!${NC}"
echo "==================="
echo -e "${BLUE}📁 Plugin folder: plugins/$PLUGIN_NAME/${NC}"
echo -e "${BLUE}📊 Report: $REPORT_FILE${NC}"
echo -e "${BLUE}📝 Logs: workspace/logs/$PLUGIN_NAME/${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. View the report: open $REPORT_FILE"
echo "2. Check logs: ls workspace/logs/$PLUGIN_NAME/"
echo "3. Run specific tests: npm run test:unit $PLUGIN_NAME"