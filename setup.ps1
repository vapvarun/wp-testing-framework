# ============================================
# WP Testing Framework - General WordPress Setup (Windows)
# Version: 5.0.0
# Purpose: Setup for ANY WordPress installation on Windows
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
    NC      = "White"
}

# Header
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Blue
Write-Host "║   WP Testing Framework - General WordPress Setup       ║" -ForegroundColor $colors.Blue
Write-Host "║   For: Standard hosting, Docker, XAMPP, WAMP, etc.     ║" -ForegroundColor $colors.Blue
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Blue
Write-Host ""

# Function to check environment
function Test-Environment {
    # Check if Local WP and suggest appropriate script
    $currentPath = $PWD.Path
    
    if ($currentPath -match "Local Sites" -or (Test-Path "/Applications/Local.app" -ErrorAction SilentlyContinue) -and $currentPath -match "app[\\\/]public") {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Yellow
        Write-Host "⚠️  Local WP Detected!" -ForegroundColor $colors.Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Yellow
        Write-Host ""
        Write-Host "You appear to be using Local WP. For optimized setup, use:"
        Write-Host ".\local-wp-setup.ps1" -ForegroundColor $colors.Green
        Write-Host ""
        
        $continue = Read-Host "Continue with general setup anyway? (y/n)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Host "Switching to Local WP setup..."
            & .\local-wp-setup.ps1
            exit 0
        }
    }
}

# Function to find WordPress root
function Find-WPRoot {
    Write-Host "🔍 Finding WordPress root..." -ForegroundColor $colors.Blue
    
    $wpRoot = $null
    
    # Check current directory
    if (Test-Path "wp-config.php" -or Test-Path "wp-config-sample.php") {
        $wpRoot = $PWD.Path
    }
    # Check parent directory
    elseif (Test-Path "..\wp-config.php") {
        $wpRoot = (Get-Item "..\").FullName
    }
    # Check if we're in wp-content
    elseif ($PWD.Path -match "wp-content") {
        $wpRoot = $PWD.Path -replace "\\wp-content.*", ""
    }
    else {
        Write-Host "❌ WordPress installation not found!" -ForegroundColor $colors.Red
        Write-Host "Please run this script from your WordPress root directory."
        exit 1
    }
    
    Write-Host "✅ WordPress root: $wpRoot" -ForegroundColor $colors.Green
    return $wpRoot
}

# Function to detect WordPress environment type
function Get-WPEnvironmentType {
    Write-Host "🔍 Detecting WordPress environment..." -ForegroundColor $colors.Blue
    
    $envType = "Unknown"
    $currentPath = $PWD.Path
    
    # Check for Docker
    if (Test-Path "docker-compose.yml" -or Test-Path "Dockerfile") {
        $envType = "Docker"
        Write-Host "✅ Docker environment detected" -ForegroundColor $colors.Green
    }
    # Check for XAMPP
    elseif ($currentPath -match "xampp" -or $currentPath -match "htdocs") {
        $envType = "XAMPP"
        Write-Host "✅ XAMPP environment detected" -ForegroundColor $colors.Green
    }
    # Check for WAMP
    elseif ($currentPath -match "wamp" -or $currentPath -match "www") {
        $envType = "WAMP"
        Write-Host "✅ WAMP environment detected" -ForegroundColor $colors.Green
    }
    # Check for standard hosting
    elseif ($currentPath -match "public_html" -or $currentPath -match "www") {
        $envType = "Standard Hosting"
        Write-Host "✅ Standard hosting environment detected" -ForegroundColor $colors.Green
    }
    else {
        Write-Host "⚠️  Environment type unknown - using defaults" -ForegroundColor $colors.Yellow
    }
    
    return $envType
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host ""
    Write-Host "📋 Checking prerequisites..." -ForegroundColor $colors.Blue
    
    $missing = 0
    
    # Check PHP
    try {
        $phpVersion = & php -r "echo PHP_VERSION;" 2>$null
        if ($phpVersion) {
            Write-Host "✅ PHP $phpVersion" -ForegroundColor $colors.Green
        }
    } catch {
        Write-Host "❌ PHP not found" -ForegroundColor $colors.Red
        $missing++
    }
    
    # Check MySQL/MariaDB
    $mysqlExists = Get-Command mysql -ErrorAction SilentlyContinue
    if ($mysqlExists) {
        Write-Host "✅ MySQL/MariaDB available" -ForegroundColor $colors.Green
    } else {
        Write-Host "⚠️  MySQL client not found (may still work)" -ForegroundColor $colors.Yellow
    }
    
    # Check WP-CLI
    $global:HAS_WP_CLI = $false
    try {
        $wpVersion = & wp --version 2>$null
        if ($wpVersion) {
            Write-Host "✅ WP-CLI $($wpVersion -replace 'WP-CLI ', '')" -ForegroundColor $colors.Green
            $global:HAS_WP_CLI = $true
        }
    } catch {
        Write-Host "⚠️  WP-CLI not found (optional but recommended)" -ForegroundColor $colors.Yellow
    }
    
    # Check Composer
    $composerExists = Get-Command composer -ErrorAction SilentlyContinue
    if ($composerExists) {
        try {
            $composerVersion = & composer --version 2>$null
            Write-Host "✅ Composer installed" -ForegroundColor $colors.Green
        } catch {
            Write-Host "⚠️  Composer found but not working properly" -ForegroundColor $colors.Yellow
        }
    } else {
        Write-Host "⚠️  Composer not found (optional)" -ForegroundColor $colors.Yellow
    }
    
    # Check Git
    $gitExists = Get-Command git -ErrorAction SilentlyContinue
    if ($gitExists) {
        try {
            $gitVersion = & git --version 2>$null
            Write-Host "✅ $gitVersion" -ForegroundColor $colors.Green
        } catch {
            Write-Host "⚠️  Git found but not working properly" -ForegroundColor $colors.Yellow
        }
    } else {
        Write-Host "⚠️  Git not found (optional)" -ForegroundColor $colors.Yellow
    }
    
    if ($missing -gt 0) {
        Write-Host ""
        Write-Host "Missing required components. Please install them first." -ForegroundColor $colors.Red
        exit 1
    }
}

# Function to setup framework directories
function Initialize-Directories {
    Write-Host ""
    Write-Host "📁 Setting up framework directories..." -ForegroundColor $colors.Blue
    
    # Create necessary directories
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
    
    # Create uploads directories if they don't exist
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
        Write-Host "✅ Upload directories created" -ForegroundColor $colors.Green
    }
    
    Write-Host "✅ Directory structure ready" -ForegroundColor $colors.Green
}

