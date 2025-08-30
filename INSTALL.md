# Installation Guide

## 🚀 Quick Install (Local WP - Recommended)

90% of users should use this method with Local WP:

### Mac/Linux
```bash
# 1. Open Local WP and navigate to your site
cd ~/Local\ Sites/your-site/app/public

# 2. Clone and setup (one command!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# 3. Test any plugin immediately
./test-plugin.sh plugin-name
```

### Windows
```powershell
# 1. Open Local WP "Site Shell" (PowerShell)

# 2. Clone and setup
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
.\local-wp-setup.ps1

# 3. Test any plugin immediately
.\test-plugin.ps1 plugin-name
```

**Done!** Zero configuration needed with Local WP on any platform! 🎉

📘 **Windows Guide:** [WINDOWS-SETUP.md](WINDOWS-SETUP.md)

## ✅ What Local WP Setup Does

When you run `./local-wp-setup.sh`, it automatically:

1. **Detects your site name** from Local WP path
2. **Configures database** with root/root credentials
3. **Sets up site URL** using .local domain
4. **Installs dependencies** (npm and composer)
5. **Creates test database** for your site
6. **Generates .env file** with all settings

## 📦 First Plugin Test

After installation, test any plugin:

```bash
# Examples (folders created automatically!)
./test-plugin.sh woocommerce
./test-plugin.sh elementor
./test-plugin.sh bbpress
./test-plugin.sh buddypress
```

## 🔧 Alternative Installation Methods

### Auto-Detect Setup (Works for any environment)
```bash
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./setup.sh  # Automatically detects Local WP or standard environment
```

### Manual Local WP Setup
```bash
cd ~/Local\ Sites/your-site/app/public
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./local-wp-setup.sh
```

## 📋 Requirements

### Local WP (Recommended)
- **Just install Local WP** - Everything else is included!
- Download free: https://localwp.com/

### Other Environments
- PHP 8.0+
- Node.js 16+
- Composer
- WP-CLI
- MySQL/MariaDB

## 🎯 Post-Installation

### Test Your First Plugin
```bash
./test-plugin.sh plugin-name
```

### View Results
```bash
open workspace/reports/plugin-name/report-*.html
```

### Update Framework
```bash
git pull origin main
npm install
composer update
```

## 🐛 Troubleshooting

### Local WP Common Issues

**Can't find Local Sites folder?**
```bash
# Default locations:
# Mac: ~/Local Sites/
# Windows: C:\Users\{username}\Local Sites\
# Linux: ~/Local Sites/
```

**Permission denied?**
```bash
chmod +x local-wp-setup.sh test-plugin.sh setup.sh
```

**Which PHP/Node version?**
```bash
# Local WP includes multiple PHP versions
# Select PHP 8.0+ in Local WP site settings
# Node.js comes pre-installed
```

## 📁 Directory Structure After Install

```
your-site/app/public/
├── wp-content/
├── wp-admin/
├── wp-includes/
└── wp-testing-framework/     # Our framework
    ├── local-wp-setup.sh      # Local WP setup
    ├── test-plugin.sh         # Plugin tester
    ├── plugins/               # Auto-created test folders
    └── workspace/             # Reports and logs
```

## ⚡ Quick Commands Reference

```bash
# Setup (Local WP)
./local-wp-setup.sh

# Test plugins
./test-plugin.sh woocommerce
./test-plugin.sh elementor quick
./test-plugin.sh bbpress security
./test-plugin.sh buddypress performance

# View reports
open workspace/reports/
```

## 💡 Why Local WP?

- ✅ **Zero configuration** - Everything pre-configured
- ✅ **Includes WP-CLI** - No manual installation
- ✅ **Database ready** - root/root access works
- ✅ **Multiple PHP versions** - Test compatibility
- ✅ **SSL support** - Test HTTPS scenarios
- ✅ **Mail catching** - Test email functions
- ✅ **One-click cloning** - Create test sites instantly

## 📚 Next Steps

1. **Read plugin guides:**
   - [bbPress Testing](BBPRESS-TESTING.md)
   - [BuddyPress Testing](BUDDYPRESS-TESTING.md)

2. **Explore documentation:**
   - [Plugin Guides](docs/plugin-guides/)
   - [Technical Docs](docs/technical/)

## 💬 Support

- **Repository:** https://github.com/vapvarun/wp-testing-framework/
- **Issues:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)

---

**Pro Tip:** Use Local WP - it makes everything 10x easier!