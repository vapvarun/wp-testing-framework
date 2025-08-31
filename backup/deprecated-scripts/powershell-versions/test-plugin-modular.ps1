# WordPress Plugin Testing Framework v12.0 - Modular PowerShell Edition
# Main orchestrator script that calls individual phase modules
# Usage: .\test-plugin-modular.ps1 <plugin-name> [-Mode <full|quick|security|ai>] [-SkipPhases 1,2,3]

param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("full", "quick", "security", "performance", "ai")]
    [string]$Mode = "full",
    
    [Parameter(Mandatory=$false)]
    [int[]]$SkipPhases = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoInstallTools,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Script configuration
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Show help if requested
if ($Help) {
    Write-Host @"
WordPress Plugin Testing Framework v12.0 - Modular Edition
===========================================================

USAGE:
    .\test-plugin-modular.ps1 <plugin-name> [options]

PARAMETERS:
    -PluginName      : Name of the plugin to test (required)
    -Mode            : Testing mode (full|quick|security|performance|ai)
    -SkipPhases      : Comma-separated list of phase numbers to skip
    -NonInteractive  : Run without user prompts
    -AutoInstallTools: Automatically install missing tools
    -GenerateOnly    : Only generate tests, don't execute them
    -Help           : Show this help message

EXAMPLES:
    # Full analysis with all 12 phases
    .\test-plugin-modular.ps1 woocommerce
    
    # Quick mode (skips time-consuming phases)
    .\test-plugin-modular.ps1 elementor -Mode quick
    
    # Skip specific phases
    .\test-plugin-modular.ps1 yoast-seo -SkipPhases 7,8,11
    
    # Non-interactive mode for CI/CD
    .\test-plugin-modular.ps1 wpforms -NonInteractive
    
    # Generate tests only
    .\test-plugin-modular.ps1 buddypress -GenerateOnly

PHASES:
    1.  Setup & Directory Structure
    2.  Plugin Detection & Basic Analysis
    3.  AI-Driven Code Analysis (AST + Dynamic)
    4.  Security Vulnerability Scanning
    5.  Performance Analysis
    6.  Test Generation, Execution & Coverage
    7.  Visual Testing & Screenshots
    8.  WordPress Integration Tests
    9.  Documentation Generation & Quality Validation
    10. Consolidating All Reports
    11. Live Testing with Test Data
    12. Framework Safekeeping

MODES:
    full        : Run all 12 phases (default)
    quick       : Skip time-consuming phases (3,7,11)
    security    : Focus on security analysis (phases 1-4)
    performance : Focus on performance (phases 1-5)
    ai          : AI-enhanced analysis (requires API key)

"@ -ForegroundColor Cyan
    exit 0
}

# Get script paths
$FRAMEWORK_PATH = $PSScriptRoot
$MODULES_PATH = Join-Path $FRAMEWORK_PATH "ps1-modules"
$PHASES_PATH = Join-Path $MODULES_PATH "phases"
$SHARED_PATH = Join-Path $MODULES_PATH "shared"

# Import common functions
Import-Module "$SHARED_PATH\Common-Functions.ps1" -Force

# Initialize global configuration
$Global:Config = @{
    PluginName = $PluginName
    Mode = $Mode
    SkipPhases = $SkipPhases
    InteractiveMode = -not $NonInteractive
    AutoInstallTools = $AutoInstallTools
    GenerateOnly = $GenerateOnly
    QuickMode = ($Mode -eq "quick")
    
    # Paths
    FrameworkPath = $FRAMEWORK_PATH
    WPPath = Split-Path $FRAMEWORK_PATH -Parent
    PluginPath = Join-Path (Split-Path $FRAMEWORK_PATH -Parent) "wp-content\plugins\$PluginName"
    UploadPath = Join-Path (Split-Path $FRAMEWORK_PATH -Parent) "wp-content\uploads"
    
    # Runtime paths (will be set by Phase 1)
    ScanDir = ""
    PlanDir = ""
    SafekeepDir = ""
    Timestamp = ""
    
    # Options
    UsePHPStan = $true
    UseXdebug = $true
    RunTests = -not $GenerateOnly
}

# Define phases to skip based on mode
switch ($Mode) {
    "quick" {
        $Global:Config.SkipPhases += @(3, 7, 11)
    }
    "security" {
        $Global:Config.SkipPhases += @(5, 6, 7, 8, 9, 10, 11, 12)
    }
    "performance" {
        $Global:Config.SkipPhases += @(6, 7, 8, 9, 10, 11, 12)
    }
}

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   WP Testing Framework v12.0 - Modular     ║" -ForegroundColor Blue
Write-Host "║   Complete Plugin Analysis & Testing       ║" -ForegroundColor Blue
Write-Host "║   Plugin: $PluginName" -ForegroundColor Blue
Write-Host "║   Mode: $Mode" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Phase definitions
$phases = @(
    @{ Number = 1;  Name = "Setup";           Script = "Phase01-Setup.ps1" },
    @{ Number = 2;  Name = "Detection";       Script = "Phase02-Detection.ps1" },
    @{ Number = 3;  Name = "AI Analysis";     Script = "Phase03-AIAnalysis.ps1" },
    @{ Number = 4;  Name = "Security";        Script = "Phase04-Security.ps1" },
    @{ Number = 5;  Name = "Performance";     Script = "Phase05-Performance.ps1" },
    @{ Number = 6;  Name = "Test Generation"; Script = "Phase06-TestGeneration.ps1" },
    @{ Number = 7;  Name = "Visual Testing";  Script = "Phase07-VisualTesting.ps1" },
    @{ Number = 8;  Name = "Integration";     Script = "Phase08-Integration.ps1" },
    @{ Number = 9;  Name = "Documentation";   Script = "Phase09-Documentation.ps1" },
    @{ Number = 10; Name = "Consolidation";   Script = "Phase10-Consolidation.ps1" },
    @{ Number = 11; Name = "Live Testing";    Script = "Phase11-LiveTesting.ps1" },
    @{ Number = 12; Name = "Safekeeping";     Script = "Phase12-Safekeeping.ps1" }
)

