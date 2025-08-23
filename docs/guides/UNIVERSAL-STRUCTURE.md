# Universal Testing Framework Structure

## Design Philosophy
- **Framework**: Remains generic and reusable (in wp-testing-framework)
- **Plugin Tests**: Generated dynamically based on plugin being tested
- **Test Results**: Environment-specific (stored in wbcom-scan)
- **Learning Models**: Portable and reusable (stored in wbcom-plan)

## Directory Structure

### 1. Framework Core (wp-testing-framework/) - COMMITTED TO GIT
```
wp-testing-framework/
├── tools/                      # Universal tools
│   ├── ai/                    # AI analyzers (generic)
│   ├── scanners/              # Universal scanners
│   └── e2e/                   # E2E framework
├── tests/
│   ├── templates/             # Test templates (reusable)
│   │   ├── unit/             # Unit test templates
│   │   ├── integration/      # Integration templates
│   │   ├── functionality/    # Functionality templates
│   │   └── security/         # Security templates
│   └── framework/            # Framework self-tests
├── docs/                      # Framework documentation
└── bin/                       # Setup scripts
```

### 2. Plugin-Specific Tests (Dynamic Generation)
```
wp-content/uploads/wbcom-scan/{plugin-slug}/
├── scan-data/
│   ├── complete.json          # Full scan data
│   ├── components.json        # Component analysis
│   ├── functionality.json     # Functionality mapping
│   └── api-endpoints.json     # API analysis
├── test-results/
│   ├── unit/                  # Unit test results
│   ├── integration/           # Integration results
│   ├── e2e/                   # E2E test results
│   └── coverage/              # Coverage reports
├── generated-tests/           # Plugin-specific tests
│   ├── unit/
│   ├── integration/
│   └── functionality/
└── reports/
    ├── ai-analysis/           # AI-generated reports
    ├── customer-value/        # Business analysis
    └── execution-summary.json # Test execution summary
```

### 3. Learning Models (wbcom-plan/) - PORTABLE
```
wp-content/uploads/wbcom-plan/
├── models/
│   ├── test-patterns/         # Learned test patterns
│   │   ├── buddypress.json   # BuddyPress patterns
│   │   ├── woocommerce.json  # WooCommerce patterns
│   │   └── generic.json      # Generic patterns
│   ├── demo-data/             # Demo data generators
│   │   ├── users.json        # User generation patterns
│   │   ├── content.json      # Content patterns
│   │   └── relationships.json # Data relationships
│   └── bug-patterns/          # Known bug patterns
│       ├── security.json      # Security vulnerabilities
│       ├── performance.json   # Performance issues
│       └── compatibility.json # Compatibility problems
├── templates/                  # Reusable templates
│   ├── test-scenarios/        # Test scenario templates
│   ├── user-journeys/         # User journey maps
│   └── fix-patterns/          # Fix recommendations
└── knowledge-base/            # Accumulated knowledge
    ├── plugin-behaviors.json  # How plugins behave
    ├── wp-patterns.json       # WordPress patterns
    └── best-practices.json    # Testing best practices
```

## Implementation Changes

### 1. Update Universal Workflow
```javascript
// tools/universal-workflow.mjs
const WORKFLOW_CONFIG = {
  scanDir: '../wp-content/uploads/wbcom-scan',
  planDir: '../wp-content/uploads/wbcom-plan',
  frameworkDir: './',
  
  getPluginDir(pluginSlug) {
    return path.join(this.scanDir, pluginSlug);
  },
  
  getModelPath(modelType) {
    return path.join(this.planDir, 'models', modelType);
  },
  
  getTemplatePath(templateType) {
    return path.join(this.frameworkDir, 'tests/templates', templateType);
  }
};
```

### 2. Dynamic Test Generation
```javascript
// tools/ai/universal-test-generator.mjs
export async function generateTestsForPlugin(pluginSlug) {
  // Load plugin scan data
  const scanData = await loadScanData(pluginSlug);
  
  // Load learning models
  const patterns = await loadLearningModel(pluginSlug);
  
  // Generate tests in plugin-specific directory
  const outputDir = `${SCAN_DIR}/${pluginSlug}/generated-tests`;
  
  // Use templates from framework
  const templates = await loadTemplates();
  
  // Generate with learned patterns
  return generateWithPatterns(scanData, patterns, templates, outputDir);
}
```

### 3. Learning Model Builder
```javascript
// tools/ai/learning-model-builder.mjs
export async function updateLearningModel(pluginSlug, testResults) {
  const modelPath = `${PLAN_DIR}/models/test-patterns/${pluginSlug}.json`;
  
  // Load existing model or create new
  const model = await loadOrCreateModel(modelPath);
  
  // Update with new learnings
  model.successfulPatterns.push(...testResults.passed);
  model.failurePatterns.push(...testResults.failed);
  model.fixPatterns.push(...testResults.fixes);
  
  // Save updated model
  await saveModel(modelPath, model);
  
  // Update generic patterns
  await updateGenericPatterns(testResults);
}
```

## Benefits

### 1. Portability
- Framework can be installed anywhere
- Learning models can be shared across environments
- Test results stay with the environment

### 2. Scalability
- Each plugin gets its own directory
- No conflicts between plugin tests
- Easy to test multiple plugins

### 3. Learning & Improvement
- Models improve with each test run
- Patterns are reusable across plugins
- Knowledge accumulates over time

### 4. Version Control
- Framework code in Git
- Plugin-specific tests generated dynamically
- Learning models can be versioned separately

## Migration Commands

```bash
# Initialize structure for a plugin
npm run universal:init --plugin=buddypress

# Generate tests using learned patterns
npm run universal:generate --plugin=buddypress --use-models

# Update learning models after test run
npm run universal:learn --plugin=buddypress --results=./test-results

# Export learning models for sharing
npm run universal:export-models --output=./models-backup

# Import learning models
npm run universal:import-models --input=./models-backup
```

## Environment Variables

```bash
# .env.local
WP_TESTING_SCAN_DIR=/wp-content/uploads/wbcom-scan
WP_TESTING_PLAN_DIR=/wp-content/uploads/wbcom-plan
WP_TESTING_FRAMEWORK_DIR=/wp-testing-framework
WP_TESTING_USE_MODELS=true
WP_TESTING_UPDATE_MODELS=true
```