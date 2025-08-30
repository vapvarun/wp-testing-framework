# Windows Setup Guide

## 🚀 Quick Start for Windows Users (Local WP)

Windows users can use the WP Testing Framework with Local WP just as easily! We provide PowerShell scripts that work perfectly on Windows.

## 📋 Prerequisites

### Required (Windows)
- **Local WP for Windows** - [Download free](https://localwp.com/)
- **PowerShell** - Included in Windows 10/11
- **Git for Windows** - [Download](https://git-scm.com/download/win)

### Automatically Included in Local WP
- ✅ PHP 8.0+
- ✅ Node.js
- ✅ WP-CLI
- ✅ MySQL

## 🎯 Installation Steps

### Step 1: Open Local WP Site Shell

1. Open Local WP
2. Select your site
3. Click "Open Site Shell" button
4. This opens PowerShell in the correct directory

### Step 2: Clone Framework

```powershell
# In Local WP Site Shell (PowerShell)
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
```

### Step 3: Run Windows Setup

```powershell
# Run PowerShell setup script
.\local-wp-setup.ps1
```

### Step 4: Test Any Plugin

```powershell
# Test a plugin (PowerShell version)
.\test-plugin.ps1 bbpress
.\test-plugin.ps1 buddypress
.\test-plugin.ps1 woocommerce
```

## 📁 Windows Path Locations

### Local WP Sites Directory
```powershell
# Windows paths for Local WP sites:
C:\Users\%USERNAME%\Local Sites\your-site\app\public

# Or use environment variable
$env:USERPROFILE\Local Sites\your-site\app\public
```

### Navigate to Site
```powershell
# Method 1: Use Local WP "Open Site Shell"

# Method 2: Manual navigation
cd "C:\Users\$env:USERNAME\Local Sites\your-site\app\public"
```

## 🔧 PowerShell Scripts Provided

### 1. `local-wp-setup.ps1`
Windows version of Local WP setup:
- Auto-detects Local WP on Windows
- Configures database (root/root)
- Sets up .env file
- Installs dependencies

### 2. `test-plugin.ps1`
Windows version of plugin tester:
- Creates folders automatically
- Runs all tests
- Generates HTML reports

### 3. `setup.ps1`
Universal setup that detects environment

## 💻 Using WP-CLI on Windows

Local WP includes WP-CLI, use it in Site Shell:

```powershell
# WP-CLI works in Local WP Site Shell
wp plugin list
wp plugin install bbpress --activate
wp plugin install buddypress --activate
```

## 🎨 Alternative: Use PHP Directly

If PowerShell scripts don't work, use PHP:

```powershell
# Run setup with PHP
php setup.php

# Test plugin with PHP
php test-plugin.php bbpress
```

## 📊 View Results on Windows

```powershell
# Open HTML report (Windows)
Start-Process workspace\reports\plugin-name\report-*.html

# Or navigate manually
explorer workspace\reports\
```

## 🐛 Windows-Specific Troubleshooting

### Issue: Scripts Not Running

```powershell
# Enable script execution (Run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for current session
powershell -ExecutionPolicy Bypass -File .\local-wp-setup.ps1
```

### Issue: Git Not Found

1. Install Git for Windows: https://git-scm.com/download/win
2. Restart PowerShell/Terminal
3. Verify: `git --version`

### Issue: Node/NPM Not Found

```powershell
# Local WP includes Node, but if not found:
# 1. Open Local WP
# 2. Go to site settings
# 3. Open Site Shell (uses correct environment)
```

### Issue: Path Spaces

```powershell
# Windows paths often have spaces, use quotes:
cd "C:\Users\John Doe\Local Sites\my-site\app\public"

# Or use short names:
cd C:\Users\JOHNDO~1\LOCALS~1\my-site\app\public
```

## 🎯 Quick Commands Reference (Windows)

```powershell
# Setup
.\local-wp-setup.ps1

# Test plugins
.\test-plugin.ps1 woocommerce
.\test-plugin.ps1 elementor
.\test-plugin.ps1 bbpress
.\test-plugin.ps1 buddypress

# View reports
explorer workspace\reports\

# Update framework
git pull origin main
npm install
composer update
```

## 🔄 Windows Batch Files (Alternative)

We also provide `.bat` files for Windows Command Prompt:

```batch
REM Setup
local-wp-setup.bat

REM Test plugin
test-plugin.bat bbpress
```

## 📝 Environment Variables (Windows)

The `.env` file works the same on Windows:

```env
# Auto-configured for Windows Local WP
WP_ROOT_DIR=../
TEST_DB_NAME=yoursite_test
TEST_DB_USER=root
TEST_DB_PASSWORD=root
TEST_DB_HOST=localhost
WP_TEST_URL=http://yoursite.local
```

## 💡 Windows Pro Tips

1. **Use Local WP Site Shell** - Ensures correct environment
2. **Use PowerShell** - More powerful than Command Prompt
3. **Install Windows Terminal** - Better experience (from Microsoft Store)
4. **Use quotes for paths** - Windows paths often have spaces
5. **Run as Administrator** - If permission issues

## 🚀 One-Line Installation (Windows PowerShell)

```powershell
# Complete installation in one line (PowerShell)
git clone https://github.com/vapvarun/wp-testing-framework.git; cd wp-testing-framework; .\local-wp-setup.ps1
```

## 🛠️ Manual Setup (If Scripts Don't Work)

```powershell
# 1. Install dependencies manually
npm install
composer install

# 2. Create directories
mkdir -p workspace\reports, workspace\logs, workspace\coverage
mkdir plugins

# 3. Create .env file manually
# Copy .env.example to .env and edit

# 4. Test using PHP
php test-plugin.php bbpress
```

## 📚 Visual Studio Code Integration

For Windows developers using VS Code:

1. Install "Local WP" VS Code extension
2. Open site in VS Code from Local WP
3. Use integrated terminal (PowerShell)
4. Run commands directly in VS Code

## 🔗 Useful Links for Windows Users

- **Local WP for Windows:** https://localwp.com/
- **Git for Windows:** https://git-scm.com/download/win
- **Windows Terminal:** https://aka.ms/terminal
- **PowerShell Docs:** https://docs.microsoft.com/powershell/
- **VS Code:** https://code.visualstudio.com/

## 💬 Windows Support

- **GitHub Issues:** [Report Windows-specific issues](https://github.com/vapvarun/wp-testing-framework/issues)
- **Tag:** Use `[Windows]` in issue title

---

**Note:** Windows users get the same powerful testing capabilities as Mac/Linux users. Local WP makes it seamless!