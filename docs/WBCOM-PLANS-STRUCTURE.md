# WBCom-Plans Directory Structure

## Overview

The `wbcom-plans/` directory contains **AI-generated plans, models, and templates** that are portable and reusable across different plugin analyses. This is separate from `wbcom-scan/` which contains analysis results.

## Directory Location

```
wp-content/uploads/wbcom-plans/
```

## What Goes in WBCom-Plans

### 1. AI Learning Models
Reusable patterns learned from analyzing multiple plugins:

```
wbcom-plans/
├── models/
│   ├── security-patterns/       # Common security vulnerability patterns
│   │   ├── xss-patterns.json
│   │   ├── sql-injection.json
│   │   └── nonce-validation.json
│   ├── test-patterns/           # Test generation patterns by plugin type
│   │   ├── ecommerce.json
│   │   ├── forum.json
│   │   ├── membership.json
│   │   └── forms.json
│   └── fix-patterns/           # Common fix templates
│       ├── sanitization.json
│       ├── validation.json
│       └── escaping.json
```

### 2. AI-Generated Templates
Reusable templates for different plugin types:

```
wbcom-plans/
├── templates/
│   ├── test-data/              # Test data templates by plugin type
│   │   ├── ecommerce-data.sql
│   │   ├── forum-data.sql
│   │   ├── membership-data.sql
│   │   └── lms-data.sql
│   ├── documentation/          # Documentation templates
│   │   ├── user-guide.md
│   │   ├── developer-guide.md
│   │   └── api-reference.md
│   └── code-generation/        # Code templates
│       ├── phpunit-tests.php
│       ├── integration-tests.php
│       └── mock-data.php
```

### 3. Knowledge Base
Accumulated knowledge from all analyses:

```
wbcom-plans/
├── knowledge-base/
│   ├── plugin-patterns/        # Patterns by plugin
│   │   ├── woocommerce.json
│   │   ├── bbpress.json
│   │   └── buddypress.json
│   ├── wordpress-patterns/     # WordPress-specific patterns
│   │   ├── hooks.json
│   │   ├── filters.json
│   │   └── shortcodes.json
│   └── best-practices/         # Learned best practices
│       ├── security.json
│       ├── performance.json
│       └── testing.json
```

### 4. AI Improvement Plans
Plans for enhancing plugins based on analysis:

```
wbcom-plans/
├── improvement-plans/
│   ├── security-fixes/         # Security improvement plans
│   ├── performance-optimization/ # Performance plans
│   ├── code-refactoring/       # Refactoring suggestions
│   └── feature-additions/      # New feature plans
```

### 5. Plugin-Specific Plans (by date)
AI-generated plans for specific plugins:

```
wbcom-plans/
├── [plugin-name]/
│   └── [YYYY-MM]/
│       ├── test-plan.md        # Test strategy
│       ├── fix-plan.md         # Fix recommendations
│       ├── enhancement-plan.md # Enhancement suggestions
│       ├── migration-plan.md   # Version migration plans
│       └── optimization-plan.md # Optimization strategies
```

## Key Differences: wbcom-plans vs wbcom-scan

### wbcom-plans/ (AI Plans & Templates)
- **Purpose**: Reusable AI models and templates
- **Content**: Learning patterns, templates, knowledge base
- **Persistence**: Long-term, improves over time
- **Sharing**: Can be shared across projects
- **Examples**:
  - Test data templates for different plugin types
  - Security fix patterns
  - Documentation templates
  - Best practice models

### wbcom-scan/ (Analysis Results)
- **Purpose**: Plugin analysis outputs
- **Content**: Scan results, reports, generated tests
- **Persistence**: Per-plugin, per-scan
- **Sharing**: Specific to each analysis
- **Examples**:
  - extracted-features.json
  - security-report.md
  - Generated PHPUnit tests
  - Screenshot results

## File Types in wbcom-plans

### JSON Models (.json)
Pattern recognition and learning models:
```json
{
  "plugin_type": "ecommerce",
  "patterns": {
    "database": ["orders", "products", "customers"],
    "hooks": ["checkout", "cart", "payment"],
    "security": ["payment_validation", "user_authentication"]
  }
}
```

### SQL Templates (.sql)
Reusable test data templates:
```sql
-- Forum test data template
INSERT INTO wp_posts (post_type, post_title) VALUES ('forum', 'Test Forum');
INSERT INTO wp_posts (post_type, post_title) VALUES ('topic', 'Test Topic');
```

### Markdown Plans (.md)
AI-generated improvement plans:
```markdown
# Security Enhancement Plan
## Identified Issues
1. XSS vulnerability in user input
2. Missing nonce validation

## Recommended Fixes
1. Add wp_kses() sanitization
2. Implement wp_verify_nonce()
```

### PHP Templates (.php)
Code generation templates:
```php
<?php
// PHPUnit test template for {plugin_type}
class {PluginName}Test extends WP_UnitTestCase {
    // Template methods
}
```

## Usage in Framework

### Reading from wbcom-plans
```bash
# Phase 6 uses test data templates
cat wbcom-plans/templates/test-data/forum-data.sql

# Phase 9 uses documentation templates
cat wbcom-plans/templates/documentation/user-guide.md
```

### Writing to wbcom-plans
```bash
# AI generates new patterns
echo "$patterns" > wbcom-plans/models/test-patterns/new-plugin-type.json

# Save learned best practices
echo "$practices" > wbcom-plans/knowledge-base/best-practices/plugin-name.json
```

## Benefits

1. **Reusability**: Templates work across multiple plugins
2. **Learning**: Models improve with each analysis
3. **Portability**: Can be shared between projects
4. **Efficiency**: No need to regenerate common patterns
5. **Knowledge Base**: Accumulated wisdom from all analyses

## Best Practices

1. **Keep Generic**: Templates should work for plugin types, not specific plugins
2. **Version Control**: Can be committed to git (unlike scan results)
3. **Regular Updates**: Update models as patterns evolve
4. **Documentation**: Document what each model/template does
5. **Validation**: Test templates before adding to plans

## Future Enhancements

1. **Machine Learning Integration**: Train models on accumulated data
2. **Template Versioning**: Track template evolution
3. **Community Sharing**: Share models with WordPress community
4. **Auto-Generation**: Automatically create templates from successful patterns
5. **Pattern Recognition**: Auto-detect new patterns from analyses