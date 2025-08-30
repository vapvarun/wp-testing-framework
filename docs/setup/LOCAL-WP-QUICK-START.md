# WP Testing Framework - Local WP Quick Start

**GitHub:** https://github.com/vapvarun/wp-testing-framework/

## 🚀 One-Line Installation for Local WP

```bash
# From your Local WP site's public directory:
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh
```

## 📦 What It Does Automatically

1. **Detects Local WP Environment**
   - Auto-finds your site name
   - Sets up correct database settings
   - Configures site URL (.local domain)

2. **Creates Test Environment**
   - Installs all dependencies
   - Creates test database
   - Sets up workspace directories

3. **Plugin Folder Auto-Creation**
   - No manual folder creation needed
   - Happens automatically when you test

## 🎯 Testing Any Plugin (Super Simple!)

```bash
# Just run this - folders are created automatically!
npm run test:plugin bbpress

# Or test multiple aspects
npm run test:plugin woocommerce --full

# Quick test
npm run quick:test elementor
```

## 🔧 How It Works

### Auto-Detection Features
- **Site Name:** Extracted from Local WP path
- **Database:** Uses Local WP's MySQL (root/root)
- **URL:** Automatically uses .local domain
- **WP-CLI:** Pre-installed in Local WP

### No Configuration Needed
The framework automatically:
- Creates `plugins/{plugin-name}/` structure
- Sets up test suites
- Generates reports
- Handles all dependencies

## 📋 Pre-Configured for Local WP

```env
# Auto-generated .env for Local WP
WP_ROOT_DIR=../
TEST_DB_NAME={sitename}_test
TEST_DB_USER=root
TEST_DB_PASSWORD=root
TEST_DB_HOST=localhost
WP_TEST_URL=http://{sitename}.local
```

## 🎭 Common Local WP Sites

### Testing Popular Plugins

```bash
# E-commerce
npm run test:plugin woocommerce
npm run test:plugin easy-digital-downloads

# Page Builders  
npm run test:plugin elementor
npm run test:plugin beaver-builder
npm run test:plugin divi-builder

# SEO
npm run test:plugin wordpress-seo  # Yoast
npm run test:plugin all-in-one-seo-pack

# Forms
npm run test:plugin contact-form-7
npm run test:plugin wpforms-lite
npm run test:plugin ninja-forms

# Community/Forum
npm run test:plugin buddypress
npm run test:plugin bbpress

# Security
npm run test:plugin wordfence
npm run test:plugin sucuri-scanner

# Performance
npm run test:plugin w3-total-cache
npm run test:plugin wp-rocket
```

## 🏃 Quick Commands

```bash
# Full test suite (everything)
npm run test:plugin {plugin} --full

# Quick test (essential checks only)
npm run quick:test {plugin}

# Security focus
npm run test:plugin {plugin} --security

# Performance focus
npm run test:plugin {plugin} --performance

# Generate report
npm run report {plugin}

# Clean workspace
npm run clean
```

## 📊 Output Locations

After testing, find results in:
- **Reports:** `workspace/reports/{plugin}/`
- **Coverage:** `workspace/coverage/{plugin}/`
- **Logs:** `workspace/logs/{plugin}/`
- **Screenshots:** `workspace/screenshots/{plugin}/`

## 🔄 Updating Framework

```bash
# Pull latest updates
git pull origin main
npm install
composer update
```

## 🐛 Troubleshooting Local WP

### Database Connection Issues
```bash
# Local WP uses socket connection
wp db cli  # Test connection
```

### Permission Issues
```bash
# Fix permissions for Local WP
chmod -R 755 wp-testing-framework
```

### Port Conflicts
Local WP typically uses:
- HTTP: 10000+ range
- MySQL: 10000+ range

## 💡 Pro Tips for Local WP

1. **Enable Xdebug:** Local WP has built-in Xdebug support
2. **Use MailHog:** Built-in email testing
3. **SSL Available:** Use https://{site}.local
4. **Adminer:** Database GUI at {site}.local/adminer

## 📝 Example Workflow

```bash
# 1. Clone fresh site in Local WP
# 2. Install plugin you want to test
# 3. Navigate to public directory
cd ~/Local\ Sites/mysite/app/public

# 4. Install framework
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 5. Run setup
./local-wp-setup.sh

# 6. Test the plugin (auto-creates folders!)
npm run test:plugin my-awesome-plugin

# 7. View results
open workspace/reports/my-awesome-plugin/index.html
```

## 🤝 Contributing

Repository: https://github.com/vapvarun/wp-testing-framework/

1. Fork the repository
2. Create feature branch
3. Submit pull request

## 📧 Support

- **Issues:** https://github.com/vapvarun/wp-testing-framework/issues
- **Documentation:** In `/docs` folder
- **Examples:** In `/examples` folder