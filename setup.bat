@echo off
REM ============================================
REM WP Testing Framework - Windows Setup
REM Version: 13.0
REM Purpose: Easy setup for Windows users
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo   WP Testing Framework Setup - Windows
echo   Version 13.0
echo ============================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not installed or not in PATH
    echo Please install PowerShell to continue
    pause
    exit /b 1
)

REM Check for WordPress
if not exist "wp-config.php" (
    if not exist "..\wp-config.php" (
        echo WARNING: WordPress installation not detected
        echo Make sure you're running this from your WordPress root directory
        echo.
        set /p CONTINUE="Continue anyway? (y/n): "
        if /i not "!CONTINUE!"=="y" (
            exit /b 1
        )
    )
)

echo Checking system requirements...
echo.

REM Check PHP
where php >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] PHP not found in PATH
    echo    Please install PHP or add it to your PATH
    set PHP_OK=0
) else (
    echo [OK] PHP found
    php -v | findstr /r "[0-9]"
    set PHP_OK=1
)

REM Check Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] Node.js not found
    echo    Some features will be limited
    set NODE_OK=0
) else (
    echo [OK] Node.js found
    node -v
    set NODE_OK=1
)

REM Check WP-CLI
where wp >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] WP-CLI not found
    echo    Download from: https://wp-cli.org/
    set WPCLI_OK=0
) else (
    echo [OK] WP-CLI found
    wp --version | findstr /r "[0-9]"
    set WPCLI_OK=1
)

REM Check Composer
where composer >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] Composer not found
    echo    Some features will be limited
    set COMPOSER_OK=0
) else (
    echo [OK] Composer found
    composer --version | findstr /r "[0-9]"
    set COMPOSER_OK=1
)

echo.
echo ============================================
echo   Running PowerShell Setup Script
echo ============================================
echo.

REM Check execution policy
powershell -Command "Get-ExecutionPolicy" | findstr /i "Restricted" >nul
if %errorlevel% equ 0 (
    echo PowerShell execution policy is Restricted
    echo Running with bypass...
    set BYPASS=-ExecutionPolicy Bypass
) else (
    set BYPASS=
)

REM Run the PowerShell setup
powershell %BYPASS% -File "%~dp0setup.ps1"

if %errorlevel% neq 0 (
    echo.
    echo Setup failed! Please check the error messages above.
    pause
    exit /b %errorlevel%
)

echo.
echo ============================================
echo   Setup Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Install Plugin Check: setup-plugin-check.bat
echo 2. Test a plugin: test-plugin.bat ^<plugin-name^>
echo.
echo Example: test-plugin.bat woocommerce
echo.
pause
exit /b 0