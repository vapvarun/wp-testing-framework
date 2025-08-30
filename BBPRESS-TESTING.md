# bbPress Testing Guide

## 🚀 Quick Start

```bash
# From wp-testing-framework directory
./test-plugin.sh bbpress
```

That's it! The framework automatically:
- Creates all necessary folders
- Scans bbPress code
- Runs comprehensive tests
- Generates HTML report

## 📊 View Results

```bash
# Open HTML report
open workspace/reports/bbpress/report-*.html

# Check logs
cat workspace/logs/bbpress/*.log
```

## 🎯 Test Types

```bash
# Full test suite (default)
./test-plugin.sh bbpress

# Quick test
./test-plugin.sh bbpress quick

# Security focus
./test-plugin.sh bbpress security

# Performance focus
./test-plugin.sh bbpress performance
```

## 🧪 What Gets Tested

### Forums
- Creation, deletion, permissions
- Hierarchies and subscriptions

### Topics
- Creation, editing, tags
- Sticky topics, status changes

### Replies
- Threading, moderation
- Notifications

### Users
- Roles (Keymaster, Moderator, Participant)
- Profiles and capabilities

## 📁 Generated Structure

```
plugins/bbpress/
├── test-config.json
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── security/
│   └── performance/
├── analysis/
└── data/
```

## 📚 Full Documentation

See [docs/plugin-guides/bbpress/](docs/plugin-guides/bbpress/) for detailed guides.

## 💬 Support

- **Repository:** https://github.com/vapvarun/wp-testing-framework/
- **bbPress Docs:** https://codex.bbpress.org/