#!/bin/bash

# WP Testing Framework - AI-Driven Plugin Scanner
# Scans plugins and generates comprehensive reports for AI (Claude) analysis
# Repository: https://github.com/vapvarun/wp-testing-framework/

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PLUGIN_NAME=$1

if [ -z "$PLUGIN_NAME" ]; then
    echo -e "${RED}❌ Please specify a plugin name${NC}"
    echo "Usage: ./scan-for-ai.sh <plugin-name>"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    AI-Driven Plugin Scanner for Claude     ║${NC}"
echo -e "${BLUE}║    Plugin: $PLUGIN_NAME${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Create AI reports directory
AI_REPORT_DIR="workspace/ai-reports/$PLUGIN_NAME"
mkdir -p $AI_REPORT_DIR

PLUGIN_PATH="../wp-content/plugins/$PLUGIN_NAME"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Step 1: Extract all functions
echo -e "${BLUE}🔍 Step 1: Extracting all PHP functions...${NC}"

FUNCTIONS_FILE="$AI_REPORT_DIR/functions-list.txt"
echo "# Functions in $PLUGIN_NAME plugin" > $FUNCTIONS_FILE
echo "# Generated: $(date)" >> $FUNCTIONS_FILE
echo "" >> $FUNCTIONS_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract all function definitions with file paths
    grep -r "function " $PLUGIN_PATH --include="*.php" | \
        sed 's/:[\t ]*function/ : function/g' | \
        sed "s|$PLUGIN_PATH/||g" >> $FUNCTIONS_FILE
    
    FUNC_COUNT=$(grep -c "function" $FUNCTIONS_FILE || echo "0")
    echo -e "${GREEN}✅ Found $FUNC_COUNT functions${NC}"
fi

# Step 2: Extract all classes
echo -e "${BLUE}🔍 Step 2: Extracting all PHP classes...${NC}"

CLASSES_FILE="$AI_REPORT_DIR/classes-list.txt"
echo "# Classes in $PLUGIN_NAME plugin" > $CLASSES_FILE
echo "# Generated: $(date)" >> $CLASSES_FILE
echo "" >> $CLASSES_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract all class definitions
    grep -r "^class \|^abstract class \|^final class " $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $CLASSES_FILE
    
    CLASS_COUNT=$(grep -c "class" $CLASSES_FILE || echo "0")
    echo -e "${GREEN}✅ Found $CLASS_COUNT classes${NC}"
fi

# Step 3: Extract all hooks (actions and filters)
echo -e "${BLUE}🔍 Step 3: Extracting WordPress hooks...${NC}"

HOOKS_FILE="$AI_REPORT_DIR/hooks-list.txt"
echo "# Hooks in $PLUGIN_NAME plugin" > $HOOKS_FILE
echo "# Generated: $(date)" >> $HOOKS_FILE
echo "" >> $HOOKS_FILE
echo "## Actions" >> $HOOKS_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract add_action calls
    grep -r "add_action\|do_action" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $HOOKS_FILE
    
    echo "" >> $HOOKS_FILE
    echo "## Filters" >> $HOOKS_FILE
    
    # Extract add_filter calls
    grep -r "add_filter\|apply_filters" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $HOOKS_FILE
    
    HOOK_COUNT=$(grep -c "add_\|do_\|apply_" $HOOKS_FILE || echo "0")
    echo -e "${GREEN}✅ Found $HOOK_COUNT hook references${NC}"
fi

# Step 4: Extract database queries
echo -e "${BLUE}🔍 Step 4: Extracting database operations...${NC}"

DB_FILE="$AI_REPORT_DIR/database-operations.txt"
echo "# Database Operations in $PLUGIN_NAME plugin" > $DB_FILE
echo "# Generated: $(date)" >> $DB_FILE
echo "" >> $DB_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract $wpdb usage
    grep -r "\$wpdb->" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $DB_FILE
    
    DB_COUNT=$(grep -c "\$wpdb" $DB_FILE || echo "0")
    echo -e "${GREEN}✅ Found $DB_COUNT database operations${NC}"
fi

# Step 5: Extract AJAX handlers
echo -e "${BLUE}🔍 Step 5: Extracting AJAX handlers...${NC}"

