# ============================================
# WP Testing Framework - Local WP Windows Setup
# Version: 6.0.0
# Purpose: Optimized setup ONLY for Local by Flywheel/WP Engine on Windows
# ============================================

# Requires PowerShell 5.0 or higher
#Requires -Version 5.0

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors for output
$colors = @{
    Red     = "Red"
    Green   = "Green"
    Yellow  = "Yellow"
    Blue    = "Cyan"
    Magenta = "Magenta"
}

# Header
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Magenta
Write-Host "║     WP Testing Framework - Local WP Setup (Windows)    ║" -ForegroundColor $colors.Magenta
Write-Host "║     Optimized for Local by Flywheel/WP Engine          ║" -ForegroundColor $colors.Magenta
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Magenta
Write-Host ""

# Function to detect Local WP installation
function Test-LocalWPEnvironment {
    Write-Host "🔍 Detecting Local WP environment..." -ForegroundColor $colors.Blue
    
    $isLocalWP = $false
    $siteName = ""
    $localPath = $PWD.Path
    
    # Check if we're in Local Sites directory structure
    if ($localPath -match "Local Sites") {
        $isLocalWP = $true
        # Extract site name from path
        if ($localPath -match "Local Sites[\\\/]([^\\\/]+)") {
            $siteName = $Matches[1]
        }
    }
    # Check for app/public structure
    elseif ($localPath -match "app[\\\/]public") {
        $isLocalWP = $true
        if ($localPath -match "Local Sites[\\\/]([^\\\/]+)") {
            $siteName = $Matches[1]
        } else {
            $siteName = "local-site"
        }
    }
    
    if (-not $isLocalWP) {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Yellow
        Write-Host "⚠️  Local WP environment not detected!" -ForegroundColor $colors.Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Yellow
        Write-Host ""
        Write-Host "This script is specifically for Local WP. Your current path:"
        Write-Host $localPath
        Write-Host ""
        Write-Host "For general WordPress installations, use:"
        Write-Host ".\setup.ps1" -ForegroundColor $colors.Green
        Write-Host ""
        
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    } else {
        Write-Host "✅ Local WP environment confirmed" -ForegroundColor $colors.Green
        Write-Host "   Site: $siteName" -ForegroundColor $colors.Green
        Write-Host "   Path: $localPath" -ForegroundColor $colors.Green
    }
    
    return @{
        IsLocalWP = $isLocalWP
        SiteName = $siteName
        Path = $localPath
    }
}

# Function to get Local WP configuration
function Get-LocalWPConfig {
    param([string]$SiteName)
    
    Write-Host ""
    Write-Host "📋 Reading Local WP configuration..." -ForegroundColor $colors.Blue
    
    # Common Local WP settings
    $config = @{
        LocalDomain = "$SiteName.local"
        WPUrl = "http://$SiteName.local"
        WPPath = $PWD.Path
        DBHost = "localhost"
        DBName = "local"
        DBUser = "root"
        DBPassword = "root"
    }
    
    # Windows specific paths
    $localAppPath = "C:\Program Files\Local"
    if (Test-Path $localAppPath) {
        $config.LocalAppPath = $localAppPath
    } else {
        # Check alternative path
        $localAppPath = "${env:LOCALAPPDATA}\Local"
        if (Test-Path $localAppPath) {
            $config.LocalAppPath = $localAppPath
        }
    }
    
    # Local run path
    $config.LocalRunPath = "${env:LOCALAPPDATA}\Local\run"
    
    # Try to find MySQL socket/pipe
    if (Test-Path $config.LocalRunPath) {
        $mysqlPipe = Get-ChildItem -Path $config.LocalRunPath -Filter "mysql.sock" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($mysqlPipe) {
            $config.MySQLSocket = $mysqlPipe.FullName
            Write-Host "✅ MySQL socket: $($mysqlPipe.FullName)" -ForegroundColor $colors.Green
        }
    }
    
    Write-Host "✅ Configuration detected:" -ForegroundColor $colors.Green
    Write-Host "   URL: $($config.WPUrl)"
    Write-Host "   Database: $($config.DBName)"
    Write-Host "   User: $($config.DBUser)"
    
    return $config
}

# Function to check Local WP services
function Test-LocalWPServices {
    param([string]$SiteName)
    
    Write-Host ""
    Write-Host "🔧 Checking Local WP services..." -ForegroundColor $colors.Blue
    
    # Check if Local is running
    $localProcess = Get-Process -Name "Local" -ErrorAction SilentlyContinue
    if ($localProcess) {
        Write-Host "✅ Local WP is running" -ForegroundColor $colors.Green
    } else {
        Write-Host "⚠️  Local WP might not be running" -ForegroundColor $colors.Yellow
        Write-Host "   Please ensure your site is started in Local WP"
    }
    
    # Check PHP version
    try {
        $phpVersion = & php -r "echo PHP_VERSION;" 2>$null
        if ($phpVersion) {
            Write-Host "✅ PHP $phpVersion" -ForegroundColor $colors.Green
        }
    } catch {
        Write-Host "⚠️  PHP not found in PATH" -ForegroundColor $colors.Yellow
    }
    
    # Check WP-CLI
    try {
        $wpVersion = & wp core version 2>$null
        if ($wpVersion) {
            Write-Host "✅ WordPress $wpVersion" -ForegroundColor $colors.Green
            Write-Host "✅ WP-CLI available" -ForegroundColor $colors.Green
        }
    } catch {
        Write-Host "⚠️  WP-CLI not found in PATH" -ForegroundColor $colors.Yellow
        Write-Host "   Local WP includes WP-CLI - you may need to use it from Local's shell"
    }
}

