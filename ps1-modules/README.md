# PowerShell Modular Testing Framework

## 📁 Structure

```
ps1-modules/
├── shared/
│   └── Common-Functions.ps1    # Shared functions used by all phases
├── phases/
│   ├── Phase01-Setup.ps1       # Setup & Directory Structure
│   ├── Phase02-Detection.ps1   # Plugin Detection & Basic Analysis
│   ├── Phase03-AIAnalysis.ps1  # AI-Driven Code Analysis
│   ├── Phase04-Security.ps1    # Security Vulnerability Scanning
│   ├── Phase05-Performance.ps1 # Performance Analysis
│   ├── Phase06-TestGeneration.ps1 # Test Generation & Coverage
│   ├── Phase07-VisualTesting.ps1  # Visual Testing & Screenshots
│   ├── Phase08-Integration.ps1    # WordPress Integration Tests
│   ├── Phase09-Documentation.ps1  # Documentation Generation
│   ├── Phase10-Consolidation.ps1  # Report Consolidation
│   ├── Phase11-LiveTesting.ps1    # Live Testing with Test Data
│   └── Phase12-Safekeeping.ps1    # Framework Safekeeping
└── README.md
```

## 🚀 Usage

### Main Orchestrator
```powershell
# Run all phases
.\test-plugin-modular.ps1 woocommerce

# Quick mode (skips time-consuming phases)
.\test-plugin-modular.ps1 elementor -Mode quick

# Skip specific phases
.\test-plugin-modular.ps1 yoast-seo -SkipPhases 7,8,11

# Non-interactive CI/CD mode
.\test-plugin-modular.ps1 wpforms -NonInteractive
```

### Run Individual Phases
```powershell
# Set up configuration
$Config = @{
    PluginName = "wpforo"
    PluginPath = "C:\path\to\wp-content\plugins\wpforo"
    FrameworkPath = "C:\path\to\wp-testing-framework"
    InteractiveMode = $true
}

# Run specific phase
& ".\ps1-modules\phases\Phase04-Security.ps1" -Config $Config
```

## 📝 Creating New Phases

### Phase Template
```powershell
# Phase XX: Phase Name
# Description of what this phase does

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-PhaseXX {
    param([hashtable]$Config)
    
    Write-Phase "PHASE XX: Phase Name"
    
    # Your phase logic here
    $results = @{
        Status = "Completed"
        # Add your results
    }
    
    # Save results
    Save-PhaseResults -Phase "XX" -Results $results -OutputPath $Config.ScanDir
    
    return $results
}

# Execute if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-PhaseXX -Config $Config
}
```

## 🔧 Configuration Object

The `$Config` hashtable passed to each phase contains:

```powershell
@{
    # Basic settings
    PluginName = "plugin-name"
    Mode = "full|quick|security|performance|ai"
    InteractiveMode = $true|$false
    
    # Paths
    FrameworkPath = "C:\path\to\framework"
    PluginPath = "C:\path\to\plugin"
    WPPath = "C:\path\to\wordpress"
    UploadPath = "C:\path\to\uploads"
    
    # Runtime paths (set by Phase 1)
    ScanDir = "path\to\scan\output"
    PlanDir = "path\to\plan\output"
    SafekeepDir = "path\to\safekeep"
    Timestamp = "20250830-123456"
    
    # Options
    SkipPhases = @(7,11)  # Phases to skip
    AutoInstallTools = $true
    GenerateOnly = $false
    UsePHPStan = $true
    UseXdebug = $true
}
```

## 🛠️ Common Functions

Available in all phases via `Common-Functions.ps1`:

### Output Functions
- `Write-Phase` - Display phase header
- `Write-Success` - Success message (green)
- `Write-Info` - Information message (cyan)
- `Write-Warning` - Warning message (yellow)
- `Write-Error` - Error message (red)

### Utility Functions
- `Invoke-Checkpoint` - Interactive checkpoint with user prompt
- `Invoke-WithTimeout` - Run command with timeout
- `Test-PluginExists` - Check if plugin exists
- `Ensure-Directory` - Create directory if not exists
- `Get-PluginMetadata` - Extract plugin header information
- `Get-FileStats` - Count files by type
- `Save-PhaseResults` - Save phase results to JSON
- `Get-PhaseResults` - Load previous phase results

## 🎯 Benefits of Modular Approach

1. **Maintainability**: Each phase is self-contained and easy to update
2. **Reusability**: Phases can be run independently
3. **Testing**: Individual phases can be tested in isolation
4. **Customization**: Easy to add/remove/modify phases
5. **Debugging**: Issues are isolated to specific phase files
6. **Team Development**: Multiple developers can work on different phases
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
- `Completed` - Phase executed successfully
- `Skipped` - Phase was skipped (user choice or mode)
- `Failed` - Phase encountered an error
- `NotImplemented` - Phase module exists but not implemented
- `InProgress` - Phase is currently executing

## 🐛 Troubleshooting

### Module Not Found
```powershell
# Ensure you're in the framework directory
cd C:\path\to\wp-testing-framework

# Check module exists
Test-Path ".\ps1-modules\phases\PhaseXX-Name.ps1"
```

### Permission Issues
```powershell
# Run as Administrator or set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Phase Fails
```powershell
# Run phase individually with verbose output
$VerbosePreference = "Continue"
& ".\ps1-modules\phases\PhaseXX-Name.ps1" -Config $Config
```

## 📝 Contributing

To add a new phase:
1. Create `PhaseXX-Name.ps1` in `ps1-modules/phases/`
2. Follow the phase template structure
3. Add phase to the `$phases` array in `test-plugin-modular.ps1`
4. Update this README with phase description

## 📄 License

Part of WP Testing Framework - MIT License