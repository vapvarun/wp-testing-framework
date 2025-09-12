# Phase 9: WordPress Integration Tests
# Tests plugin integration with WordPress core functionality

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase09 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 9: WordPress Integration Tests"
    
    Write-Info "Testing WordPress integration points..."
    
    $integrationTests = @{
        CoreHooks = @()
        DatabaseTables = @()
        UserCapabilities = @()
        RestEndpoints = @()
        AdminPages = @()
        Shortcodes = @()
        Widgets = @()
        Blocks = @()
    }
    
    # Get all PHP files
    $phpFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.php" -Recurse
    
    # 1. Test Core WordPress Hooks
    Write-Info "Analyzing WordPress hook integration..."
    $coreHooks = @(
        'init', 'wp_loaded', 'wp', 'template_redirect',
        'wp_head', 'wp_footer', 'admin_init', 'admin_menu',
        'wp_enqueue_scripts', 'admin_enqueue_scripts',
        'the_content', 'the_title', 'the_excerpt'
    )
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        foreach ($hook in $coreHooks) {
            if ($content -match "add_(action|filter)\s*\(\s*['\"]$hook['\"]" ) {
                $integrationTests.CoreHooks += @{
                    Hook = $hook
                    File = $file.Name
                    Type = if ($content -match "add_action.*$hook") { "Action" } else { "Filter" }
                }
            }
        }
    }
    
    Write-Success "   Found $($integrationTests.CoreHooks.Count) core hook integrations"
    
    # 2. Check Database Tables
    Write-Info "Checking custom database tables..."
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Check for table creation
        if ($content -match 'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+`?([^`\s]+)`?' ) {
            $tableName = $Matches[1]
            $integrationTests.DatabaseTables += @{
                Table = $tableName
                File = $file.Name
                HasPrefix = $tableName -match '\$wpdb->prefix'
            }
        }
        
        # Check for custom queries
        if ($content -match '\$wpdb->(insert|update|delete|get_results|get_var|get_row)' ) {
            # Track database operations
        }
    }
    
    Write-Info "   Custom tables: $($integrationTests.DatabaseTables.Count)"
    
    # 3. Test User Capabilities
    Write-Info "Analyzing user capabilities..."
    $capabilities = @()
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Check for capability checks
        if ($content -match 'current_user_can\s*\(\s*['\"]([^'\"]+)['\"]' ) {
            $capability = $Matches[1]
            if ($capability -notin $capabilities) {
                $capabilities += $capability
                $integrationTests.UserCapabilities += @{
                    Capability = $capability
                    IsCustom = $capability -notmatch '^(manage_options|edit_posts|read|upload_files|edit_pages)$'
                }
            }
        }
    }
    
    Write-Info "   Capabilities used: $($integrationTests.UserCapabilities.Count)"
    
    # 4. Test REST API Endpoints
    Write-Info "Checking REST API endpoints..."
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        if ($content -match 'register_rest_route\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]' ) {
            $namespace = $Matches[1]
            $route = $Matches[2]
            $integrationTests.RestEndpoints += @{
                Namespace = $namespace
                Route = $route
                File = $file.Name
            }
        }
    }
    
    Write-Info "   REST endpoints: $($integrationTests.RestEndpoints.Count)"
    
    # 5. Test Admin Pages
    Write-Info "Checking admin pages..."
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        if ($content -match 'add_(menu|submenu|options|theme|plugins|users|management|dashboard|posts|media|links|pages|comments)_page' ) {
            $pageType = $Matches[1]
            $integrationTests.AdminPages += @{
                Type = $pageType
                File = $file.Name
            }
        }
    }
    
    Write-Info "   Admin pages: $($integrationTests.AdminPages.Count)"
    
    # 6. Test Shortcodes
    Write-Info "Checking shortcodes..."
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        if ($content -match 'add_shortcode\s*\(\s*['\"]([^'\"]+)['\"]' ) {
            $shortcode = $Matches[1]
            $integrationTests.Shortcodes += @{
                Tag = $shortcode
                File = $file.Name
            }
        }
    }
    
    Write-Info "   Shortcodes: $($integrationTests.Shortcodes.Count)"
    
    # 7. Test Widgets
    Write-Info "Checking widgets..."
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        if ($content -match 'class\s+(\w+)\s+extends\s+WP_Widget' ) {
            $widgetClass = $Matches[1]
            $integrationTests.Widgets += @{
                Class = $widgetClass
                File = $file.Name
            }
        }
    }
    
    Write-Info "   Widgets: $($integrationTests.Widgets.Count)"
    
    # 8. Test Gutenberg Blocks
    Write-Info "Checking Gutenberg blocks..."
    $jsFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.js" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $jsFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -match 'registerBlockType\s*\(\s*['\"]([^'\"]+)['\"]' ) {
            $blockName = $Matches[1]
            $integrationTests.Blocks += @{
                Name = $blockName
                File = $file.Name
            }
        }
    }
    
    Write-Info "   Blocks: $($integrationTests.Blocks.Count)"
    
    # Calculate integration score
    $totalIntegrations = 0
    foreach ($key in $integrationTests.Keys) {
        $totalIntegrations += $integrationTests[$key].Count
    }
    
    $score = [Math]::Min(100, ($totalIntegrations * 2))
    
    # Generate report
    $report = @"
