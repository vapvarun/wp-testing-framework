# WordPress Testing Framework - Complete Testing Guide

## 🎯 Overview

This comprehensive testing framework provides automated testing capabilities for WordPress and BuddyPress installations, featuring:

- **Unit Testing** with PHPUnit
- **Integration Testing** with WordPress environment
- **End-to-End Testing** with Playwright
- **Security Testing** for vulnerabilities
- **Performance Testing** for optimization
- **Accessibility Testing** with WCAG compliance
- **Visual Regression Testing** with BackstopJS
- **CI/CD Integration** with GitHub Actions

## 📋 Quick Start

### Prerequisites

- **Node.js** 18+ and npm
- **PHP** 8.0+ with Composer
- **WordPress** installation with BuddyPress
- **MySQL/MariaDB** database

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 2. Install dependencies
npm install
composer install

# 3. Install Playwright browsers
npx playwright install --with-deps

# 4. Set up WordPress test environment
bash bin/install-wp-tests.sh wordpress_test root root localhost latest

# 5. Configure environment variables
cp .env.e2e.example .env.e2e
# Edit .env.e2e with your local settings
```

### Environment Configuration

Create `.env.e2e` file:

```bash
# E2E Test Configuration
E2E_BASE_URL=http://your-site.local
E2E_USER=admin
E2E_PASS=password

# Database Configuration (for integration tests)
WP_TESTS_DB_NAME=wordpress_test
WP_TESTS_DB_USER=root
WP_TESTS_DB_PASSWORD=root
WP_TESTS_DB_HOST=localhost
```

## 🧪 Test Types and Usage

### 1. Unit Tests

**Purpose**: Test individual functions and classes in isolation

```bash
# Run all unit tests
npm run test:unit

# Run specific unit test
./vendor/bin/phpunit -c phpunit-unit.xml tests/phpunit/Unit/SampleTest.php

# With coverage
./vendor/bin/phpunit -c phpunit-unit.xml --coverage-html coverage/unit
```

**Writing Unit Tests:**

```php
<?php
namespace BuddyNext\Tests\Unit;

use PHPUnit\Framework\TestCase;

class MyComponentTest extends TestCase 
{
    public function test_function_returns_expected_value()
    {
        $result = my_component_function('input');
        $this->assertEquals('expected', $result);
    }
}
```

### 2. Integration Tests

**Purpose**: Test WordPress and BuddyPress integration

```bash
# Run all integration tests
npm run test:integration

# Run specific component tests
npm run test:bp:members
npm run test:bp:activity
npm run test:bp:groups
```

**Writing Integration Tests:**

```php
<?php
namespace BuddyNext\Tests\Integration;

use BuddyPressTestCase;

class MemberIntegrationTest extends BuddyPressTestCase
{
    public function test_member_creation()
    {
        $user_id = $this->factory->user->create();
        $this->assertIsInt($user_id);
        $this->assertUserExists($user_id);
    }
    
    public function test_activity_creation()
    {
        $activity_id = $this->create_test_activity([
            'content' => 'Test activity content'
        ]);
        
        $this->assertActivityExists($activity_id);
    }
}
```

### 3. End-to-End Tests

**Purpose**: Test complete user workflows in real browser

```bash
# Run all E2E tests
npm run test:e2e

# Run specific test file
npx playwright test tools/e2e/tests/interactions.spec.ts

# Run with UI mode (visual)
npm run e2e:ui

# Update screenshots
npm run e2e:update
```

**Writing E2E Tests:**

```typescript
import { test, expect } from '@playwright/test';

test('user can post activity update', async ({ page }) => {
  await page.goto('/activity');
  
  await page.fill('#whats-new', 'Test activity update');
  await page.click('#aw-whats-new-submit');
  
  await expect(page.locator('.activity-content').first())
    .toContainText('Test activity update');
});
```

### 4. Security Tests

**Purpose**: Identify security vulnerabilities

```bash
# Run security scanner
php tools/security-scanner.php

# Run E2E security tests
npm run test:security

# Manual security check
wp bp security-scan
```

**Security Test Coverage:**
- XSS prevention in forms
- SQL injection protection
- CSRF protection
- File upload security
- Permission checks
- API endpoint security

### 5. Performance Tests

**Purpose**: Measure and optimize performance

```bash
# Run performance tests
npm run test:performance

# Run performance profiler
php tools/performance-profiler.php

