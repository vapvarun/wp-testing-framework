@echo off
REM ============================================
REM WordPress Plugin Check Setup - Windows
REM Version: 1.0
REM Purpose: Install and configure Plugin Check
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo   WordPress Plugin Check Setup
echo   For WP Testing Framework v13.0
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

REM Check WP-CLI
where wp >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: WP-CLI is required for Plugin Check
    echo Please install WP-CLI first
    echo Download from: https://wp-cli.org/
    pause
    exit /b 1
)

echo This will install and configure WordPress Plugin Check
echo as a data source for the testing framework.
echo.
set /p CONTINUE="Continue with installation? (y/n): "
if /i not "!CONTINUE!"=="y" (
    echo Installation cancelled.
    exit /b 0
)

echo.
echo Installing Plugin Check plugin...
wp plugin install plugin-check --activate 2>nul
if %errorlevel% neq 0 (
    echo Plugin Check may already be installed, continuing...
)

echo.
echo Setting up dependencies...
echo.

REM Check execution policy
powershell -Command "Get-ExecutionPolicy" | findstr /i "Restricted" >nul
if %errorlevel% equ 0 (
    set BYPASS=-ExecutionPolicy Bypass
) else (
    set BYPASS=
)

REM Run the PowerShell setup script
powershell %BYPASS% -File "%~dp0tools\setup-plugin-check.ps1"

if %errorlevel% neq 0 (
    echo.
    echo WARNING: Some dependencies may not have installed correctly
    echo Plugin Check will still work but with limited features
    echo.
)

echo.
echo ============================================
echo   Plugin Check Setup Complete!
echo ============================================
echo.
echo Plugin Check has been installed and configured.
echo.
echo You can now:
echo 1. Run full framework analysis: test-plugin.bat ^<plugin-name^>
echo 2. Run Plugin Check directly: wp plugin check ^<plugin-name^>
echo.
echo Plugin Check will run as Phase 3 in the framework,
echo providing WordPress standards compliance data for
echo all subsequent analysis phases.
echo.
pause
exit /b 0