# BuddyPress Commands Reference - Complete List

## 🎯 Master Commands (Run Everything)

```bash
# Run EVERYTHING - scan, test, analyze, report
npm run universal:buddypress
```

## 📊 WP-CLI Commands (Scanning)

### Component Scanning
```bash
# Scan all components
wp bp scan --component=all

# Scan individual components
wp bp scan --component=xprofile      # Extended profiles
wp bp scan --component=groups        # User groups
wp bp scan --component=activity      # Activity streams
wp bp scan --component=messages      # Private messaging
wp bp scan --component=friends       # Friend connections
wp bp scan --component=members       # Member directory
wp bp scan --component=notifications # User notifications
wp bp scan --component=settings      # User settings
wp bp scan --component=blogs         # Blog tracking

# Advanced scanning
wp bp scan --type=code-flow          # User interaction flows
wp bp scan --type=rest-api           # REST API endpoints
wp bp scan --type=templates          # Template structure
wp bp scan --type=hooks              # Actions and filters
wp bp scan --type=database           # Database schema
```

### Analysis Commands
```bash
# Analyze specific aspects
wp bp analyze --type=security        # Security vulnerabilities
wp bp analyze --type=performance     # Performance bottlenecks
wp bp analyze --type=compatibility   # Plugin conflicts
wp bp analyze --type=queries         # Database queries
wp bp analyze --type=memory          # Memory usage
```

## 🧪 PHPUnit Test Commands

### Unit Tests by Component
```bash
# Test individual components
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/XProfile/XProfileComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Groups/GroupsComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Activity/ActivityComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Messages/MessagesComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Friends/FriendsComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Members/MembersComponentTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Notifications/NotificationsComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Settings/SettingsComprehensiveTest.php
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/Blogs/BlogsComprehensiveTest.php

# Test all unit tests
./vendor/bin/phpunit plugins/buddypress/tests/unit/
```

### Integration Tests
```bash
# Component integration tests
./vendor/bin/phpunit plugins/buddypress/tests/integration/Components/XProfile/
./vendor/bin/phpunit plugins/buddypress/tests/integration/Components/Groups/
./vendor/bin/phpunit plugins/buddypress/tests/integration/Components/Activity/

# Workflow integration tests
./vendor/bin/phpunit plugins/buddypress/tests/integration/Workflows/

# API integration tests
./vendor/bin/phpunit plugins/buddypress/tests/integration/API/BuddyPressRestApiTest.php

# All integration tests
./vendor/bin/phpunit plugins/buddypress/tests/integration/
```

### Security Tests
```bash
# Run all security tests
./vendor/bin/phpunit plugins/buddypress/tests/security/

# Component-specific security
./vendor/bin/phpunit plugins/buddypress/tests/security/ --filter=XProfile
./vendor/bin/phpunit plugins/buddypress/tests/security/ --filter=Groups
./vendor/bin/phpunit plugins/buddypress/tests/security/ --filter=Messages
```

### Functional Tests
```bash
# User flow tests
./vendor/bin/phpunit plugins/buddypress/tests/functional/UserFlows/

# Admin flow tests
./vendor/bin/phpunit plugins/buddypress/tests/functional/AdminFlows/

# Code flow tests
php plugins/buddypress/tests/functional/UserFlows/CodeFlowTest.php
```

## 📦 NPM Commands (Quick Access)

### Testing Commands
```bash
# All tests for BuddyPress
npm run test:buddypress:all

# Specific test types
npm run test:buddypress:unit         # Unit tests only
npm run test:buddypress:integration  # Integration tests
npm run test:buddypress:security     # Security tests
npm run test:buddypress:ux          # UX/Accessibility tests
npm run test:buddypress:modern      # Modern standards tests
```

### Analysis & Reporting
```bash
# Generate reports
npm run report:buddypress           # AI-optimized report
npm run coverage:buddypress         # Coverage report
npm run security:buddypress         # Security scan
npm run performance:buddypress      # Performance profile

# Analyze functionality
npm run analyze:functionality       # Feature analysis
npm run analyze:customer           # Customer value analysis
```

## 🔧 PHP Scanner Commands

### Component Scanners
```bash
# Deep component analysis
php plugins/buddypress/scanners/bp-deep-component-scanner.php

# Code flow analysis
php plugins/buddypress/scanners/bp-code-flow-scanner.php

# REST API parity check
php plugins/buddypress/scanners/bp-rest-api-parity-tester.php

# Template API mapping
php plugins/buddypress/scanners/bp-template-api-mapper.php

# XProfile comprehensive scan
php plugins/buddypress/scanners/bp-xprofile-comprehensive-scanner.php

# Advanced features scan
php plugins/buddypress/scanners/bp-advanced-features-scanner.php
```

### Framework Tools
```bash
# Coverage report
php tools/test-coverage-report.php --plugin=buddypress

# Security scanner
php tools/security-scanner.php --plugin=buddypress

# Performance profiler
php tools/performance-profiler.php --plugin=buddypress

# Component dashboard
php tools/component-test-dashboard.php --plugin=buddypress

# Demo data generator
php tools/bp-demo-data-generator.php --users=50 --groups=10
```

## 🤖 AI-Powered Tools

