# Phase 5: Performance Analysis
# Analyzes plugin performance metrics and identifies bottlenecks

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase05 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 5: Performance Analysis"
    
    Write-Info "Analyzing plugin performance metrics..."
    
    # Get all PHP files
    $phpFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.php" -Recurse
    
    # 1. Check for large files
    Write-Info "Checking file sizes..."
    $largeFiles = $phpFiles | Where-Object { $_.Length -gt 100KB }
    $veryLargeFiles = $phpFiles | Where-Object { $_.Length -gt 500KB }
    
    if ($veryLargeFiles) {
        Write-Warning "Found $($veryLargeFiles.Count) very large files (>500KB)"
        foreach ($file in $veryLargeFiles) {
            Write-Host "   - $($file.Name): $([math]::Round($file.Length / 1KB, 2))KB" -ForegroundColor Yellow
        }
    }
    
    if ($largeFiles) {
        Write-Info "Large files (>100KB): $($largeFiles.Count)"
    }
    
    # 2. Database query analysis
    Write-Info "Analyzing database operations..."
    $dbMetrics = @{
        TotalQueries = 0
        DirectQueries = 0
        PreparedQueries = 0
        Inserts = 0
        Updates = 0
        Deletes = 0
        Selects = 0
        ComplexJoins = 0
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Count different types of database operations
        $dbMetrics.TotalQueries += ([regex]::Matches($content, '\$wpdb->')).Count
        $dbMetrics.DirectQueries += ([regex]::Matches($content, '\$wpdb->query')).Count
        $dbMetrics.PreparedQueries += ([regex]::Matches($content, '\$wpdb->prepare')).Count
        $dbMetrics.Inserts += ([regex]::Matches($content, '\$wpdb->insert')).Count
        $dbMetrics.Updates += ([regex]::Matches($content, '\$wpdb->update')).Count
        $dbMetrics.Deletes += ([regex]::Matches($content, '\$wpdb->delete')).Count
        $dbMetrics.Selects += ([regex]::Matches($content, '\$wpdb->get_(results|var|row|col)')).Count
        $dbMetrics.ComplexJoins += ([regex]::Matches($content, 'JOIN\s+')).Count
    }
    
    Write-Info "Database operations: $($dbMetrics.TotalQueries) total"
    Write-Host "   - Direct queries: $($dbMetrics.DirectQueries)" -ForegroundColor $(if ($dbMetrics.DirectQueries -gt 50) { "Yellow" } else { "Green" })
    Write-Host "   - Prepared statements: $($dbMetrics.PreparedQueries)" -ForegroundColor Green
    Write-Host "   - Complex JOINs: $($dbMetrics.ComplexJoins)" -ForegroundColor $(if ($dbMetrics.ComplexJoins -gt 20) { "Yellow" } else { "Green" })
    
    # 3. Hook density analysis
    Write-Info "Analyzing hook density..."
    $hookMetrics = @{
        TotalHooks = 0
        ActionsAdded = 0
        FiltersAdded = 0
        HooksPerFile = @{}
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        $fileHooks = 0
        
        $fileHooks += ([regex]::Matches($content, 'add_action\s*\(')).Count
        $fileHooks += ([regex]::Matches($content, 'add_filter\s*\(')).Count
        
        $hookMetrics.ActionsAdded += ([regex]::Matches($content, 'add_action\s*\(')).Count
        $hookMetrics.FiltersAdded += ([regex]::Matches($content, 'add_filter\s*\(')).Count
        
        if ($fileHooks -gt 0) {
            $hookMetrics.HooksPerFile[$file.Name] = $fileHooks
        }
        
        $hookMetrics.TotalHooks += $fileHooks
    }
    
    # Find files with excessive hooks
    $highHookFiles = $hookMetrics.HooksPerFile.GetEnumerator() | Where-Object { $_.Value -gt 20 }
    if ($highHookFiles) {
        Write-Warning "Files with high hook density (>20 hooks):"
        foreach ($file in $highHookFiles | Sort-Object Value -Descending | Select-Object -First 5) {
            Write-Host "   - $($file.Key): $($file.Value) hooks" -ForegroundColor Yellow
        }
    }
    
    # 4. Caching analysis
    Write-Info "Checking caching implementation..."
    $cacheMetrics = @{
        Transients = 0
        ObjectCache = 0
        WPCache = 0
        NoCaching = $true
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        $cacheMetrics.Transients += ([regex]::Matches($content, '(get|set|delete)_transient\s*\(')).Count
        $cacheMetrics.ObjectCache += ([regex]::Matches($content, 'wp_cache_(get|set|delete|add|replace)')).Count
        $cacheMetrics.WPCache += ([regex]::Matches($content, 'wp_cache_')).Count
    }
    
    if ($cacheMetrics.Transients -gt 0 -or $cacheMetrics.ObjectCache -gt 0) {
        $cacheMetrics.NoCaching = $false
        Write-Success "Caching implemented: $($cacheMetrics.Transients) transients, $($cacheMetrics.ObjectCache) object cache calls"
    } else {
        Write-Warning "No caching implementation detected"
    }
    
    # 5. Script/Style enqueuing
    Write-Info "Analyzing asset loading..."
    $assetMetrics = @{
        Scripts = 0
        Styles = 0
        InlineScripts = 0
        InlineStyles = 0
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        $assetMetrics.Scripts += ([regex]::Matches($content, 'wp_enqueue_script\s*\(')).Count
        $assetMetrics.Styles += ([regex]::Matches($content, 'wp_enqueue_style\s*\(')).Count
        $assetMetrics.InlineScripts += ([regex]::Matches($content, 'wp_add_inline_script\s*\(')).Count
        $assetMetrics.InlineStyles += ([regex]::Matches($content, 'wp_add_inline_style\s*\(')).Count
    }
    
    Write-Info "Assets: $($assetMetrics.Scripts) scripts, $($assetMetrics.Styles) styles"
    
    # 6. Loop detection
    Write-Info "Checking for potential infinite loops..."
    $loopRisks = @()
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Check for recursive patterns
        if ($content -match 'while\s*\(\s*true\s*\)' -or $content -match 'for\s*\(\s*;\s*;\s*\)') {
            $loopRisks += "Potential infinite loop in $($file.Name)"
        }
        
        # Check for nested loops with database queries
        if ($content -match 'while.*\$wpdb.*while' -or $content -match 'foreach.*\$wpdb.*foreach') {
            $loopRisks += "Nested loops with DB queries in $($file.Name)"
        }
    }
    
    if ($loopRisks) {
        Write-Warning "Loop risks detected:"
        foreach ($risk in $loopRisks) {
            Write-Host "   - $risk" -ForegroundColor Yellow
        }
    }
    
    # Calculate performance score
    $score = 100
    $score -= ($largeFiles.Count * 2)
    $score -= ($veryLargeFiles.Count * 5)
    $score -= ([Math]::Min(20, $dbMetrics.DirectQueries / 5))
    $score -= ([Math]::Min(10, $dbMetrics.ComplexJoins / 2))
    $score -= ($loopRisks.Count * 10)
    $score += $(if (-not $cacheMetrics.NoCaching) { 10 } else { 0 })
    $score = [Math]::Max(0, [Math]::Min(100, $score))
    
    Write-Host ""
    Write-Host "Performance Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Generate performance report
    $report = @"
