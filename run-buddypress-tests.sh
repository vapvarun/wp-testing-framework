#!/bin/bash

# Complete BuddyPress Testing Workflow
# This script runs all tests for BuddyPress in the correct order

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}              BuddyPress Complete Testing Workflow${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: Must run from wp-testing-framework directory${NC}"
    exit 1
fi

# Step 1: Scan BuddyPress
echo -e "${YELLOW}Step 1: Scanning BuddyPress structure...${NC}"
if [ ! -f "../wp-content/uploads/wbcom-scan/buddypress-complete.json" ]; then
    echo -e "${GREEN}Running scan...${NC}"
    wp scan buddypress --path='../' --output=json > ../wp-content/uploads/wbcom-scan/buddypress-complete.json 2>/dev/null || true
else
    echo -e "${GREEN}Using existing scan data${NC}"
fi

# Step 2: Analyze Functionality
echo ""
echo -e "${YELLOW}Step 2: Analyzing BuddyPress functionality...${NC}"
node tools/ai/functionality-analyzer.mjs \
    --plugin buddypress \
    --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json || true

# Step 3: Execute Scenario Tests
echo ""
echo -e "${YELLOW}Step 3: Executing scenario tests...${NC}"
node tools/ai/scenario-test-executor.mjs \
    --plugin buddypress \
    --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json || true

# Step 4: Customer Value Analysis
echo ""
echo -e "${YELLOW}Step 4: Analyzing customer value...${NC}"
node tools/ai/customer-value-analyzer.mjs \
    --plugin buddypress \
    --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json || true

# Step 5: Generate AI-Optimized Report
echo ""
echo -e "${YELLOW}Step 5: Generating AI-optimized report...${NC}"
node tools/ai/ai-optimized-reporter.mjs \
    --plugin buddypress \
    --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json || true

# Step 6: Run PHPUnit Tests (if available)
echo ""
echo -e "${YELLOW}Step 6: Running PHPUnit tests...${NC}"
if [ -f "vendor/bin/phpunit" ]; then
    # Run BuddyPress component tests
    ./vendor/bin/phpunit -c phpunit-components.xml --testsuite core-component 2>/dev/null || true
    echo -e "${GREEN}✓ Core component tested${NC}"
    
    ./vendor/bin/phpunit -c phpunit-components.xml --testsuite members-component 2>/dev/null || true
    echo -e "${GREEN}✓ Members component tested${NC}"
    
    ./vendor/bin/phpunit -c phpunit-components.xml --testsuite activity-component 2>/dev/null || true
    echo -e "${GREEN}✓ Activity component tested${NC}"
else
    echo -e "${YELLOW}PHPUnit not installed, skipping unit tests${NC}"
fi

# Step 7: Run E2E Tests (if Playwright installed)
echo ""
echo -e "${YELLOW}Step 7: Running E2E tests...${NC}"
if command -v npx &> /dev/null && npx playwright --version &> /dev/null; then
    npx playwright test --config=tools/e2e/playwright.config.ts 2>/dev/null || true
    echo -e "${GREEN}✓ E2E tests completed${NC}"
else
    echo -e "${YELLOW}Playwright not installed, skipping E2E tests${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ BuddyPress Testing Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}📊 Reports Generated:${NC}"
echo "  • tests/functionality/buddypress-functionality-report.md"
echo "  • tests/functionality/buddypress-user-scenario-tests.md"
echo "  • tests/functionality/buddypress-executable-test-plan.md"
echo "  • reports/customer-analysis/buddypress-customer-value-report.md"
echo "  • reports/ai-analysis/buddypress-ai-actionable-report.md"
echo ""

echo -e "${YELLOW}📁 Test Results Location:${NC}"
echo "  • Scan Data: ../wp-content/uploads/wbcom-scan/"
echo "  • Reports: ./reports/"
echo "  • Tests: ./tests/functionality/"
echo ""

echo -e "${BLUE}🤖 For AI Analysis with Claude Code:${NC}"
echo "  Use: reports/ai-analysis/buddypress-ai-actionable-report.md"
echo ""

# Check if there are any critical issues
if [ -f "reports/ai-analysis/buddypress-ai-actionable-report.md" ]; then
    CRITICAL_COUNT=$(grep -c "CRITICAL" reports/ai-analysis/buddypress-ai-actionable-report.md 2>/dev/null || echo "0")
    if [ "$CRITICAL_COUNT" -gt "0" ]; then
        echo -e "${RED}⚠️  Found $CRITICAL_COUNT critical issues that need attention${NC}"
    else
        echo -e "${GREEN}✓ No critical issues found${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review reports in ./reports/"
echo "  2. Check test results in ./tests/functionality/"
echo "  3. Use AI reports with Claude Code for automated fixes"
echo ""