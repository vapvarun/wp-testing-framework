# BuddyNext Testing Framework Documentation

## 🎯 Overview

BuddyNext is a comprehensive **automated testing framework** for BuddyPress-based WordPress themes and plugins. It combines:
- **Runtime scanning** of BuddyPress features
- **AI-powered test generation** using scan data
- **PHPUnit** for unit and integration testing
- **Playwright** for end-to-end testing
- **Visual regression** testing capabilities

## 📁 Project Structure

```
buddynext/
├── tools/                      # Testing tools and utilities
│   ├── ai/                     # AI-powered test generators
│   │   ├── claude-analyze.mjs  # Automatic test plan generator
│   │   └── simple-plan-plus.mjs # Alternative plan generator
│   ├── e2e/                    # End-to-end testing
│   │   ├── playwright.config.ts # Playwright configuration
│   │   └── tests/              # E2E test specs
│   │       ├── sanity.spec.ts  # Basic WordPress tests
│   │       └── interactions.spec.ts # BuddyPress interactions
│   └── scan-bp.sh              # BuddyPress scanner script
│
├── tests/                      # Test files
│   └── phpunit/               # PHPUnit tests
│       ├── Unit/              # Unit tests (no WordPress)
│       │   └── SampleTest.php # Example unit test
│       ├── Integration/       # Integration tests (with WordPress)
│       ├── bootstrap.php      # Bootstrap for integration tests
│       └── bootstrap-unit.php # Bootstrap for unit tests
│
├── wp-content/
│   ├── plugins/
│   │   └── wbcom-dev-tools/   # Scanner plugin
│   │       └── wbcom-dev-tools.php # WP-CLI commands for scanning
│   └── uploads/
│       ├── wbcom-scan/        # Scan output (JSON)
│       │   ├── components.json
│       │   ├── pages.json
│       │   ├── nav.json
│       │   ├── activity-types.json
│       │   ├── xprofile.json
│       │   ├── rest.json
│       │   ├── emails.json
│       │   └── settings.json
│       └── wbcom-plan/        # Generated test plans
│           └── docs/
│               ├── PLAN.yaml
│               ├── BUDDYPRESS-TEST-PLAN.refined.md
│               └── RISKS.md
│
├── vendor/                    # Composer dependencies (PHPUnit, etc.)
├── node_modules/             # NPM dependencies (Playwright, etc.)
├── composer.json             # PHP dependencies
├── composer.lock            # PHP dependency lock file
├── package.json             # Node dependencies and scripts
├── package-lock.json        # Node dependency lock file
├── phpunit.xml              # PHPUnit config for integration tests
├── phpunit-unit.xml         # PHPUnit config for unit tests
└── plan.md                  # This documentation file
```

## 🚀 Quick Start

### Prerequisites
- Local by Flywheel with WordPress site
- Node.js 18+ and npm
- PHP 8.0+ with Composer
- BuddyPress plugin installed

### Initial Setup (One-time)

```bash
# 1. Clone or navigate to your project
cd ~/Local\ Sites/buddynext/app/public

# 2. Install all dependencies
npm run test:install

# 3. Install Playwright browsers
npx playwright install

# 4. Activate BuddyPress components (if not already active)
wp bp component activate members groups activity xprofile friends messages settings notifications

# 5. Activate the scanner plugin
wp plugin activate wbcom-dev-tools
```

## 📋 Complete Testing Workflow

### Step 1: Scan BuddyPress Configuration

```bash
npm run bp:scan
```

This command:
- Runs `tools/scan-bp.sh`
- Uses WP-CLI commands from `wbcom-dev-tools` plugin
- Outputs JSON files to `wp-content/uploads/wbcom-scan/`
- Captures: components, pages, navigation, REST endpoints, emails, settings

### Step 2: Generate Test Plan and Files

```bash
npm run bp:claude
```

This command:
- Reads scan data from `wp-content/uploads/wbcom-scan/`
- Automatically generates without requiring API keys:
  - Test plan YAML (`PLAN.yaml`)
  - Documentation (`BUDDYPRESS-TEST-PLAN.refined.md`)
  - PHPUnit test stubs in `tests/phpunit/Integration/`
  - Playwright specs in `tools/e2e/tests/`
  - Risk assessment (`RISKS.md`)

### Step 3: Run Tests

```bash
# Run all tests
npm test

# Run only unit tests (fast, no WordPress needed)
npm run test:unit

# Run only E2E tests
npm run test:e2e

# Update visual regression snapshots
npm run e2e:update
```

## 🔧 Available NPM Scripts

| Command | Description |
|---------|-------------|
| `npm run bp:scan` | Scan BuddyPress configuration |
| `npm run bp:claude` | Generate test plan and files from scan |
| `npm run bp:plan` | Run scan + generate tests (combines above) |
| `npm run test` | Run all tests (unit + E2E) |
| `npm run test:unit` | Run PHPUnit unit tests only |
| `npm run test:e2e` | Run Playwright E2E tests |
| `npm run e2e:update` | Update Playwright visual snapshots |
| `npm run test:install` | Install all test dependencies |

## 🔧 Available Composer Scripts

| Command | Description |
|---------|-------------|
| `composer test` | Run PHPUnit tests |
| `composer test:unit` | Run unit tests only |
| `composer test:integration` | Run integration tests |
| `composer test:coverage` | Generate code coverage report |

## 🛠️ Component Details

