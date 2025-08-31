# Deprecated Shell Scripts

This folder contains shell scripts that are no longer part of the active testing process.

## Files Moved Here

### best-practice-analyzer.sh
- **Purpose**: Analyzed WordPress best practices
- **Deprecated**: January 2025
- **Replaced by**: Integrated into main test-plugin.sh phases
- **Reason**: Functionality absorbed into Phase 4 (Security) and Phase 5 (Performance)

### test-coverage-report.sh
- **Purpose**: Generated test coverage reports
- **Deprecated**: January 2025
- **Replaced by**: PHP tools (run-unit-tests-with-coverage.php) and Phase 6
- **Reason**: Better integrated coverage in test generation phase

### generate-auto-login-url.sh
- **Purpose**: Generated auto-login URLs for testing
- **Deprecated**: January 2025
- **Replaced by**: PHP tool (create-auto-login.php) and Node.js tools
- **Reason**: Better implementation in cross-platform tools

### generate-documentation.sh
- **Purpose**: Generated plugin documentation
- **Deprecated**: January 2025
- **Replaced by**: Phase 9 (Documentation) in main framework
- **Reason**: Integrated into comprehensive testing phases

### setup-data-dirs.sh
- **Purpose**: Set up data directories
- **Deprecated**: January 2025
- **Replaced by**: Phase 1 (Setup) in main framework
- **Reason**: Directory setup now handled by main testing framework

## Active Shell Scripts

The following shell scripts remain active:

### Root Directory
- `test-plugin.sh` - Main testing orchestrator
- `run-phase.sh` - Individual phase runner
- `setup.sh` - Framework setup
- `local-wp-setup.sh` - Local WP environment setup

### Tools Directory
- `tools/documentation/enhance-documentation.sh` - Still used by test-plugin.sh
- `tools/documentation/validate-documentation.sh` - Still used by test-plugin.sh

## Migration Guide

If you were using deprecated scripts:

### Old:
```bash
./tools/best-practice-analyzer.sh plugin-name
./tools/test-coverage-report.sh plugin-name
./tools/generate-documentation.sh plugin-name
```

### New:
```bash
# All functionality now in main script
./test-plugin.sh plugin-name

# Or run specific phases
./run-phase.sh -p plugin-name -n 4  # Security analysis
./run-phase.sh -p plugin-name -n 5  # Performance analysis
./run-phase.sh -p plugin-name -n 6  # Test coverage
./run-phase.sh -p plugin-name -n 9  # Documentation
```

## Note

These scripts are archived for reference. All functionality has been integrated into the main testing framework with better error handling, reporting, and cross-platform support.