#!/bin/bash

# BuddyPress Comprehensive Test Coverage Report
# Shows what's implemented vs what's needed

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     BuddyPress Comprehensive Test Coverage Report           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if command/tool exists
check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

# Function to check if file/directory exists
check_exists() {
    if [ -e "$1" ]; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

# Function to count files
count_files() {
    if [ -d "$1" ]; then
        find "$1" -name "*.php" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

echo -e "${CYAN}1. Testing Infrastructure${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-40s %s\n" "PHPUnit installed:" "$(check_tool vendor/bin/phpunit)"
printf "%-40s %s\n" "Playwright installed:" "$(check_tool npx playwright)"
printf "%-40s %s\n" "Cypress installed:" "$(check_tool npx cypress)"
printf "%-40s %s\n" "Component test config:" "$(check_exists phpunit-components.xml)"
printf "%-40s %s\n" "E2E test config:" "$(check_exists tools/e2e/playwright.config.ts)"
echo ""

echo -e "${CYAN}2. Test Files Coverage${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
unit_count=$(count_files "tests/phpunit/Components/*/Unit")
integration_count=$(count_files "tests/phpunit/Components/*/Integration")
e2e_count=$(count_files "tools/e2e/tests")
total_tests=$((unit_count + integration_count + e2e_count))

printf "%-40s %d files\n" "Unit Tests:" "$unit_count"
printf "%-40s %d files\n" "Integration Tests:" "$integration_count"
printf "%-40s %d files\n" "E2E Tests:" "$e2e_count"
printf "%-40s %d files\n" "Total Test Files:" "$total_tests"
echo ""

echo -e "${CYAN}3. Component Test Coverage${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
components=("Core" "Members" "XProfile" "Activity" "Groups" "Friends" "Messages" "Notifications" "Settings" "Blogs")
for comp in "${components[@]}"; do
    comp_tests=$(count_files "tests/phpunit/Components/$comp")
    if [ "$comp_tests" -gt 0 ]; then
        status="${GREEN}✅${NC}"
    else
        status="${RED}❌${NC}"
    fi
    printf "%-20s %s (%d tests)\n" "$comp:" "$status" "$comp_tests"
done
echo ""

echo -e "${CYAN}4. Testing Types Implementation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Test Type            Status   Details"
echo -e "──────────────────────────────────────────────────────────────"

# Unit Tests
if [ "$unit_count" -gt 0 ]; then
    echo -e "Unit Tests           ${YELLOW}⚠️${NC}      Partial ($unit_count files)"
else
    echo -e "Unit Tests           ${RED}❌${NC}      Not implemented"
fi

# Integration Tests
if [ "$integration_count" -gt 10 ]; then
    echo -e "Integration Tests    ${GREEN}✅${NC}      Good coverage ($integration_count files)"
elif [ "$integration_count" -gt 0 ]; then
    echo -e "Integration Tests    ${YELLOW}⚠️${NC}      Partial ($integration_count files)"
else
    echo -e "Integration Tests    ${RED}❌${NC}      Not implemented"
fi

# E2E Tests
if [ "$e2e_count" -gt 0 ]; then
    echo -e "E2E Tests           ${YELLOW}⚠️${NC}      Basic ($e2e_count files)"
else
    echo -e "E2E Tests           ${RED}❌${NC}      Not implemented"
fi

# Visual Tests
if [ -f "backstop.json" ]; then
    echo -e "Visual Tests        ${YELLOW}⚠️${NC}      Config exists, not running"
else
    echo -e "Visual Tests        ${RED}❌${NC}      Not configured"
fi

# Performance Tests
if [ -f "tools/performance/k6-config.js" ]; then
    echo -e "Performance Tests   ${GREEN}✅${NC}      Configured"
else
    echo -e "Performance Tests   ${RED}❌${NC}      Not configured"
fi

# Security Tests
security_tests=$(find tests -name "*Security*Test.php" 2>/dev/null | wc -l | tr -d ' ')
if [ "$security_tests" -gt 0 ]; then
    echo -e "Security Tests      ${YELLOW}⚠️${NC}      Basic ($security_tests files)"
else
    echo -e "Security Tests      ${RED}❌${NC}      Not implemented"
fi

# Accessibility Tests
if [ -f "tools/a11y/pa11y-config.js" ]; then
    echo -e "Accessibility Tests ${GREEN}✅${NC}      Configured"
else
    echo -e "Accessibility Tests ${RED}❌${NC}      Not configured"
fi

echo ""

echo -e "${CYAN}5. Test Data & Fixtures${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-40s %s\n" "Demo Data Generator:" "$(check_exists tools/bp-demo-data-generator.php)"
printf "%-40s %s\n" "Test Fixtures:" "$(check_exists tests/fixtures)"
printf "%-40s %s\n" "Factory Classes:" "$(check_exists tests/phpunit/factory)"
printf "%-40s %s\n" "Seed Data:" "$(check_exists tests/data)"
echo ""

echo -e "${CYAN}6. Documentation & Workflow${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-40s %s\n" "Component Testing Guide:" "$(check_exists BUDDYPRESS-COMPONENT-TESTING.md)"
printf "%-40s %s\n" "Coverage Documentation:" "$(check_exists COMPREHENSIVE-TEST-COVERAGE.md)"
printf "%-40s %s\n" "Test Plan:" "$(check_exists plan.md)"
printf "%-40s %s\n" "GitHub Sync Checklist:" "$(check_exists GITHUB-SYNC-CHECKLIST.md)"
echo ""

echo -e "${CYAN}7. Code Flow Documentation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
flows=("registration" "activity-posting" "group-creation" "messaging" "friendship")
for flow in "${flows[@]}"; do
    if [ -f "docs/code-flows/${flow}.md" ]; then
        status="${GREEN}✅${NC}"
    else
        status="${RED}❌${NC}"
    fi
    flow_name=$(echo "$flow" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    printf "%-30s %s\n" "$flow_name Flow:" "$status"
done
echo ""

echo -e "${CYAN}8. Quick Actions Available${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generate demo data:     wp eval-file tools/bp-demo-data-generator.php"
echo "Run component tests:    ./tools/run-component-tests.sh -c members"
echo "View test dashboard:    php tools/component-test-dashboard.php"
echo "Run visual tests:       npx backstop test"
echo "Scan BuddyPress:       bash tools/scan-buddypress.sh"
echo ""

# Calculate overall coverage
implemented=0
total=15

[ "$unit_count" -gt 0 ] && ((implemented++))
[ "$integration_count" -gt 0 ] && ((implemented++))
[ "$e2e_count" -gt 0 ] && ((implemented++))
[ -f "backstop.json" ] && ((implemented++))
[ -f "tools/bp-demo-data-generator.php" ] && ((implemented++))
[ -f "BUDDYPRESS-COMPONENT-TESTING.md" ] && ((implemented++))

percentage=$((implemented * 100 / total))

echo -e "${CYAN}9. Overall Testing Coverage${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "Progress: ["
for i in {1..20}; do
    if [ $i -le $((percentage / 5)) ]; then
        echo -n "█"
    else
        echo -n "░"
    fi
done
echo "] ${percentage}%"
echo ""

echo -e "${YELLOW}📝 Priority Actions Needed:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Generate demo data for testing"
echo "2. Create more unit tests for critical components"
echo "3. Set up visual regression testing with BackstopJS"
echo "4. Document code flows for main features"
echo "5. Implement security and accessibility tests"
echo ""

echo -e "${GREEN}✨ Run 'npm run test:bp:all' to execute all available tests${NC}"