# WP Testing Framework - Windows Edition
Version 13.0 - Now with WordPress Plugin Check Integration!

## 🚀 Quick Start for Windows Users

### Prerequisites
- Windows 10/11 with PowerShell 5.0+
- PHP 7.4+ installed and in PATH
- WordPress installation (Local WP, XAMPP, WAMP, etc.)
- WP-CLI installed ([Download here](https://wp-cli.org/))

### Optional but Recommended
- Node.js 14+ for advanced analysis
- Composer for dependency management
- Git for version control

## 📦 Installation

### Method 1: Using Batch Files (Easiest)

1. **Initial Setup:**
   ```batch
   setup.bat
   ```

2. **Install Plugin Check:**
   ```batch
   setup-plugin-check.bat
   ```

3. **Test a Plugin:**
   ```batch
   test-plugin.bat woocommerce
   ```

### Method 2: Using PowerShell

1. **Open PowerShell as Administrator**

2. **Set Execution Policy (if needed):**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run Setup:**
   ```powershell
   .\setup.ps1
   ```

4. **Install Plugin Check:**
   ```powershell
   .\tools\setup-plugin-check.ps1
   ```

5. **Test a Plugin:**
   ```powershell
   .\test-plugin.ps1 -PluginName "woocommerce"
   ```

## 🎯 Framework Phases (v13.0)

The framework now includes 13 comprehensive phases:

1. **Setup & Directory Structure** - Environment preparation
2. **Plugin Detection** - Extract plugin features and structure
3. **Plugin Check Analysis** 🆕 - WordPress standards compliance
4. **AI Analysis** - Uses Plugin Check data for smarter insights
5. **Security Scan** - Vulnerability detection
6. **Performance Analysis** - Speed and optimization checks
7. **Test Generation** - Create PHPUnit tests
8. **Visual Testing** - Screenshot capture and comparison
9. **Integration Tests** - WordPress integration validation
10. **Documentation** - Generate comprehensive docs
11. **Consolidation** - Merge all reports
12. **Live Testing** - Test with real data
13. **Safekeeping** - Archive results

## 🔧 Testing Modes

### Full Analysis (Default)
```batch
test-plugin.bat buddypress
```

### Quick Mode (Skip heavy phases)
```batch
test-plugin.bat elementor quick
```

### Security Focus
```batch
test-plugin.bat wordfence security
```

### Performance Focus
```batch
test-plugin.bat w3-total-cache performance
```

## 📊 What's New in v13.0

### WordPress Plugin Check Integration
- **Phase 3** now runs WordPress Plugin Check analysis
- Detects WordPress.org submission blockers
- Identifies security and performance issues per WP standards
- Results feed into AI analysis for smarter recommendations

### Enhanced AI Analysis
- AI now uses Plugin Check data for context
- Prioritizes WordPress standards violations
- Provides line-by-line fix recommendations

### Windows Optimizations
- Full PowerShell module support
- Batch file launchers for ease of use
- Windows-compatible path handling
- Proper error handling for Windows environments

## 🛠️ Troubleshooting

### PowerShell Execution Policy Error
```powershell
# Run this command:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### WP-CLI Not Found
1. Download WP-CLI from https://wp-cli.org/
2. Add to Windows PATH
3. Restart terminal

### PHP Not Found
1. Install PHP from https://windows.php.net/download/
2. Add PHP to Windows PATH:
   - Right-click "This PC" → Properties
   - Advanced system settings → Environment Variables
   - Add PHP folder to PATH
3. Restart terminal

### Plugin Check Not Working
```batch
# Reinstall Plugin Check:
wp plugin uninstall plugin-check --deactivate
setup-plugin-check.bat
```

## 📁 Output Location

Results are saved to:
```
wp-content/uploads/wbcom-scan/<plugin-name>/<year-month>/
```

Key files:
- `plugin-check/` - WordPress standards compliance reports
- `reports/` - Consolidated analysis reports
- `analysis-requests/` - Claude/ChatGPT prompts
- `generated-tests/` - PHPUnit test files

## 🔍 Using Plugin Check Results

### View Plugin Check Report
```batch
# Navigate to results folder
cd wp-content\uploads\wbcom-scan\<plugin-name>\<date>\plugin-check

# View the insights report
type plugin-check-insights.md
```

### Understanding Results
- **Errors (Red)**: Must fix before WordPress.org submission
- **Warnings (Yellow)**: Should fix for better quality
- **Info (Blue)**: Best practice suggestions

## 💡 Tips for Windows Users

1. **Use Local WP**: Best WordPress development environment for Windows
2. **Install Git Bash**: Provides Unix-like commands on Windows
3. **Use VSCode**: Excellent editor with terminal integration
4. **Enable WSL2**: Run Linux tools natively on Windows

## 🐛 Common Issues

### "Access Denied" Errors
- Run as Administrator
- Check file permissions
- Disable antivirus temporarily

### Path Too Long Errors
- Enable long paths in Windows:
  ```batch
  reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1
  ```

### Composer/NPM Issues
- Use Windows-specific installers
- Run in Administrator mode
- Check proxy settings if behind firewall

## 📚 Additional Resources

- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)
- [WordPress Plugin Check](https://wordpress.org/plugins/plugin-check/)
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)

## 🤝 Support

For issues specific to Windows:
1. Check this README first
2. Review error messages carefully
3. Try running as Administrator
4. Report issues with Windows tag

## 📝 Version History

- **v13.0** - Added Plugin Check integration, improved Windows support
- **v12.0** - Previous stable version
- **v11.0** - Added AI analysis features

---

**Note**: This framework is optimized for WordPress plugin development on Windows. For best results, ensure all prerequisites are properly installed and configured.