# Performance Analysis Report
Plugin: $($Config.PluginName)
Date: $(Get-Date)
Score: $score/100

## File Analysis
- Total PHP Files: $($phpFiles.Count)
- Large Files (>100KB): $($largeFiles.Count)
- Very Large Files (>500KB): $($veryLargeFiles.Count)

## Database Performance
- Total DB Operations: $($dbMetrics.TotalQueries)
- Direct Queries: $($dbMetrics.DirectQueries)
- Prepared Statements: $($dbMetrics.PreparedQueries)
- Complex JOINs: $($dbMetrics.ComplexJoins)

## Hook Analysis
- Total Hooks: $($hookMetrics.TotalHooks)
- Actions: $($hookMetrics.ActionsAdded)
- Filters: $($hookMetrics.FiltersAdded)
- Average per file: $([Math]::Round($hookMetrics.TotalHooks / $phpFiles.Count, 2))

## Caching
- Transients Used: $($cacheMetrics.Transients)
- Object Cache Calls: $($cacheMetrics.ObjectCache)
- Caching Implemented: $(if (-not $cacheMetrics.NoCaching) { "Yes" } else { "No" })

## Assets
- Enqueued Scripts: $($assetMetrics.Scripts)
- Enqueued Styles: $($assetMetrics.Styles)
- Inline Scripts: $($assetMetrics.InlineScripts)
- Inline Styles: $($assetMetrics.InlineStyles)

## Recommendations
$(if ($veryLargeFiles.Count -gt 0) {
"1. **Split large files** - Files over 500KB should be refactored"
})
$(if ($dbMetrics.DirectQueries -gt 50) {
"2. **Optimize database queries** - Too many direct queries detected"
})
$(if ($cacheMetrics.NoCaching) {
"3. **Implement caching** - Use transients or object cache for expensive operations"
})
$(if ($hookMetrics.TotalHooks -gt 500) {
"4. **Review hook usage** - Consider lazy loading for some hooks"
})
$(if ($loopRisks.Count -gt 0) {
"5. **Fix loop risks** - Potential infinite loops detected"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\performance-report.md"
    Ensure-Directory -Path (Split-Path $reportPath -Parent)
    $report | Out-File $reportPath
    
    # Save results
    $results = @{
        Score = $score
        FileMetrics = @{
            Total = $phpFiles.Count
            Large = $largeFiles.Count
            VeryLarge = $veryLargeFiles.Count
        }
        DatabaseMetrics = $dbMetrics
        HookMetrics = $hookMetrics
        CacheMetrics = $cacheMetrics
        AssetMetrics = $assetMetrics
        LoopRisks = $loopRisks
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "05" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Performance analysis complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase05 -Config $Config
}