# bbPress Testing Guide

## 🚀 Quick Start (Local WP)

### Step 1: Setup Framework (If not done)
```bash
# Navigate to your Local WP site
cd ~/Local\ Sites/your-site/app/public

# Clone and setup
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh
```

### Step 2: Test bbPress
```bash
# Just one command!
./test-plugin.sh bbpress
```

**That's it!** The framework automatically:
- ✅ Creates all folders
- ✅ Scans bbPress code
- ✅ Runs comprehensive tests
- ✅ Generates HTML report

## 📊 View Results

```bash
# Open beautiful HTML report
open workspace/reports/bbpress/report-*.html

# Check test logs
cat workspace/logs/bbpress/*.log

# View code coverage
open workspace/coverage/bbpress/index.html
```

## 🎯 Test Types

```bash
# Full test suite (default)
./test-plugin.sh bbpress

# Quick test (essentials only)
./test-plugin.sh bbpress quick

# Security focused
./test-plugin.sh bbpress security

# Performance analysis
./test-plugin.sh bbpress performance
```

## 🧪 What Gets Tested

### Core bbPress Components
- **Forums** - Creation, deletion, permissions, hierarchies
- **Topics** - Creation, editing, tags, sticky topics
- **Replies** - Threading, moderation, notifications
- **Users** - Roles (Keymaster, Moderator, Participant)
- **Integration** - WordPress integration, widgets, shortcodes

### Automatic Testing Features
- ✅ **Code Analysis** - PHP/JS/CSS file scanning
- ✅ **Security Checks** - SQL injection, XSS, CSRF
- ✅ **Performance Metrics** - Load times, database queries
- ✅ **Compatibility** - WordPress version compatibility
- ✅ **Best Practices** - Coding standards validation

## 📁 Auto-Generated Structure

When you run `./test-plugin.sh bbpress`, these folders are created:

```
plugins/bbpress/
├── test-config.json       # Configuration (auto-generated)
├── tests/
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   ├── security/         # Security tests
│   └── performance/      # Performance tests
├── analysis/
│   └── scan-results.json # Code analysis results
└── data/                 # Test fixtures

workspace/reports/bbpress/
├── report-*.html         # Visual HTML report
└── coverage/            # Code coverage report
```

## 🔧 Local WP Advantages

With Local WP, you get:
- ✅ **Zero configuration** - Database auto-configured (root/root)
- ✅ **Instant setup** - WP-CLI pre-installed
- ✅ **Perfect URLs** - .local domain works automatically
- ✅ **Quick cloning** - Test on multiple sites easily

## 📈 Sample Test Output

```
🚀 Testing bbPress
==================
✅ Plugin detected: bbPress v2.6.9
✅ Folders created automatically
✅ Scanning: 245 PHP files, 18 JS files, 12 CSS files
✅ Running tests...
   - Unit tests: 156 passed
   - Integration: 89 passed
   - Security: All passed
   - Performance: Optimized
✅ Report generated: workspace/reports/bbpress/report-20240330-143022.html
```

## 🎨 Advanced Testing

### Custom bbPress Tests
Add your own tests in `plugins/bbpress/tests/custom/`:

```php
<?php
class CustomBBPressTest extends PHPUnit\Framework\TestCase {
    public function testForumPermissions() {
        // Your custom test
    }
}
```

### Run Specific Components
```bash
# Test only forums
./vendor/bin/phpunit plugins/bbpress/tests/unit/ForumTest.php

# Test only topics
./vendor/bin/phpunit plugins/bbpress/tests/unit/TopicTest.php
```

### NPM Commands
```bash
npm run test:bbpress:all       # All tests
npm run security:bbpress       # Security only
npm run performance:bbpress    # Performance only
npm run coverage:bbpress       # Coverage report
```

## 🐛 Troubleshooting

### bbPress Not Found?
```bash
# Install bbPress first
wp plugin install bbpress --activate

# Verify installation
wp plugin list | grep bbpress
```

### Tests Not Running?
```bash
# Make sure you're in framework directory
cd wp-testing-framework

# Run setup if needed
./local-wp-setup.sh

# Check permissions
chmod +x test-plugin.sh
```

### Local WP Database Issues?
```bash
# Local WP uses these credentials:
# Username: root
# Password: root
# Database: automatically created
```

## 💡 Pro Tips

1. **Use Local WP** - Everything just works!
2. **One command** - `./test-plugin.sh bbpress` does everything
3. **Check HTML reports** - Best way to view results
4. **Auto-updates** - `git pull origin main` for latest features
5. **Test regularly** - After bbPress updates

## 📚 More Resources

- **Full Documentation:** [docs/plugin-guides/bbpress/](docs/plugin-guides/bbpress/)
- **bbPress Official:** https://bbpress.org/
- **Support:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)

---

**Quick Reminder:** With Local WP, just run `./test-plugin.sh bbpress` - everything else is automatic!