# Function to setup framework directories
function Initialize-FrameworkDirectories {
    Write-Host ""
    Write-Host "📁 Setting up framework directories..." -ForegroundColor $colors.Blue
    
    # Create framework directories
    $directories = @(
        "plugins",
        "tools",
        "templates\default",
        "backup\deprecated-scripts"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Create Local WP specific directories
    if (Test-Path "..\wp-content") {
        $uploadDirs = @(
            "..\wp-content\uploads\wbcom-scan",
            "..\wp-content\uploads\wbcom-plan"
        )
        
        foreach ($dir in $uploadDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }
    }
    
    Write-Host "✅ Directory structure created" -ForegroundColor $colors.Green
}

# Function to install dependencies
function Install-Dependencies {
    Write-Host ""
    Write-Host "📦 Installing dependencies..." -ForegroundColor $colors.Blue
    
    # Check if Composer is available
    $composerExists = Get-Command composer -ErrorAction SilentlyContinue
    
    if ($composerExists) {
        # Create composer.json if needed
        if (-not (Test-Path "composer.json")) {
            $composerJson = @'
{
    "name": "wp-testing/local-framework",
    "description": "WordPress Plugin Testing Framework for Local WP",
    "type": "project",
    "require-dev": {
        "phpstan/phpstan": "^1.0",
        "squizlabs/php_codesniffer": "^3.7",
        "wp-coding-standards/wpcs": "^3.0",
        "phpmd/phpmd": "^2.13",
        "sebastian/phpcpd": "^6.0",
        "phploc/phploc": "^7.0",
        "phpstan/extension-installer": "^1.1",
        "szepeviktor/phpstan-wordpress": "^1.0"
    },
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true,
            "phpstan/extension-installer": true
        },
        "optimize-autoloader": true,
        "preferred-install": "dist"
    }
}
'@
            Set-Content -Path "composer.json" -Value $composerJson
            Write-Host "✅ composer.json created" -ForegroundColor $colors.Green
        }
        
        # Install with Local WP optimizations
        try {
            & composer install --no-interaction --prefer-dist --optimize-autoloader 2>$null
            Write-Host "✅ Composer packages installed" -ForegroundColor $colors.Green
        } catch {
            Write-Host "⚠️  Some Composer packages failed to install" -ForegroundColor $colors.Yellow
        }
        
        # Configure PHPCS
        if (Test-Path "vendor\bin\phpcs.bat") {
            try {
                & .\vendor\bin\phpcs.bat --config-set installed_paths vendor/wp-coding-standards/wpcs 2>$null
                Write-Host "✅ PHP analysis tools installed" -ForegroundColor $colors.Green
            } catch {
                # Silent fail - not critical
            }
        }
    } else {
        Write-Host "⚠️  Composer not found" -ForegroundColor $colors.Yellow
        Write-Host "   Install Composer: https://getcomposer.org"
    }
}

# Function to create configuration file
function New-LocalWPConfig {
    param($Config, $SiteName)
    
    Write-Host ""
    Write-Host "📝 Creating Local WP configuration..." -ForegroundColor $colors.Blue
    
    $envContent = @"
# WP Testing Framework - Local WP Configuration
# Generated: $(Get-Date)
# Site: $SiteName

# Local WP Settings
SITE_NAME=$SiteName
LOCAL_DOMAIN=$($Config.LocalDomain)
WP_URL=$($Config.WPUrl)
WP_PATH=$($Config.WPPath)

# Database (Local WP defaults)
DB_HOST=$($Config.DBHost)
DB_NAME=$($Config.DBName)
DB_USER=$($Config.DBUser)
DB_PASSWORD=$($Config.DBPassword)
DB_SOCKET=$($Config.MySQLSocket)

# Local WP Paths
LOCAL_APP_PATH=$($Config.LocalAppPath)
LOCAL_RUN_PATH=$($Config.LocalRunPath)

# Testing Configuration
TEST_TYPE=full
GENERATE_DOCS=true
VALIDATE_QUALITY=true
MIN_QUALITY_SCORE=70

# Local WP Specific
USE_LOCAL_WP_CLI=true
LOCAL_PHP_VERSION=$phpVersion
"@
    
    Set-Content -Path ".env.local" -Value $envContent
    Write-Host "✅ Configuration saved to .env.local" -ForegroundColor $colors.Green
}

