# WP Testing Framework - Documentation Index

## 📁 Documentation Structure

```
docs/
├── README.md                  # This index
├── QUICK-START.md            # 5-minute quick start
├── MASTER-INDEX.md           # Complete framework index
├── framework/                # Framework documentation
│   └── FRAMEWORK-GUIDE.md    # Core framework guide
├── architecture/             # Architecture & design
│   ├── FRAMEWORK-STRUCTURE.md
│   ├── FILE-INDEX.md
│   ├── RESTRUCTURE-REPORT.md
│   └── SCAN-SUMMARY.md
├── guides/                   # User guides
│   ├── UNIVERSAL-TESTING-GUIDE.md
│   ├── TESTING-GUIDE.md
│   └── REPORT-ORGANIZATION.md
└── api/                      # API documentation
```

## 🔌 Plugin Documentation

Each plugin has its own documentation:

```
plugins/
└── [plugin-name]/
    └── docs/
        ├── README.md         # Plugin test overview
        ├── TESTING-GUIDE.md  # How to test this plugin
        └── ...
```

### BuddyPress Documentation

Complete example implementation:

- [BuddyPress Testing Guide](/plugins/buddypress/docs/TESTING-GUIDE.md)
- [Component Testing](/plugins/buddypress/docs/COMPONENT-TESTING.md)
- [Test Coverage Report](/plugins/buddypress/docs/TEST-COVERAGE.md)
- [Testing Summary](/plugins/buddypress/docs/TESTING-SUMMARY.md)

## 📖 Quick Links

### Getting Started
1. [Quick Start Guide](QUICK-START.md) - Test any plugin in 5 minutes
2. [Framework Guide](framework/FRAMEWORK-GUIDE.md) - Understanding the framework
3. [Universal Testing](guides/UNIVERSAL-TESTING-GUIDE.md) - Testing methodology

### Architecture
1. [Framework Structure](architecture/FRAMEWORK-STRUCTURE.md) - Directory layout
2. [File Index](architecture/FILE-INDEX.md) - Complete file listing
3. [Master Index](MASTER-INDEX.md) - Everything about the framework

### For Developers
1. [Testing Guide](guides/TESTING-GUIDE.md) - How to write tests
2. [Report Organization](guides/REPORT-ORGANIZATION.md) - Report structure
3. [Plugin Template](/templates/plugin-skeleton/docs/README.md) - Starting template

## 🎯 Documentation Standards

### Framework Documentation
- Location: `/docs/`
- Purpose: Universal framework documentation
- Audience: All users

### Plugin Documentation
- Location: `/plugins/[plugin-name]/docs/`
- Purpose: Plugin-specific guides and reports
- Audience: Plugin testers

### Report Files
- Location: `/reports/[plugin-name]/`
- Purpose: Generated test reports
- Format: Markdown and JSON

---

*Documentation organized for 100+ plugin scalability*
