# Phase 13: Framework Safekeeping
# Archives results and maintains framework integrity

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase13 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 13: Framework Safekeeping"
    
    Write-Info "Archiving test results and maintaining framework..."
    
    $safekeepingResults = @{
        ArchivedItems = @()
        CleanedItems = @()
        BackupLocation = ""
        FrameworkHealth = @{}
        MaintenanceTasks = @()
    }
    
    # Create safekeeping directory structure
    $safekeepDir = Join-Path $Config.FrameworkPath "safekeeping"
    $archiveDir = Join-Path $safekeepDir "archives"
    $backupDir = Join-Path $safekeepDir "backups"
    $historyDir = Join-Path $safekeepDir "history"
    
    Ensure-Directory -Path $safekeepDir
    Ensure-Directory -Path $archiveDir
    Ensure-Directory -Path $backupDir
    Ensure-Directory -Path $historyDir
    
    # Archive current scan results
    Write-Info "Archiving scan results..."
    
    if (Test-Path $Config.ScanDir) {
        $archiveName = "$($Config.PluginName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        $archivePath = Join-Path $archiveDir $archiveName
        
        try {
            # Create archive
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($Config.ScanDir, $archivePath)
            
            $safekeepingResults.ArchivedItems += @{
                Name = $archiveName
                Path = $archivePath
                Size = [Math]::Round((Get-Item $archivePath).Length / 1MB, 2)
                Date = Get-Date
            }
            
            Write-Success "   Archived to: $archiveName ($([Math]::Round((Get-Item $archivePath).Length / 1MB, 2))MB)"
        } catch {
            Write-Warning "   Failed to create archive: $_"
        }
    }
    
    # Maintain scan history
    Write-Info "Updating scan history..."
    
    $historyFile = Join-Path $historyDir "scan-history.json"
    $history = @()
    
    if (Test-Path $historyFile) {
        $history = Get-Content $historyFile -Raw | ConvertFrom-Json
    }
    
    # Load phase 10 results for summary
    $phase10Results = Get-PhaseResults -Phase "10" -OutputPath $Config.ScanDir
    
    $historyEntry = @{
        Plugin = $Config.PluginName
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Mode = $Config.Mode
        Score = if ($phase10Results -and $phase10Results.OverallMetrics) { 
            $phase10Results.OverallMetrics.AverageScore 
        } else { 0 }
        CriticalIssues = if ($phase10Results -and $phase10Results.OverallMetrics) { 
            $phase10Results.OverallMetrics.CriticalIssues 
        } else { 0 }
        ArchivePath = if ($safekeepingResults.ArchivedItems.Count -gt 0) {
            $safekeepingResults.ArchivedItems[0].Path
        } else { "" }
    }
    
    $history += $historyEntry
    
    # Keep only last 100 entries
    if ($history.Count -gt 100) {
        $history = $history[-100..-1]
    }
    
    $history | ConvertTo-Json -Depth 5 | Out-File $historyFile
    Write-Success "   Scan history updated"
    
    # Clean up old files
    Write-Info "Cleaning up old files..."
    
    # Clean archives older than 30 days
    $oldArchives = Get-ChildItem $archiveDir -Filter "*.zip" | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    
    foreach ($oldArchive in $oldArchives) {
        Remove-Item $oldArchive.FullName -Force
        $safekeepingResults.CleanedItems += $oldArchive.Name
        Write-Info "   Removed old archive: $($oldArchive.Name)"
    }
    
    # Framework health check
    Write-Info "Performing framework health check..."
    
    $safekeepingResults.FrameworkHealth = @{
        CoreFiles = @{}
        Dependencies = @{}
        Permissions = @{}
    }
    
    # Check core files
    $coreFiles = @(
        "test-plugin.ps1",
        "test-plugin.sh",
        "package.json",
        "composer.json",
        "README.md"
    )
    
    foreach ($file in $coreFiles) {
        $filePath = Join-Path $Config.FrameworkPath $file
        $safekeepingResults.FrameworkHealth.CoreFiles[$file] = Test-Path $filePath
        
        if (!(Test-Path $filePath)) {
            Write-Warning "   Missing core file: $file"
        }
    }
    
    # Check Node.js dependencies
    $nodeModules = Join-Path $Config.FrameworkPath "node_modules"
    $safekeepingResults.FrameworkHealth.Dependencies["NodeModules"] = Test-Path $nodeModules
    
    # Check PHP dependencies
    $vendor = Join-Path $Config.FrameworkPath "vendor"
    $safekeepingResults.FrameworkHealth.Dependencies["Composer"] = Test-Path $vendor
    
    # Backup framework configuration
    Write-Info "Backing up framework configuration..."
    
    $configBackup = @{
        Date = Get-Date
        FrameworkVersion = "12.0"
        LastPlugin = $Config.PluginName
        Settings = @{
            UsePHPStan = $Config.UsePHPStan
            UseXdebug = $Config.UseXdebug
            AutoInstallTools = $Config.AutoInstallTools
        }
        Health = $safekeepingResults.FrameworkHealth
    }
    
    $configBackupPath = Join-Path $backupDir "framework-config.json"
    $configBackup | ConvertTo-Json -Depth 5 | Out-File $configBackupPath
    
    # Maintenance tasks
    Write-Info "Performing maintenance tasks..."
    
    # Update framework version file
    $versionFile = Join-Path $Config.FrameworkPath "VERSION"
    "12.0" | Out-File $versionFile
    $safekeepingResults.MaintenanceTasks += "Updated VERSION file"
    
    # Check for framework updates
    if (Test-Path (Join-Path $Config.FrameworkPath ".git")) {
        Write-Info "   Checking for framework updates..."
        Push-Location $Config.FrameworkPath
        $gitStatus = git status --porcelain 2>&1
        Pop-Location
        
        if ($gitStatus) {
            $safekeepingResults.MaintenanceTasks += "Uncommitted changes detected"
        }
    }
    
    # Generate maintenance report
    $report = @"