AJAX_FILE="$AI_REPORT_DIR/ajax-handlers.txt"
echo "# AJAX Handlers in $PLUGIN_NAME plugin" > $AJAX_FILE
echo "# Generated: $(date)" >> $AJAX_FILE
echo "" >> $AJAX_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract wp_ajax handlers
    grep -r "wp_ajax_\|admin-ajax.php" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $AJAX_FILE
    
    AJAX_COUNT=$(grep -c "wp_ajax" $AJAX_FILE || echo "0")
    echo -e "${GREEN}✅ Found $AJAX_COUNT AJAX references${NC}"
fi

# Step 6: Extract REST API endpoints
echo -e "${BLUE}🔍 Step 6: Extracting REST API endpoints...${NC}"

REST_FILE="$AI_REPORT_DIR/rest-endpoints.txt"
echo "# REST API Endpoints in $PLUGIN_NAME plugin" > $REST_FILE
echo "# Generated: $(date)" >> $REST_FILE
echo "" >> $REST_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract register_rest_route calls
    grep -r "register_rest_route\|rest_api_init" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $REST_FILE
    
    REST_COUNT=$(grep -c "rest_" $REST_FILE || echo "0")
    echo -e "${GREEN}✅ Found $REST_COUNT REST API references${NC}"
fi

# Step 7: Extract shortcodes
echo -e "${BLUE}🔍 Step 7: Extracting shortcodes...${NC}"

SHORTCODE_FILE="$AI_REPORT_DIR/shortcodes.txt"
echo "# Shortcodes in $PLUGIN_NAME plugin" > $SHORTCODE_FILE
echo "# Generated: $(date)" >> $SHORTCODE_FILE
echo "" >> $SHORTCODE_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Extract add_shortcode calls
    grep -r "add_shortcode\|do_shortcode" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $SHORTCODE_FILE
    
    SHORTCODE_COUNT=$(grep -c "shortcode" $SHORTCODE_FILE || echo "0")
    echo -e "${GREEN}✅ Found $SHORTCODE_COUNT shortcode references${NC}"
fi

# Step 8: Create file structure map
echo -e "${BLUE}🔍 Step 8: Mapping file structure...${NC}"

STRUCTURE_FILE="$AI_REPORT_DIR/file-structure.txt"
echo "# File Structure of $PLUGIN_NAME plugin" > $STRUCTURE_FILE
echo "# Generated: $(date)" >> $STRUCTURE_FILE
echo "" >> $STRUCTURE_FILE