# Results collection
$Global:Results = @{}
$startTime = Get-Date

# Execute phases
foreach ($phase in $phases) {
    # Check if phase should be skipped
    if ($phase.Number -in $Global:Config.SkipPhases) {
        Write-Warning "Skipping Phase $($phase.Number): $($phase.Name) (as requested)"
        $Global:Results["Phase$($phase.Number)"] = @{ Status = "Skipped" }
        continue
    }
    
    # Check if phase script exists
    $phaseScript = Join-Path $PHASES_PATH $phase.Script
    if (!(Test-Path $phaseScript)) {
        Write-Warning "Phase $($phase.Number) script not found: $($phase.Script)"
        Write-Info "Creating placeholder for Phase $($phase.Number)..."
        
        # Create a simple placeholder if the phase doesn't exist yet
        $placeholderContent = @"
# Phase $($phase.Number): $($phase.Name)
# TODO: Implement this phase

param([hashtable]`$Config)
Import-Module "`$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase$($phase.Number.ToString().PadLeft(2, '0')) {
    param([hashtable]`$Config)
    Write-Phase "PHASE $($phase.Number): $($phase.Name)"
    Write-Warning "This phase is not yet implemented"
    return @{ Status = "NotImplemented" }
}

if (`$MyInvocation.InvocationName -ne '.') {
    Invoke-Phase$($phase.Number.ToString().PadLeft(2, '0')) -Config `$Config
}
"@
        $placeholderContent | Out-File $phaseScript -Encoding UTF8
    }
    
    # Execute phase
    try {
        Write-Info "Executing Phase $($phase.Number): $($phase.Name)..."
        
        # Dot-source the phase script to get its function
        . $phaseScript
        
        # Call the phase function
        $functionName = "Invoke-Phase$($phase.Number.ToString().PadLeft(2, '0'))"
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            $phaseResult = & $functionName -Config $Global:Config
            $Global:Results["Phase$($phase.Number)"] = $phaseResult
        } else {
            Write-Warning "Phase function $functionName not found"
            $Global:Results["Phase$($phase.Number)"] = @{ Status = "Error"; Message = "Function not found" }
        }
    }
    catch {
        Write-Error "Error in Phase $($phase.Number): $_"
        $Global:Results["Phase$($phase.Number)"] = @{ Status = "Error"; Error = $_.ToString() }
        
        if ($Global:Config.InteractiveMode) {
            $continue = Read-Host "Continue with remaining phases? (Y/N)"
            if ($continue -ne "Y" -and $continue -ne "y") {
                break
            }
        }
    }
}

# Calculate execution time
$endTime = Get-Date
$duration = $endTime - $startTime

# Generate final report
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "🎉 ANALYSIS COMPLETE!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Execution Summary:" -ForegroundColor Blue
Write-Host "   Plugin: $PluginName"
Write-Host "   Mode: $Mode"
Write-Host "   Duration: $($duration.ToString('mm\:ss'))"
Write-Host ""

Write-Host "📈 Phase Results:" -ForegroundColor Blue
foreach ($phase in $phases) {
    $result = $Global:Results["Phase$($phase.Number)"]
    $status = if ($result.Status -eq "Completed") { "✅" } 
              elseif ($result.Status -eq "Skipped") { "⏭️" }
              elseif ($result.Status -eq "NotImplemented") { "🚧" }
              else { "❌" }
    
    Write-Host "   Phase $($phase.Number.ToString().PadLeft(2)): $status $($phase.Name)"
}

# Save final results
if ($Global:Config.ScanDir -and (Test-Path $Global:Config.ScanDir)) {
    $finalResults = @{
        PluginName = $PluginName
        Mode = $Mode
        StartTime = $startTime
        EndTime = $endTime
        Duration = $duration.TotalSeconds
        PhaseResults = $Global:Results
    }
    
    $resultsPath = Join-Path $Global:Config.ScanDir "final-results.json"
    $finalResults | ConvertTo-Json -Depth 10 | Out-File $resultsPath
    
    Write-Host ""
    Write-Host "📁 Results saved to:" -ForegroundColor Blue
    Write-Host "   $resultsPath"
}

# Open reports if in interactive mode
if ($Global:Config.InteractiveMode -and $Global:Config.ScanDir) {
    Write-Host ""
    $openReport = Read-Host "Open analysis report? (Y/N)"
    if ($openReport -eq "Y" -or $openReport -eq "y") {
        $reportPath = Join-Path $Global:Config.ScanDir "reports"
        if (Test-Path $reportPath) {
            Start-Process $reportPath
        }
    }
}

Write-Host ""
Write-Host "Thank you for using WP Testing Framework!" -ForegroundColor Green