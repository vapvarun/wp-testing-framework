@echo off
REM ============================================
REM WP Testing Framework - Windows Launcher
REM Version: 13.0
REM Purpose: Easy launcher for Windows users
REM ============================================

setlocal enabledelayedexpansion

REM Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not installed or not in PATH
    echo Please install PowerShell to use this framework
    pause
    exit /b 1
)

REM Check if plugin name was provided
if "%1"=="" (
    echo.
    echo ========================================
    echo   WP Testing Framework v13.0 - Windows
    echo ========================================
    echo.
    echo USAGE: test-plugin.bat ^<plugin-name^> [mode]
    echo.
    echo MODES:
    echo   full     - Run all 13 phases ^(default^)
    echo   quick    - Skip time-consuming phases
    echo   security - Focus on security phases
    echo.
    echo EXAMPLES:
    echo   test-plugin.bat woocommerce
    echo   test-plugin.bat elementor quick
    echo   test-plugin.bat yoast-seo security
    echo.
    echo PHASES:
    echo   1.  Setup ^& Directory Structure
    echo   2.  Plugin Detection ^& Basic Analysis
    echo   3.  Plugin Check Analysis ^(WP Standards^)
    echo   4.  AI-Driven Code Analysis
    echo   5.  Security Vulnerability Scanning
    echo   6.  Performance Analysis
    echo   7.  Test Generation ^& Coverage
    echo   8.  Visual Testing ^& Screenshots
    echo   9.  WordPress Integration Tests
    echo   10. Documentation Generation
    echo   11. Report Consolidation
    echo   12. Live Testing with Test Data
    echo   13. Framework Safekeeping
    echo.
    pause
    exit /b 1
)

REM Get parameters
set PLUGIN_NAME=%1
set TEST_MODE=%2
if "%TEST_MODE%"=="" set TEST_MODE=full

REM Display header
echo.
echo ============================================
echo   WP Testing Framework v13.0
echo   Analyzing: %PLUGIN_NAME%
echo   Mode: %TEST_MODE%
echo ============================================
echo.

REM Check execution policy
echo Checking PowerShell execution policy...
powershell -Command "Get-ExecutionPolicy" | findstr /i "Restricted" >nul
if %errorlevel% equ 0 (
    echo.
    echo WARNING: PowerShell execution policy is set to Restricted
    echo Attempting to bypass for this session...
    echo.
    set BYPASS=-ExecutionPolicy Bypass
) else (
    set BYPASS=
)

REM Run the PowerShell script
echo Starting analysis...
echo.
powershell %BYPASS% -File "%~dp0test-plugin.ps1" -PluginName "%PLUGIN_NAME%" -TestMode "%TEST_MODE%"

REM Check if it ran successfully
if %errorlevel% neq 0 (
    echo.
    echo ============================================
    echo   ERROR: Analysis failed
    echo ============================================
    echo.
    echo Possible issues:
    echo 1. Plugin not found
    echo 2. PowerShell execution policy blocking
    echo 3. Missing dependencies
    echo.
    echo Try running this command directly:
    echo   powershell -ExecutionPolicy Bypass -File test-plugin.ps1 %PLUGIN_NAME%
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ============================================
echo   Analysis Complete!
echo ============================================
echo.
pause
exit /b 0