if [ -d "$PLUGIN_PATH" ]; then
    # Create directory tree (simplified)
    find $PLUGIN_PATH -type f -name "*.php" | \
        sed "s|$PLUGIN_PATH/||g" | \
        sort | \
        sed 's|/|  /|g' >> $STRUCTURE_FILE
    
    FILE_COUNT=$(find $PLUGIN_PATH -name "*.php" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Mapped $FILE_COUNT PHP files${NC}"
fi

# Step 9: Extract security-sensitive patterns
echo -e "${BLUE}🔍 Step 9: Scanning for security patterns...${NC}"

SECURITY_FILE="$AI_REPORT_DIR/security-analysis.txt"
echo "# Security Analysis of $PLUGIN_NAME plugin" > $SECURITY_FILE
echo "# Generated: $(date)" >> $SECURITY_FILE
echo "" >> $SECURITY_FILE

if [ -d "$PLUGIN_PATH" ]; then
    echo "## Nonce Checks" >> $SECURITY_FILE
    grep -r "check_admin_referer\|wp_verify_nonce\|check_ajax_referer" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $SECURITY_FILE
    
    echo "" >> $SECURITY_FILE
    echo "## Capability Checks" >> $SECURITY_FILE
    grep -r "current_user_can\|user_can" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" >> $SECURITY_FILE
    
    echo "" >> $SECURITY_FILE
    echo "## Data Sanitization" >> $SECURITY_FILE
    grep -r "sanitize_\|esc_\|wp_kses" $PLUGIN_PATH --include="*.php" | \
        sed "s|$PLUGIN_PATH/||g" | head -50 >> $SECURITY_FILE
    
    echo -e "${GREEN}✅ Security analysis completed${NC}"
fi

# Step 10: Generate comprehensive AI report
echo -e "${BLUE}📊 Step 10: Generating AI analysis report...${NC}"

AI_REPORT="$AI_REPORT_DIR/ai-analysis-report.md"
cat > $AI_REPORT << EOF
# AI Analysis Report: $PLUGIN_NAME

Generated: $(date)
Plugin Path: $PLUGIN_PATH

## Summary Statistics

- **PHP Functions:** $FUNC_COUNT
- **PHP Classes:** $CLASS_COUNT
- **Hook References:** $HOOK_COUNT
- **Database Operations:** $DB_COUNT
- **AJAX Handlers:** $AJAX_COUNT
- **REST Endpoints:** $REST_COUNT
- **Shortcodes:** $SHORTCODE_COUNT
- **Total PHP Files:** $FILE_COUNT

## Component Analysis

### Functions
See: functions-list.txt
Total: $FUNC_COUNT functions across multiple files

### Classes
See: classes-list.txt
Total: $CLASS_COUNT class definitions

### WordPress Integration
- Hooks: $HOOK_COUNT (actions and filters)
- AJAX: $AJAX_COUNT handlers
- REST: $REST_COUNT endpoints
- Shortcodes: $SHORTCODE_COUNT definitions

### Database Layer
- Direct \$wpdb calls: $DB_COUNT
See: database-operations.txt for details

### Security
- Nonce verification patterns found
- Capability checks implemented
- Data sanitization functions used
See: security-analysis.txt for details

## File Organization
See: file-structure.txt for complete file tree

## Recommendations for Testing

Based on this analysis, the following test areas should be prioritized:

1. **Unit Tests:** Test the $FUNC_COUNT functions individually
2. **Integration Tests:** Test the $HOOK_COUNT hooks integration
3. **API Tests:** Test the $REST_COUNT REST endpoints
4. **Security Tests:** Verify nonce and capability checks
5. **Database Tests:** Test the $DB_COUNT database operations

## AI Instructions for Test Generation

Use the following files to generate comprehensive tests:
- functions-list.txt - for unit test generation
- hooks-list.txt - for integration test generation
- ajax-handlers.txt - for AJAX test generation
- rest-endpoints.txt - for API test generation
- security-analysis.txt - for security test generation

Each file contains the actual code patterns that need testing.
EOF

echo -e "${GREEN}✅ AI analysis report generated${NC}"

# Step 11: Create JSON summary for programmatic use
echo -e "${BLUE}📊 Step 11: Creating JSON summary...${NC}"

JSON_SUMMARY="$AI_REPORT_DIR/summary.json"
cat > $JSON_SUMMARY << EOF
{
    "plugin": "$PLUGIN_NAME",
    "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "statistics": {
        "functions": $FUNC_COUNT,
        "classes": $CLASS_COUNT,
        "hooks": $HOOK_COUNT,
        "database_operations": $DB_COUNT,
        "ajax_handlers": $AJAX_COUNT,
        "rest_endpoints": $REST_COUNT,
        "shortcodes": $SHORTCODE_COUNT,
        "php_files": $FILE_COUNT
    },
    "files": {
        "functions": "functions-list.txt",
        "classes": "classes-list.txt",
        "hooks": "hooks-list.txt",
        "database": "database-operations.txt",
        "ajax": "ajax-handlers.txt",
        "rest": "rest-endpoints.txt",
        "shortcodes": "shortcodes.txt",
        "structure": "file-structure.txt",
        "security": "security-analysis.txt",
        "report": "ai-analysis-report.md"
    }
}
EOF

echo -e "${GREEN}✅ JSON summary created${NC}"

# Final summary
echo ""
echo -e "${GREEN}🎉 AI Scan Complete!${NC}"
echo "==================="
echo -e "${BLUE}📁 Reports saved to: $AI_REPORT_DIR/${NC}"
echo ""
echo -e "${YELLOW}Files generated for AI analysis:${NC}"
echo "  • ai-analysis-report.md - Main report for Claude"
echo "  • functions-list.txt - All PHP functions"
echo "  • classes-list.txt - All PHP classes"
echo "  • hooks-list.txt - WordPress hooks"
echo "  • database-operations.txt - Database queries"
echo "  • ajax-handlers.txt - AJAX endpoints"
echo "  • rest-endpoints.txt - REST API"
echo "  • shortcodes.txt - Shortcode definitions"
echo "  • security-analysis.txt - Security patterns"
echo "  • file-structure.txt - File organization"
echo "  • summary.json - Machine-readable summary"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Feed these reports to Claude for test generation"
echo "2. Use: cat $AI_REPORT_DIR/ai-analysis-report.md"
echo "3. Ask Claude to generate tests based on the analysis"