### Test Generation
```bash
# Generate tests from scan
node tools/ai/universal-test-generator.mjs \
  --plugin=buddypress \
  --component=xprofile

# Component-specific test generation
node tools/ai/component-test-generator.mjs \
  --plugin=buddypress \
  --component=groups \
  --feature=group-types
```

### Analysis Tools
```bash
# Functionality analyzer
node tools/ai/functionality-analyzer.mjs \
  --plugin=buddypress \
  --scan=plugins/buddypress/analysis/scan.json

# Customer value analyzer
node tools/ai/customer-value-analyzer.mjs \
  --plugin=buddypress

# Compatibility checker
node tools/ai/compatibility-checker.mjs \
  --plugin=buddypress

# Scenario test executor
node tools/ai/scenario-test-executor.mjs \
  --plugin=buddypress \
  --scenario=user-registration
```

### Reporting
```bash
# AI-optimized reporter
node tools/ai/ai-optimized-reporter.mjs \
  --plugin=buddypress \
  --format=markdown

# Claude-specific analysis
node tools/ai/claude-analyze.mjs \
  --plugin=buddypress \
  --component=all
```

## 🎭 E2E Testing (Playwright)

```bash
# Run all E2E tests
npm run test:e2e

# Specific E2E tests
npm run test:security      # Security E2E tests
npm run test:performance   # Performance E2E tests
npm run test:accessibility # Accessibility E2E tests

# Interactive mode
npm run e2e:ui             # Open Playwright UI

# Update snapshots
npm run e2e:update         # Update visual snapshots
```

## 🧹 Utility Commands

### Cleanup
```bash
# Clean workspace
npm run clean:workspace

# Clean reports
npm run clean:reports

# Clean coverage
npm run clean:coverage

# Clean everything
npm run clean:all
```

### Setup
```bash
# Initial setup
npm run setup

# Install dependencies
composer install
npm install

# Setup data directories
./src/Bin/setup-data-dirs.sh
```

## 📊 Coverage Commands

### Generate Coverage Reports
```bash
# HTML coverage report
./vendor/bin/phpunit plugins/buddypress/tests/unit/ \
  --coverage-html coverage/buddypress

# Text coverage summary
./vendor/bin/phpunit plugins/buddypress/tests/unit/ \
  --coverage-text

# Component-specific coverage
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/XProfile/ \
  --coverage-html coverage/xprofile
```

## 🔍 Filtering & Specific Tests

### Run Specific Tests
```bash
# By test name
./vendor/bin/phpunit --filter=testProfileFieldCreation

# By component
./vendor/bin/phpunit --filter=XProfile
./vendor/bin/phpunit --filter=Groups

# By test type
./vendor/bin/phpunit --filter=Security
./vendor/bin/phpunit --filter=Performance
./vendor/bin/phpunit --filter=Integration

# Multiple filters
./vendor/bin/phpunit --filter="XProfile.*Field"
```

## 🚀 Quick Start Sequences

### Complete Test Suite
```bash
# 1. Scan everything
wp bp scan --component=all

# 2. Run all tests
npm run test:buddypress:all

# 3. Generate reports
npm run report:buddypress
```

### Component Testing
```bash
# 1. Scan component
wp bp scan --component=xprofile

# 2. Test component
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/XProfile/

# 3. Check coverage
./vendor/bin/phpunit plugins/buddypress/tests/unit/Components/XProfile/ --coverage-text
```

### Security Audit
```bash
# 1. Security scan
php tools/security-scanner.php --plugin=buddypress

# 2. Security tests
npm run test:buddypress:security

# 3. Security report
wp bp analyze --type=security
```

### Performance Check
```bash
# 1. Performance profile
php tools/performance-profiler.php --plugin=buddypress

# 2. Performance tests
npm run test:performance

# 3. Query analysis
wp bp analyze --type=queries
```

## 📈 Monitoring Commands

### Continuous Testing
```bash
# Watch mode (if configured)
./vendor/bin/phpunit --watch plugins/buddypress/tests/

# Scheduled testing
crontab -e
# Add: 0 */6 * * * cd /path && npm run test:buddypress:all
```

### Status Checks
```bash
# Component health
php tools/component-test-dashboard.php --plugin=buddypress

# Test status
./vendor/bin/phpunit plugins/buddypress/tests/ --list-tests

# Coverage status
php tools/test-coverage-report.php --plugin=buddypress --summary
```

## 🎯 Component Test Method Counts

| Component | Command | Test Methods |
|-----------|---------|--------------|
| XProfile | `--filter=XProfile` | 95 methods |
| Groups | `--filter=Groups` | 55 methods |
| Activity | `--filter=Activity` | 40 methods |
| Members | `--filter=Members` | 45 methods |
| Messages | `--filter=Messages` | 35 methods |
| Friends | `--filter=Friends` | 30 methods |
| Notifications | `--filter=Notifications` | 30 methods |
| Settings | `--filter=Settings` | 25 methods |
| Blogs | `--filter=Blogs` | 20 methods |
| Core | `--filter=Core` | 96+ methods |

**Total: 471+ test methods ready to run!**

---

Use these commands to achieve **91.6% test coverage** for BuddyPress! 🚀