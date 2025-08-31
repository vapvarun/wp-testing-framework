# Legacy Configuration Files

These configuration files were moved from the root directory as they are no longer actively used by the testing framework.

## Files

### PHPUnit Configurations
- **phpunit.xml** - Main PHPUnit configuration (legacy)
- **phpunit-components.xml** - Component testing configuration (unused)
- **phpunit-modern.xml** - Modern PHPUnit setup (unused)
- **phpunit-unit.xml** - Unit testing configuration (unused)

### PHPStan Configuration
- **phpstan.neon** - Static analysis configuration (legacy)

## Current Approach

The framework now generates configuration files dynamically during test execution:

1. **Phase 6 (Test Generation)** creates PHPUnit configs on-the-fly based on plugin analysis
2. **Phase 4 (Security)** uses PHPStan with dynamic configuration
3. All test configurations are customized per plugin in their respective scan directories

## Location of Generated Configs

Generated configurations are stored in:
```
wp-content/uploads/wbcom-scan/[plugin-name]/[date]/generated-tests/
```

## Note

These files are kept for reference and backward compatibility with older backup scripts. They are not required for the current modular testing framework (v12.0).

**Date Moved**: $(date)
**Reason**: Cleanup of root directory - framework uses dynamic configuration generation