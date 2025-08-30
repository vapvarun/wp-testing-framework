# Installation Guide

## 🚀 Quick Install

### For Local WP Users

#### Mac/Linux
```bash
cd ~/Local\ Sites/your-site/app/public
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./local-wp-setup.sh
```

#### Windows
```powershell
cd "C:\Users\%USERNAME%\Local Sites\your-site\app\public"
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
.\local-wp-setup.ps1
```

### For General WordPress Installations

#### Mac/Linux
```bash
cd /path/to/wordpress
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./setup.sh
```

#### Windows
```powershell
cd C:\path\to\wordpress
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
.\setup.ps1
```

## 📋 Requirements

### Local WP (Recommended)
- Just install Local WP from https://localwp.com/
- Everything else is included!

### Other Environments
- PHP 7.4+ (8.0+ recommended)
- WordPress 5.0+
- Composer (for PHP analysis tools)
- Git

## 🎯 Testing Your First Plugin

After installation, test any plugin:

```bash
# Mac/Linux
./test-plugin.sh plugin-name

# Windows
.\test-plugin.ps1 plugin-name
```

### Test Types
- `full` - Complete 7-phase analysis (default)
- `quick` - Essential tests only
- `security` - Security-focused scan
- `performance` - Performance analysis

### Examples
```bash
./test-plugin.sh bbpress
./test-plugin.sh woocommerce quick
./test-plugin.sh akismet security
```

## 📁 Output Structure

```
wp-content/uploads/
├── wbcom-scan/[plugin]/[yyyy-MM]/    # Temporary scan data
└── wbcom-plan/[plugin]/[yyyy-MM]/    # AI-processed plans

wp-testing-framework/
└── plugins/[plugin]/                  # Permanent documentation
    ├── USER-GUIDE.md
    ├── ISSUES-AND-FIXES.md
    ├── DEVELOPMENT-PLAN.md
    └── QUALITY-REPORT.md
```

## 🔧 Troubleshooting

### Permission Issues
```bash
chmod +x *.sh
```

### Composer Not Found
Install from https://getcomposer.org/

### Local WP Site Not Found
Default locations:
- Mac: `~/Local Sites/`
- Windows: `C:\Users\[username]\Local Sites\`
- Linux: `~/Local Sites/`

## 📚 Additional Resources

- **Repository:** https://github.com/vapvarun/wp-testing-framework/
- **Issues:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)
- **Main Documentation:** [README.md](README.md)

---

*For detailed information, see [README.md](README.md)*