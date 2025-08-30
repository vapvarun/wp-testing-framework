# WP Testing Framework - Local WP Setup for Windows
# PowerShell Script for Windows Users
# Repository: https://github.com/vapvarun/wp-testing-framework/

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║    WP Testing Framework - Windows Setup     ║" -ForegroundColor Blue
Write-Host "║           Optimized for Local WP            ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Detect Local WP environment
Write-Host "🔍 Detecting Local WP Environment..." -ForegroundColor Blue

$currentPath = Get-Location
$siteName = ""

if ($currentPath -match "Local Sites\\([^\\]+)\\app\\public") {
    $siteName = $matches[1]
    Write-Host "✅ Local WP site detected: $siteName" -ForegroundColor Green
    $wpUrl = "http://${siteName}.local"
    Write-Host "✅ Site URL: $wpUrl" -ForegroundColor Green
} else {
    Write-Host "⚠️  Not in Local WP directory" -ForegroundColor Yellow
    Write-Host "Please run from: C:\Users\$env:USERNAME\Local Sites\your-site\app\public" -ForegroundColor Yellow
    exit 1
}

# Quick setup
Write-Host ""
Write-Host "⚡ Running Quick Setup..." -ForegroundColor Blue

# Check and install Node dependencies
if (-Not (Test-Path "node_modules")) {
    Write-Host "Installing Node packages..." -ForegroundColor Yellow
    npm ci 2>$null || npm install
    Write-Host "✅ Node packages installed" -ForegroundColor Green
}

# Check and install Composer dependencies
if (-Not (Test-Path "vendor")) {
    Write-Host "Installing PHP packages..." -ForegroundColor Yellow
    composer install --no-interaction --quiet
    Write-Host "✅ PHP packages installed" -ForegroundColor Green
}

# Create .env file with Windows paths
if (-Not (Test-Path ".env")) {
    Write-Host "Creating .env configuration..." -ForegroundColor Yellow
    
    $envContent = @"
# Local WP Configuration (Windows Auto-detected)
WP_ROOT_DIR=../
WP_TESTS_DIR=C:/tmp/wordpress-tests-lib
WP_CORE_DIR=../

# Database (Local WP defaults)
TEST_DB_NAME=${siteName}_test
TEST_DB_USER=root
TEST_DB_PASSWORD=root
TEST_DB_HOST=localhost

# Site Configuration
WP_TEST_URL=$wpUrl
WP_TEST_DOMAIN=${siteName}.local
WP_TEST_EMAIL=admin@${siteName}.local

# Testing
SKIP_DB_CREATE=false
TEST_SUITE=all
"@

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Created .env with Local WP settings" -ForegroundColor Green
}

# Create directories
Write-Host "Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    "workspace\reports",
    "workspace\logs", 
    "workspace\coverage",
    "workspace\screenshots",
    "plugins"
)

foreach ($dir in $directories) {
    if (-Not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "✅ Directory structure ready" -ForegroundColor Green

# Create test database using WP-CLI
Write-Host "Creating test database..." -ForegroundColor Yellow
try {
    wp db create "${siteName}_test" 2>$null
    Write-Host "✅ Test database created" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Test database may already exist" -ForegroundColor Yellow
}

# Final message
Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test a plugin: .\test-plugin.ps1 plugin-name" -ForegroundColor White
Write-Host "2. View reports: explorer workspace\reports\" -ForegroundColor White
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host "  .\test-plugin.ps1 bbpress" -ForegroundColor Cyan
Write-Host "  .\test-plugin.ps1 buddypress" -ForegroundColor Cyan
Write-Host "  .\test-plugin.ps1 woocommerce" -ForegroundColor Cyan
Write-Host ""