# WordPress Integration Test Report
Plugin: $($Config.PluginName)
Date: $(Get-Date)
Score: $score/100

## Integration Summary
Total Integration Points: $totalIntegrations

## Core WordPress Hooks
- Total: $($integrationTests.CoreHooks.Count)
- Most Used: $(($integrationTests.CoreHooks | Group-Object Hook | Sort-Object Count -Descending | Select-Object -First 1).Name)

### Hook List
$($integrationTests.CoreHooks | Group-Object Hook | ForEach-Object {
"- **$($_.Name)**: $($_.Count) uses"
})

## Database Integration
- Custom Tables: $($integrationTests.DatabaseTables.Count)
$($integrationTests.DatabaseTables | ForEach-Object {
"- Table: ``$($_.Table)`` (Prefixed: $($_.HasPrefix))"
})

## User Capabilities
- Total: $($integrationTests.UserCapabilities.Count)
- Custom: $(($integrationTests.UserCapabilities | Where-Object { $_.IsCustom }).Count)

## REST API
- Endpoints: $($integrationTests.RestEndpoints.Count)
$($integrationTests.RestEndpoints | ForEach-Object {
"- ``$($_.Namespace)/$($_.Route)``"
})

## Admin Interface
- Admin Pages: $($integrationTests.AdminPages.Count)
- Shortcodes: $($integrationTests.Shortcodes.Count)
- Widgets: $($integrationTests.Widgets.Count)
- Blocks: $($integrationTests.Blocks.Count)

## Recommendations
$(if ($integrationTests.DatabaseTables.Count -gt 0 -and ($integrationTests.DatabaseTables | Where-Object { -not $_.HasPrefix }).Count -gt 0) {
"1. **Use table prefixes** - Some tables don't use WordPress prefix"
})
$(if ($integrationTests.UserCapabilities.Count -eq 0) {
"2. **Add capability checks** - No user permission checks found"
})
$(if ($integrationTests.RestEndpoints.Count -gt 0) {
"3. **Secure REST endpoints** - Ensure proper authentication and validation"
})
$(if ($totalIntegrations -lt 5) {
"4. **Limited integration** - Plugin has minimal WordPress integration"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\integration-report.md"
    Ensure-Directory -Path (Split-Path $reportPath -Parent)
    $report | Out-File $reportPath
    
    Write-Host ""
    Write-Host "Integration Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Save results
    $results = @{
        Score = $score
        IntegrationTests = $integrationTests
        TotalIntegrations = $totalIntegrations
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "08" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "WordPress integration tests complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase08 -Config $Config
}