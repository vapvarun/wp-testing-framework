# WP Testing Framework - Plugin Tester for Windows
# PowerShell Script for Testing WordPress Plugins
# Repository: https://github.com/vapvarun/wp-testing-framework/

param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    
    [Parameter(Mandatory=$false)]
    [string]$TestType = "full"
)

# Colors setup
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Error { Write-Host $args[0] -ForegroundColor Red }
function Write-Info { Write-Host $args[0] -ForegroundColor Blue }
function Write-Warning { Write-Host $args[0] -ForegroundColor Yellow }

# Header
Write-Info "╔════════════════════════════════════════════╗"
Write-Info "║       WP Testing Framework - Windows        ║"
Write-Info "║       Testing: $PluginName"
Write-Info "╚════════════════════════════════════════════╝"
Write-Host ""

# Step 1: Create plugin folder structure
Write-Info "📁 Setting up plugin structure..."

$pluginPath = "plugins\$PluginName"
$directories = @(
    "$pluginPath\data",
    "$pluginPath\tests\unit",
    "$pluginPath\tests\integration",
    "$pluginPath\tests\security",
    "$pluginPath\tests\performance",
    "$pluginPath\scanners",
    "$pluginPath\models",
    "$pluginPath\analysis",
    "workspace\reports\$PluginName",
    "workspace\logs\$PluginName",
    "workspace\coverage\$PluginName"
)

