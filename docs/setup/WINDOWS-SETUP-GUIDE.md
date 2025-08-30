# WP Testing Framework - Windows Setup Guide

**GitHub:** https://github.com/vapvarun/wp-testing-framework/

## 🪟 Windows Users - Complete AI-Driven Plugin Testing

This guide helps Windows users run the complete integrated testing framework with Local WP.

## Prerequisites

- Local WP installed on Windows
- PowerShell (comes with Windows)
- Git for Windows (includes Git Bash)
- Your WordPress site running in Local WP

## 🚀 Installation Options for Windows

### Option 1: Using Git Bash (Recommended)

Git Bash allows you to run bash scripts on Windows.

```bash
# 1. Open Git Bash
# 2. Navigate to your Local WP site
cd /c/Users/[YourName]/Local\ Sites/[sitename]/app/public

# 3. Clone the framework
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 4. Run the setup
./local-wp-setup.sh

# 5. Run complete plugin analysis
./test-plugin.sh bbpress
```

### Option 2: Using PowerShell Script

We provide a PowerShell version for native Windows execution.

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to your Local WP site
cd "C:\Users\[YourName]\Local Sites\[sitename]\app\public"

# 3. Clone the framework
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 4. Run PowerShell setup
.\local-wp-setup.ps1

# 5. Run complete plugin analysis
.\test-plugin.ps1 bbpress
```

## 🎯 Complete AI-Driven Analysis (8 Phases)

The integrated script performs comprehensive analysis:

```powershell
# Using PowerShell
.\test-plugin.ps1 woocommerce          # Full analysis
.\test-plugin.ps1 elementor quick      # Quick test
.\test-plugin.ps1 wordfence security   # Security focus
.\test-plugin.ps1 wp-rocket performance # Performance focus

# Using Git Bash
./test-plugin.sh woocommerce
./test-plugin.sh elementor quick
```

### What Happens in Each Phase:

1. **Setup** - Creates workspace directories
2. **Detection** - Finds and activates plugin
3. **AI Analysis** - Scans all code (2,431+ functions for bbPress!)
4. **Security** - Vulnerability scanning
5. **Performance** - Memory and load profiling
6. **Testing** - Coverage analysis
7. **AI Reports** - Claude-ready files
8. **Dashboard** - HTML visualization

## 📊 Windows-Specific Paths

Local WP on Windows typically installs to:
```
C:\Users\[YourName]\Local Sites\[sitename]\app\public
```

After testing, find your results:
```powershell
# AI Analysis Reports
workspace\ai-reports\[plugin]\ai-analysis-report.md
workspace\ai-reports\[plugin]\functions-list.txt
workspace\ai-reports\[plugin]\classes-list.txt

# Visual Reports
workspace\reports\[plugin]\report-*.html

# Open in browser
start workspace\reports\bbpress\report-*.html
```

## 🛠️ PowerShell Script (test-plugin.ps1)

```powershell
# PowerShell version of test-plugin.sh
param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    
    [Parameter()]
    [string]$TestType = "full"
)

Write-Host "=================================" -ForegroundColor Blue
Write-Host "WP Testing Framework - AI Analysis" -ForegroundColor Blue
Write-Host "Plugin: $PluginName" -ForegroundColor Blue
Write-Host "=================================" -ForegroundColor Blue

# Phase 1: Setup
Write-Host "`nPhase 1: Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "workspace\ai-reports\$PluginName"
New-Item -ItemType Directory -Force -Path "workspace\reports\$PluginName"
New-Item -ItemType Directory -Force -Path "plugins\$PluginName\tests"