# Framework Safekeeping Report
Date: $(Get-Date)
Plugin Tested: $($Config.PluginName)

## Archives
- Created: $($safekeepingResults.ArchivedItems.Count)
- Cleaned: $($safekeepingResults.CleanedItems.Count)
- Location: $archiveDir

### Recent Archives
$(($safekeepingResults.ArchivedItems | ForEach-Object {
"- $($_.Name): $($_.Size)MB"
}) -join "\n")

## Framework Health

### Core Files
$(($safekeepingResults.FrameworkHealth.CoreFiles.GetEnumerator() | ForEach-Object {
"- $($_.Key): $(if ($_.Value) { "✅" } else { "❌" })"
}) -join "\n")

### Dependencies
- Node Modules: $(if ($safekeepingResults.FrameworkHealth.Dependencies.NodeModules) { "✅ Installed" } else { "❌ Missing" })
- Composer: $(if ($safekeepingResults.FrameworkHealth.Dependencies.Composer) { "✅ Installed" } else { "❌ Missing" })

## Scan History
Total Scans Recorded: $($history.Count)

### Recent Scans
$(($history | Select-Object -Last 5 | ForEach-Object {
"- $($_.Plugin) - $($_.Date) - Score: $($_.Score)/100"
}) -join "\n")

## Maintenance Tasks
$(($safekeepingResults.MaintenanceTasks | ForEach-Object { "- $_" }) -join "\n")

## Storage Usage
- Archives: $(Get-ChildItem $archiveDir -Filter "*.zip" | Measure-Object -Property Length -Sum | ForEach-Object { [Math]::Round($_.Sum / 1MB, 2) })MB
- Total Safekeeping: $(Get-ChildItem $safekeepDir -Recurse -File | Measure-Object -Property Length -Sum | ForEach-Object { [Math]::Round($_.Sum / 1MB, 2) })MB

## Recommendations
$(if ($safekeepingResults.CleanedItems.Count -gt 10) {
"1. Consider adjusting archive retention policy"
})
$(if (!$safekeepingResults.FrameworkHealth.Dependencies.NodeModules) {
"2. Run 'npm install' to install Node.js dependencies"
})
$(if (!$safekeepingResults.FrameworkHealth.Dependencies.Composer) {
"3. Run 'composer install' to install PHP dependencies"
})
$(if (($safekeepingResults.FrameworkHealth.CoreFiles.Values | Where-Object { -not $_ }).Count -gt 0) {
"4. Some core files are missing - check framework integrity"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\safekeeping-report.md"
    Ensure-Directory -Path (Split-Path $reportPath -Parent)
    $report | Out-File $reportPath
    
    # Calculate safekeeping score
    $score = 100
    $score -= (($safekeepingResults.FrameworkHealth.CoreFiles.Values | Where-Object { -not $_ }).Count * 10)
    $score -= $(if (!$safekeepingResults.FrameworkHealth.Dependencies.NodeModules) { 10 } else { 0 })
    $score -= $(if (!$safekeepingResults.FrameworkHealth.Dependencies.Composer) { 10 } else { 0 })
    $score = [Math]::Max(0, [Math]::Min(100, $score))
    
    Write-Host ""
    Write-Host "Safekeeping Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Save results
    $results = @{
        Score = $score
        ArchivedItems = $safekeepingResults.ArchivedItems
        CleanedItems = $safekeepingResults.CleanedItems
        FrameworkHealth = $safekeepingResults.FrameworkHealth
        MaintenanceTasks = $safekeepingResults.MaintenanceTasks
        HistoryEntries = $history.Count
        BackupLocation = $safekeepDir
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "12" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Framework safekeeping complete!"
    Write-Info "Archives stored in: $archiveDir"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase12 -Config $Config
}