# WP-CLI performance test
wp bp performance-test
```

**Performance Metrics:**
- Page load times
- Database query counts
- Memory usage
- Core Web Vitals (LCP, FID, CLS)
- Resource loading optimization

### 6. Accessibility Tests

**Purpose**: Ensure WCAG 2.1 AA compliance

```bash
# Install axe-core for accessibility testing
npm install @axe-core/playwright

# Run accessibility tests
npm run test:accessibility
```

**Accessibility Coverage:**
- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader compatibility
- Color contrast ratios
- Form labeling
- Heading hierarchy

### 7. Visual Regression Tests

**Purpose**: Catch unintended visual changes

```bash
# Generate reference screenshots
npx backstop reference

# Run visual regression tests
npx backstop test

# Approve changes
npx backstop approve
```

## 🔧 Advanced Testing Features

### Component-Based Testing

Test BuddyPress components individually:

```bash
# Test specific components
npm run test:bp:core      # Core functionality
npm run test:bp:members   # Member management
npm run test:bp:activity  # Activity streams
npm run test:bp:groups    # Group functionality
npm run test:bp:friends   # Friend connections
npm run test:bp:messages  # Private messaging
npm run test:bp:xprofile  # Extended profiles
```

### Test Data Management

**Demo Data Generator:**

```bash
# Generate test data
php tools/bp-demo-data-generator.php

# Clean test data
wp bp clean-test-data
```

**Factory Methods (in tests):**

```php
// Create test users
$user_id = $this->factory->user->create();

// Create test activities
$activity_id = $this->create_test_activity();

// Create test groups  
$group_id = $this->create_test_group();

// Create test messages
$message_id = $this->create_test_message();
```

### Custom Test Utilities

**BuddyPressTestCase Methods:**

```php
// Assert component is active
$this->assertBuddyPressComponentActive('activity');

// Assert user capabilities
$this->assertUserCan('bp_moderate', $admin_id);

// Assert data exists
$this->assertActivityExists($activity_id);
$this->assertGroupExists($group_id);

// Cleanup test data
$this->cleanup_buddypress_data();
```

## 📊 Test Coverage and Reporting

### Coverage Reports

```bash
# Generate PHPUnit coverage
./vendor/bin/phpunit -c phpunit.xml --coverage-html coverage/

# Generate component-specific coverage
npm run coverage:bp:members
npm run coverage:bp:activity

# View coverage report
open coverage/index.html
```

### Test Results and Artifacts

**Playwright Test Results:**
- `tools/e2e/test-results/` - Test execution results
- `tools/e2e/playwright-report/` - HTML reports
- Screenshots and videos on failure
- Performance traces for debugging

**PHPUnit Test Results:**
- Console output with detailed results
- Coverage reports in HTML format
- JUnit XML for CI integration

### Performance Monitoring

**Performance Logs:**
- `wp-content/uploads/performance-logs/` - Daily performance logs
- Query analysis and slow query detection
- Memory usage tracking
- Component performance metrics

**Security Scan Results:**
- `wp-content/uploads/security-scan-*.json` - Security scan reports
- Vulnerability assessments
- Configuration security checks
- Remediation recommendations

## 🚀 Continuous Integration

### GitHub Actions Workflow

The framework includes comprehensive CI/CD pipeline:

**Test Matrix:**
- PHP versions: 8.0, 8.1, 8.2
- WordPress versions: 6.3, 6.4, latest
- Browsers: Chrome, Firefox, Safari

**Automated Testing:**
1. **PHP Tests** - Unit and integration tests
2. **E2E Tests** - Cross-browser testing
3. **Security Tests** - Vulnerability scanning
4. **Performance Tests** - Performance benchmarking
5. **Accessibility Tests** - WCAG compliance
6. **Visual Tests** - Screenshot comparisons
7. **Code Quality** - Static analysis

**Triggering CI:**
```bash
# Push to main/develop branches
git push origin main

# Create pull request
gh pr create --title "Feature: New functionality"

# Manual workflow trigger
gh workflow run tests.yml
```

### Local CI Simulation

```bash
# Run full test suite (like CI)
npm run test:full

# Run tests in parallel
npm run test:parallel

# Generate complete report
npm run test:report
```

## 🛠️ Configuration and Customization

### PHPUnit Configuration

**phpunit.xml** - WordPress integration tests:
```xml
<phpunit bootstrap="tests/phpunit/bootstrap-wordpress.php">
  <testsuites>
    <testsuite name="integration">
      <directory>tests/phpunit/Integration</directory>
    </testsuite>
    <testsuite name="security">
      <directory>tests/phpunit/Security</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

