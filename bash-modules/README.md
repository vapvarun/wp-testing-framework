# Bash Modules for WordPress Plugin Testing Framework

## 📁 Structure

```
bash-modules/
├── shared/
│   └── common-functions.sh    # Shared functions used by all phases
├── phases/
│   ├── phase-01-setup.sh       # Setup & Directory Structure
│   ├── phase-02-detection.sh   # Plugin Detection & Basic Analysis
│   ├── phase-03-ai-analysis.sh # AI-Driven Code Analysis
│   ├── phase-04-security.sh    # Security Vulnerability Scanning
│   ├── phase-05-performance.sh # Performance Analysis
│   ├── phase-06-test-generation.sh # Test Generation & Coverage
│   ├── phase-07-visual-testing.sh  # Visual Testing & Screenshots
│   ├── phase-08-integration.sh     # WordPress Integration Tests
│   ├── phase-09-documentation.sh   # Documentation Generation
│   ├── phase-10-consolidation.sh   # Report Consolidation
│   ├── phase-11-live-testing.sh    # Live Testing with Test Data
│   └── phase-12-safekeeping.sh     # Framework Safekeeping
└── README.md
```

## 🚀 Usage

### Using the Main Orchestrator

```bash
# Run all phases
./test-plugin.sh woocommerce

# Quick mode (skips phases 3, 7, 11)
./test-plugin.sh elementor quick

# Interactive mode
INTERACTIVE=true ./test-plugin.sh yoast-seo

# Skip specific phases
SKIP_PHASES="7,11" ./test-plugin.sh wpforms
```

### Running Individual Phases

Each phase can be run independently:

```bash
# Run setup phase
./bash-modules/phases/phase-01-setup.sh plugin-name

# Run security scan
./bash-modules/phases/phase-04-security.sh plugin-name

# Run performance analysis
./bash-modules/phases/phase-05-performance.sh plugin-name
```

### Using run-phase.sh Helper

```bash
# Run specific phase
./run-phase.sh -p woocommerce -n 4

# List all phases
./run-phase.sh -l
```

## 📝 Creating New Phases

### Phase Template

```bash
#!/bin/bash

# Phase XX: Phase Name
# Description of what this phase does

# Source common functions
source "$(dirname "$0")/../shared/common-functions.sh"

run_phase_XX() {
    local plugin_name=$1
    
    print_phase XX "Phase Name"
    
    # Your phase logic here
    print_info "Running phase tasks..."
    
    # Save results
    save_phase_results "XX" "completed"
    
    # Interactive checkpoint
    checkpoint XX "Phase complete. Ready for next step."
    
    return 0
}

# Execute if running standalone
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Set required variables
    PLUGIN_NAME=$1
    FRAMEWORK_PATH="$(cd "$(dirname "$0")/../../" && pwd)"
    # ... other setup
    
    # Run the phase
    run_phase_XX "$PLUGIN_NAME"
fi
```

## 🔧 Common Functions

Available in all phases via `common-functions.sh`:

### Output Functions
- `print_phase` - Display phase header
- `print_success` - Success message (green)
- `print_info` - Information message (cyan)
- `print_warning` - Warning message (yellow)
- `print_error` - Error message (red)

### Utility Functions
- `checkpoint` - Interactive checkpoint with user prompt
- `show_progress` - Display progress spinner
- `ensure_directory` - Create directory if not exists
- `command_exists` - Check if command is available
- `run_with_timeout` - Run command with timeout
- `save_phase_results` - Save phase results to JSON
- `load_phase_results` - Load previous phase results

### Validation Functions
- `check_wp_cli` - Check if WP-CLI is available
- `check_nodejs` - Check if Node.js is available
- `check_php` - Check if PHP is available
- `validate_plugin` - Validate plugin exists
- `get_plugin_metadata` - Extract plugin header info

### Helper Functions
- `count_files` - Count files by extension
- `format_size` - Format file size (KB/MB)

## 🎯 Benefits of Modular Approach

1. **Maintainability**: Each phase is self-contained and easy to update
2. **Reusability**: Phases can be run independently
3. **Testing**: Individual phases can be tested in isolation
4. **Customization**: Easy to add/remove/modify phases
5. **Debugging**: Issues are isolated to specific phase files
6. **Parallel Development**: Multiple developers can work on different phases
7. **CI/CD Integration**: Phases can be executed selectively in pipelines

## 📊 Phase Dependencies

Some phases depend on results from previous phases:

- **Phase 2-12**: Require paths from Phase 1
- **Phase 6**: Benefits from AST analysis in Phase 3
- **Phase 9**: Uses results from Phases 3-5 for documentation
- **Phase 10**: Consolidates all previous phase results
- **Phase 11**: Uses test data from Phase 6

## 🔄 Phase Status Codes

Each phase returns a status:
- `0` - Success/Completed
- `1` - Failed/Error
- `2` - Skipped (by user or mode)
- `3` - Not Implemented

## 🐛 Troubleshooting

### Module Not Found
```bash
# Ensure you're in the framework directory
cd /path/to/wp-testing-framework

# Check module exists
ls -la bash-modules/phases/phase-XX-*.sh
```

### Permission Issues
```bash
# Make scripts executable
chmod +x bash-modules/phases/*.sh
chmod +x bash-modules/shared/*.sh
```

### Phase Fails
```bash
# Run phase individually with debug output
bash -x bash-modules/phases/phase-XX-*.sh plugin-name
```

## 📝 Migration from Monolithic Script

The modular approach maintains backward compatibility:

1. **test-plugin.sh** - Now acts as orchestrator, can use modules or inline
2. **test-plugin-modular.sh** - Pure modular version
3. **Fallback Support** - If module not found, falls back to inline function

## 🔄 Environment Variables

### Required
- `PLUGIN_NAME` - Name of plugin to test
- `FRAMEWORK_PATH` - Path to testing framework
- `WP_PATH` - Path to WordPress installation

### Optional
- `INTERACTIVE` - Enable interactive mode (true/false)
- `USE_AST` - Enable AST analysis (true/false)
- `SKIP_PHASES` - Comma-separated list of phases to skip
- `TEST_TYPE` - Testing mode (full/quick/security/performance)
- `ANTHROPIC_API_KEY` - For AI-enhanced analysis

## 📄 License

Part of WP Testing Framework - MIT License