### 1. Scanner Plugin (`wbcom-dev-tools`)

WP-CLI commands that extract BuddyPress runtime data:
- `wp wbcom:bp components` - List all components and status
- `wp wbcom:bp pages` - List BuddyPress pages
- `wp wbcom:bp nav` - List navigation items
- `wp wbcom:bp activity-types` - List activity types
- `wp wbcom:bp xprofile` - List extended profile fields
- `wp wbcom:bp rest` - List REST API endpoints
- `wp wbcom:bp emails` - List email templates
- `wp wbcom:bp settings` - List BuddyPress settings

### 2. Test Generator (`claude-analyze.mjs`)

Automated test generation that:
- Reads JSON scan data
- Analyzes active components and configuration
- Generates comprehensive test coverage
- Creates runnable test stubs
- Identifies configuration risks
- No external API dependencies required

### 3. PHPUnit Testing

Two configurations available:
- **Unit Tests** (`phpunit-unit.xml`): Fast, no WordPress required
- **Integration Tests** (`phpunit.xml`): Full WordPress + BuddyPress environment

### 4. Playwright E2E Testing

Configuration (`tools/e2e/playwright.config.ts`):
- Base URL: `https://buddynext.local`
- Authentication via environment variables
- Visual regression testing enabled
- Screenshots/videos on failure
- Trace recording for debugging

## 🔐 Environment Variables

For E2E testing, set these in your environment or `.env` file:

```bash
# E2E Test Configuration
E2E_BASE_URL=https://buddynext.local
E2E_USER=admin
E2E_PASS=password

# Database for Integration Tests (optional)
WP_TESTS_DB_NAME=wordpress_test
WP_TESTS_DB_USER=root
WP_TESTS_DB_PASS=root
WP_TESTS_DB_HOST=localhost
```

## 🧪 Writing New Tests

### Unit Test Example

```php
// tests/phpunit/Unit/MyComponentTest.php
namespace BuddyNext\Tests\Unit;

use PHPUnit\Framework\TestCase;

class MyComponentTest extends TestCase {
    public function test_something() {
        $this->assertTrue(true);
    }
}
```

### E2E Test Example

```typescript
// tools/e2e/tests/my-feature.spec.ts
import { test, expect } from '@playwright/test';

test('my feature works', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('h1')).toBeVisible();
});
```

## 🐛 Troubleshooting

### Common Issues and Solutions

1. **"WordPress test library not found"**
   - This is normal for unit tests
   - Use `npm run test:unit` for tests without WordPress
   - For integration tests, install WP test library

2. **"No scan data found"**
   - Run `npm run bp:scan` first
   - Check that `wbcom-dev-tools` plugin is active
   - Verify BuddyPress is installed and active

3. **"Playwright browsers not installed"**
   - Run `npx playwright install`
   - May need to install system dependencies

4. **"Composer command not found"**
   - Local includes Composer at: `/Applications/Local.app/Contents/Resources/extraResources/bin/composer/posix/composer`
   - Can alias it: `alias composer="/Applications/Local.app/Contents/Resources/extraResources/bin/composer/posix/composer"`

5. **Empty test generation**
   - Activate BuddyPress components first
   - Run fresh scan after activation
   - Check `wp-content/uploads/wbcom-scan/` for JSON files

## 📊 Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: |
          npm ci
          composer install
          npx playwright install --with-deps
      - name: Run tests
        run: npm test
```

## 🎯 Best Practices

1. **Run scans regularly** - After major changes to capture current state
2. **Review generated tests** - AI-generated tests are starting points
3. **Add custom assertions** - Enhance generated tests with specific checks
4. **Use visual regression** - Catch UI changes with Playwright screenshots
5. **Test in isolation** - Unit tests should not depend on WordPress
6. **Mock external services** - Use Brain/Monkey for WordPress functions
7. **Version control test data** - Commit scan results for history

## 🚦 Testing Strategy

### Test Pyramid
```
         /\
        /E2E\       <- Playwright (few, slow, realistic)
       /------\
      /Integration\ <- PHPUnit with WordPress (some, moderate)
     /------------\
    /   Unit Tests  \ <- PHPUnit without WordPress (many, fast)
   /----------------\
```

### Coverage Goals
- **Unit Tests**: 80% code coverage for utilities and helpers
- **Integration Tests**: Critical BuddyPress component interactions
- **E2E Tests**: User journeys and visual regression
- **Performance Tests**: Page load times under 3 seconds

## 📚 Additional Resources

- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [BuddyPress Developer Docs](https://codex.buddypress.org/developer/)
- [WordPress Testing Documentation](https://make.wordpress.org/core/handbook/testing/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass: `npm test`
5. Submit a pull request

## 📝 License

This testing framework is part of the BuddyNext project and follows the same licensing terms.

---

## Quick Command Reference

```bash
# First-time setup
npm run test:install && npx playwright install

# Daily workflow
npm run bp:plan      # Scan + generate tests
npm test            # Run all tests

# Individual commands
npm run bp:scan     # Scan BuddyPress
npm run bp:claude   # Generate tests
npm run test:unit   # Unit tests only
npm run test:e2e    # E2E tests only

# Maintenance
npm run e2e:update  # Update snapshots
composer update     # Update PHP deps
npm update         # Update Node deps
```

---

**Last Updated**: August 2024
**Version**: 1.0.0
**Maintainer**: BuddyNext Team