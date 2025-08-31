# Phase 1: Setup & Directory Structure
# Creates all necessary directories and prepares the environment

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase01 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 1: Setup & Directory Structure"
    
    # Create timestamp-based paths
    $DATE_MONTH = Get-Date -Format "yyyy-MM"
    $TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Define directory structure
    $directories = @{
        ScanDir = Join-Path $Config.UploadPath "wbcom-scan\$($Config.PluginName)\$DATE_MONTH"
        PlanDir = Join-Path $Config.UploadPath "wbcom-plan\$($Config.PluginName)\$DATE_MONTH"
        SafekeepDir = Join-Path $Config.FrameworkPath "plugins\$($Config.PluginName)"
    }
    
    # Create all directories
    $subDirs = @(
        "$($directories.ScanDir)\raw-outputs",
        "$($directories.ScanDir)\raw-outputs\coverage",
        "$($directories.ScanDir)\raw-outputs\security",
        "$($directories.ScanDir)\raw-outputs\performance",
        "$($directories.ScanDir)\ai-analysis",
        "$($directories.ScanDir)\reports",
        "$($directories.ScanDir)\generated-tests",
        "$($directories.PlanDir)\documentation",
        "$($directories.PlanDir)\test-results",
        "$($directories.PlanDir)\ai-enhanced",
        "$($directories.SafekeepDir)\developer-tasks",
        "$($directories.SafekeepDir)\final-reports-$TIMESTAMP"
    )
    
    foreach ($dir in $subDirs) {
        Ensure-Directory -Path $dir
    }
    
    Write-Success "Directory structure created successfully"
    
    # Check for required tools
    Write-Info "Checking required tools..."
    
    $tools = @{
        PHP = (Get-Command php -ErrorAction SilentlyContinue) -ne $null
        Node = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        Composer = (Get-Command composer -ErrorAction SilentlyContinue) -ne $null
        Git = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
    }
    
    foreach ($tool in $tools.GetEnumerator()) {
        if ($tool.Value) {
            Write-Success "$($tool.Key) is installed"
        } else {
            Write-Warning "$($tool.Key) is not installed"
        }
    }
    
    # Install Composer if missing and requested
    if (!$tools.Composer -and $Config.AutoInstallTools) {
        Write-Info "Installing Composer..."
        $composerInstaller = Join-Path $env:TEMP "composer-setup.php"
        Invoke-WebRequest -Uri "https://getcomposer.org/installer" -OutFile $composerInstaller
        & php $composerInstaller --install-dir="$($Config.FrameworkPath)\tools" --filename=composer.phar
        Remove-Item $composerInstaller
        Write-Success "Composer installed"
    }
    
    # Save phase results
    $results = @{
        Directories = $directories
        Timestamp = $TIMESTAMP
        DateMonth = $DATE_MONTH
        ToolsAvailable = $tools
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "01" -Results $results -OutputPath $directories.ScanDir
    
    # Update global config with paths
    $Config.ScanDir = $directories.ScanDir
    $Config.PlanDir = $directories.PlanDir
    $Config.SafekeepDir = $directories.SafekeepDir
    $Config.Timestamp = $TIMESTAMP
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase01 -Config $Config
}