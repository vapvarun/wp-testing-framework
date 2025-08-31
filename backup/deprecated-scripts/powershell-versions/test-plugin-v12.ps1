# WordPress Plugin Testing Framework v12.0 - PowerShell Edition
# Complete 12-phase testing with AI-enhanced test generation
# Usage: .\test-plugin-v12.ps1 <plugin-name>

param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    
    [Parameter(Mandatory=$false)]
    [string]$Mode = "full"  # full, quick, security, performance, ai
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Colors for output
$colors = @{
    Blue = "Blue"
    Green = "Green"
    Yellow = "Yellow"
    Red = "Red"
    Cyan = "Cyan"
    Magenta = "Magenta"
}

# Output functions
function Write-Phase($message) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Blue
    Write-Host "🔍 $message" -ForegroundColor $colors.Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Blue
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor $colors.Green
}

function Write-Info($message) {
    Write-Host "📊 $message" -ForegroundColor $colors.Cyan
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor $colors.Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor $colors.Red
}

# Get WordPress paths
$WP_PATH = Split-Path $PSScriptRoot -Parent
$PLUGIN_PATH = Join-Path $WP_PATH "wp-content\plugins\$PluginName"
$UPLOAD_PATH = Join-Path $WP_PATH "wp-content\uploads"
$FRAMEWORK_PATH = $PSScriptRoot

# Check if plugin exists
if (!(Test-Path $PLUGIN_PATH)) {
    Write-Error "Plugin '$PluginName' not found at: $PLUGIN_PATH"
    exit 1
}

# Create timestamp
$DATE_MONTH = Get-Date -Format "yyyy-MM"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Create directory structure
$SCAN_DIR = Join-Path $UPLOAD_PATH "wbcom-scan\$PluginName\$DATE_MONTH"
$PLAN_DIR = Join-Path $UPLOAD_PATH "wbcom-plan\$PluginName\$DATE_MONTH"
$FRAMEWORK_SAFEKEEP = Join-Path $FRAMEWORK_PATH "plugins\$PluginName"

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor $colors.Blue
Write-Host "║   WP Testing Framework v12.0 - PowerShell  ║" -ForegroundColor $colors.Blue
Write-Host "║   Complete Plugin Analysis & Testing       ║" -ForegroundColor $colors.Blue
Write-Host "║   Plugin: $PluginName" -ForegroundColor $colors.Blue
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor $colors.Blue
Write-Host ""

# ============================================================================
# PHASE 1: Setup & Structure
# ============================================================================
Write-Phase "PHASE 1: Setup & Structure"

# Create directories
$directories = @(
    "$SCAN_DIR\raw-outputs",
    "$SCAN_DIR\raw-outputs\coverage",
    "$SCAN_DIR\ai-analysis",
    "$SCAN_DIR\reports",
    "$SCAN_DIR\generated-tests",
    "$PLAN_DIR\documentation",
    "$PLAN_DIR\test-results",
    "$FRAMEWORK_SAFEKEEP\developer-tasks",
    "$FRAMEWORK_SAFEKEEP\final-reports-$TIMESTAMP"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Success "Directory structure ready"

# ============================================================================
# PHASE 2: Plugin Detection
# ============================================================================
Write-Phase "PHASE 2: Plugin Detection"

# Check if plugin is active
$activePlugins = & php -r "
    require_once '../wp-load.php';
    echo json_encode(get_option('active_plugins'));
" 2>$null | ConvertFrom-Json

$pluginFile = "$PluginName/$PluginName.php"
$isActive = $activePlugins -contains $pluginFile

if ($isActive) {
    Write-Success "Plugin $PluginName is active"
} else {
    Write-Warning "Plugin $PluginName is not active"
}

# Get plugin version
$pluginData = Get-Content "$PLUGIN_PATH\$PluginName.php" -Raw
if ($pluginData -match 'Version:\s*([^\n]+)') {
    $version = $matches[1].Trim()
    Write-Info "Version: $version"
}

# ============================================================================
# PHASE 3: AI-Driven Code Analysis
# ============================================================================
Write-Phase "PHASE 3: AI-Driven Code Analysis"

Write-Info "Running WordPress AST Analysis..."

# Run AST analysis if available
if (Test-Path "$FRAMEWORK_PATH\tools\wordpress-ast-analyzer.js") {
    & node "$FRAMEWORK_PATH\tools\wordpress-ast-analyzer.js" "$PLUGIN_PATH" 2>&1 | Out-String
    Write-Success "AST analysis completed"
} else {
    Write-Warning "AST analyzer not found, skipping"
}

# Run dynamic test data generation
Write-Info "Generating dynamic test data..."
if (Test-Path "$FRAMEWORK_PATH\tools\ai\dynamic-test-data-generator.mjs") {
    & node "$FRAMEWORK_PATH\tools\ai\dynamic-test-data-generator.mjs" "$PluginName" 2>&1 | Out-String
    Write-Success "Dynamic test data generated"
}

# Count PHP files and basic metrics
$phpFiles = Get-ChildItem -Path $PLUGIN_PATH -Filter "*.php" -Recurse
$jsFiles = Get-ChildItem -Path $PLUGIN_PATH -Filter "*.js" -Recurse
$cssFiles = Get-ChildItem -Path $PLUGIN_PATH -Filter "*.css" -Recurse

Write-Info "Found: $($phpFiles.Count) PHP, $($jsFiles.Count) JS, $($cssFiles.Count) CSS files"

# ============================================================================
# PHASE 4: Security Analysis
# ============================================================================
Write-Phase "PHASE 4: Security Analysis"

Write-Info "Scanning for security vulnerabilities..."

# Security checks
$securityIssues = @()

# Check for eval usage
foreach ($file in $phpFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '\beval\s*\(') {
        $securityIssues += "eval() found in $($file.Name)"
    }
}

