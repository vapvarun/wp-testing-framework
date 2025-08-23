# WBCom Plan Directory Structure

This is an example of how the `wbcom-plan` directory should be structured. This directory contains portable learning models and templates that can be shared across environments.

The actual directory should be located at:

```
/wp-content/uploads/wbcom-plan/
```

## Directory Structure

```
wbcom-plan/
├── models/                          # Learning models (portable)
│   ├── test-patterns/              # Learned test patterns
│   │   ├── generic.json           # Generic patterns for all plugins
│   │   ├── buddypress.json        # BuddyPress-specific patterns
│   │   ├── woocommerce.json       # WooCommerce-specific patterns
│   │   └── {plugin-slug}.json     # Plugin-specific patterns
│   │
│   ├── demo-data/                  # Demo data generation patterns
│   │   ├── users.json             # User generation patterns
│   │   ├── content.json           # Content generation patterns
│   │   ├── relationships.json     # Data relationship patterns
│   │   └── scenarios.json         # Test scenario data
│   │
│   └── bug-patterns/               # Known bug patterns
│       ├── security.json          # Security vulnerability patterns
│       ├── performance.json       # Performance issue patterns
│       ├── compatibility.json     # Compatibility problem patterns
│       └── common-fixes.json      # Common fix patterns
│
├── templates/                       # Reusable templates
│   ├── test-scenarios/             # Test scenario templates
│   │   ├── user-journey.json      # User journey templates
│   │   ├── admin-workflow.json    # Admin workflow templates
│   │   └── api-testing.json       # API testing templates
│   │
│   ├── user-journeys/              # Detailed user journeys
│   │   ├── registration.json      # Registration flow
│   │   ├── purchase.json          # Purchase flow
│   │   └── content-creation.json  # Content creation flow
│   │
│   └── fix-patterns/               # Fix recommendation templates
│       ├── sql-injection.json     # SQL injection fixes
│       ├── xss.json               # XSS fixes
│       └── performance.json       # Performance optimization
│
└── knowledge-base/                 # Accumulated knowledge
    ├── plugin-behaviors.json       # How different plugins behave
    ├── wp-patterns.json            # WordPress-specific patterns
    ├── best-practices.json         # Testing best practices
    └── compatibility-matrix.json   # Plugin compatibility data
```

## File Purposes

### models/test-patterns/
Contains learned patterns from successful and failed tests. These patterns improve over time as more tests are run.

### models/demo-data/
Templates for generating realistic test data including users, posts, and relationships.

### models/bug-patterns/
Known bug patterns and their solutions, accumulated from testing various plugins.

### templates/
Reusable templates for creating test scenarios, user journeys, and fix recommendations.

### knowledge-base/
Accumulated knowledge about WordPress plugins, testing patterns, and best practices.

## Usage

### Loading Learning Models

```javascript
// Load plugin-specific model
const model = await loadModel('buddypress');

// Load generic patterns
const generic = await loadModel('generic');

// Merge patterns for comprehensive testing
const patterns = mergePatterns(model, generic);
```

### Updating Learning Models

```javascript
// After test execution
await updateLearningModel('buddypress', {
  passed: passedTests,
  failed: failedTests,
  fixes: appliedFixes
});
```

### Exporting/Importing Models

```bash
# Export models for backup or sharing
npm run universal:export-models --output=./my-models

# Import models from another environment
npm run universal:import-models --input=./shared-models
```

## Model Versioning

Models include version information and can be:
- Exported for backup
- Shared between teams
- Version controlled separately
- Merged from multiple sources

## Example Files

See the example JSON files in this directory for the structure of each model type.

## Important Notes

1. **Portable**: These models can be moved between environments
2. **Learning**: Models improve with each test run
3. **Shareable**: Can be shared between teams/projects
4. **Version Control**: Can be committed to a separate repository for model versioning