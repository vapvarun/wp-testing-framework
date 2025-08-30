# bbPress Testing Setup Guide

## 🚀 Quick Start (Local WP Users - Recommended)

If you're using Local WP, testing bbPress is incredibly simple:

```bash
# 1. Navigate to your Local WP site
cd ~/Local\ Sites/your-site/app/public

# 2. Clone and setup framework (one line!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# 3. Test bbPress (auto-creates everything!)
./test-plugin.sh bbpress
```

**That's it!** No manual folder creation, no configuration needed! 🎉

## 📋 What Happens Automatically

When you run `./test-plugin.sh bbpress`, the framework:

1. ✅ **Creates all folders automatically**
   - `plugins/bbpress/tests/`
   - `plugins/bbpress/data/`
   - `plugins/bbpress/analysis/`
   - `workspace/reports/bbpress/`

2. ✅ **Detects bbPress installation**
   - Checks if bbPress is installed
   - Gets version information
   - Activates if needed

3. ✅ **Scans bbPress code**
   - Counts PHP/JS/CSS files
   - Analyzes code structure
   - Saves analysis results

4. ✅ **Runs comprehensive tests**
   - Unit tests
   - Integration tests
   - Security checks
   - Performance analysis

5. ✅ **Generates HTML report**
   - Beautiful visual report
   - Test results summary
   - Code analysis metrics

## 🎯 Testing Commands

### Basic Testing
```bash
# Full test suite (recommended)
./test-plugin.sh bbpress

# Quick test only
./test-plugin.sh bbpress quick

# Security focused
./test-plugin.sh bbpress security

# Performance focused
./test-plugin.sh bbpress performance
```

### Using NPM
```bash
# Alternative NPM commands
npm run test:plugin bbpress
npm run quick:test bbpress
npm run universal:bbpress
```

## 📊 Finding Your Results

After testing, your results are in:

```bash
# View HTML report
open workspace/reports/bbpress/report-*.html

# Check logs
cat workspace/logs/bbpress/*.log

# View coverage
open workspace/coverage/bbpress/index.html
```

## 🔧 Manual Setup (If Needed)

If you prefer manual setup or are not using Local WP:

### Prerequisites
- bbPress plugin installed and activated
- PHP 8.0+, Node.js 16+
- Composer and WP-CLI installed

### Manual Installation
```bash
# 1. Clone repository
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 2. Install dependencies
composer install
npm install

# 3. Run setup
./fresh-install.sh

# 4. Test bbPress
./test-plugin.sh bbpress
```

## 📁 bbPress Test Structure

After running tests, you'll have:

```
wp-testing-framework/
└── plugins/
    └── bbpress/
        ├── test-config.json      # Auto-generated config
        ├── tests/
        │   ├── unit/            # Unit tests
        │   ├── integration/     # Integration tests
        │   ├── security/        # Security tests
        │   └── performance/     # Performance tests
        ├── data/                # Test fixtures
        ├── analysis/
        │   └── scan-results.json # Code analysis
        └── models/              # Learning models
```

## 🧪 bbPress-Specific Tests

The framework automatically tests bbPress features:

### Forums
- Forum creation/deletion
- Forum permissions
- Forum hierarchies
- Forum subscriptions

### Topics
- Topic creation/editing
- Topic tags
- Topic status changes
- Sticky topics
- Topic subscriptions

### Replies
- Reply creation/editing
- Reply threading
- Reply moderation
- Reply notifications

### Users
- User roles (Keymaster, Moderator, Participant)
- User profiles
- User capabilities
- User statistics

### Integration
- WordPress integration
- Theme compatibility
- Widget functionality
- Shortcode processing

## 🔍 Advanced Testing

### Custom bbPress Tests
Create custom tests in `plugins/bbpress/tests/custom/`:

```php
<?php
// plugins/bbpress/tests/custom/ForumTest.php
namespace WPTestingFramework\Plugins\BBPress\Tests\Custom;

class ForumTest extends \PHPUnit\Framework\TestCase {
    public function testForumCreation() {
        // Your custom test
    }
}
```

### Run Specific Tests
```bash
# Run only forum tests
./vendor/bin/phpunit plugins/bbpress/tests/unit/ForumTest.php

# Run integration tests
./vendor/bin/phpunit plugins/bbpress/tests/integration/

# Run with coverage
./vendor/bin/phpunit --coverage-html workspace/coverage/bbpress/
```

## 📈 Performance Testing

```bash
# Run performance profiling
npm run performance:bbpress

# Check database queries
wp profile stage --all --spotlight

# Memory usage analysis
php tools/performance-profiler.php --plugin bbpress
```

## 🔒 Security Testing

```bash
# Run security scan
npm run security:bbpress

# Check for vulnerabilities
./vendor/bin/psalm plugins/bbpress/

# SQL injection tests
./vendor/bin/phpunit plugins/bbpress/tests/security/SqlInjectionTest.php
```

## 🐛 Troubleshooting

### Common Issues

**bbPress not detected:**
```bash
# Make sure bbPress is installed
wp plugin install bbpress --activate

# Verify installation
wp plugin list | grep bbpress
```

**Tests failing:**
```bash
# Check PHP version
php -v  # Should be 8.0+

# Clear cache
npm run clean
rm -rf vendor node_modules
npm install && composer install
```

**Database errors:**
```bash
# For Local WP (auto-configured)
# Database: root/root
# Host: localhost

# Create test database manually if needed
wp db create sitename_test
```

## 📝 Configuration

### Environment Variables (.env)
```env
# Auto-generated for Local WP
WP_TEST_URL=http://yoursite.local
TEST_DB_NAME=yoursite_test
TEST_DB_USER=root
TEST_DB_PASSWORD=root
```

### Custom Configuration
Edit `plugins/bbpress/test-config.json`:
```json
{
    "plugin": "bbpress",
    "tests": {
        "unit": true,
        "integration": true,
        "security": true,
        "performance": true
    }
}
```

## 📚 Additional Resources

- **Framework Repo:** https://github.com/vapvarun/wp-testing-framework/
- **bbPress Docs:** https://codex.bbpress.org/
- **Local WP Guide:** [LOCAL-WP-QUICK-START.md](LOCAL-WP-QUICK-START.md)
- **General Testing:** [HOW-TO-TEST-ANY-PLUGIN.md](HOW-TO-TEST-ANY-PLUGIN.md)

## 💡 Tips

1. **Use Local WP** - Everything works out of the box
2. **Run `./test-plugin.sh bbpress`** - Handles everything automatically
3. **Check HTML reports** - Visual results in `workspace/reports/bbpress/`
4. **No manual setup** - Folders created automatically
5. **Keep framework updated** - `git pull origin main`

---

**Need help?** Open an issue at [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)