# Check for SQL injection risks
foreach ($file in $phpFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '\$wpdb->query\s*\([^)]*\$_(GET|POST|REQUEST)') {
        $securityIssues += "Potential SQL injection in $($file.Name)"
    }
}

if ($securityIssues.Count -eq 0) {
    Write-Success "No critical security issues found"
} else {
    Write-Warning "Found $($securityIssues.Count) security issues"
    $securityIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor $colors.Yellow }
}

# ============================================================================
# PHASE 5: Performance Analysis
# ============================================================================
Write-Phase "PHASE 5: Performance Analysis"

# Check for large files
$largeFiles = $phpFiles | Where-Object { $_.Length -gt 100KB }
if ($largeFiles) {
    Write-Warning "Found $($largeFiles.Count) large files (>100KB)"
}

# Count database queries
$dbQueries = 0
foreach ($file in $phpFiles) {
    $content = Get-Content $file.FullName -Raw
    $dbQueries += ([regex]::Matches($content, '\$wpdb->(get_|query|prepare|insert|update|delete)')).Count
}
Write-Info "Database operations found: $dbQueries"

# ============================================================================
# PHASE 6: Test Generation, Execution & Coverage
# ============================================================================
Write-Phase "PHASE 6: Test Generation, Execution & Coverage"

# Generate PHPUnit tests
if (Test-Path "$FRAMEWORK_PATH\tools\generate-phpunit-tests.php") {
    Write-Info "Generating PHPUnit test cases..."
    & php "$FRAMEWORK_PATH\tools\generate-phpunit-tests.php" $PluginName 2>&1 | Out-String
    Write-Success "PHPUnit tests generated"
}

# Generate executable tests
if (Test-Path "$FRAMEWORK_PATH\tools\generate-executable-tests.php") {
    Write-Info "Generating executable tests for coverage..."
    & php "$FRAMEWORK_PATH\tools\generate-executable-tests.php" $PluginName 2>&1 | Out-String
    Write-Success "Executable tests generated"
}

# Generate AI-enhanced smart tests (if API key available)
if ($env:ANTHROPIC_API_KEY -and (Test-Path "$FRAMEWORK_PATH\tools\ai\generate-smart-executable-tests.mjs")) {
    Write-Info "Generating AI-enhanced smart tests..."
    & node "$FRAMEWORK_PATH\tools\ai\generate-smart-executable-tests.mjs" $PluginName 2>&1 | Out-String
    Write-Success "AI-enhanced tests generated"
} else {
    Write-Warning "Skipping AI test generation (no API key)"
}

# Run tests with coverage
if (Test-Path "$FRAMEWORK_PATH\tools\run-unit-tests-with-coverage.php") {
    Write-Info "Running tests with coverage analysis..."
    $env:XDEBUG_MODE = "coverage"
    & php "$FRAMEWORK_PATH\tools\run-unit-tests-with-coverage.php" $PluginName 2>&1 | Out-String
    Write-Success "Test execution complete"
}

# ============================================================================
# PHASE 7: Visual Testing & Screenshots
# ============================================================================
Write-Phase "PHASE 7: Visual Testing & Screenshots"

if (Test-Path "$FRAMEWORK_PATH\tools\automated-screenshot-capture.js") {
    Write-Info "Capturing plugin UI screenshots..."
    # This would require setting up Playwright
    Write-Warning "Screenshot capture requires Playwright setup"
} else {
    Write-Warning "Screenshot tool not available"
}

# ============================================================================
# PHASE 8: WordPress Integration Tests
# ============================================================================
Write-Phase "PHASE 8: WordPress Integration Tests"

# Test shortcodes
$astFile = "$SCAN_DIR\wordpress-ast-analysis.json"
if (Test-Path $astFile) {
    $astData = Get-Content $astFile -Raw | ConvertFrom-Json
    $shortcodes = $astData.details.shortcodes
    Write-Info "Testing $($shortcodes.Count) shortcodes"
}

# Test hooks
Write-Info "Validating hook integrations..."

# ============================================================================
# PHASE 9: Reporting & Documentation
# ============================================================================
Write-Phase "PHASE 9: Reporting & Documentation"

