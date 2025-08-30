# WP Testing Framework

**Universal WordPress Plugin Testing Framework - Optimized for Local WP**

🚀 Test ANY WordPress plugin with a single command. Zero configuration needed for Local WP users!

## ✨ Quick Start (30 seconds!)

### For Local WP Users (Recommended)

```bash
# 1. Navigate to your Local WP site
cd ~/Local\ Sites/your-site/app/public

# 2. Clone and setup (one line!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# 3. Test any plugin (auto-creates everything!)
./test-plugin.sh bbpress
```

That's it! No configuration, no manual folder creation, everything automatic! 🎉

### For Other Environments

```bash
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework
./fresh-install.sh
```

## 🎯 Testing Any Plugin

```bash
# Method 1: Direct command (recommended)
./test-plugin.sh plugin-name

# Method 2: NPM
npm run test:plugin plugin-name

# Method 3: Quick test
npm run quick:test plugin-name
```

**Examples:**
```bash
./test-plugin.sh woocommerce
./test-plugin.sh elementor
./test-plugin.sh contact-form-7
./test-plugin.sh wordpress-seo
./test-plugin.sh buddypress
```

## 🔥 Key Features

- **🚀 Zero Configuration** - Works instantly with Local WP
- **📁 Auto-Creates Folders** - No manual setup needed
- **🔍 Auto-Detects Environment** - Finds your site settings automatically
- **📊 Comprehensive Testing** - Unit, integration, security, performance
- **📈 Beautiful Reports** - HTML reports with all results
- **🎨 Works with ANY Plugin** - Universal compatibility

## 📋 What Gets Tested

When you run `./test-plugin.sh plugin-name`, the framework:

1. **Creates folder structure** (automatic)
2. **Scans plugin code**
3. **Runs security tests**
4. **Checks performance**
5. **Tests functionality**
6. **Generates HTML report**

## 📊 Test Reports

Find your results in:
- **Reports:** `workspace/reports/{plugin}/`
- **Logs:** `workspace/logs/{plugin}/`
- **Coverage:** `workspace/coverage/{plugin}/`

## 🛠️ Requirements

### Local WP (Recommended)
- That's it! Local WP includes everything needed

### Other Environments
- PHP 8.0+
- Node.js 16+
- Composer
- WordPress 5.9+
- MySQL/MariaDB

## 📚 Popular Plugin Tests

### E-Commerce
```bash
./test-plugin.sh woocommerce
./test-plugin.sh easy-digital-downloads
./test-plugin.sh woocommerce-subscriptions
./test-plugin.sh woocommerce-memberships
```

### Page Builders
```bash
./test-plugin.sh elementor
./test-plugin.sh elementor-pro
./test-plugin.sh beaver-builder
./test-plugin.sh divi-builder
./test-plugin.sh oxygen
./test-plugin.sh bricks
```

### Forms
```bash
./test-plugin.sh contact-form-7
./test-plugin.sh wpforms-lite
./test-plugin.sh ninja-forms
./test-plugin.sh gravity-forms
./test-plugin.sh formidable
```

### SEO
```bash
./test-plugin.sh wordpress-seo      # Yoast
./test-plugin.sh all-in-one-seo-pack
./test-plugin.sh seo-framework
./test-plugin.sh rank-math
```

### Community/Social
```bash
./test-plugin.sh buddypress
./test-plugin.sh bbpress
./test-plugin.sh buddyboss-platform
./test-plugin.sh peepso
./test-plugin.sh ultimate-member
```

### Security
```bash
./test-plugin.sh wordfence
./test-plugin.sh sucuri-scanner
./test-plugin.sh ithemes-security
./test-plugin.sh all-in-one-wp-security
```

### Performance
```bash
./test-plugin.sh w3-total-cache
./test-plugin.sh wp-rocket
./test-plugin.sh wp-super-cache
./test-plugin.sh litespeed-cache
./test-plugin.sh autoptimize
```

## 🎨 Test Types

```bash
# Full test suite (default)
./test-plugin.sh plugin-name

# Quick test only
./test-plugin.sh plugin-name quick

# Security focused
./test-plugin.sh plugin-name security

# Performance focused
./test-plugin.sh plugin-name performance
```

## 📁 Project Structure

```
wp-testing-framework/
├── test-plugin.sh          # Main test runner (auto-creates folders!)
├── local-wp-setup.sh       # Local WP auto-setup
├── plugins/                # Auto-created plugin test folders
│   └── {plugin-name}/      # Created when you test
│       ├── tests/          # Test files
│       ├── analysis/       # Code analysis
│       └── data/           # Test data
├── workspace/              # Test outputs
│   ├── reports/           # HTML reports
│   ├── logs/              # Test logs
│   └── coverage/          # Code coverage
└── src/                   # Framework core
```

## 🔄 Updating

```bash
# Get latest updates
git pull origin main
npm install
composer update
```

## 🐛 Troubleshooting

### Local WP Issues

**Can't find wp command:**
```bash
# Local WP includes WP-CLI, just make sure you're in the site directory
cd ~/Local\ Sites/your-site/app/public
```

**Database connection failed:**
```bash
# Local WP uses root/root by default
# The framework auto-configures this
```

### General Issues

**Permission denied:**
```bash
chmod +x test-plugin.sh
chmod +x local-wp-setup.sh
```

**Plugin not found:**
```bash
# Make sure plugin is installed
wp plugin list
```

## 📖 Documentation

### Quick Guides (Main Folder)
- **[Installation Guide](INSTALL.md)** - Quick setup instructions
- **[bbPress Testing](BBPRESS-TESTING.md)** - Test bbPress plugin
- **[BuddyPress Testing](BUDDYPRESS-TESTING.md)** - Test BuddyPress plugin

### Detailed Documentation
- **[Setup Guides](docs/setup/)** - Installation, requirements, Local WP setup
- **[Plugin Guides](docs/plugin-guides/)** - Plugin-specific testing documentation
- **[Technical Docs](docs/technical/)** - Framework architecture and internals

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📝 License

MIT License - feel free to use in your projects!

## 🙏 Credits

Maintained by [@vapvarun](https://github.com/vapvarun)

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)
- **Discussions:** [GitHub Discussions](https://github.com/vapvarun/wp-testing-framework/discussions)

---

**Made with ❤️ for WordPress developers**

*Test any plugin, anytime, with zero hassle!*