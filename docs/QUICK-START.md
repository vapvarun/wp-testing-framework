# WP Testing Framework - Quick Start Guide

## 🚀 Test Any WordPress Plugin in 5 Minutes

### Prerequisites
- WordPress installation
- Node.js 18+
- Composer
- WP-CLI

### One-Time Setup
```bash
cd wp-testing-framework
./setup.sh
```

## Testing BuddyPress (Complete Example)

### Option 1: Run Everything (Recommended)
```bash
npm run universal:buddypress
```
This runs: scan → analyze → test → report (20 minutes)

### Option 2: Step-by-Step

#### 1. Scan Plugin Structure
```bash
wp wbcom:bp:scan --output=json
```

#### 2. Analyze Functionality
```bash
npm run functionality:analyze
```

#### 3. Run Tests
```bash
npm run test:bp:all
```

#### 4. Generate Reports
```bash
npm run ai:report
```

## Testing Any Other Plugin

### 1. Create Plugin Structure
```bash
# Copy template
cp -r templates/plugin-skeleton plugins/[plugin-name]

# Example for WooCommerce
cp -r templates/plugin-skeleton plugins/woocommerce
```

### 2. Create Scanner
```bash
# Edit plugins/[plugin-name]/scanners/scanner.php
# Use BuddyPress scanner as reference
```

### 3. Run Universal Workflow
```bash
npm run universal:[plugin-name]

# Example
npm run universal:woocommerce
```

## Essential Commands

### Test Execution
```bash
# All tests
npm run test:bp:all

# Specific component
npm run test:bp:xprofile
npm run test:bp:groups
npm run test:bp:messages

# Critical components only
npm run test:bp:critical

# E2E tests
npm run test:e2e
```

### Analysis & Reports
```bash
# Functionality analysis
npm run functionality:analyze

# Customer value
npm run customer:analyze

# AI-optimized report
npm run ai:report

# Coverage report
npm run coverage:report
```

### Utilities
```bash
# Clean workspace
npm run clean

# Rebuild
npm run setup

# Sync to GitHub (permanent data only)
./sync-to-github.sh
```

## Directory Structure

```
wp-testing-framework/
├── src/              # Universal framework code
├── plugins/          # Plugin-specific implementations
│   └── buddypress/   # Complete BuddyPress example
├── reports/          # Generated reports (by plugin)
├── workspace/        # Temporary files (not synced)
└── templates/        # Plugin skeleton
```

## What Gets Tested?

### Automatic Coverage
✅ Component functionality
✅ REST API endpoints
✅ Database operations
✅ User workflows
✅ Security vectors
✅ Performance metrics
✅ Integration points
✅ Error handling

### Report Types Generated
- Customer value analysis
- AI-ready recommendations
- Coverage metrics
- Execution results
- Fix priorities
- Implementation guides

## BuddyPress Results Summary

- **471+ Test Methods** created
- **91.6% Feature Coverage** achieved
- **92.86% REST API Parity** confirmed
- **10/10 Components** tested
- **23 Reports** generated

## Troubleshooting

### If tests fail to run
```bash
# Check dependencies
composer install
npm install

# Verify plugin is active
wp plugin list | grep [plugin-name]

# Check PHPUnit
./vendor/bin/phpunit --version
```

### If no reports generated
```bash
# Ensure directories exist
./bin/setup-data-dirs.sh

# Check permissions
ls -la reports/
ls -la workspace/
```

## Next Steps

1. **Review Reports**: Check `reports/[plugin-name]/` for insights
2. **Use with Claude Code**: Reports are AI-optimized for automated fixes
3. **Extend Coverage**: Add custom tests in `plugins/[plugin-name]/tests/`
4. **Share Results**: Push to GitHub with `./sync-to-github.sh`

---

**Ready to test ANY WordPress plugin with zero global dependencies!**

For detailed documentation, see:
- `/README.md` - Complete framework guide
- `/plugins/buddypress/docs/` - BuddyPress implementation example
- `/MASTER-INDEX.md` - Full architecture documentation