# Function to install PHP dependencies
function Install-PHPDependencies {
    Write-Host ""
    Write-Host "📦 Installing PHP dependencies..." -ForegroundColor $colors.Blue
    
    $composerExists = Get-Command composer -ErrorAction SilentlyContinue
    
    if ($composerExists) {
        # Create composer.json if it doesn't exist
        if (-not (Test-Path "composer.json")) {
            $composerJson = @'
{
    "name": "wp-testing/framework",
    "description": "WordPress Plugin Testing Framework",
    "type": "project",
    "require-dev": {
        "phpstan/phpstan": "^1.0",
        "squizlabs/php_codesniffer": "^3.7",
        "wp-coding-standards/wpcs": "^3.0",
        "phpmd/phpmd": "^2.13",
        "sebastian/phpcpd": "^6.0",
        "phploc/phploc": "^7.0"
    },
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true
        }
    }
}
'@
            Set-Content -Path "composer.json" -Value $composerJson
            Write-Host "✅ composer.json created" -ForegroundColor $colors.Green
        }
        
        # Install dependencies
        try {
            & composer install --no-interaction --quiet 2>$null
            
            # Configure PHPCS with WordPress standards
            if (Test-Path "vendor\bin\phpcs.bat") {
                & .\vendor\bin\phpcs.bat --config-set installed_paths vendor/wp-coding-standards/wpcs 2>$null
                Write-Host "✅ PHP tools installed and configured" -ForegroundColor $colors.Green
            }
        } catch {
            Write-Host "⚠️  Some dependencies failed to install" -ForegroundColor $colors.Yellow
        }
    } else {
        Write-Host "⚠️  Composer not available - skipping PHP tools" -ForegroundColor $colors.Yellow
    }
}

