# BuddyPress Testing Guide

## 🚀 Quick Start

```bash
# From wp-testing-framework directory
./test-plugin.sh buddypress
```

The framework automatically:
- Creates all necessary folders
- Scans BuddyPress components
- Runs 716+ test methods
- Generates comprehensive reports

## 📊 View Results

```bash
# Open HTML report
open workspace/reports/buddypress/report-*.html

# Check coverage
open workspace/coverage/buddypress/index.html

# View logs
cat workspace/logs/buddypress/*.log
```

## 🎯 Test Types

```bash
# Full test suite (default)
./test-plugin.sh buddypress

# Quick test
./test-plugin.sh buddypress quick

# Security focus
./test-plugin.sh buddypress security

# Performance focus
./test-plugin.sh buddypress performance
```

## 🧪 What Gets Tested

### Core Components
- **Activity Streams** - Posting, commenting, favorites
- **Groups** - Creation, membership, forums
- **Members** - Profiles, directories, connections
- **Messages** - Private messaging, notifications
- **Friends** - Connections, requests, lists
- **Notifications** - Email, on-site notifications

### Extended Features
- **Extended Profiles** - Field groups, visibility
- **Settings** - Privacy, email preferences
- **Blogs** - Multi-site integration
- **Forums** - bbPress integration

## 📁 Generated Structure

```
plugins/buddypress/
├── test-config.json
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── security/
│   └── performance/
├── analysis/
├── models/
└── data/
```

## 📈 Coverage

The framework provides **91.6% coverage** of BuddyPress features:
- 716+ test methods
- All major components
- Security validations
- Performance metrics

## 📚 Full Documentation

See [docs/plugin-guides/buddypress/](docs/plugin-guides/buddypress/) for:
- Detailed implementation plans
- Modernization strategies
- Complete testing guides
- Gap analysis reports

## 💬 Support

- **Repository:** https://github.com/vapvarun/wp-testing-framework/
- **BuddyPress Docs:** https://codex.buddypress.org/