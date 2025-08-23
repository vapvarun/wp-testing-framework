# WordPress Universal Testing Framework

[![CI](https://github.com/yourusername/wp-testing-framework/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/wp-testing-framework/actions/workflows/ci.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![PHP Version](https://img.shields.io/badge/PHP-%3E%3D8.0-8892BF.svg)](https://php.net)
[![Node Version](https://img.shields.io/badge/Node-%3E%3D18.0-339933.svg)](https://nodejs.org)
[![WordPress Compatible](https://img.shields.io/badge/WordPress-%3E%3D6.0-21759B.svg)](https://wordpress.org)

A comprehensive, automated testing framework for **ANY** WordPress plugin or theme. No API keys required, works with any WordPress extension!

## 🚀 Features

- **Universal Scanner**: Works with any WordPress plugin or theme
- **Automatic Test Generation**: Creates PHPUnit, Playwright, and Cypress tests
- **Zero Configuration**: No API keys or external services needed
- **Comprehensive Detection**: Finds hooks, shortcodes, REST routes, blocks, and more
- **Multiple Test Frameworks**: PHPUnit, Playwright, Cypress, Brain Monkey
- **CI/CD Ready**: GitHub Actions, GitLab CI, Jenkins compatible

## 📦 What It Scans

The framework automatically detects and generates tests for:

- ✅ WordPress Hooks (actions & filters)
- ✅ Shortcodes
- ✅ AJAX Endpoints
- ✅ REST API Routes
- ✅ Gutenberg Blocks
- ✅ Custom Post Types
- ✅ Taxonomies
- ✅ Admin Pages
- ✅ Database Tables
- ✅ Widgets
- ✅ Theme Templates
- ✅ Customizer Settings

## 🎯 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/wp-testing-framework.git
cd wp-testing-framework

# Run the installer in your WordPress directory
bash install-wp-testing-framework.sh
```

### Interactive Mode

Just run the installer without arguments:

```bash
bash install-wp-testing-framework.sh
```

### Command Line Mode

Test a specific plugin:

```bash
bash install-wp-testing-framework.sh --plugin woocommerce --name "WooCommerce Tests"
```

Test a theme:

```bash
bash install-wp-testing-framework.sh --theme twentytwentyfour --name "Twenty Twenty-Four Tests"
```

## 📋 Usage Examples

### Popular Plugins

#### WooCommerce
```bash
bash install-wp-testing-framework.sh --plugin woocommerce --name "WooCommerce"
# Generates tests for: products, orders, cart, checkout, payment gateways, REST API
```

#### Elementor
```bash
bash install-wp-testing-framework.sh --plugin elementor --name "Elementor"
# Generates tests for: widgets, editor, templates, dynamic content, controls
```

#### Contact Form 7
```bash
bash install-wp-testing-framework.sh --plugin contact-form-7 --name "CF7"
# Generates tests for: forms, submissions, mail, validation, tags
```

#### Yoast SEO
```bash
bash install-wp-testing-framework.sh --plugin wordpress-seo --name "Yoast"
# Generates tests for: meta tags, sitemaps, schema, redirects, breadcrumbs
```

### Custom Development

```bash
# Your custom plugin
bash install-wp-testing-framework.sh --plugin my-awesome-plugin --name "My Plugin"

# Your custom theme
bash install-wp-testing-framework.sh --theme my-theme --name "My Theme"
```

## 🏗️ Project Structure

After installation, you'll have:

```
your-wordpress-site/
├── tools/
│   ├── scanners/              # WordPress scanners
│   │   └── scan-wp.sh         # Main scanner script
│   ├── ai/                    # Test generators
│   │   └── generate-tests.mjs # Automatic test generation
│   └── e2e/                   # E2E configuration
│       ├── playwright.config.ts
│       └── tests/
├── tests/
│   ├── phpunit/              # PHP tests
│   │   ├── Unit/             # Unit tests (no WordPress)
│   │   ├── Integration/      # Integration tests (with WordPress)
│   │   └── Functional/       # Functional tests
│   ├── cypress/              # Cypress E2E tests
│   │   ├── integration/
│   │   └── support/
│   └── playwright/           # Playwright tests
├── wp-content/
│   ├── plugins/
│   │   └── wbcom-universal-scanner/  # Scanner plugin
│   └── uploads/
│       ├── wp-scan/          # Scan results (JSON)
│       └── wp-test-plan/     # Generated test plans
│           └── docs/         # Documentation
├── composer.json             # PHP dependencies
├── package.json             # Node dependencies
├── phpunit.xml              # PHPUnit configuration
└── cypress.config.js        # Cypress configuration
```

## 🧪 Available Commands

After installation, use these npm scripts:

```bash
# Scanning
npm run scan                 # Scan your plugin/theme

# Test Generation
npm run generate             # Generate tests from scan
npm run test:plan           # Scan + Generate (one command)

# Testing
npm test                    # Run all tests
npm run test:unit          # PHPUnit unit tests only
npm run test:integration  # Integration tests
npm run test:functional    # Functional tests
npm run test:e2e          # Playwright E2E tests
npm run test:cypress      # Cypress tests

# Utilities
npm run e2e:ui            # Playwright UI mode
npm run cypress:open      # Cypress interactive mode
npm run test:coverage     # Generate coverage report
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in your project root:

```env
# E2E Test Configuration
E2E_BASE_URL=http://localhost:8080
E2E_USER=admin
E2E_PASS=password

# Database for Integration Tests
WP_TESTS_DB_NAME=wordpress_test
WP_TESTS_DB_USER=root
WP_TESTS_DB_PASS=root
WP_TESTS_DB_HOST=localhost

# Cypress Configuration
CYPRESS_BASE_URL=http://localhost:8080
```

## 📊 What Gets Generated

The framework automatically creates:

### 1. Test Files
- **PHPUnit Tests**: Unit, Integration, and Functional tests
- **Playwright Tests**: Modern E2E tests with multiple browsers
- **Cypress Tests**: Alternative E2E framework tests

### 2. Documentation
- `TEST-PLAN.yaml`: Structured test plan
- `TEST-PLAN.md`: Human-readable test documentation
- `RISKS.md`: Identified testing risks and recommendations

### 3. Coverage Areas
- Hook testing (actions/filters)
- Shortcode rendering
- AJAX endpoint validation
- REST API testing
- Block editor components
- Admin interface testing
- Database operations
- Frontend rendering

## 🚦 CI/CD Integration

### GitHub Actions

The framework includes a ready-to-use GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm run setup
      - run: npm test
```

### GitLab CI

```yaml
test:
  script:
    - npm run setup
    - npm test
  artifacts:
    reports:
      junit: test-results/junit.xml
```

## 📈 Examples of Generated Tests

### PHPUnit Test Example

```php
class WooCommerceIntegrationTest extends WP_UnitTestCase {
    public function test_plugin_is_active() {
        $this->assertTrue(is_plugin_active('woocommerce/woocommerce.php'));
    }
    
    public function test_product_creation() {
        $product = WC_Helper_Product::create_simple_product();
        $this->assertInstanceOf('WC_Product', $product);
    }
}
```

### Playwright Test Example

```typescript
test('should complete checkout process', async ({ page }) => {
    await page.goto('/shop');
    await page.click('.add_to_cart_button');
    await page.goto('/checkout');
    await page.fill('#billing_first_name', 'John');
    // ... more checkout steps
    await expect(page.locator('.order-received')).toBeVisible();
});
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Framework Guide](docs/FRAMEWORK-GUIDE.md)
- [API Reference](docs/API.md)
- [Examples](examples/)
- [FAQ](docs/FAQ.md)

## 🛟 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/wp-testing-framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/wp-testing-framework/discussions)
- **Wiki**: [Project Wiki](https://github.com/yourusername/wp-testing-framework/wiki)

## 📝 License

This project is licensed under the GPL v2 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- WordPress Core Team
- PHPUnit Team
- Playwright Team
- Cypress Team
- Brain Monkey Team
- All WordPress plugin and theme developers

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/wp-testing-framework&type=Date)](https://star-history.com/#yourusername/wp-testing-framework&Date)

---

**Built with ❤️ for the WordPress community**