# Function to configure for specific environments
function Set-EnvironmentConfig {
    param([string]$EnvType)
    
    Write-Host ""
    Write-Host "⚙️  Configuring for $EnvType environment..." -ForegroundColor $colors.Blue
    
    switch ($EnvType) {
        "Docker" {
            Write-Host "Docker-specific configuration:"
            Write-Host "- Database host: Usually 'db' or 'mysql' (check docker-compose.yml)"
            Write-Host "- Use container names for service connections"
        }
        "XAMPP" {
            Write-Host "XAMPP-specific configuration:"
            Write-Host "- Database host: localhost"
            Write-Host "- Default MySQL port: 3306"
            Write-Host "- phpMyAdmin: http://localhost/phpmyadmin"
        }
        "WAMP" {
            Write-Host "WAMP-specific configuration:"
            Write-Host "- Database host: localhost"
            Write-Host "- Default MySQL port: 3306"
            Write-Host "- phpMyAdmin: http://localhost/phpmyadmin"
        }
        "Standard Hosting" {
            Write-Host "Standard hosting configuration:"
            Write-Host "- Check hosting provider for database details"
            Write-Host "- May need to use specific PHP version selector"
        }
        default {
            Write-Host "Using default configuration"
        }
    }
}

# Function to test plugin functionality
function Test-Framework {
    Write-Host ""
    Write-Host "🧪 Testing framework setup..." -ForegroundColor $colors.Blue
    
    # Check if test script exists
    if (Test-Path "test-plugin.ps1") {
        Write-Host "✅ test-plugin.ps1 is ready" -ForegroundColor $colors.Green
        
        # List available plugins
        if (Test-Path "..\wp-content\plugins") {
            Write-Host ""
            Write-Host "Available plugins to test:"
            Get-ChildItem -Path "..\wp-content\plugins" -Directory | 
                Select-Object -First 5 | 
                ForEach-Object { Write-Host "  - $($_.Name)" }
            
            Write-Host ""
            Write-Host "To test a plugin, run:"
            Write-Host ".\test-plugin.ps1 plugin-name" -ForegroundColor $colors.Green
        }
    } else {
        Write-Host "❌ test-plugin.ps1 not found" -ForegroundColor $colors.Red
    }
}

# Function to create environment config file
function New-ConfigFile {
    param(
        [string]$WPRoot,
        [string]$EnvType
    )
    
    Write-Host ""
    Write-Host "📝 Creating environment configuration..." -ForegroundColor $colors.Blue
    
    $configContent = @"
# WP Testing Framework Configuration
# Generated: $(Get-Date)
# Environment: $EnvType

WP_ROOT=$WPRoot
ENV_TYPE=$EnvType
HAS_WP_CLI=$($global:HAS_WP_CLI)

# Database Configuration (update as needed)
DB_HOST=localhost
DB_NAME=wordpress
DB_USER=root
DB_PASSWORD=

# Testing Configuration
TEST_TYPE=full
GENERATE_DOCS=true
VALIDATE_QUALITY=true
MIN_QUALITY_SCORE=70
"@
    
    Set-Content -Path ".env.testing" -Value $configContent
    Write-Host "✅ Configuration saved to .env.testing" -ForegroundColor $colors.Green
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "This script will set up WP Testing Framework for general WordPress installations."
    Write-Host ""
    
    # Check environment
    Test-Environment
    
    # Find WordPress root
    $wpRoot = Find-WPRoot
    
    # Detect environment type
    $envType = Get-WPEnvironmentType
    
    # Check prerequisites
    Test-Prerequisites
    
    # Setup directories
    Initialize-Directories
    
    # Install dependencies
    Install-PHPDependencies
    
    # Configure for environment
    Set-EnvironmentConfig -EnvType $envType
    
    # Create config file
    New-ConfigFile -WPRoot $wpRoot -EnvType $envType
    
    # Test framework
    Test-Framework
    
    # Success message
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
    Write-Host "✅ WP Testing Framework Setup Complete!" -ForegroundColor $colors.Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Green
    Write-Host ""
    Write-Host "Environment: $envType"
    Write-Host "WordPress Root: $wpRoot"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Review .env.testing and update database credentials if needed"
    Write-Host "2. Run: " -NoNewline
    Write-Host ".\test-plugin.ps1 [plugin-name]" -ForegroundColor $colors.Green -NoNewline
    Write-Host " to test a plugin"
    Write-Host "3. Check generated documentation in plugins\[plugin-name]\"
    Write-Host ""
    Write-Host "For help: " -NoNewline
    Write-Host ".\test-plugin.ps1 --help" -ForegroundColor $colors.Green
}

# Run main function
Main