# WordPress Universal Testing Framework

**🚀 Self-contained, portable testing framework for ANY WordPress plugin**

## ✨ Key Features

- **Self-Contained**: All tools, vendor dependencies, and node_modules are inside `wp-testing-framework/`
- **Portable**: Copy the entire folder to any WordPress installation and run `./setup.sh`
- **Universal**: Works with ANY WordPress plugin (BuddyPress as comprehensive model)
- **AI-Ready**: Generates reports optimized for Claude Code automation

## 📦 What's Included

```
wp-testing-framework/
├── vendor/                 # PHP dependencies (PHPUnit, etc.)
├── node_modules/          # Node dependencies (Playwright, etc.)
├── bin/                   # Local wrapper scripts
├── tools/                 # Testing tools & generators
│   ├── ai/               # AI-powered analyzers
│   ├── e2e/              # End-to-end test configs
│   └── universal-workflow.mjs  # Main orchestrator
├── tests/                 # Test suites
│   ├── phpunit/          # PHP unit tests
│   ├── generated/        # Auto-generated tests
│   └── functionality/    # Functionality tests
├── reports/              # Generated reports
├── docs/                 # Documentation
├── setup.sh             # One-command setup
├── package.json         # Node dependencies
└── composer.json        # PHP dependencies
```

## 🚀 Quick Start

### 1. Initial Setup (One Time)

```bash
# From WordPress root, clone or copy wp-testing-framework
cd wp-testing-framework
./setup.sh
```

This installs everything inside `wp-testing-framework/`:
- ✅ npm dependencies → `./node_modules/`
- ✅ Composer dependencies → `./vendor/`
- ✅ Playwright browsers
- ✅ Local tool wrappers → `./bin/`

### 2. Test BuddyPress (or Any Plugin)

```bash
# Full automated workflow
npm run universal:buddypress

# Or test any plugin
npm run universal:full -- --plugin plugin-slug
```

### 3. Run Specific Tests

```bash
# Using local tools (no global dependencies needed)
./vendor/bin/phpunit tests/generated/buddypress/
./bin/test unit
./bin/test bp members
npx playwright test
```

## 🎯 BuddyPress Testing Commands

All commands use the local `./vendor/bin/` tools:

```bash
# Component testing
npm run test:bp:all          # All components
npm run test:bp:members       # Members component
npm run test:bp:groups        # Groups component
npm run test:bp:activity      # Activity streams

# Analysis
npm run functionality:analyze # What BuddyPress DOES
npm run customer:analyze      # Business value analysis
npm run ai:report             # AI-optimized reports
```

## 📊 Generated Reports

All reports are in the framework directory:

```
reports/
├── ai-analysis/           # AI-ready reports for Claude Code
├── customer-analysis/     # Business value & ROI
└── execution/            # Test execution results

tests/
├── generated/            # Auto-generated test suites
└── functionality/        # TRUE/FALSE test results
```

## 🔧 Directory Structure

**Everything is self-contained:**

```bash
# PHP tools
./vendor/bin/phpunit      # PHPUnit (local)
./vendor/bin/composer     # Composer autoloader

# Node tools  
./node_modules/.bin/playwright  # Playwright (local)
./node_modules/.bin/cypress     # Cypress (local)

# Custom wrappers
./bin/test                # Test runner wrapper
./bin/phpunit            # PHPUnit wrapper
```

## 🔄 Development Workflow

### For BuddyNext Development

1. **Work in:** `/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework/`
2. **Scan data:** `../wp-content/uploads/wbcom-scan/`
3. **Run tests:** Against live site at http://buddynext.local/
4. **Sync to GitHub:** `./sync-to-github.sh`

### For New WordPress Sites

1. Copy entire `wp-testing-framework/` folder to WordPress root
2. Run `./setup.sh`
3. Start testing!

## 🛠️ No Global Dependencies Required

**Everything runs from within wp-testing-framework:**

```bash
# Instead of global phpunit:
./vendor/bin/phpunit

# Instead of global playwright:
npx playwright test

# Instead of global wp-cli (still needs system wp-cli):
wp --path="../"
```

## 📝 Configuration

All paths are relative to framework directory:

- **Scan data:** `../wp-content/uploads/wbcom-scan/`
- **WordPress root:** `../`
- **Plugins:** `../wp-content/plugins/`

## 🚨 Requirements

System requirements (installed globally):
- Node.js 18+
- Composer
- WP-CLI
- WordPress installation

Framework handles everything else locally!

## 📋 Complete Command Reference

```bash
# Setup
./setup.sh                     # Install everything locally

# Scanning
npm run scan:bp                # Scan BuddyPress

# Full workflow
npm run universal:buddypress   # Complete BuddyPress testing

# Component tests
npm run test:bp:members        # Test members component
npm run test:bp:all           # Test all components

# Analysis
npm run functionality:analyze  # Functionality analysis
npm run customer:analyze       # Customer value analysis
npm run ai:report             # AI-optimized reports

# Manual testing
./vendor/bin/phpunit          # Run PHPUnit locally
./bin/test unit               # Run unit tests
./bin/test bp members         # Test specific component
```

## 🔄 Portability

To use on a new WordPress site:

1. **Copy entire folder:**
   ```bash
   cp -r wp-testing-framework /path/to/new/wordpress/
   ```

2. **Run setup:**
   ```bash
   cd /path/to/new/wordpress/wp-testing-framework
   ./setup.sh
   ```

3. **Start testing:**
   ```bash
   npm run universal:buddypress
   ```

## 📦 What Makes This Self-Contained?

- ✅ **No global PHP dependencies** - Uses `./vendor/bin/`
- ✅ **No global Node dependencies** - Uses `./node_modules/.bin/`
- ✅ **Portable configuration** - All paths are relative
- ✅ **Single setup command** - `./setup.sh` installs everything
- ✅ **Complete toolchain** - PHPUnit, Playwright, analyzers, generators

---

**Ready to test ANY WordPress plugin with zero global dependencies!** 🚀