# Phase 2: Plugin Detection
Write-Host "`nPhase 2: Detecting plugin..." -ForegroundColor Yellow
$pluginPath = "..\wp-content\plugins\$PluginName"
if (Test-Path $pluginPath) {
    Write-Host "✓ Plugin found" -ForegroundColor Green
    
    # Phase 3: Code Analysis
    Write-Host "`nPhase 3: Analyzing code..." -ForegroundColor Yellow
    $phpFiles = Get-ChildItem -Path $pluginPath -Filter "*.php" -Recurse
    $functions = Select-String -Path $phpFiles.FullName -Pattern "function\s+" -AllMatches
    $classes = Select-String -Path $phpFiles.FullName -Pattern "^class\s+" -AllMatches
    $hooks = Select-String -Path $phpFiles.FullName -Pattern "add_action|add_filter" -AllMatches
    
    Write-Host "Functions: $($functions.Count)" -ForegroundColor Green
    Write-Host "Classes: $($classes.Count)" -ForegroundColor Green
    Write-Host "Hooks: $($hooks.Count)" -ForegroundColor Green
    
    # Save analysis
    $functions | Out-File "workspace\ai-reports\$PluginName\functions-list.txt"
    $classes | Out-File "workspace\ai-reports\$PluginName\classes-list.txt"
    $hooks | Out-File "workspace\ai-reports\$PluginName\hooks-list.txt"
    
    # Generate report
    @"
# AI Analysis Report: $PluginName
Generated: $(Get-Date)

## Summary
- PHP Files: $($phpFiles.Count)
- Functions: $($functions.Count)
- Classes: $($classes.Count)
- Hooks: $($hooks.Count)

## Next Steps
1. Review function list in functions-list.txt
2. Feed to Claude for test generation
3. Run generated tests
"@ | Out-File "workspace\ai-reports\$PluginName\ai-analysis-report.md"
    
    Write-Host "`n✓ Analysis complete!" -ForegroundColor Green
    Write-Host "View report: workspace\ai-reports\$PluginName\ai-analysis-report.md" -ForegroundColor Cyan
}
else {
    Write-Host "✗ Plugin not found at $pluginPath" -ForegroundColor Red
}
```

## 🔧 Troubleshooting Windows Issues

### Permission Errors
```powershell
# Run PowerShell as Administrator
# Or set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Path Issues with Spaces
```powershell
# Always use quotes for paths with spaces
cd "C:\Users\Your Name\Local Sites\mysite\app\public"
```

### Line Ending Issues
```bash
# If scripts fail due to line endings, use Git Bash:
dos2unix test-plugin.sh
# Or in Git config:
git config core.autocrlf true
```

## 💻 WSL2 Alternative (Windows Subsystem for Linux)

For the best experience, use WSL2:

```bash
# In WSL2 terminal
cd /mnt/c/Users/[YourName]/Local\ Sites/[sitename]/app/public
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./local-wp-setup.sh
./test-plugin.sh bbpress
```

## 📝 Complete Windows Workflow Example

```powershell
# 1. Open PowerShell
# 2. Navigate to Local WP site
cd "C:\Users\JohnDoe\Local Sites\testsite\app\public"

# 3. Clone framework
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 4. Run setup (PowerShell version)
.\local-wp-setup.ps1

# 5. Analyze bbPress plugin
.\test-plugin.ps1 bbpress

# Output:
# ✓ 2,431 functions analyzed
# ✓ 63 classes documented  
# ✓ 2,059 hooks identified
# ✓ Security scan complete
# ✓ Performance profiled
# ✓ AI reports generated

# 6. View HTML report
start workspace\reports\bbpress\report-*.html

# 7. Get AI analysis for Claude
Get-Content workspace\ai-reports\bbpress\ai-analysis-report.md
```

## 🚀 Quick Reference

| Task | Git Bash | PowerShell |
|------|----------|------------|
| Setup | `./local-wp-setup.sh` | `.\local-wp-setup.ps1` |
| Full Test | `./test-plugin.sh plugin` | `.\test-plugin.ps1 plugin` |
| Quick Test | `./test-plugin.sh plugin quick` | `.\test-plugin.ps1 plugin quick` |
| View Report | `start workspace/reports/plugin/report-*.html` | `start workspace\reports\plugin\report-*.html` |

## 📧 Support

- **Issues:** https://github.com/vapvarun/wp-testing-framework/issues
- **Windows-specific help:** Tag issues with `windows`
- **Documentation:** This guide and more in `/docs`

## 🎉 You're Ready!

Whether using Git Bash, PowerShell, or WSL2, you can now run complete AI-driven plugin analysis on Windows. The framework automatically handles path differences and generates the same comprehensive reports as Mac/Linux users.