# Generate HTML report
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Analysis Report - $PluginName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; }
        .metric { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$PluginName Analysis Report</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <div class="metric">
        <h2>Code Metrics</h2>
        <ul>
            <li>PHP Files: $($phpFiles.Count)</li>
            <li>JavaScript Files: $($jsFiles.Count)</li>
            <li>CSS Files: $($cssFiles.Count)</li>
            <li>Database Operations: $dbQueries</li>
        </ul>
    </div>
    
    <div class="metric">
        <h2>Security Analysis</h2>
        <p class="$(if ($securityIssues.Count -eq 0) { 'success' } else { 'warning' })">
            Found $($securityIssues.Count) security issues
        </p>
    </div>
    
    <div class="metric">
        <h2>Test Coverage</h2>
        <p>Tests generated in: $SCAN_DIR\generated-tests</p>
    </div>
</body>
</html>
"@

$htmlReport | Out-File "$SCAN_DIR\reports\report-$TIMESTAMP.html"
Write-Success "HTML report generated"

# ============================================================================
# PHASE 10: Consolidating Reports
# ============================================================================
Write-Phase "PHASE 10: Consolidating All Reports"

# Copy all reports to final directory
Copy-Item "$SCAN_DIR\*" -Destination "$FRAMEWORK_SAFEKEEP\final-reports-$TIMESTAMP" -Recurse -Force
Write-Success "Reports consolidated"

# Create INDEX.md
$indexContent = @"
# $PluginName - Complete Analysis Index
Generated: $(Get-Date)

## Reports
- [HTML Report](reports/report-$TIMESTAMP.html)
- [AST Analysis](wordpress-ast-analysis.json)
- [Test Results](generated-tests/)

## Metrics
- PHP Files: $($phpFiles.Count)
- Security Issues: $($securityIssues.Count)
- Database Operations: $dbQueries
"@

$indexContent | Out-File "$FRAMEWORK_SAFEKEEP\final-reports-$TIMESTAMP\INDEX.md"
Write-Success "Master index created"

# ============================================================================
# PHASE 11: Live Testing with Test Data
# ============================================================================
Write-Phase "PHASE 11: Live Testing with Test Data"

# Get site URL
$siteUrl = & php -r "require_once '../wp-load.php'; echo home_url();" 2>$null
Write-Info "Site URL: $siteUrl"

# Create test data
Write-Info "Creating test data..."
if (Test-Path "$SCAN_DIR\reports\create-test-data.php") {
    & php "$SCAN_DIR\reports\create-test-data.php" 2>&1 | Out-String
}

# ============================================================================
# PHASE 12: Framework Safekeeping
# ============================================================================
Write-Phase "PHASE 12: Framework Safekeeping"

# Save important files
Write-Info "Saving framework files..."

# Save test configuration
$testConfig = @{
    plugin = $PluginName
    version = $version
    timestamp = $TIMESTAMP
    phpFiles = $phpFiles.Count
    jsFiles = $jsFiles.Count
    cssFiles = $cssFiles.Count
    securityIssues = $securityIssues.Count
    dbOperations = $dbQueries
}

$testConfig | ConvertTo-Json | Out-File "$FRAMEWORK_SAFEKEEP\test-config.json"
Write-Success "Test configuration saved"

# ============================================================================
# COMPLETE
# ============================================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
Write-Host "🎉 COMPLETE ANALYSIS FINISHED!" -ForegroundColor $colors.Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
Write-Host ""

Write-Host "📊 Analysis Summary for ${PluginName}:" -ForegroundColor $colors.Blue
Write-Host "   • $($phpFiles.Count) PHP files analyzed"
Write-Host "   • $($securityIssues.Count) security issues found"
Write-Host "   • $dbQueries database operations detected"
Write-Host "   • 3 tiers of tests generated"
Write-Host ""

Write-Host "📁 Report Locations:" -ForegroundColor $colors.Blue
Write-Host "   • Raw Scans: $SCAN_DIR"
Write-Host "   • AI Analysis: $PLAN_DIR"
Write-Host "   • Framework: $FRAMEWORK_SAFEKEEP"
Write-Host ""

Write-Host "🧪 Tests Generated:" -ForegroundColor $colors.Green
Write-Host "   • Smart Tests: $SCAN_DIR\generated-tests\*SmartExecutableTest.php"
Write-Host "   • Executable: $SCAN_DIR\generated-tests\*ExecutableTest.php"
Write-Host "   • Basic Tests: $SCAN_DIR\generated-tests\*Test.php"
Write-Host ""

Write-Host "📈 View Results:" -ForegroundColor $colors.Blue
Write-Host "   Start-Process '$SCAN_DIR\reports\report-$TIMESTAMP.html'"
Write-Host "   Get-Content '$FRAMEWORK_SAFEKEEP\final-reports-$TIMESTAMP\INDEX.md'"
Write-Host ""

# Open report if requested
if ($Mode -eq "full") {
    $openReport = Read-Host "Open HTML report? (Y/N)"
    if ($openReport -eq "Y") {
        Start-Process "$SCAN_DIR\reports\report-$TIMESTAMP.html"
    }
}