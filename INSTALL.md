# Installation Guide

## 🚀 Quick Install for Local WP (Recommended)

```bash
# Navigate to your Local WP site
cd ~/Local\ Sites/your-site/app/public

# Clone and setup (one line!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# Test any plugin
./test-plugin.sh plugin-name
```

**That's it!** The framework auto-detects Local WP and configures everything automatically.

## 📋 Standard Installation

For non-Local WP environments:

```bash
# Clone the repository
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# Run installation script
./fresh-install.sh

# Test a plugin
./test-plugin.sh plugin-name
```

## ⚡ Testing Plugins

```bash
# Test any plugin (auto-creates folders)
./test-plugin.sh woocommerce
./test-plugin.sh elementor
./test-plugin.sh bbpress
./test-plugin.sh buddypress
```

## 📖 Documentation

- **[Setup Guides](docs/setup/)** - Detailed installation instructions
- **[Plugin Guides](docs/plugin-guides/)** - Plugin-specific testing guides
- **[Technical Docs](docs/technical/)** - Framework architecture

## 🛠️ Requirements

- **Local WP:** Everything included
- **Other:** PHP 8.0+, Node.js 16+, Composer, WP-CLI

## 💬 Support

- **Repository:** https://github.com/vapvarun/wp-testing-framework/
- **Issues:** [GitHub Issues](https://github.com/vapvarun/wp-testing-framework/issues)