# WordPress Plugin Testing Framework - Run Specific Phase
# Allows running individual phases on demand
# Usage: .\run-phase.ps1 -Plugin <plugin-name> -Phase <1-12> [-ConfigFile <path>]

param(
    [Parameter(Mandatory=$false)]
    [string]$Plugin,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,12)]
    [int]$Phase,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListPhases,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Script configuration
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Get script paths
$FRAMEWORK_PATH = $PSScriptRoot
$MODULES_PATH = Join-Path $FRAMEWORK_PATH "ps1-modules"
$PHASES_PATH = Join-Path $MODULES_PATH "phases"
$SHARED_PATH = Join-Path $MODULES_PATH "shared"

# Phase information
$phaseInfo = @{
    1 = @{ Name = "Setup & Directory Structure"; Script = "Phase01-Setup.ps1"; Description = "Creates directory structure and initializes environment" }
    2 = @{ Name = "Plugin Detection"; Script = "Phase02-Detection.ps1"; Description = "Detects plugin features and analyzes structure" }
    3 = @{ Name = "AI Analysis"; Script = "Phase03-AIAnalysis.ps1"; Description = "Performs AI-driven code analysis and AST parsing" }
    4 = @{ Name = "Security Scan"; Script = "Phase04-Security.ps1"; Description = "Scans for security vulnerabilities" }
    5 = @{ Name = "Performance Analysis"; Script = "Phase05-Performance.ps1"; Description = "Analyzes performance metrics and bottlenecks" }
    6 = @{ Name = "Test Generation"; Script = "Phase06-TestGeneration.ps1"; Description = "Generates and executes PHPUnit tests" }
    7 = @{ Name = "Visual Testing"; Script = "Phase07-VisualTesting.ps1"; Description = "Captures screenshots and performs visual regression" }
    8 = @{ Name = "Integration Tests"; Script = "Phase08-Integration.ps1"; Description = "Tests WordPress integration points" }
    9 = @{ Name = "Documentation"; Script = "Phase09-Documentation.ps1"; Description = "Generates documentation and validates quality" }
    10 = @{ Name = "Consolidation"; Script = "Phase10-Consolidation.ps1"; Description = "Consolidates all reports into final summary" }
    11 = @{ Name = "Live Testing"; Script = "Phase11-LiveTesting.ps1"; Description = "Performs live testing with generated data" }
    12 = @{ Name = "Safekeeping"; Script = "Phase12-Safekeeping.ps1"; Description = "Archives results and maintains framework" }
}

# Show help
if ($Help -or (!$Plugin -and !$ListPhases -and !$ConfigFile)) {
    Write-Host @"
WordPress Plugin Testing Framework - Phase Runner
================================================

Run individual testing phases on demand.

USAGE:
    .\run-phase.ps1 -Plugin <name> -Phase <1-12>
    .\run-phase.ps1 -ConfigFile <path>
    .\run-phase.ps1 -ListPhases

PARAMETERS:
    -Plugin      : Name of the plugin to test
    -Phase       : Phase number to run (1-12)
    -ConfigFile  : Path to saved configuration JSON file
    -ListPhases  : List all available phases
    -Help        : Show this help message

EXAMPLES:
    # Run security scan on WooCommerce
    .\run-phase.ps1 -Plugin woocommerce -Phase 4
    
    # Run performance analysis
    .\run-phase.ps1 -Plugin elementor -Phase 5
    
    # Generate tests for a plugin
    .\run-phase.ps1 -Plugin wpforms -Phase 6
    
    # Run using saved configuration
    .\run-phase.ps1 -ConfigFile "C:\scans\config.json"
    
    # List all available phases
    .\run-phase.ps1 -ListPhases

NOTES:
    - Phase 1 must be run first for new plugins to set up directories
    - Some phases depend on results from previous phases
    - Configuration is saved after each run for reuse

"@ -ForegroundColor Cyan
    exit 0
}

# List phases
if ($ListPhases) {
    Write-Host ""
    Write-Host "Available Phases:" -ForegroundColor Blue
    Write-Host "═════════════════" -ForegroundColor Blue
    Write-Host ""
    
    for ($i = 1; $i -le 12; $i++) {
        $info = $phaseInfo[$i]
        Write-Host "Phase $($i.ToString().PadLeft(2)): $($info.Name)" -ForegroundColor Green
        Write-Host "         $($info.Description)" -ForegroundColor Gray
        Write-Host ""
    }
    exit 0
}

# Import common functions
Import-Module "$SHARED_PATH\Common-Functions.ps1" -Force

# Load or create configuration
$Config = $null

if ($ConfigFile -and (Test-Path $ConfigFile)) {
    Write-Info "Loading configuration from: $ConfigFile"
    $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json -AsHashtable
    
    # Override with command line parameters if provided
    if ($Plugin) { $Config.PluginName = $Plugin }
    if ($Phase) { $Config.RunPhase = $Phase }
} elseif ($Plugin) {
    # Create new configuration
    $Config = @{
        PluginName = $Plugin
        RunPhase = $Phase
        Mode = "single"
        InteractiveMode = $true
        FrameworkPath = $FRAMEWORK_PATH
        WPPath = Split-Path $FRAMEWORK_PATH -Parent
        PluginPath = Join-Path (Split-Path $FRAMEWORK_PATH -Parent) "wp-content\plugins\$Plugin"
        UploadPath = Join-Path (Split-Path $FRAMEWORK_PATH -Parent) "wp-content\uploads"
        UsePHPStan = $true
        UseXdebug = $true
    }
} else {
    Write-Error "Please provide either -Plugin and -Phase, or -ConfigFile"
    exit 1
}

