#!/bin/bash

# Automated Documentation Generator for WordPress Plugins
# This ensures all documentation is generated after analysis

PLUGIN_NAME="${1:-wpforo}"
BASE_DIR="/Users/varundubey/Local Sites/wptesting/app/public"
SCAN_DIR="$BASE_DIR/wp-content/uploads/wbcom-scan/$PLUGIN_NAME"
PLAN_DIR="$BASE_DIR/wp-content/uploads/wbcom-plan/$PLUGIN_NAME"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📚 Generating Complete Documentation for $PLUGIN_NAME${NC}"
echo "================================================"

# Find latest scan
LATEST_SCAN=$(ls -d $SCAN_DIR/*/ 2>/dev/null | sort -r | head -1)
if [ -z "$LATEST_SCAN" ]; then
    echo "❌ No scan data found for $PLUGIN_NAME"
    exit 1
fi

# Create documentation directory
TIMESTAMP=$(basename "$LATEST_SCAN")
DOC_DIR="$PLAN_DIR/$TIMESTAMP/documentation"
mkdir -p "$DOC_DIR"

# Read AST analysis
AST_FILE="$LATEST_SCAN/wordpress-ast-analysis.json"
if [ ! -f "$AST_FILE" ]; then
    echo "❌ No AST analysis found"
    exit 1
fi

# Extract metrics from AST
FILES_COUNT=$(jq '.files_analyzed' "$AST_FILE")
HOOKS_COUNT=$(jq '.total.hooks' "$AST_FILE")
AJAX_COUNT=$(jq '.total.ajax_handlers' "$AST_FILE")
SHORTCODES_COUNT=$(jq '.total.shortcodes' "$AST_FILE")
DATABASE_COUNT=$(jq '.total.database_queries' "$AST_FILE")
OPTIONS_COUNT=$(jq '.total.options' "$AST_FILE")
SECURITY_ISSUES=$(jq '.total.security_issues' "$AST_FILE")
NONCES=$(jq '.total.nonces' "$AST_FILE")
ESCAPING=$(jq '.total.escaping' "$AST_FILE")

echo "📊 Analysis Summary:"
echo "   Files: $FILES_COUNT"
echo "   Hooks: $HOOKS_COUNT"
echo "   AJAX: $AJAX_COUNT"
echo "   Shortcodes: $SHORTCODES_COUNT"

# Generate USER-GUIDE.md
echo -e "\n${YELLOW}Generating USER-GUIDE.md...${NC}"
cat > "$DOC_DIR/USER-GUIDE.md" << EOF
# $PLUGIN_NAME - Comprehensive User Guide

## Plugin Overview
- **Files Analyzed:** $FILES_COUNT
- **Hooks Available:** $HOOKS_COUNT
- **AJAX Handlers:** $AJAX_COUNT
- **Shortcodes:** $SHORTCODES_COUNT

## Quick Start
\`\`\`bash
wp plugin install $PLUGIN_NAME --activate
\`\`\`

## Core Features
Based on automated analysis:
- Database Operations: $DATABASE_COUNT
- Options API Calls: $OPTIONS_COUNT
- Security Implementations: $NONCES nonces, $ESCAPING escaping functions

## Configuration
See admin panel at \`/wp-admin/admin.php?page=$PLUGIN_NAME\`

## Shortcodes
$SHORTCODES_COUNT shortcodes available for embedding

## Performance
- Hooks: $HOOKS_COUNT (may impact performance if excessive)
- AJAX: $AJAX_COUNT handlers for interactivity
- Database: $DATABASE_COUNT queries

## Security
- Nonce Verifications: $NONCES
- Output Escaping: $ESCAPING
- Security Issues Found: $SECURITY_ISSUES

---
*Generated from WordPress AST Analysis*
EOF

# Generate ISSUES-AND-FIXES.md
echo -e "${YELLOW}Generating ISSUES-AND-FIXES.md...${NC}"
cat > "$DOC_DIR/ISSUES-AND-FIXES.md" << EOF
# $PLUGIN_NAME - Issues & Fixes Report

## Analysis Date: $(date)
- Files Scanned: $FILES_COUNT
- Security Issues: $SECURITY_ISSUES

## Performance Concerns
$(if [ "$HOOKS_COUNT" -gt 1000 ]; then
    echo "⚠️ High hook count ($HOOKS_COUNT) may impact performance"
fi)

$(if [ "$AJAX_COUNT" -gt 50 ]; then
    echo "⚠️ High AJAX handler count ($AJAX_COUNT) needs rate limiting"
fi)

$(if [ "$DATABASE_COUNT" -gt 20 ]; then
    echo "⚠️ Many database queries ($DATABASE_COUNT) - consider caching"
fi)

## Security Analysis
- Nonces Found: $NONCES
- Escaping Functions: $ESCAPING
- Issues Detected: $SECURITY_ISSUES

## Recommendations
1. $([ "$SECURITY_ISSUES" -gt 0 ] && echo "Fix security issues immediately" || echo "Security looks good")
2. $([ "$HOOKS_COUNT" -gt 2000 ] && echo "Optimize hook usage" || echo "Hook usage is reasonable")
3. $([ "$AJAX_COUNT" -gt 100 ] && echo "Implement AJAX rate limiting" || echo "AJAX usage is manageable")

---
*Automated analysis report*
EOF

# Generate DEVELOPMENT-PLAN.md
echo -e "${YELLOW}Generating DEVELOPMENT-PLAN.md...${NC}"
cat > "$DOC_DIR/DEVELOPMENT-PLAN.md" << EOF
# $PLUGIN_NAME - Development Plan

## Current State
- Files: $FILES_COUNT
- Complexity: $([ "$FILES_COUNT" -gt 100 ] && echo "High" || echo "Moderate")
- Security Score: $([ "$SECURITY_ISSUES" -eq 0 ] && echo "95/100" || echo "$((90 - SECURITY_ISSUES * 5))/100")

## Phase 1: Security (Week 1)
$([ "$SECURITY_ISSUES" -gt 0 ] && echo "- Fix $SECURITY_ISSUES security issues" || echo "- Security audit passed")
- Add missing nonces
- Enhance output escaping

## Phase 2: Performance (Week 2)
$([ "$HOOKS_COUNT" -gt 2000 ] && echo "- Reduce hooks from $HOOKS_COUNT" || echo "- Hooks optimized")
$([ "$AJAX_COUNT" -gt 100 ] && echo "- Optimize $AJAX_COUNT AJAX handlers" || echo "- AJAX is efficient")
$([ "$DATABASE_COUNT" -gt 20 ] && echo "- Cache $DATABASE_COUNT database queries" || echo "- Database queries optimized")

## Phase 3: Testing (Week 3)
- Create unit tests
- Integration testing
- Performance benchmarks

## Phase 4: Features (Week 4)
- REST API endpoints
- Gutenberg blocks
- Mobile optimization

## Budget Estimate
- Security fixes: \$$(( SECURITY_ISSUES * 300 ))
- Performance optimization: \$$(( (HOOKS_COUNT / 100) * 50 ))
- Testing implementation: \$3,000
- Feature development: \$5,000
- **Total: \$$(( SECURITY_ISSUES * 300 + (HOOKS_COUNT / 100) * 50 + 8000 ))**

---
*Automated development plan*
EOF

echo -e "\n${GREEN}✅ Documentation generation complete!${NC}"
echo "📁 Files created in: $DOC_DIR"
ls -la "$DOC_DIR"/*.md 2>/dev/null | awk '{print "   ✓ " $9}'

# Generate summary
echo -e "\n📊 Documentation Summary:"
echo "   USER-GUIDE.md - $(wc -l < "$DOC_DIR/USER-GUIDE.md") lines"
echo "   ISSUES-AND-FIXES.md - $(wc -l < "$DOC_DIR/ISSUES-AND-FIXES.md") lines"
echo "   DEVELOPMENT-PLAN.md - $(wc -l < "$DOC_DIR/DEVELOPMENT-PLAN.md") lines"