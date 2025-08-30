# WP Testing Framework

**Universal WordPress Plugin Testing - Optimized for Local WP**

🚀 Test ANY WordPress plugin in 30 seconds with zero configuration!

## ✨ Quick Start (Local WP)

### Mac/Linux Users
```bash
# 1. Open Local WP and navigate to your site
cd ~/Local\ Sites/your-site/app/public

# 2. Clone and setup (one command!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# 3. Test any plugin
./test-plugin.sh plugin-name
```

### Windows Users
```powershell
# 1. Open Local WP "Site Shell" (PowerShell)

# 2. Clone and setup
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
.\local-wp-setup.ps1

# 3. Test any plugin
.\test-plugin.ps1 plugin-name
```

**That's it!** Works on all platforms. Everything is automatic! 🎉

📘 **Windows Users:** See [WINDOWS-SETUP.md](WINDOWS-SETUP.md) for detailed guide

## 🎯 How It Works

The framework automatically:
1. **Detects Local WP** environment
2. **Configures database** (uses root/root)
3. **Sets up site URL** (.local domain)
4. **Creates folders** when testing
5. **Generates reports** instantly

## 📦 Testing Any Plugin

### Mac/Linux
```bash
# Just one command - folders created automatically!
./test-plugin.sh woocommerce
./test-plugin.sh elementor
./test-plugin.sh bbpress
```

### Windows (PowerShell)
```powershell
# Same simple commands for Windows!
.\test-plugin.ps1 woocommerce
.\test-plugin.ps1 elementor
.\test-plugin.ps1 bbpress
```

### Test Types (All Platforms)
```bash
# Mac/Linux
./test-plugin.sh plugin-name         # Full test suite
./test-plugin.sh plugin-name quick   # Quick test only

# Windows
.\test-plugin.ps1 plugin-name        # Full test suite
.\test-plugin.ps1 plugin-name quick  # Quick test only
```

## 📊 View Results

After testing, find your results:
```bash
# Open HTML report
open workspace/reports/plugin-name/report-*.html

# Check logs
cat workspace/logs/plugin-name/*.log
```

## 🔥 Why Local WP?

Local WP is the preferred environment because:
- ✅ **Zero configuration** - Everything pre-installed
- ✅ **WP-CLI included** - No manual installation
- ✅ **Database ready** - root/root access configured
- ✅ **Site URL works** - .local domain auto-configured
- ✅ **One-click sites** - Create test sites instantly

## 📚 Popular Plugin Examples

### E-Commerce
```bash
./test-plugin.sh woocommerce
./test-plugin.sh easy-digital-downloads
./test-plugin.sh woocommerce-subscriptions
```

### Page Builders
```bash
./test-plugin.sh elementor
./test-plugin.sh beaver-builder
./test-plugin.sh divi-builder
./test-plugin.sh bricks
```

### Forms
```bash
./test-plugin.sh contact-form-7
./test-plugin.sh wpforms-lite
./test-plugin.sh ninja-forms
./test-plugin.sh gravity-forms
```

### SEO
```bash
./test-plugin.sh wordpress-seo      # Yoast
./test-plugin.sh all-in-one-seo-pack
./test-plugin.sh rank-math
```

### Community
```bash
./test-plugin.sh buddypress
./test-plugin.sh bbpress
./test-plugin.sh buddyboss-platform
./test-plugin.sh peepso
```

### Security
```bash
./test-plugin.sh wordfence
./test-plugin.sh sucuri-scanner
./test-plugin.sh ithemes-security
```

### Performance
```bash
./test-plugin.sh w3-total-cache
./test-plugin.sh wp-rocket
./test-plugin.sh litespeed-cache
./test-plugin.sh autoptimize
```

## 📁 What Gets Created Automatically

When you run `./test-plugin.sh plugin-name`:

```
plugins/plugin-name/
├── test-config.json      # Auto-generated config
├── tests/                # Test suites
│   ├── unit/
│   ├── integration/
│   ├── security/
│   └── performance/
├── analysis/             # Code analysis
└── data/                 # Test fixtures

workspace/
├── reports/plugin-name/  # HTML reports
├── logs/plugin-name/     # Test logs
└── coverage/plugin-name/ # Code coverage
```

## 🛠️ Requirements

### With Local WP (Recommended)
- Just install Local WP - everything else included!
- Download: https://localwp.com/

### Without Local WP
- PHP 8.0+, Node.js 16+, Composer, WP-CLI
- See [docs/setup/REQUIREMENTS.md](docs/setup/REQUIREMENTS.md)

## 🔄 Updating Framework

```bash
# Get latest updates
git pull origin main
npm install
composer update
```

## 🚀 Installation Options

### Option 1: Local WP (Recommended - 90% of users)
```bash
cd ~/Local\ Sites/your-site/app/public
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./local-wp-setup.sh
```

### Option 2: Other Environments
```bash
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./setup.sh  # Auto-detects environment
```

## 📖 Documentation

### Quick Guides
- **[Installation](INSTALL.md)** - Setup instructions
- **[bbPress Testing](BBPRESS-TESTING.md)** - Test bbPress
- **[BuddyPress Testing](BUDDYPRESS-TESTING.md)** - Test BuddyPress

### Detailed Docs
- **[Setup Guides](docs/setup/)** - Detailed installation
- **[Plugin Guides](docs/plugin-guides/)** - Plugin-specific docs
- **[Technical Docs](docs/technical/)** - Framework internals

## 🐛 Troubleshooting

### Local WP Issues

**Can't find site directory?**
```bash
# Local WP sites are usually in:
# Mac: ~/Local Sites/
# Windows: C:\Users\{username}\Local Sites\
# Linux: ~/Local Sites/
```

**Permission denied?**
```bash
chmod +x local-wp-setup.sh test-plugin.sh
```

**Database issues?**
```bash
# Local WP uses:
# Username: root
# Password: root
# Host: localhost
```

## 💡 Pro Tips

1. **Use Local WP** - Everything just works!
2. **One command testing** - `./test-plugin.sh plugin-name`
3. **Auto folder creation** - No manual setup needed
4. **Check HTML reports** - Beautiful visual results
5. **Keep updated** - `git pull origin main`

## 🤝 Contributing

We welcome contributions! Fork and submit PRs.

## 📝 License

MIT License - Use freely in your projects!

## 🙏 Credits

Maintained by [@vapvarun](https://github.com/vapvarun)

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)
- **Discussions:** [GitHub Discussions](https://github.com/vapvarun/wp-testing-framework/discussions)

---

**Made with ❤️ for WordPress developers using Local WP**

*Test any plugin in 30 seconds - no configuration needed!*