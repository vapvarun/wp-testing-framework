# Deprecated PowerShell Scripts

This folder contains PowerShell scripts that have been superseded by newer implementations.

## Files in this directory:

### test-plugin-v12.ps1
- **Purpose**: Intermediate 12-phase version of the testing framework
- **Deprecated**: January 2025
- **Replaced by**: `test-plugin.ps1` (main file with hybrid module support)
- **Reason**: Functionality fully integrated into main script with modular architecture

### test-plugin-modular.ps1
- **Purpose**: Prototype modular orchestrator for phase execution
- **Deprecated**: January 2025
- **Replaced by**: `test-plugin.ps1` with `Invoke-PhaseExecution` function
- **Reason**: Main script now supports both modular and inline execution

## Migration Guide

If you were using these scripts, update your commands:

### Old:
```powershell
.\test-plugin-v12.ps1 wpforo
.\test-plugin-modular.ps1 woocommerce
```

### New:
```powershell
# Use the main script (has all 12 phases + module support)
.\test-plugin.ps1 wpforo

# Or run individual phases
.\run-phase.ps1 -Plugin wpforo -Phase 4
```

## Why These Were Deprecated

1. **Consolidation**: Having multiple versions created confusion
2. **Single Entry Point**: `test-plugin.ps1` now handles everything
3. **Backward Compatibility**: Main script maintains all functionality
4. **Module Support**: Main script can use modules when available, falls back to inline

## Note

These files are kept for reference only. Do not use them for new testing.
All functionality has been preserved in the current `test-plugin.ps1`.