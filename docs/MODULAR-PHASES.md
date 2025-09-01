# Modular Phase System Documentation

## Overview

The WP Testing Framework uses a **fully modular architecture** where each of the 12 phases can be run independently. This allows for targeted analysis, debugging, and custom workflows.

## Progressive Data Flow

Each phase builds on the previous phases' data without repeating work:

```
Phase 1 (Setup) → scan-info.json
    ↓
Phase 2 (Detection) → extracted-features.json (500+ functions, classes, hooks)
    ↓
Phase 3 (AI/AST) → wordpress-ast-analysis.json (2MB+ AST data)
    ↓
Phase 4-5 (Security/Performance) → Uses AST data
    ↓
Phase 6 (Test + AI Data) → test-data-manifest.json
    ↓
Phase 7-8 (Visual/Integration) → Uses test data
    ↓
Phase 9 (AI Documentation) → 50K+ prompt using ALL data
    ↓
Phase 10 (Consolidation) → MASTER-REPORT.md with score
    ↓
Phase 11-12 (Live Testing/Archive) → Final validation
```

## Running Individual Phases

### Complete Analysis
```bash
# Run all 12 phases
./test-plugin.sh plugin-name
```

### Individual Phase Execution

Each phase can be run independently:

```bash
# Phase 1: Setup
./bash-modules/phases/phase-01-setup.sh plugin-name

# Phase 2: Enhanced Detection (extracts actual data)
./bash-modules/phases/phase-02-detection-enhanced.sh plugin-name

# Phase 3: AI/AST Analysis
./bash-modules/phases/phase-03-ai-analysis.sh plugin-name

# Phase 4: Security Scanning
./bash-modules/phases/phase-04-security.sh plugin-name

# Phase 5: Performance Analysis
./bash-modules/phases/phase-05-performance.sh plugin-name

# Phase 6: Test Generation + AI Data
./bash-modules/phases/phase-06-enhanced.sh plugin-name

# Phase 6 (AI Test Data only)
./bash-modules/phases/phase-06-ai-test-data.sh plugin-name

# Phase 7: Visual Testing
./bash-modules/phases/phase-07-visual-testing.sh plugin-name

# Phase 8: Integration Testing
./bash-modules/phases/phase-08-integration.sh plugin-name

# Phase 9: AI Documentation
./bash-modules/phases/phase-09-documentation.sh plugin-name

# Phase 10: Enhanced Consolidation
./bash-modules/phases/phase-10-consolidation-enhanced.sh plugin-name

# Phase 11: Live Testing
./bash-modules/phases/phase-11-live-testing.sh plugin-name

# Phase 12: Safekeeping
./bash-modules/phases/phase-12-safekeeping.sh plugin-name
```

### Skipping Phases

You can skip specific phases:

```bash
# Skip visual and live testing
SKIP_PHASES="7,11" ./test-plugin.sh plugin-name

# Skip AI phases (if no API key)
SKIP_PHASES="3,6,9" ./test-plugin.sh plugin-name
```

## Phase Details

### Phase 1: Setup
- Creates directory structure in `wbcom-scan/`
- Generates `scan-info.json`
- Sets up report directories

### Phase 2: Enhanced Detection
- Extracts 500+ actual function signatures
- Collects class definitions with methods
- Finds all hooks with context
- Identifies shortcodes, CPTs, AJAX handlers
- **Output**: `extracted-features.json`

### Phase 3: AI/AST Analysis
- Generates Abstract Syntax Tree
- Calculates complexity metrics
- Identifies security patterns
- **Output**: `wordpress-ast-analysis.json` (2MB+)

### Phase 4: Security Scanning
- Uses AST data for vulnerability detection
- Checks XSS, SQL injection, nonces
- Validates capabilities and permissions
- **Output**: `security-report.md`

### Phase 5: Performance Analysis
- Uses complexity metrics from AST
- Analyzes database queries
- Checks resource usage
- **Output**: `performance-report.md`

