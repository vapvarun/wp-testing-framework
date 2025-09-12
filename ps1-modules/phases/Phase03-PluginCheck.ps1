# Phase 3: WordPress Plugin Check Integration
# This phase runs the official WordPress Plugin Check tool to analyze plugin compliance
# Runs early so AI and other analysis phases can use the data

# Import common functions
$SharedPath = Join-Path $PSScriptRoot "..\shared\Common-Functions.ps1"
if (Test-Path $SharedPath) {
    . $SharedPath
}

# Main phase function
function Invoke-Phase03 {
    param(
        [hashtable]$Config
    )
    
    if (-not $Config.PluginName) {
        Write-Error "Plugin name required"
        return @{ Status = "Failed"; Error = "Plugin name required" }
    }

    Write-Phase "PHASE 3: WordPress Plugin Check Analysis"

    # Initialize paths
    $WPContentPath = if ($env:WP_CONTENT_PATH) { $env:WP_CONTENT_PATH } else { 
        Join-Path (Split-Path $Config.FrameworkPath -Parent) "wp-content"
    }
    $PluginPath = Join-Path $WPContentPath "plugins\$($Config.PluginName)"
    $ScanDir = Join-Path $WPContentPath "uploads\wbcom-scan\$($Config.PluginName)\$(Get-Date -Format 'yyyy-MM')"
    $PluginCheckDir = Join-Path $ScanDir "plugin-check"
    
    # Create directory for plugin check results
    Ensure-Directory -Path $PluginCheckDir

    # Validate plugin
    if (!(Test-Path $PluginPath)) {
        Write-Error "Plugin not found: $PluginPath"
        return @{ Status = "Failed"; Error = "Plugin not found" }
    }

    Write-Info "Running WordPress Plugin Check analysis for: $($Config.PluginName)"
    
    # Plugin Check path
    $PluginCheckPath = Join-Path $WPContentPath "plugins\plugin-check"
    
    # Ensure Plugin Check is installed
    if (!(Test-Path $PluginCheckPath)) {
        Write-Warning "Plugin Check not found. Installing..."
        try {
            $installResult = & wp plugin install plugin-check --quiet 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to install Plugin Check: $installResult"
            }
        }
        catch {
            Write-Warning "Error installing Plugin Check: $_"
        }
    }
    
    # Setup Plugin Check dependencies
    Write-Info "Setting up Plugin Check dependencies"
    
    # Check and install composer dependencies
    $composerPath = Join-Path $PluginCheckPath "composer.json"
    if (Test-Path $composerPath) {
        Write-Info "Installing Composer dependencies for Plugin Check..."
        Push-Location $PluginCheckPath
        
        if (Get-Command composer -ErrorAction SilentlyContinue) {
            try {
                $composerResult = & composer install --no-dev --quiet 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Composer install failed. Trying with --ignore-platform-reqs..."
                    $composerResult = & composer install --no-dev --quiet --ignore-platform-reqs 2>&1
                }
            }
            catch {
                Write-Warning "Composer install error: $_"
            }
        } else {
            Write-Warning "Composer not found. Some Plugin Check features may be limited."
        }
        
        Pop-Location
    }
    
    # Check and install npm dependencies if package.json exists
    $packagePath = Join-Path $PluginCheckPath "package.json"
    if (Test-Path $packagePath) {
        Write-Info "Installing npm dependencies for Plugin Check..."
        Push-Location $PluginCheckPath
        
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            # Check if node_modules exists, if not, install
            if (!(Test-Path "node_modules")) {
                try {
                    $npmResult = & npm install --silent 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "npm install failed. Trying with --force..."
                        $npmResult = & npm install --force --silent 2>&1
                    }
                }
                catch {
                    Write-Warning "npm install error: $_"
                }
            }
            
            # Build if needed
            $packageContent = Get-Content "package.json" -Raw
            if ($packageContent -match '"build"') {
                try {
                    & npm run build --silent 2>&1 | Out-Null
                }
                catch {
                    Write-Warning "npm build failed: $_"
                }
            }
        } else {
            Write-Warning "npm not found. Some Plugin Check features may be limited."
        }
        
        Pop-Location
    }
    
    # Activate Plugin Check if not active
    try {
        $isActive = & wp plugin is-active plugin-check 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Info "Activating Plugin Check..."
            $activateResult = & wp plugin activate plugin-check --quiet 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to activate Plugin Check: $activateResult"
            }
        }
    }
    catch {
        Write-Warning "Error checking Plugin Check status: $_"
    }

    # Setup environment for our test plugin's dependencies
    Write-Info "Preparing target plugin dependencies"
    
    # Check if target plugin needs npm/composer setup
    $targetPackagePath = Join-Path $PluginPath "package.json"
    if (Test-Path $targetPackagePath) {
        Write-Info "Installing npm dependencies for $($Config.PluginName)..."
        Push-Location $PluginPath
        if ((Get-Command npm -ErrorAction SilentlyContinue) -and !(Test-Path "node_modules")) {
            try {
                & npm install --silent 2>&1 | Out-Null
            }
            catch {
                Write-Warning "npm install failed for target plugin: $_"
            }
        }
        Pop-Location
    }
    
    $targetComposerPath = Join-Path $PluginPath "composer.json"
    if (Test-Path $targetComposerPath) {
        Write-Info "Installing composer dependencies for $($Config.PluginName)..."
        Push-Location $PluginPath
        if ((Get-Command composer -ErrorAction SilentlyContinue) -and !(Test-Path "vendor")) {
            try {
                & composer install --no-dev --quiet 2>&1 | Out-Null
            }
            catch {
                Write-Warning "composer install failed for target plugin: $_"
            }
        }
        Pop-Location
    }
    
    # Run comprehensive plugin check with all available checks
    Write-Info "Running All Plugin Checks"
    
    # Save results in multiple formats
    $jsonOutput = Join-Path $PluginCheckDir "plugin-check-full.json"
    $tableOutput = Join-Path $PluginCheckDir "plugin-check-full.txt"
    $csvOutput = Join-Path $PluginCheckDir "plugin-check-full.csv"
    
    # Run full check and save JSON output
    Write-Info "Generating comprehensive JSON report..."
    try {
        $jsonResult = & wp plugin check $Config.PluginName --format=json --include-experimental 2>&1
        $jsonResult | Out-File $jsonOutput -Encoding UTF8
    }
    catch {
        Write-Warning "JSON report generation failed: $_"
        "Error generating JSON report: $_" | Out-File $jsonOutput -Encoding UTF8
    }
    
    # Run check with table format for readability
    Write-Info "Generating readable table report..."
    try {
        $tableResult = & wp plugin check $Config.PluginName --format=table --include-experimental 2>&1
        $tableResult | Out-File $tableOutput -Encoding UTF8
    }
    catch {
        Write-Warning "Table report generation failed: $_"
        "Error generating table report: $_" | Out-File $tableOutput -Encoding UTF8
    }
    
    # Run check with CSV format for data processing
    Write-Info "Generating CSV report for data processing..."
    try {
        $csvResult = & wp plugin check $Config.PluginName --format=csv --include-experimental 2>&1
        $csvResult | Out-File $csvOutput -Encoding UTF8
    }
    catch {
        Write-Warning "CSV report generation failed: $_"
        "Error generating CSV report: $_" | Out-File $csvOutput -Encoding UTF8
    }
    
    # Run specific category checks
    Write-Info "Running Category-Specific Checks"
    
    # Security-focused checks
    Write-Info "Running security-focused checks..."
    $securityChecks = "late_escaping,direct_db_queries,non_blocking_scripts"
    try {
        $securityResult = & wp plugin check $Config.PluginName --checks=$securityChecks --format=json 2>&1
        $securityResult | Out-File (Join-Path $PluginCheckDir "plugin-check-security.json") -Encoding UTF8
    }
    catch {
        Write-Warning "Security checks failed: $_"
    }
    
    # Performance-focused checks
    Write-Info "Running performance-focused checks..."
    $performanceChecks = "enqueued_scripts_in_footer,enqueued_scripts_size,enqueued_styles_size"
    try {
        $performanceResult = & wp plugin check $Config.PluginName --checks=$performanceChecks --format=json 2>&1
        $performanceResult | Out-File (Join-Path $PluginCheckDir "plugin-check-performance.json") -Encoding UTF8
    }
    catch {
        Write-Warning "Performance checks failed: $_"
    }
    
    # Internationalization checks
    Write-Info "Running i18n checks..."
    $i18nChecks = "i18n_usage"
    try {
        $i18nResult = & wp plugin check $Config.PluginName --checks=$i18nChecks --format=json 2>&1
        $i18nResult | Out-File (Join-Path $PluginCheckDir "plugin-check-i18n.json") -Encoding UTF8
    }
    catch {
        Write-Warning "i18n checks failed: $_"
    }
    
    # Run update mode check (for existing plugins)
    Write-Info "Running update mode analysis..."
    try {
        $updateResult = & wp plugin check $Config.PluginName --mode=update --format=json 2>&1
        $updateResult | Out-File (Join-Path $PluginCheckDir "plugin-check-update-mode.json") -Encoding UTF8
    }
    catch {
        Write-Warning "Update mode check failed: $_"
    }
    
    # Parse and generate insights report
    Write-Info "Generating Plugin Check Insights"
    
    $insightsFile = Join-Path $PluginCheckDir "plugin-check-insights.md"
    
    $insightsContent = @"