# Validate plugin exists
if (!(Test-Path $Config.PluginPath)) {
    Write-Error "Plugin not found at: $($Config.PluginPath)"
    exit 1
}

# Check if we need to run Phase 1 first
$needsSetup = $false
if ($Config.RunPhase -ne 1) {
    # Check if previous runs exist
    $scanDirPattern = Join-Path (Split-Path $FRAMEWORK_PATH -Parent) "wp-content\uploads\wbcom-scan\$($Config.PluginName)"
    
    if (!(Test-Path $scanDirPattern)) {
        Write-Warning "No previous scan found for $($Config.PluginName)"
        $response = Read-Host "Run Phase 1 (Setup) first? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            $needsSetup = $true
        } else {
            Write-Warning "Some phases require Phase 1 to be run first. Continuing anyway..."
        }
    } else {
        # Find most recent scan
        $latestScan = Get-ChildItem $scanDirPattern -Directory | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($latestScan) {
            $Config.ScanDir = $latestScan.FullName
            Write-Info "Using existing scan directory: $($Config.ScanDir)"
        }
    }
}

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   WP Testing Framework - Phase Runner      ║" -ForegroundColor Blue
Write-Host "║   Plugin: $($Config.PluginName.PadRight(33))║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Run Phase 1 if needed
if ($needsSetup) {
    Write-Info "Running Phase 1: Setup first..."
    $phaseScript = Join-Path $PHASES_PATH $phaseInfo[1].Script
    
    if (Test-Path $phaseScript) {
        . $phaseScript
        $setupResult = Invoke-Phase01 -Config $Config
        
        if ($setupResult.Status -eq "Completed") {
            Write-Success "Setup completed successfully"
            # Update config with new paths
            $Config.ScanDir = $setupResult.Directories.ScanDir
            $Config.PlanDir = $setupResult.Directories.PlanDir
            $Config.SafekeepDir = $setupResult.Directories.SafekeepDir
            $Config.Timestamp = $setupResult.Timestamp
        } else {
            Write-Error "Setup failed. Cannot continue."
            exit 1
        }
    }
}

# Run the requested phase
$phaseNum = $Config.RunPhase
$info = $phaseInfo[$phaseNum]

Write-Host ""
Write-Phase "RUNNING PHASE $phaseNum: $($info.Name)"
Write-Info $info.Description
Write-Host ""

$phaseScript = Join-Path $PHASES_PATH $info.Script

if (!(Test-Path $phaseScript)) {
    Write-Error "Phase script not found: $($info.Script)"
    exit 1
}

# Load and execute the phase
try {
    . $phaseScript
    $functionName = "Invoke-Phase$($phaseNum.ToString().PadLeft(2, '0'))"
    
    if (Get-Command $functionName -ErrorAction SilentlyContinue) {
        $startTime = Get-Date
        
        # Execute the phase
        $result = & $functionName -Config $Config
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Display results
        Write-Host ""
        Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
        Write-Host "Phase $phaseNum Completed" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
        
        if ($result.Status) {
            Write-Host "Status: $($result.Status)" -ForegroundColor $(if ($result.Status -eq "Completed") { "Green" } else { "Yellow" })
        }
        
        if ($result.Score) {
            Write-Host "Score: $($result.Score)/100" -ForegroundColor $(
                if ($result.Score -ge 80) { "Green" }
                elseif ($result.Score -ge 60) { "Yellow" }
                else { "Red" }
            )
        }
        
        if ($result.ReportPath) {
            Write-Host "Report: $($result.ReportPath)" -ForegroundColor Cyan
        }
        
        Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
        
        # Save configuration for reuse
        $configSavePath = Join-Path $Config.FrameworkPath "last-phase-config.json"
        $Config | ConvertTo-Json -Depth 5 | Out-File $configSavePath
        Write-Host ""
        Write-Info "Configuration saved to: $configSavePath"
        Write-Info "Rerun with: .\run-phase.ps1 -ConfigFile `"$configSavePath`""
        
        # Save phase results if scan directory exists
        if ($Config.ScanDir -and (Test-Path $Config.ScanDir)) {
            Save-PhaseResults -Phase $phaseNum.ToString().PadLeft(2, '0') -Results $result -OutputPath $Config.ScanDir
            Write-Success "Results saved to scan directory"
        }
        
    } else {
        Write-Error "Phase function $functionName not found in module"
        exit 1
    }
} catch {
    Write-Error "Error executing phase: $_"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Success "Phase $phaseNum execution complete!"

# Suggest next steps
if ($phaseNum -lt 12) {
    $nextPhase = $phaseNum + 1
    $nextInfo = $phaseInfo[$nextPhase]
    Write-Host ""
    Write-Host "Next Step:" -ForegroundColor Blue
    Write-Host "Run Phase $nextPhase ($($nextInfo.Name)):" -ForegroundColor Gray
    Write-Host ".\run-phase.ps1 -Plugin $($Config.PluginName) -Phase $nextPhase" -ForegroundColor Yellow
}

if ($phaseNum -eq 10) {
    Write-Host ""
    Write-Host "Tip: Phase 10 consolidates all previous phase results." -ForegroundColor Cyan
    Write-Host "Make sure you've run all needed phases before consolidation." -ForegroundColor Cyan
}