### Phase 6: Test Generation + AI Data
Two parts:
- **6A**: Generates PHPUnit tests
- **6B**: Creates AI-driven test data based on database patterns
- **Output**: Tests + `test-data-manifest.json`

### Phase 6 (AI Test Data)
- Analyzes database queries and patterns
- Detects plugin type (ecommerce, forum, LMS)
- Generates contextual test data prompt
- **Output**: `phase-6-ai-test-data.md`

### Phase 7: Visual Testing
- Uses test data from Phase 6
- Screenshots admin pages
- Captures shortcode renderings
- **Output**: Screenshots + `visual-testing-report.md`

### Phase 8: Integration Testing
- Tests with realistic data relationships
- Validates hooks and filters
- Checks database operations
- **Output**: `integration-report.md`

### Phase 9: AI Documentation
- Aggregates ALL previous phase data
- Creates 50K+ comprehensive prompt
- Generates documentation via AI
- **Output**: `phase-9-ai-documentation.md`

### Phase 10: Enhanced Consolidation
- Aggregates all phase results
- Calculates overall score (0-100)
- Creates master report
- **Output**: `MASTER-REPORT.md`

### Phase 11: Live Testing
- Uses test data from Phase 6
- Tests AJAX endpoints
- Validates form submissions
- **Output**: `live-testing-report.md`

### Phase 12: Safekeeping
- Archives to `wbcom-scan/archives/`
- Maintains scan history
- Preserves all data
- **Output**: Compressed archives

## Data Storage

All data is stored in `wp-content/uploads/wbcom-scan/` to keep the framework clean:

```
wbcom-scan/
└── plugin-name/
    └── 2025-09/
        ├── extracted-features.json
        ├── wordpress-ast-analysis.json
        ├── test-data-manifest.json
        ├── analysis-requests/
        ├── reports/
        ├── generated-tests/
        ├── documentation/
        └── raw-outputs/
```

## Benefits of Modular Approach

1. **Debugging**: Run individual phases to isolate issues
2. **Performance**: Skip time-consuming phases when not needed
3. **Customization**: Create custom workflows
4. **Development**: Test phase improvements independently
5. **Flexibility**: Mix and match phases as needed

## Custom Workflows

### Quick Security Check
```bash
./bash-modules/phases/phase-02-detection-enhanced.sh plugin-name
./bash-modules/phases/phase-04-security.sh plugin-name
```

### Documentation Only
```bash
./bash-modules/phases/phase-02-detection-enhanced.sh plugin-name
./bash-modules/phases/phase-09-documentation.sh plugin-name
```

### Test Data Generation
```bash
./bash-modules/phases/phase-02-detection-enhanced.sh plugin-name
./bash-modules/phases/phase-06-ai-test-data.sh plugin-name
```

## Environment Variables

Control phase execution with environment variables:

```bash
# Skip specific phases
export SKIP_PHASES="7,11"

# Set paths
export WP_PATH="/path/to/wordpress"
export PLUGIN_PATH="/path/to/plugin"

# Enable debug mode
export DEBUG=1

# Run analysis
./test-plugin.sh plugin-name
```

## Troubleshooting

### Phase Not Found
```bash
# Make phases executable
chmod +x bash-modules/phases/*.sh
```

### Missing Dependencies
```bash
# Check required tools
which jq wp node php
```

### Path Issues
```bash
# Set MODULES_PATH if needed
export MODULES_PATH="/full/path/to/bash-modules"
```

## Best Practices

1. **Always run Phase 2 first** - It extracts the data other phases need
2. **Phase 3 (AST) is heavy** - Skip if you only need basic analysis
3. **Phase 6B before Phase 7** - Create test data before visual testing
4. **Use Phase 10 for summary** - It aggregates everything
5. **Keep framework clean** - All data goes to wbcom-scan/

## Future Enhancements

- Parallel phase execution
- Phase dependency management
- Custom phase plugins
- Phase result caching
- Real-time progress monitoring