**phpunit-unit.xml** - Standalone unit tests:
```xml
<phpunit bootstrap="tests/phpunit/bootstrap-unit.php">
  <testsuites>
    <testsuite name="unit">
      <directory>tests/phpunit/Unit</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

### Playwright Configuration

**playwright.config.ts:**
```typescript
export default defineConfig({
  testDir: './tools/e2e/tests',
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

### BackstopJS Configuration

**backstop.json:**
```json
{
  "scenarios": [
    {
      "label": "Homepage",
      "url": "http://localhost/",
      "viewports": [
        { "label": "phone", "width": 375, "height": 667 },
        { "label": "tablet", "width": 768, "height": 1024 },
        { "label": "desktop", "width": 1280, "height": 800 }
      ]
    }
  ]
}
```

## 📝 Best Practices

### Test Organization

1. **Directory Structure:**
   ```
   tests/
   ├── phpunit/
   │   ├── Unit/           # Isolated unit tests
   │   ├── Integration/    # WordPress integration
   │   ├── Security/       # Security tests
   │   └── includes/       # Test utilities
   └── e2e/
       ├── tests/          # E2E test specs
       └── fixtures/       # Test data
   ```

2. **Naming Conventions:**
   - Test files: `*Test.php` or `*.spec.ts`
   - Test methods: `test_what_it_does()`
   - Test classes: `ComponentNameTest`

3. **Test Data:**
   - Use factories for consistent test data
   - Clean up after each test
   - Use meaningful test data names

### Performance Optimization

1. **Test Speed:**
   - Run unit tests frequently (fast)
   - Run integration tests before commits
   - Run E2E tests in CI only
   - Use test parallelization

2. **Resource Usage:**
   - Clean up test data
   - Use transactions for database tests
   - Mock external services
   - Optimize test queries

### Security Testing

1. **Input Validation:**
   - Test all form inputs
   - Include XSS payloads
   - Test SQL injection vectors
   - Verify CSRF protection

2. **Permission Testing:**
   - Test user capabilities
   - Verify admin-only functions
   - Check API endpoint security
   - Test file upload restrictions

## 🐛 Troubleshooting

### Common Issues

**WordPress Test Environment:**
```bash
# Issue: WordPress test library not found
# Solution: Install test environment
bash bin/install-wp-tests.sh wordpress_test root root localhost latest

# Issue: Database connection failed
# Solution: Check database credentials in .env file
```

**Playwright Issues:**
```bash
# Issue: Browsers not installed
# Solution: Install browsers
npx playwright install --with-deps

# Issue: Tests timing out
# Solution: Increase timeout in config
timeout: 60000  # 60 seconds
```

**BuddyPress Integration:**
```bash
# Issue: BuddyPress not loaded in tests
# Solution: Check bootstrap file loads BuddyPress
tests_add_filter('muplugins_loaded', '_manually_load_buddypress');

# Issue: Database tables not created
# Solution: Run BuddyPress installation
bp_core_install();
```

### Debug Mode

**Enable Debug Logging:**

```bash
# WordPress debug
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);

# Playwright debug
DEBUG=pw:api npx playwright test

# PHPUnit debug  
./vendor/bin/phpunit --debug
```

**Performance Debugging:**

```php
// Enable performance profiler
if (defined('WP_DEBUG') && WP_DEBUG) {
    new BuddyPressPerformanceProfiler();
}
```

## 📚 Resources and Documentation

### Framework Documentation

- [Framework Guide](FRAMEWORK-GUIDE.md) - Architecture overview
- [BuddyPress Component Testing](BUDDYPRESS-COMPONENT-TESTING.md) - Component-specific testing
- [Comprehensive Test Coverage](COMPREHENSIVE-TEST-COVERAGE.md) - Coverage requirements

### External Resources

- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [WordPress Testing Handbook](https://make.wordpress.org/core/handbook/testing/)
- [BuddyPress Developer Documentation](https://codex.buddypress.org/developer/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

### Community

- [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/vapvarun/wp-testing-framework/discussions) - Community support
- [Contributing Guide](CONTRIBUTING.md) - How to contribute

---

## 🎯 Testing Checklist

### Before Committing Code

- [ ] Unit tests pass locally
- [ ] Integration tests pass
- [ ] No security vulnerabilities detected
- [ ] Performance within acceptable limits
- [ ] Accessibility tests pass
- [ ] Visual regression approved

### Before Releasing

- [ ] All CI tests pass
- [ ] Cross-browser E2E tests pass
- [ ] Security audit completed
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Test coverage adequate (>80%)

---

**Last Updated**: August 2024  
**Version**: 3.0.0  
**Maintainer**: WordPress Testing Framework Team