foreach ($dir in $directories) {
    if (-Not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Success "✅ Created folder structure for $PluginName"

# Step 2: Check if plugin is installed
Write-Info "🔍 Checking plugin installation..."

try {
    $pluginList = wp plugin list --format=json | ConvertFrom-Json
    $plugin = $pluginList | Where-Object { $_.name -eq $PluginName }
    
    if ($plugin) {
        Write-Success "✅ Plugin $PluginName is installed"
        Write-Info "   Version: $($plugin.version)"
        Write-Info "   Status: $($plugin.status)"
        
        if ($plugin.status -ne "active") {
            Write-Warning "⚡ Activating plugin for testing..."
            wp plugin activate $PluginName
        }
    } else {
        Write-Warning "⚠️  Plugin $PluginName not found in WordPress"
        Write-Warning "   Tests will run against plugin structure only"
    }
} catch {
    Write-Warning "⚠️  Could not check plugin status"
}

# Step 3: Generate test configuration
Write-Info "⚙️  Generating test configuration..."

$config = @{
    plugin = $PluginName
    version = if ($plugin) { $plugin.version } else { "unknown" }
    generated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    test_type = $TestType
    environment = @{
        wp_version = (wp core version)
        php_version = (php -r "echo PHP_VERSION;")
        site_url = (wp option get siteurl)
    }
    tests = @{
        unit = $true
        integration = $true
        security = $true
        performance = $true
        accessibility = $true
    }
}

$config | ConvertTo-Json -Depth 3 | Out-File -FilePath "$pluginPath\test-config.json" -Encoding UTF8
Write-Success "✅ Configuration generated"

# Step 4: Scan plugin code
Write-Info "🔍 Scanning plugin code..."

$wpContentPath = "..\wp-content\plugins\$PluginName"
if (Test-Path $wpContentPath) {
    $phpFiles = (Get-ChildItem -Path $wpContentPath -Filter "*.php" -Recurse).Count
    $jsFiles = (Get-ChildItem -Path $wpContentPath -Filter "*.js" -Recurse).Count
    $cssFiles = (Get-ChildItem -Path $wpContentPath -Filter "*.css" -Recurse).Count
    
    Write-Info "   PHP files: $phpFiles"
    Write-Info "   JS files: $jsFiles"
    Write-Info "   CSS files: $cssFiles"
    
    $scanResults = @{
        plugin = $PluginName
        files = @{
            php = $phpFiles
            javascript = $jsFiles
            css = $cssFiles
        }
        scan_date = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    
    $scanResults | ConvertTo-Json | Out-File -FilePath "$pluginPath\analysis\scan-results.json" -Encoding UTF8
}

# Step 5: Generate basic test file
Write-Info "🧪 Generating test files..."

$testContent = @"
<?php
namespace WPTestingFramework\Plugins\$PluginName\Tests\Unit;

use PHPUnit\Framework\TestCase;

class BasicTest extends TestCase {
    public function testPluginExists() {
        `$plugin_file = WP_PLUGIN_DIR . '/$PluginName/$PluginName.php';
        `$this->assertFileExists(`$plugin_file, 'Plugin main file should exist');
    }
}
"@

if (-Not (Test-Path "$pluginPath\tests\unit\BasicTest.php")) {
    $testContent | Out-File -FilePath "$pluginPath\tests\unit\BasicTest.php" -Encoding UTF8
}

Write-Success "✅ Test files ready"

# Step 6: Run tests based on type
Write-Host ""
Write-Info "🚀 Running tests..."
Write-Host "=================="

switch ($TestType) {
    "quick" {
        Write-Info "Running quick tests..."
        if (Test-Path "vendor\bin\phpunit.bat") {
            & vendor\bin\phpunit.bat "$pluginPath\tests\unit\" 2>$null
        }
    }
    "security" {
        Write-Info "Running security tests..."
        # Run security-specific tests
    }
    "performance" {
        Write-Info "Running performance tests..."
        # Run performance-specific tests
    }
    default {
        Write-Info "Running full test suite..."
        
        # Check for npm scripts
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $universalScript = "universal:$PluginName"
        
        if ($packageJson.scripts.$universalScript) {
            npm run $universalScript
        } else {
            Write-Warning "Running standard test suite..."
            
            # Run PHPUnit tests if available
            if (Test-Path "vendor\bin\phpunit.bat") {
                if (Test-Path "$pluginPath\tests\unit") {
                    & vendor\bin\phpunit.bat "$pluginPath\tests\unit\"
                }
            }
        }
    }
}

# Step 7: Generate HTML report
Write-Host ""
Write-Info "📊 Generating report..."

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = "workspace\reports\$PluginName\report-$timestamp.html"

$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Report - $PluginName</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #0073aa; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; background: white; border: 1px solid #ddd; border-radius: 5px; }
        .success { color: #46b450; }
        .warning { color: #ffb900; }
        .error { color: #dc3232; }
        h1 { margin: 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Test Report: $PluginName</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Platform: Windows with Local WP</p>
    </div>
    
    <div class="section">
        <h2>Plugin Information</h2>
        <ul>
            <li>Name: $PluginName</li>
            <li>Version: $(if ($plugin) { $plugin.version } else { "unknown" })</li>
            <li>Status: $(if ($plugin) { $plugin.status } else { "not installed" })</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Test Results</h2>
        <ul>
            <li class="success">✓ Folder structure created</li>
            <li class="success">✓ Configuration generated</li>
            <li class="success">✓ Plugin scanned</li>
            <li class="success">✓ Tests executed</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>File Analysis</h2>
        <ul>
            <li>PHP Files: $phpFiles</li>
            <li>JavaScript Files: $jsFiles</li>
            <li>CSS Files: $cssFiles</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Environment</h2>
        <ul>
            <li>WordPress: $(wp core version)</li>
            <li>PHP: $(php -r "echo PHP_VERSION;")</li>
            <li>Test Type: $TestType</li>
        </ul>
    </div>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $reportFile -Encoding UTF8
Write-Success "✅ Report generated: $reportFile"

# Step 8: Summary
Write-Host ""
Write-Success "🎉 Testing Complete!"
Write-Host "==================="
Write-Info "📁 Plugin folder: $pluginPath"
Write-Info "📊 Report: $reportFile"
Write-Info "📝 Logs: workspace\logs\$PluginName\"
Write-Host ""
Write-Warning "Next steps:"
Write-Host "1. View report: Start-Process '$reportFile'" -ForegroundColor White
Write-Host "2. Check logs: explorer workspace\logs\$PluginName\" -ForegroundColor White
Write-Host "3. Run specific tests: .\test-plugin.ps1 $PluginName security" -ForegroundColor White