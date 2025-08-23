# BuddyPress Testing Complete Guide

## Quick Start (One Command)

```bash
# Run EVERYTHING for BuddyPress
npm run universal:buddypress
```

This runs the complete workflow: scan → analyze → generate → test → report

## Step-by-Step Commands

### 1. Initial Setup (One Time)

```bash
# Install dependencies
cd /Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework
npm install
composer install

# Setup data directories
./bin/setup-data-dirs.sh

# Install Playwright browsers (for E2E tests)
npx playwright install
```

### 2. Scan BuddyPress

```bash
# Scan BuddyPress structure and features
npm run scan

# OR explicitly for BuddyPress
wp scan buddypress --path='../' --output=json > ../wp-content/uploads/wbcom-scan/buddypress-complete.json
```

### 3. Analyze Functionality (What BuddyPress DOES)

```bash
# Analyze what BuddyPress actually does for users
npm run functionality:analyze

# This creates:
# - tests/functionality/buddypress-functionality-report.md
# - tests/functionality/buddypress-user-scenario-tests.md
```

### 4. Test Execution

```bash
# Execute functionality tests (TRUE/FALSE results)
npm run functionality:test

# This creates:
# - tests/functionality/buddypress-executable-test-plan.md
# - Real test execution with evidence
```

### 5. Customer Value Analysis

```bash
# Analyze business value and ROI
npm run customer:analyze

# This creates:
# - reports/customer-analysis/buddypress-customer-value-report.md
# - reports/customer-analysis/buddypress-improvement-roadmap.md
```

### 6. AI-Optimized Report (For Claude Code)

```bash
# Generate AI-ready report for automated fixes
npm run ai:report

# This creates:
# - reports/ai-analysis/buddypress-ai-actionable-report.md
# - reports/ai-analysis/buddypress-ai-fix-recommendations.md
```

## Component-Specific Testing

### Test Individual BuddyPress Components

```bash
# Core Component
npm run test:bp:core

# Members Component
npm run test:bp:members

# Activity Streams
npm run test:bp:activity

# Groups
npm run test:bp:groups

# Friends
npm run test:bp:friends

# Private Messages
npm run test:bp:messages

# Notifications
npm run test:bp:notifications

# Extended Profiles
npm run test:bp:xprofile

# Settings
npm run test:bp:settings
```

### Test Component Groups

```bash
# Critical Components (Core, Members, Activity)
npm run test:bp:critical

# Social Components (Groups, Friends, Messages)
npm run test:bp:social

# Management Components (Settings, Notifications)
npm run test:bp:management

# All Components
npm run test:bp:all
```

## E2E Testing

```bash
# Run all E2E tests
npm run test:e2e

# Run with UI mode (see tests running)
npm run e2e:ui

# Specific E2E test types
npm run test:security      # Security tests
npm run test:performance   # Performance tests
npm run test:accessibility # Accessibility tests
```

## Coverage Reports

```bash
# Generate coverage for specific component
npm run coverage:bp:core
npm run coverage:bp:members
npm run coverage:bp:activity

# Generate overall coverage report
npm run coverage:report
```

## Complete Test Suite

```bash
# Run ALL tests (unit, integration, e2e, security, performance, accessibility)
npm run test:full
```

## Current BuddyPress Test Status

### ✅ What's Ready:
1. **Scan Data**: Complete BuddyPress structure scanned
2. **Learning Models**: BuddyPress patterns configured
3. **Test Templates**: Functionality test templates ready
4. **Component Tests**: All 10 components have tests
5. **E2E Tests**: Visual regression snapshots captured

### 📊 Expected Results:
- **Functionality Tests**: User flows, data operations, API endpoints
- **Security Tests**: SQL injection, XSS, CSRF protection
- **Performance Tests**: Load times, query optimization
- **Compatibility Tests**: WordPress versions, PHP versions

### 📁 Where Results Are Saved:

```
/wp-content/uploads/wbcom-scan/
├── buddypress-complete.json     # Scan data
├── buddypress/
│   ├── test-results/            # Test execution results
│   └── reports/                 # Analysis reports

/wp-testing-framework/
├── reports/
│   ├── ai-analysis/            # AI-ready reports
│   └── customer-analysis/      # Business value reports
└── tests/functionality/         # Functionality test files
```

## Workflow for Complete Testing

```bash
# 1. Clean start
npm run clean

# 2. Setup
npm run setup

# 3. Full BuddyPress test
npm run universal:buddypress

# 4. View results
cat reports/ai-analysis/buddypress-ai-actionable-report.md
```

## Using Results with Claude Code

After running tests, use the AI-optimized reports:

```bash
# The reports are formatted for Claude Code to:
# 1. Understand issues
# 2. Generate fixes
# 3. Apply patches
# 4. Verify solutions

# Example Claude Code command:
# "Analyze reports/ai-analysis/buddypress-ai-actionable-report.md and fix critical issues"
```

## Troubleshooting

### If scan fails:
```bash
# Check BuddyPress is active
wp plugin list | grep buddypress

# Manually create scan
wp wbcom:bp:scan
```

### If tests fail to run:
```bash
# Check dependencies
composer install
npm install

# Check PHPUnit
./vendor/bin/phpunit --version

# Check Playwright
npx playwright --version
```

### If no results generated:
```bash
# Check directories exist
ls -la ../wp-content/uploads/wbcom-scan/
ls -la ../wp-content/uploads/wbcom-plan/

# Re-run setup
./bin/setup-data-dirs.sh
```

## Summary

For complete BuddyPress testing, just run:

```bash
npm run universal:buddypress
```

This will:
1. ✅ Scan BuddyPress structure
2. ✅ Analyze functionality (what it DOES)
3. ✅ Generate test cases
4. ✅ Execute tests (TRUE/FALSE)
5. ✅ Analyze customer value
6. ✅ Generate AI-ready reports
7. ✅ Provide fix recommendations

All results will be ready for Claude Code to analyze and fix automatically!