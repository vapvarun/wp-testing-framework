# WBCom Scan Directory Structure

This is an example of how the `wbcom-scan` directory should be structured in your WordPress installation. The actual directory should be located at:

```
/wp-content/uploads/wbcom-scan/
```

## Directory Structure

```
wbcom-scan/
├── {plugin-slug}/                    # Each plugin gets its own directory
│   ├── scan-data/                   # Raw scan data
│   │   ├── complete.json            # Full plugin scan
│   │   ├── components.json          # Component analysis
│   │   ├── functionality.json       # Functionality mapping
│   │   ├── api-endpoints.json       # REST API endpoints
│   │   ├── database-tables.json     # Database schema
│   │   └── hooks-filters.json       # Hooks and filters
│   │
│   ├── test-results/                # Test execution results (environment-specific)
│   │   ├── unit/                   # Unit test results
│   │   │   ├── latest.json         # Latest run
│   │   │   └── history/            # Previous runs
│   │   ├── integration/            # Integration test results
│   │   ├── e2e/                    # End-to-end test results
│   │   ├── security/               # Security scan results
│   │   ├── performance/            # Performance test results
│   │   └── coverage/               # Code coverage reports
│   │
│   ├── generated-tests/             # Dynamically generated tests
│   │   ├── unit/                   # Generated unit tests
│   │   ├── integration/            # Generated integration tests
│   │   ├── functionality/          # Generated functionality tests
│   │   └── scenarios/              # Generated test scenarios
│   │
│   └── reports/                     # Analysis reports
│       ├── ai-analysis/            # AI-generated analysis
│       ├── customer-value/         # Business value analysis
│       ├── bug-checklist.json      # Known issues
│       └── execution-summary.json  # Test summary
│
├── buddypress/                      # Example: BuddyPress plugin
├── woocommerce/                     # Example: WooCommerce plugin
└── site.json                        # Site-wide configuration
```

## Usage

### Initial Setup

```bash
# Create wbcom-scan directory
mkdir -p wp-content/uploads/wbcom-scan

# Run scan for a plugin
npm run universal:scan --plugin=buddypress
```

### File Descriptions

#### scan-data/complete.json
Complete plugin scan including:
- Plugin metadata
- File structure
- Database tables
- Hooks and filters
- Admin pages
- Frontend pages
- REST endpoints

#### test-results/
Environment-specific test results that should NOT be committed to version control.

#### generated-tests/
Tests generated specifically for this plugin based on scan data and learning models.

#### reports/
Human and AI-readable reports for analysis and decision-making.

## Important Notes

1. **Environment-Specific**: The `wbcom-scan` directory contains environment-specific data
2. **Not in Git**: These files should NOT be committed to version control
3. **Dynamic Generation**: Tests are generated based on actual plugin structure
4. **Continuous Updates**: Results are updated with each test run

## Example Files

See the `example-plugin/` directory in this folder for sample JSON structures.