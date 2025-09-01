# WordPress Testing Framework - Directory Structure

## Framework Directory (wp-testing-framework/)
**This directory contains ONLY the testing tools and scripts**

```
wp-testing-framework/
├── bash-modules/          # Bash modules for testing
│   ├── phases/           # 12 analysis phases
│   │   ├── phase-01-setup.sh
│   │   ├── phase-02-detection.sh
│   │   ├── phase-02-detection-enhanced.sh
│   │   ├── phase-03-ai-analysis.sh
│   │   ├── phase-04-security.sh
│   │   ├── phase-05-performance.sh
│   │   ├── phase-06-test-generation.sh
│   │   ├── phase-07-visual-testing.sh
│   │   ├── phase-08-integration.sh
│   │   ├── phase-09-documentation.sh
│   │   ├── phase-10-consolidation.sh
│   │   ├── phase-10-consolidation-enhanced.sh
│   │   ├── phase-11-live-testing.sh
│   │   └── phase-12-safekeeping.sh
│   └── shared/           # Shared functions and utilities
│       ├── common-functions.sh
│       ├── advanced-analysis.sh
│       └── ai-helpers.sh
├── tools/                # Analysis tools
│   ├── ast-analyzer.js  # AST analysis for PHP/JS
│   ├── security-scanner.php
│   └── performance-analyzer.php
├── config/               # Configuration files
│   └── default.conf
├── docs/                 # Documentation
│   └── *.md
├── tests/                # Framework tests (not plugin tests)
├── src/                  # Source code for tools
├── composer.json         # PHP dependencies
├── package.json          # Node dependencies
├── test-plugin.sh        # Main test runner
├── run-phase.sh          # Phase runner
├── setup.sh              # Framework setup
└── README.md            # Framework documentation
```

## Data Directory (wp-content/uploads/wbcom-scan/)
**All scan results, reports, and archives are stored here**

```
wp-content/uploads/wbcom-scan/
└── [plugin-name]/
    ├── 2025-08/                    # Monthly scan directory
    │   ├── reports/                # All analysis reports
    │   │   ├── functionality-report.md
    │   │   ├── security-report.md
    │   │   ├── performance-report.md
    │   │   ├── integration-report.md
    │   │   ├── test-generation-report.md
    │   │   ├── documentation-report.md
    │   │   ├── live-testing-report.md
    │   │   ├── safekeeping-report.md
    │   │   └── MASTER-REPORT.md
    │   ├── analysis-requests/      # AI analysis prompts
    │   │   ├── phase-2-detection.md
    │   │   ├── phase-3-ai-analysis.md
    │   │   ├── phase-4-security.md
    │   │   ├── phase-6-test-generation.md
    │   │   └── phase-9-ai-documentation.md
    │   ├── documentation/          # Generated documentation
    │   │   ├── USER-GUIDE.md
    │   │   ├── DEVELOPER-GUIDE.md
    │   │   ├── API-REFERENCE.md
    │   │   ├── ISSUES-AND-FIXES.md
    │   │   └── FUTURE-ROADMAP.md
    │   ├── generated-tests/        # Generated test files
    │   │   └── *.php
    │   ├── screenshots/            # Visual testing screenshots
    │   │   └── *.png
    │   ├── raw-outputs/            # Raw analysis outputs
    │   │   ├── detected-hooks.txt
    │   │   ├── complexity-analysis.txt
    │   │   └── coverage/
    │   ├── wordpress-ast-analysis.json  # AST analysis data
    │   ├── extracted-features.json      # Extracted features
    │   ├── detection-results.json       # Detection results
    │   ├── aggregated-analysis.json     # Aggregated analysis
    │   ├── summary.json                 # Quick summary
    │   └── scan-info.json              # Scan metadata
    ├── archives/                    # Historical archives
    │   ├── bbpress_20250901_000735.tar.gz
    │   └── scan-metadata-*.json
    └── history/                     # Scan history
        └── scan-history.json

```

## Plans Directory (wp-content/uploads/wbcom-plan/)
**Future enhancement plans and roadmaps**

```
wp-content/uploads/wbcom-plan/
└── [plugin-name]/
    ├── enhancement-plan.md
    ├── security-fixes.md
    ├── performance-optimizations.md
    └── feature-roadmap.md
```

## Key Principles

1. **wp-testing-framework/** - Contains ONLY tools and scripts
   - No scan results
   - No reports
   - No archives
   - No plugin-specific data

2. **wbcom-scan/** - Contains ALL scan outputs
   - All reports
   - All test results
   - All archives
   - All historical data

3. **wbcom-plan/** - Contains future plans
   - Enhancement plans
   - Roadmaps
   - Fix schedules

## Benefits of This Structure

1. **Clean Separation**: Tools vs Data
2. **Version Control**: Framework can be versioned without data
3. **Multi-Plugin Support**: Each plugin has its own data directory
4. **Historical Tracking**: Monthly directories preserve history
5. **Easy Cleanup**: Can delete old scans without affecting tools
6. **Portable Framework**: Can copy framework without data
7. **Clear Organization**: Know exactly where to find things