# Function to create helper scripts
function New-HelperScripts {
    param([string]$SiteName)
    
    Write-Host ""
    Write-Host "📜 Creating Local WP helper scripts..." -ForegroundColor $colors.Blue
    
    # Create Windows batch test runner
    $batchScript = @'
@echo off
REM Quick test runner for Local WP Windows

set PLUGIN=%1
if "%PLUGIN%"=="" (
    echo Usage: run-local-test.bat plugin-name
    echo.
    echo Available plugins:
    dir /b ..\wp-content\plugins
    exit /b 1
)

echo Testing %PLUGIN%...
powershell.exe -ExecutionPolicy Bypass -File test-plugin.ps1 %PLUGIN%

REM Open results in browser
for /f "delims=" %%i in ('dir /b /s ..\wp-content\uploads\wbcom-scan\%PLUGIN%\*.html 2^>nul') do (
    start "" "%%i"
    goto :end
)
:end
'@
    
    Set-Content -Path "run-local-test.bat" -Value $batchScript
    Write-Host "✅ Helper script created: run-local-test.bat" -ForegroundColor $colors.Green
}

# Function to test the setup
function Test-Setup {
    Write-Host ""
    Write-Host "🧪 Testing Local WP setup..." -ForegroundColor $colors.Blue
    
    # Check test scripts
    if (Test-Path "test-plugin.ps1") {
        Write-Host "✅ test-plugin.ps1 ready" -ForegroundColor $colors.Green
    }
    
    if (Test-Path "test-plugin.sh") {
        # Make executable (Git Bash compatibility)
        try {
            & git update-index --chmod=+x test-plugin.sh 2>$null
        } catch {
            # Silent fail - not critical
        }
        Write-Host "✅ test-plugin.sh ready" -ForegroundColor $colors.Green
    }
    
    # List available plugins
    Write-Host ""
    Write-Host "Available plugins to test:"
    if (Test-Path "..\wp-content\plugins") {
        Get-ChildItem -Path "..\wp-content\plugins" -Directory | 
            Where-Object { $_.Name -ne "index.php" } | 
            Select-Object -First 10 | 
            ForEach-Object { Write-Host "  - $($_.Name)" }
    }
}

# Function to show Local WP tips
function Show-LocalWPTips {
    param([string]$SiteName)
    
    Write-Host ""
    Write-Host "💡 Local WP Tips:" -ForegroundColor $colors.Blue
    Write-Host ""
    Write-Host "1. Use Local's built-in terminal for best compatibility"
    Write-Host "2. Site must be running in Local before testing"
    Write-Host "3. Database credentials are usually root/root"
    Write-Host "4. Access phpMyAdmin via Local's Database tab"
    Write-Host "5. View logs in Local's site settings"
    Write-Host ""
    Write-Host "Common Local WP paths:"
    Write-Host "• Site root: ~\Local Sites\$SiteName\app\public"
    Write-Host "• Logs: ~\Local Sites\$SiteName\logs"
    Write-Host "• Config: ~\Local Sites\$SiteName\conf"
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "This script optimizes WP Testing Framework specifically for Local WP on Windows."
    Write-Host ""
    
    # Detect Local WP
    $localInfo = Test-LocalWPEnvironment
    if (-not $localInfo.SiteName) {
        $localInfo.SiteName = "local-site"
    }
    
    # Get configuration
    $config = Get-LocalWPConfig -SiteName $localInfo.SiteName
    
    # Check services
    Test-LocalWPServices -SiteName $localInfo.SiteName
    
    # Setup framework
    Initialize-FrameworkDirectories
    
    # Install dependencies
    Install-Dependencies
    
    # Create config
    New-LocalWPConfig -Config $config -SiteName $localInfo.SiteName
    
    # Create helpers
    New-HelperScripts -SiteName $localInfo.SiteName
    
    # Test setup
    Test-Setup
    
    # Show tips
    Show-LocalWPTips -SiteName $localInfo.SiteName
    
    # Success message
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
    Write-Host "✅ Local WP Setup Complete!" -ForegroundColor $colors.Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
    Write-Host ""
    Write-Host "Site: $($localInfo.SiteName)"
    Write-Host "URL: $($config.WPUrl)"
    Write-Host ""
    Write-Host "Quick start:"
    Write-Host ".\run-local-test.bat [plugin-name]" -ForegroundColor $colors.Green -NoNewline
    Write-Host " - Test with browser preview"
    Write-Host ".\test-plugin.ps1 [plugin-name]" -ForegroundColor $colors.Green -NoNewline
    Write-Host " - Standard test"
    Write-Host ""
    Write-Host "For Unix/Mac users:"
    Write-Host "Use " -NoNewline
    Write-Host "./local-wp-setup.sh" -ForegroundColor $colors.Green -NoNewline
    Write-Host " for bash setup"
}

# Run main function
Main