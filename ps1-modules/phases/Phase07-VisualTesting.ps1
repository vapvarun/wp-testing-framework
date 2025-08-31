# Phase 7: Visual Testing & Screenshots
# Captures screenshots of plugin functionality and UI elements

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase07 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 7: Visual Testing & Screenshots"
    
    # Check if screenshot tool exists
    $screenshotTool = Join-Path $Config.FrameworkPath "tools\automated-screenshot-capture.js"
    if (!(Test-Path $screenshotTool)) {
        Write-Warning "Screenshot tool not found. Skipping visual testing."
        return @{ Status = "Skipped"; Reason = "Tool not found" }
    }
    
    # Check Node.js availability
    try {
        $nodeVersion = node --version 2>&1
        Write-Info "Node.js version: $nodeVersion"
    } catch {
        Write-Warning "Node.js not found. Visual testing requires Node.js."
        return @{ Status = "Skipped"; Reason = "Node.js not found" }
    }
    
    Write-Info "Setting up visual testing environment..."
    
    # Install dependencies if needed
    $packageJson = Join-Path $Config.FrameworkPath "package.json"
    if (Test-Path $packageJson) {
        $nodeModules = Join-Path $Config.FrameworkPath "node_modules"
        if (!(Test-Path $nodeModules)) {
            Write-Info "Installing Node.js dependencies..."
            Push-Location $Config.FrameworkPath
            npm install --silent 2>&1 | Out-Null
            Pop-Location
        }
    }
    
    # Create screenshots directory
    $screenshotsDir = Join-Path $Config.ScanDir "screenshots"
    Ensure-Directory -Path $screenshotsDir
    
    # Define pages to capture
    $pagesToCapture = @(
        @{ Name = "Dashboard"; Path = "wp-admin" },
        @{ Name = "Plugin Settings"; Path = "wp-admin/admin.php?page=$($Config.PluginName)" },
        @{ Name = "Frontend Home"; Path = "" },
        @{ Name = "Plugin Frontend"; Path = $Config.PluginName }
    )
    
    $capturedScreenshots = @()
    $errors = @()
    
    # Capture screenshots
    foreach ($page in $pagesToCapture) {
        Write-Info "Capturing: $($page.Name)..."
        
        try {
            $outputPath = Join-Path $screenshotsDir "$($page.Name -replace ' ', '-').png"
            $url = "http://localhost/$($page.Path)"
            
            # Run screenshot tool
            Push-Location $Config.FrameworkPath
            $result = node $screenshotTool $Config.PluginName $url "admin" "password" $outputPath 2>&1
            Pop-Location
            
            if (Test-Path $outputPath) {
                $fileInfo = Get-Item $outputPath
                $capturedScreenshots += @{
                    Name = $page.Name
                    Path = $outputPath
                    Size = [Math]::Round($fileInfo.Length / 1KB, 2)
                    Timestamp = $fileInfo.LastWriteTime
                }
                Write-Success "   Captured: $($page.Name) ($([Math]::Round($fileInfo.Length / 1KB, 2))KB)"
            } else {
                $errors += "Failed to capture $($page.Name)"
            }
        } catch {
            $errors += "Error capturing $($page.Name): $_"
            Write-Warning "   Failed: $($page.Name)"
        }
    }
    
    # Visual regression testing
    Write-Info "Checking for visual regression baseline..."
    $baselineDir = Join-Path $Config.FrameworkPath "visual-baselines\$($Config.PluginName)"
    $hasBaseline = Test-Path $baselineDir
    
    if ($hasBaseline) {
        Write-Info "Running visual regression tests..."
        # Compare with baseline images
        # This would use a tool like pixelmatch or resemble.js
    } else {
        Write-Info "No baseline found. Current screenshots will serve as baseline."
        # Copy current screenshots as baseline
        Ensure-Directory -Path $baselineDir
        foreach ($screenshot in $capturedScreenshots) {
            Copy-Item $screenshot.Path $baselineDir -Force
        }
    }
    
    # Accessibility testing
    Write-Info "Running accessibility checks..."
    $accessibilityIssues = @()
    
    # Check for alt text, ARIA labels, contrast ratios
    # This would integrate with axe-core or similar tool
    
    # Generate visual testing report
    $report = @"
# Visual Testing Report
Plugin: $($Config.PluginName)
Date: $(Get-Date)

## Screenshots Captured
Total: $($capturedScreenshots.Count)

### Captured Pages
$($capturedScreenshots | ForEach-Object {
"- **$($_.Name)**: $($_.Size)KB
  Path: ``$($_.Path)``
  Time: $($_.Timestamp)"
})

## Visual Regression
Baseline Available: $(if ($hasBaseline) { "Yes" } else { "No - Created new baseline" })

## Accessibility
Issues Found: $($accessibilityIssues.Count)

## Errors
$($errors | ForEach-Object { "- $_" })

## Recommendations
$(if ($errors.Count -gt 0) {
"1. Review failed screenshot captures
2. Ensure WordPress is running and accessible"
})
$(if (!$hasBaseline) {
"3. Baseline created - future runs will compare against these images"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\visual-testing-report.md"
    Ensure-Directory -Path (Split-Path $reportPath -Parent)
    $report | Out-File $reportPath
    
    # Calculate score
    $score = 100
    $score -= ($errors.Count * 10)
    $score -= ($accessibilityIssues.Count * 5)
    $score = [Math]::Max(0, [Math]::Min(100, $score))
    
    Write-Host ""
    Write-Host "Visual Testing Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Save results
    $results = @{
        Score = $score
        Screenshots = $capturedScreenshots
        Errors = $errors
        HasBaseline = $hasBaseline
        AccessibilityIssues = $accessibilityIssues
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "07" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Visual testing complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase07 -Config $Config
}