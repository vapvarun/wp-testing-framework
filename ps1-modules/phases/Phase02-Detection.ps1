# Phase 2: Plugin Detection & Basic Analysis
# Detects plugin, checks activation status, and gathers basic metrics

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase02 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 2: Plugin Detection & Basic Analysis"
    
    # Check if plugin exists
    if (!(Test-PluginExists -PluginPath $Config.PluginPath)) {
        Write-Error "Plugin not found: $($Config.PluginName)"
        return @{ Status = "Failed"; Error = "Plugin not found" }
    }
    
    Write-Success "Plugin $($Config.PluginName) found"
    
    # Get plugin metadata
    Write-Info "Extracting plugin metadata..."
    $metadata = Get-PluginMetadata -PluginPath $Config.PluginPath
    
    if ($metadata.Name) {
        Write-Success "Plugin: $($metadata.Name)"
        Write-Info "Version: $($metadata.Version)"
        Write-Info "Author: $($metadata.Author)"
    }
    
    # Check if plugin is active
    Write-Info "Checking plugin activation status..."
    
    $checkActive = @"
<?php
require_once('$($Config.WPPath)/wp-load.php');
\$active = is_plugin_active('$($Config.PluginName)/$($Config.PluginName).php');
echo json_encode(['active' => \$active]);
"@
    
    $tempFile = Join-Path $env:TEMP "check-active-$(Get-Random).php"
    $checkActive | Out-File $tempFile -Encoding UTF8
    
    try {
        $result = & php $tempFile 2>$null | ConvertFrom-Json
        if ($result.active) {
            Write-Success "Plugin is ACTIVE"
            $isActive = $true
        } else {
            Write-Warning "Plugin is INACTIVE"
            $isActive = $false
            
            # Offer to activate if in interactive mode
            if ($Config.InteractiveMode) {
                $activate = Read-Host "Would you like to activate the plugin? (Y/N)"
                if ($activate -eq "Y" -or $activate -eq "y") {
                    Write-Info "Activating plugin..."
                    $activateScript = @"
<?php
require_once('$($Config.WPPath)/wp-load.php');
\$result = activate_plugin('$($Config.PluginName)/$($Config.PluginName).php');
echo json_encode(['success' => is_null(\$result)]);
"@
                    $activateScript | Out-File $tempFile -Encoding UTF8
                    $activateResult = & php $tempFile 2>$null | ConvertFrom-Json
                    if ($activateResult.success) {
                        Write-Success "Plugin activated successfully"
                        $isActive = $true
                    }
                }
            }
        }
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    # Count files
    Write-Info "Analyzing file structure..."
    $fileStats = Get-FileStats -Path $Config.PluginPath
    
    Write-Info "Found: $($fileStats.PHP) PHP, $($fileStats.JS) JS, $($fileStats.CSS) CSS files"
    
    # Check for common WordPress plugin files
    $pluginFiles = @{
        Readme = (Test-Path (Join-Path $Config.PluginPath "readme.txt")) -or 
                 (Test-Path (Join-Path $Config.PluginPath "README.md"))
        License = Test-Path (Join-Path $Config.PluginPath "license.txt")
        Uninstall = Test-Path (Join-Path $Config.PluginPath "uninstall.php")
        Composer = Test-Path (Join-Path $Config.PluginPath "composer.json")
        Package = Test-Path (Join-Path $Config.PluginPath "package.json")
    }
    
    # Calculate plugin size
    $pluginSize = (Get-ChildItem -Path $Config.PluginPath -Recurse | 
                   Measure-Object -Property Length -Sum).Sum / 1MB
    $pluginSize = [math]::Round($pluginSize, 2)
    
    Write-Info "Plugin size: ${pluginSize}MB"
    
    # Save results
    $results = @{
        PluginName = $Config.PluginName
        Metadata = $metadata
        IsActive = $isActive
        FileStats = $fileStats
        PluginFiles = $pluginFiles
        PluginSize = $pluginSize
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "02" -Results $results -OutputPath $Config.ScanDir
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase02 -Config $Config
}