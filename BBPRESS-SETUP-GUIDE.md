# bbPress Testing Setup Guide

## Prerequisites
- bbPress plugin installed and activated in WordPress
- WP Testing Framework cloned to your WordPress installation
- Node.js (v16+) and npm installed
- PHP (8.0+) and Composer installed
- WP-CLI installed

## Setup Commands

### 1. Initial Framework Setup (One-Time)

```bash
# Navigate to the testing framework directory
cd wp-testing-framework

# Install dependencies
composer install
npm install

# Run the setup script
./setup.sh
```

### 2. Create bbPress Plugin Structure

```bash
# Create bbPress plugin directory
mkdir -p plugins/bbpress
mkdir -p plugins/bbpress/data
mkdir -p plugins/bbpress/tests
mkdir -p plugins/bbpress/scanners
mkdir -p plugins/bbpress/models
mkdir -p plugins/bbpress/analysis
```

### 3. Scan bbPress Plugin

```bash
# Deep scan bbPress structure
wp plugin scan bbpress --type=components

# Analyze bbPress codebase
wp plugin analyze bbpress --output=plugins/bbpress/analysis/

# Generate test structure
wp plugin generate-tests bbpress --output=plugins/bbpress/tests/
```

### 4. Run All Tests

```bash
# Quick test (all tests in one command)
npm run universal:bbpress

# Or run individual test types:

# Unit tests
npm run test:unit bbpress

# Integration tests  
npm run test:integration bbpress

# Functional tests
npm run test:functional bbpress

# Security tests
npm run test:security bbpress

# Performance tests
npm run test:performance bbpress
```

### 5. Alternative: Use PHP Commands

```bash
# Run PHPUnit tests
./vendor/bin/phpunit --configuration phpunit.xml --testsuite bbpress

# Run code quality checks
./vendor/bin/phpcs ../wp-content/plugins/bbpress
./vendor/bin/phpstan analyze ../wp-content/plugins/bbpress

# Run security audit
./vendor/bin/psalm ../wp-content/plugins/bbpress
```

### 6. Generate Reports

```bash
# Generate comprehensive report
npm run report:bbpress

# View test coverage
npm run coverage:bbpress

# Export results
npm run export:bbpress --format=html --output=workspace/reports/bbpress/
```

## Configuration Files

### Create bbpress test configuration (if needed)

```bash
# Create phpunit configuration for bbPress
cp phpunit.xml phpunit-bbpress.xml
# Edit to point to bbPress test directory

# Create npm script in package.json
# Add: "universal:bbpress": "npm run test:all -- --plugin=bbpress"
```

## Troubleshooting

### If commands fail:

1. **Check bbPress is installed:**
   ```bash
   wp plugin list | grep bbpress
   ```

2. **Verify framework setup:**
   ```bash
   ./setup.sh --verify
   ```

3. **Check dependencies:**
   ```bash
   composer diagnose
   npm doctor
   ```

4. **Manual test run:**
   ```bash
   # Direct PHPUnit execution
   php ./vendor/bin/phpunit tests/functionality/bbpress-functionality-tests.php
   ```

## Next Steps

1. Review generated test results in `workspace/reports/bbpress/`
2. Check code coverage in `workspace/coverage/bbpress/`
3. Implement custom tests in `plugins/bbpress/tests/`
4. Add bbPress-specific scanners in `plugins/bbpress/scanners/`

## Quick Reference

| Command | Purpose |
|---------|---------|
| `npm run universal:bbpress` | Run all tests |
| `wp plugin scan bbpress` | Scan plugin structure |
| `npm run test:unit bbpress` | Run unit tests |
| `npm run report:bbpress` | Generate reports |
| `./setup.sh` | Initial setup |

## Support

- Framework issues: Check `workspace/logs/`
- Test failures: Review `workspace/reports/bbpress/`
- Configuration: See `config/` directory