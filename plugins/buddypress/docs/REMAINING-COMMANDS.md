# Remaining BuddyPress Testing Commands

## ✅ Already Completed
1. ✅ Component Code Scan (562KB detailed scan)
2. ✅ Functionality Analysis 
3. ✅ Customer Value Analysis

## 🔄 Commands Still To Run

### 1. Execute Scenario Tests (TRUE/FALSE Results)
```bash
cd /Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework

# Run scenario test executor
node tools/ai/scenario-test-executor.mjs --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json
```
**What it does:** Executes actual tests and provides TRUE/FALSE results with evidence

### 2. Generate AI-Optimized Report (For Claude Code)
```bash
# Generate AI-ready reports for automated fixing
node tools/ai/ai-optimized-reporter.mjs --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json
```
**What it does:** Creates AI-parseable reports for Claude Code to automatically fix issues

### 3. Run Component-Specific PHPUnit Tests
```bash
# Test individual components
npm run test:bp:core        # Core component
npm run test:bp:members     # Members component
npm run test:bp:activity    # Activity streams
npm run test:bp:groups      # Groups
npm run test:bp:friends     # Friends
npm run test:bp:messages    # Private messages
npm run test:bp:xprofile    # Extended profiles
npm run test:bp:settings    # Settings
npm run test:bp:blogs       # Site tracking

# Or test component groups
npm run test:bp:critical    # Core + Members + Activity
npm run test:bp:social      # Groups + Friends + Messages
npm run test:bp:all         # All components
```
**What it does:** Runs unit tests for each BuddyPress component

### 4. Run E2E Tests with Playwright
```bash
# Run all E2E tests
npm run test:e2e

# Run with UI to see tests running
npm run e2e:ui

# Run specific test types
npm run test:security       # Security tests
npm run test:performance    # Performance tests
npm run test:accessibility  # Accessibility tests

# Update visual snapshots if needed
npm run e2e:update
```
**What it does:** Tests user interactions in real browser

### 5. Generate Coverage Reports
```bash
# Component-specific coverage
npm run coverage:bp:core
npm run coverage:bp:members
npm run coverage:bp:activity

# Overall coverage report
npm run coverage:report
```
**What it does:** Shows how much code is covered by tests

### 6. Generate Component Tests from Scan
```bash
# Generate tests based on component scan
node tools/ai/component-test-generator.mjs
```
**What it does:** Creates test files based on the 562KB component scan

### 7. Run Complete Workflow (All-in-One)
```bash
# Or just run everything with one command
./run-buddypress-tests.sh
```
**What it does:** Runs the complete testing workflow automatically

## 📊 Quick Status Check Commands

### Check What's Been Generated
```bash
# List functionality reports
ls -la tests/functionality/buddypress-*.md

# List customer analysis reports  
ls -la reports/customer-analysis/buddypress-*.md

# List AI analysis reports
ls -la reports/ai-analysis/buddypress-*.md

# Check scan data
ls -la ../wp-content/uploads/wbcom-scan/
```

### View Key Reports
```bash
# View functionality report
cat tests/functionality/buddypress-functionality-report.md

# View customer value report
cat reports/customer-analysis/buddypress-customer-value-report.md

# View test execution results
cat reports/execution/buddypress-execution-report.md

# View AI recommendations
cat reports/ai-analysis/buddypress-ai-fix-recommendations.md
```

## 🎯 Recommended Order

For comprehensive BuddyPress testing, run in this order:

```bash
# 1. Execute scenario tests (5 min)
node tools/ai/scenario-test-executor.mjs --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json

# 2. Generate AI report (2 min)
node tools/ai/ai-optimized-reporter.mjs --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json

# 3. Run E2E tests (10 min)
npm run test:e2e

# 4. Run critical component tests (5 min)
npm run test:bp:critical

# 5. Generate coverage report (2 min)
npm run coverage:report
```

## 🚀 One Command to Run Everything

```bash
# This runs ALL remaining tests
./run-buddypress-tests.sh
```

## 📈 Expected Results

After running all commands, you'll have:

1. **Test Execution Results**
   - TRUE/FALSE for each functionality test
   - Pass/Fail for unit tests
   - Screenshots from E2E tests
   - Performance metrics

2. **Coverage Reports**
   - Code coverage percentage
   - Uncovered functions/classes
   - Component-specific coverage

3. **AI-Ready Reports**
   - Issue database with priorities
   - Fix recommendations
   - Implementation guide
   - Decision matrix

4. **Visual Artifacts**
   - E2E test screenshots
   - Performance graphs
   - Coverage charts

## 🔍 Debugging Commands

If something fails:

```bash
# Check PHP version
php -v

# Check Node version
node -v

# Check if BuddyPress is active
wp plugin list | grep buddypress

# Check if dependencies are installed
ls -la vendor/bin/phpunit
ls -la node_modules/.bin/playwright

# View error logs
tail -n 50 workflow.log
```

## 📝 Final Report Generation

After all tests are complete:

```bash
# Generate comprehensive report
cat reports/ai-analysis/buddypress-ai-master-index.md

# This will show:
# - Total tests run
# - Pass/fail rates  
# - Critical issues found
# - Recommended fixes
# - Priority actions
```

## Summary

**Essential commands to complete BuddyPress testing:**

1. `node tools/ai/scenario-test-executor.mjs` - Execute tests
2. `node tools/ai/ai-optimized-reporter.mjs` - Generate AI reports
3. `npm run test:e2e` - Run E2E tests
4. `npm run test:bp:all` - Run all component tests

Or simply run: `./run-buddypress-tests.sh` to do everything!