# WordPress Plugin Check Insights for $($Config.PluginName)
Generated: $(Get-Date)

## Overview
This report provides insights from the WordPress Plugin Check tool analysis.

## Check Summary
"@

    # Parse JSON results to extract key findings
    if ((Test-Path $jsonOutput) -and (Get-Content $jsonOutput -Raw).Length -gt 0) {
        # Count errors and warnings using PowerShell
        $jsonContent = Get-Content $jsonOutput -Raw
        $errorCount = ([regex]::Matches($jsonContent, '"type":"ERROR"')).Count
        $warningCount = ([regex]::Matches($jsonContent, '"type":"WARNING"')).Count
        
        $insightsContent += @"

### Statistics
- **Total Errors:** $errorCount
- **Total Warnings:** $warningCount

### Categories Analyzed
"@

        # Try to parse JSON for detailed insights
        try {
            $pluginCheckData = $jsonContent | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($pluginCheckData) {
                # Get unique categories
                $categories = $pluginCheckData | ForEach-Object { $_.category } | Where-Object { $_ } | Sort-Object -Unique
                if ($categories) {
                    foreach ($category in $categories) {
                        $insightsContent += "`n- $category"
                    }
                }
                
                # Extract critical issues
                $insightsContent += @"

## Critical Issues to Fix

### Errors
"@
                
                # List errors with details
                $errors = $pluginCheckData | Where-Object { $_.type -eq "ERROR" }
                if ($errors) {
                    foreach ($error in $errors) {
                        $code = if ($error.code) { $error.code } else { "Unknown" }
                        $message = if ($error.message) { $error.message } else { "No message" }
                        $file = if ($error.file) { $error.file } else { "Unknown file" }
                        $line = if ($error.line) { $error.line } else { 0 }
                        $insightsContent += "`n- **$code**: $message [$file:$line]"
                    }
                } else {
                    $insightsContent += "`nNo errors found."
                }
                
                $insightsContent += @"

### Warnings
"@
                
                # List warnings with details (limit to first 20)
                $warnings = $pluginCheckData | Where-Object { $_.type -eq "WARNING" } | Select-Object -First 20
                if ($warnings) {
                    foreach ($warning in $warnings) {
                        $code = if ($warning.code) { $warning.code } else { "Unknown" }
                        $message = if ($warning.message) { $warning.message } else { "No message" }
                        $file = if ($warning.file) { $warning.file } else { "Unknown file" }
                        $line = if ($warning.line) { $warning.line } else { 0 }
                        $insightsContent += "`n- **$code**: $message [$file:$line]"
                    }
                } else {
                    $insightsContent += "`nNo warnings found."
                }
                
                # Generate fix recommendations
                $insightsContent += @"

## Recommended Fixes

Based on the Plugin Check analysis, here are the recommended actions:

"@
                
                # Check for specific issues and provide recommendations
                if ($jsonContent -match "late_escaping") {
                    $insightsContent += @"
### Escaping Issues
- Review all output statements and ensure proper escaping using functions like esc_html(), esc_attr(), esc_url()
- Pay special attention to user input and database output

"@
                }
                
                if ($jsonContent -match "direct_db_queries") {
                    $insightsContent += @"
### Database Query Issues
- Replace direct database queries with WordPress API functions when possible
- Use `$wpdb->prepare()` for all custom queries to prevent SQL injection
- Consider using WP_Query for post-related queries

"@
                }
                
                if ($jsonContent -match "i18n_usage") {
                    $insightsContent += @"
### Internationalization Issues
- Wrap all user-facing strings in translation functions (__(), _e(), etc.)
- Ensure text domain is consistent throughout the plugin
- Load text domain properly in the main plugin file

"@
                }
            }
        }
        catch {
            Write-Warning "Error parsing JSON results: $_"
            
            # Fallback: use raw table output
            $insightsContent += @"

### Raw Check Results
``````
$(if (Test-Path $tableOutput) { (Get-Content $tableOutput | Select-Object -First 100) -join "`n" } else { "No table output available" })
``````
"@
        }
    } else {
        $insightsContent += "`nNo Plugin Check results available or file is empty."
    }
    
    # Generate actionable summary
    $insightsContent += @"

