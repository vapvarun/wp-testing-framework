# WP-CLI Commands for BuddyPress Testing

## Overview
All BuddyPress testing is now available through WP-CLI commands for consistency with WordPress workflows.

## Available Commands

### 1. Component Scanning

```bash
# Scan all BuddyPress components
wp bp component-scan

# Scan with JSON output
wp bp component-scan --output=json

# Scan and save to file
wp bp component-scan --save=buddypress-components.json

# Scan specific component
wp bp component-scan --component=members

# Output as table
wp bp component-scan --output=table
```

### 2. BuddyPress Testing

```bash
# Run complete scan (basic + components)
wp bp scan

# Analyze functionality
wp bp analyze

# Run all tests
wp bp test all

# Run specific test types
wp bp test execute --type=unit
wp bp test execute --type=functional
wp bp test execute --type=e2e

# Generate test scenarios
wp bp test generate

# Generate coverage report
wp bp test coverage
```

### 3. Component-Specific Testing

```bash
# Test specific component functionality
wp bp test functionality --component=members
wp bp test functionality --component=activity
wp bp test functionality --component=groups
```

## Complete Testing Workflow

```bash
# 1. Initial scan
wp bp scan

# 2. Analyze functionality
wp bp analyze

# 3. Generate tests
wp bp test generate

# 4. Execute tests
wp bp test execute

# 5. Get coverage report
wp bp test coverage
```

## One-Command Full Test

```bash
# Run everything
wp bp test all
```

This runs:
1. Component scanning
2. Functionality analysis
3. Test generation
4. Test execution (unit, functional, e2e)
5. Coverage reporting

## Output Examples

### Summary Output (default)
```
📦 Core: 170 files, 50 classes, 318 functions, 195 hooks (Complexity: 1879)
📦 Members: 74 files, 20 classes, 10 functions, 129 hooks (Complexity: 627)
📦 Groups: 80 files, 20 classes, 1 functions, 117 hooks (Complexity: 613)
```

### Table Output
```
+-----------+-------+---------+-----------+-------+------------+
| Component | Files | Classes | Functions | Hooks | Complexity |
+-----------+-------+---------+-----------+-------+------------+
| Core      | 170   | 50      | 318       | 195   | 1879       |
| Members   | 74    | 20      | 10        | 129   | 627        |
| Groups    | 80    | 20      | 1         | 117   | 613        |
+-----------+-------+---------+-----------+-------+------------+
```

### JSON Output
```json
{
  "core": {
    "name": "Core",
    "files": 170,
    "classes": 50,
    "functions": 318,
    "hooks": 195,
    "complexity": 1879
  }
}
```

## Installation

### Method 1: Load via wp-config.php
Add to your `wp-config.php`:
```php
if (defined('WP_CLI') && WP_CLI) {
    require_once ABSPATH . 'wp-testing-framework/load-wp-cli-commands.php';
}
```

### Method 2: Create mu-plugin
Create `/wp-content/mu-plugins/load-testing-commands.php`:
```php
<?php
if (defined('WP_CLI') && WP_CLI) {
    require_once ABSPATH . 'wp-testing-framework/load-wp-cli-commands.php';
}
```

### Method 3: Package include
Add to your project's `wp-cli.yml`:
```yaml
require:
  - wp-testing-framework/load-wp-cli-commands.php
```

## Scan Data Locations

All scan data is saved to:
- **Basic scan**: `/wp-content/uploads/wbcom-scan/buddypress-complete.json`
- **Component scan**: `/wp-content/uploads/wbcom-scan/buddypress-components-scan.json`

## Benefits of WP-CLI Commands

1. **Consistent with WordPress**: Uses familiar WP-CLI interface
2. **No PHP execution needed**: All commands run through WP-CLI
3. **Better error handling**: WP-CLI provides proper error messages
4. **Progress indicators**: Built-in progress bars for long operations
5. **Output formats**: JSON, table, CSV, YAML support
6. **Scriptable**: Easy to integrate in CI/CD pipelines
7. **Remote execution**: Can run on remote servers via SSH

## Advanced Usage

### Pipe to other commands
```bash
# Get complexity scores for all components
wp bp component-scan --output=json | jq '.[] | select(.metrics) | {name: .name, complexity: .metrics.complexity_score}'
```

### Save and analyze
```bash
# Save scan and analyze specific metrics
wp bp component-scan --output=json > scan.json
cat scan.json | jq '.summary.total_hooks'
```

### Automated testing
```bash
# Run in CI/CD
#!/bin/bash
wp bp scan
wp bp test all
if [ $? -eq 0 ]; then
  echo "All tests passed"
else
  echo "Tests failed"
  exit 1
fi
```

## Troubleshooting

### Commands not found
```bash
# Check if commands are loaded
wp cli cmd-dump | grep "bp component-scan"

# Load manually
wp eval-file wp-testing-framework/load-wp-cli-commands.php
```

### Permission issues
```bash
# Ensure write permissions for scan directory
chmod 755 wp-content/uploads/wbcom-scan
```

### Memory issues
```bash
# Increase memory limit
wp bp component-scan --memory_limit=256M
```