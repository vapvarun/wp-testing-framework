#!/bin/bash

# Documentation Quality Validator
# Ensures documentation meets quality standards

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Plugin to validate
PLUGIN_NAME=${1:-"bbpress"}
DOC_PATH="plugins/$PLUGIN_NAME"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Documentation Quality Validator${NC}"
echo -e "${BLUE}   Plugin: $PLUGIN_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Initialize scores
TOTAL_SCORE=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to check file quality
check_documentation_quality() {
    local file=$1
    local file_name=$(basename "$file")
    local min_lines=$2
    local min_code_blocks=$3
    local min_specific_refs=$4
    local min_headers=$5
    
    echo ""
    echo -e "${YELLOW}Checking: $file_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local score=0
    local max_score=100
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ File not found${NC}"
        return 1
    fi
    
    # Check line count
    local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
    if [ "$lines" -ge "$min_lines" ]; then
        echo -e "${GREEN}✓ Line count: $lines (minimum: $min_lines)${NC}"
        score=$((score + 20))
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Line count: $lines (minimum: $min_lines)${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check code blocks
    local code_blocks=$(grep -c '```' "$file" 2>/dev/null || echo 0)
    code_blocks=$((code_blocks / 2)) # Pairs of backticks
    if [ "$code_blocks" -ge "$min_code_blocks" ]; then
        echo -e "${GREEN}✓ Code blocks: $code_blocks (minimum: $min_code_blocks)${NC}"
        score=$((score + 25))
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Code blocks: $code_blocks (minimum: $min_code_blocks)${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check plugin-specific references
    local specific_refs=$(grep -ci "$PLUGIN_NAME" "$file" 2>/dev/null || echo 0)
    if [ "$specific_refs" -ge "$min_specific_refs" ]; then
        echo -e "${GREEN}✓ Plugin references: $specific_refs (minimum: $min_specific_refs)${NC}"
        score=$((score + 25))
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Plugin references: $specific_refs (minimum: $min_specific_refs)${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check headers/structure
    local headers=$(grep -c '^#' "$file" 2>/dev/null || echo 0)
    if [ "$headers" -ge "$min_headers" ]; then
        echo -e "${GREEN}✓ Section headers: $headers (minimum: $min_headers)${NC}"
        score=$((score + 15))
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Section headers: $headers (minimum: $min_headers)${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for specific quality indicators
    local has_examples=$(grep -c 'Example\|example\|e\.g\.\|For instance' "$file" 2>/dev/null || echo 0)
    if [ "$has_examples" -gt 0 ]; then
        echo -e "${GREEN}✓ Contains examples: $has_examples found${NC}"
        score=$((score + 5))
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠ No examples found${NC}"
    fi
    
    # Check for actionable content
    local actionable=$(grep -cE 'Step [0-9]|TODO|FIXME|WARNING|IMPORTANT|Note:|Tip:' "$file" 2>/dev/null || echo 0)
    if [ "$actionable" -gt 0 ]; then
        echo -e "${GREEN}✓ Actionable content: $actionable markers${NC}"
        score=$((score + 5))
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠ Limited actionable content${NC}"
    fi
    
    # Check for metrics/numbers
    local metrics=$(grep -cE '[0-9]+%|[0-9]+ms|[0-9]+s|[0-9]+MB|[0-9]+KB' "$file" 2>/dev/null || echo 0)
    if [ "$metrics" -gt 0 ]; then
        echo -e "${GREEN}✓ Contains metrics: $metrics data points${NC}"
        score=$((score + 5))
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠ No performance metrics found${NC}"
    fi
    
    # Calculate final score
    echo ""
    echo -e "Score: ${BLUE}$score/$max_score${NC}"
    
    # Rating
    if [ "$score" -ge 90 ]; then
        echo -e "Rating: ${GREEN}Excellent ⭐⭐⭐⭐⭐${NC}"
    elif [ "$score" -ge 75 ]; then
        echo -e "Rating: ${GREEN}Good ⭐⭐⭐⭐${NC}"
    elif [ "$score" -ge 60 ]; then
        echo -e "Rating: ${YELLOW}Acceptable ⭐⭐⭐${NC}"
    else
        echo -e "Rating: ${RED}Needs Improvement ⭐⭐${NC}"
    fi
    
    TOTAL_SCORE=$((TOTAL_SCORE + score))
    return 0
}

# Check USER-GUIDE.md
check_documentation_quality \
    "$DOC_PATH/USER-GUIDE.md" \
    500 \
    10 \
    20 \
    15

# Check ISSUES-AND-FIXES.md
check_documentation_quality \
    "$DOC_PATH/ISSUES-AND-FIXES.md" \
    400 \
    15 \
    15 \
    10

# Check DEVELOPMENT-PLAN.md
check_documentation_quality \
    "$DOC_PATH/DEVELOPMENT-PLAN.md" \
    600 \
    20 \
    10 \
    20

# Additional specific checks for each document type
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Specific Quality Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# USER-GUIDE specific checks
if [ -f "$DOC_PATH/USER-GUIDE.md" ]; then
    echo ""
    echo "USER-GUIDE.md Special Checks:"
    
    # Check for installation instructions
    if grep -q "Installation\|installation\|Install\|install" "$DOC_PATH/USER-GUIDE.md"; then
        echo -e "${GREEN}✓ Contains installation instructions${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing installation instructions${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for configuration examples
    if grep -q "Configuration\|configuration\|Config\|config" "$DOC_PATH/USER-GUIDE.md"; then
        echo -e "${GREEN}✓ Contains configuration section${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing configuration section${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for troubleshooting
    if grep -q "Troubleshooting\|troubleshoot\|Common Issues\|Problems" "$DOC_PATH/USER-GUIDE.md"; then
        echo -e "${GREEN}✓ Contains troubleshooting section${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing troubleshooting section${NC}"
        ((CHECKS_FAILED++))
    fi
fi

# ISSUES-AND-FIXES specific checks
if [ -f "$DOC_PATH/ISSUES-AND-FIXES.md" ]; then
    echo ""
    echo "ISSUES-AND-FIXES.md Special Checks:"
    
    # Check for priority levels
    if grep -q "Critical\|High\|Medium\|Low\|Priority" "$DOC_PATH/ISSUES-AND-FIXES.md"; then
        echo -e "${GREEN}✓ Contains priority classifications${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing priority classifications${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for code locations
    if grep -qE "line [0-9]+|Line [0-9]+|:[0-9]+" "$DOC_PATH/ISSUES-AND-FIXES.md"; then
        echo -e "${GREEN}✓ Contains specific line references${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing specific code locations${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for fix examples
    if grep -q "Fix:\|Solution:\|Recommendation:" "$DOC_PATH/ISSUES-AND-FIXES.md"; then
        echo -e "${GREEN}✓ Contains fix recommendations${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing fix recommendations${NC}"
        ((CHECKS_FAILED++))
    fi
fi

# DEVELOPMENT-PLAN specific checks
if [ -f "$DOC_PATH/DEVELOPMENT-PLAN.md" ]; then
    echo ""
    echo "DEVELOPMENT-PLAN.md Special Checks:"
    
    # Check for timeline
    if grep -qE "Week [0-9]|Month [0-9]|Phase [0-9]|Timeline|Schedule" "$DOC_PATH/DEVELOPMENT-PLAN.md"; then
        echo -e "${GREEN}✓ Contains timeline/schedule${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing timeline/schedule${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for resource estimates
    if grep -qE "\$[0-9]+|hours|Hours|days|Days|FTE|Budget" "$DOC_PATH/DEVELOPMENT-PLAN.md"; then
        echo -e "${GREEN}✓ Contains resource estimates${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing resource estimates${NC}"
        ((CHECKS_FAILED++))
    fi
    
    # Check for success metrics
    if grep -q "Success\|Metrics\|KPI\|Goal\|Target" "$DOC_PATH/DEVELOPMENT-PLAN.md"; then
        echo -e "${GREEN}✓ Contains success metrics${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Missing success metrics${NC}"
        ((CHECKS_FAILED++))
    fi
fi

# Final Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Final Quality Report${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

AVERAGE_SCORE=$((TOTAL_SCORE / 3))
TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED))

echo -e "Checks Passed: ${GREEN}$CHECKS_PASSED/$TOTAL_CHECKS${NC}"
echo -e "Average Score: ${BLUE}$AVERAGE_SCORE/100${NC}"

# Overall rating
echo ""
if [ "$AVERAGE_SCORE" -ge 85 ]; then
    echo -e "${GREEN}✅ DOCUMENTATION QUALITY: EXCELLENT${NC}"
    echo "Documentation is comprehensive and production-ready!"
    exit 0
elif [ "$AVERAGE_SCORE" -ge 70 ]; then
    echo -e "${GREEN}✅ DOCUMENTATION QUALITY: GOOD${NC}"
    echo "Documentation is solid with minor improvements needed."
    exit 0
elif [ "$AVERAGE_SCORE" -ge 55 ]; then
    echo -e "${YELLOW}⚠️  DOCUMENTATION QUALITY: ACCEPTABLE${NC}"
    echo "Documentation needs significant improvements."
    exit 1
else
    echo -e "${RED}❌ DOCUMENTATION QUALITY: POOR${NC}"
    echo "Documentation requires major rewrite to be useful."
    exit 1
fi

# Suggestions for improvement
if [ "$CHECKS_FAILED" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Suggestions for Improvement:${NC}"
    echo "1. Add more code examples specific to $PLUGIN_NAME"
    echo "2. Include real metrics and benchmarks from analysis"
    echo "3. Provide concrete fix implementations, not just descriptions"
    echo "4. Add timeline and resource estimates"
    echo "5. Include troubleshooting for actual issues found"
fi