## Integration with Testing Framework

The Plugin Check results have been saved in multiple formats:
- JSON: For programmatic processing and CI/CD integration
- Table: For human-readable review
- CSV: For spreadsheet analysis and reporting

These results can be integrated with:
1. **AI Analysis (Phase 4)**: Use compliance data for smarter analysis
2. **Security Scanner (Phase 5)**: Cross-reference security findings
3. **Performance Analysis (Phase 6)**: Combine with performance metrics
4. **Documentation (Phase 10)**: Include compliance status in docs
5. **Consolidation (Phase 11)**: Merge with overall test results

## Next Steps

1. Address all ERROR-level issues first
2. Review and fix WARNING-level issues
3. Consider implementing suggested best practices
4. Re-run Plugin Check after fixes to verify improvements
5. Use update mode for continuous monitoring

"@

    $insightsContent | Out-File $insightsFile -Encoding UTF8

    Write-Success "Plugin Check analysis completed for $($Config.PluginName)"
    
    # Display summary
    Write-Info "Results saved to: $PluginCheckDir"
    
    if (Test-Path $insightsFile) {
        Write-Info "Quick Summary"
        $insightsPreview = Get-Content $insightsFile | Select-Object -First 30
        Write-Host ($insightsPreview -join "`n") -ForegroundColor White
        Write-Host "`n... (full report available in $insightsFile)" -ForegroundColor Gray
    }
    
    # Save phase completion marker
    $logPath = Join-Path $ScanDir "phase-completion.log"
    "$(Get-Date): Phase 3 - Plugin Check completed for $($Config.PluginName)" | Out-File $logPath -Append -Encoding UTF8
    
    return @{
        Status = "Completed"
        ResultsDirectory = $PluginCheckDir
        InsightsFile = $insightsFile
        ReportsGenerated = @($jsonOutput, $tableOutput, $csvOutput)
    }
}

# Export the function
Export-ModuleMember -Function Invoke-Phase03