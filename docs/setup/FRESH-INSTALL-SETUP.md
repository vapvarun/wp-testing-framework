# WP Testing Framework - Fresh Installation Guide

## Prerequisites

### System Requirements
- **WordPress** 5.9+ installed and running
- **PHP** 8.0+ with extensions: mbstring, xml, curl, zip
- **Node.js** 16+ and npm 8+
- **Composer** 2.0+
- **WP-CLI** installed globally
- **Git** for version control
- **MySQL/MariaDB** database access

### Check Prerequisites
```bash
# Check versions
php -v
node -v
npm -v
composer --version
wp --version
git --version
```

## Step 1: Clone Framework

```bash
# Navigate to WordPress root directory
cd /path/to/wordpress

# Clone the framework
git clone https://github.com/your-org/wp-testing-framework.git

# Or download and extract
wget https://github.com/your-org/wp-testing-framework/archive/main.zip
unzip main.zip
mv wp-testing-framework-main wp-testing-framework
```

## Step 2: Initial Setup

```bash
cd wp-testing-framework

# Install PHP dependencies
composer install

# Install Node dependencies
npm install

# Install Playwright browsers (for E2E testing)
npx playwright install

# Run setup script
chmod +x setup.sh
./setup.sh
```

## Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

Add these variables to `.env`:
```env
# WordPress Configuration
WP_ROOT_DIR=../
WP_TESTS_DIR=/tmp/wordpress-tests-lib
WP_CORE_DIR=../

# Database Configuration (use test database)
TEST_DB_NAME=wordpress_test
TEST_DB_USER=root
TEST_DB_PASSWORD=password
TEST_DB_HOST=localhost

# Site Configuration
WP_TEST_URL=http://localhost:8080
WP_TEST_DOMAIN=localhost
WP_TEST_EMAIL=admin@example.com

# Testing Configuration
SKIP_DB_CREATE=false
TEST_SUITE=all
```

## Step 4: Setup Test Database

```bash
# Create test database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS wordpress_test;"

# Grant privileges
mysql -u root -p -e "GRANT ALL PRIVILEGES ON wordpress_test.* TO 'wp_user'@'localhost';"

# Or use the setup script
./setup.sh --create-test-db
```

## Step 5: Install WordPress Test Suite

```bash
# Download WordPress test library
./vendor/bin/wp scaffold plugin-tests wp-testing-framework --ci

# Or manually install
bash bin/install-wp-tests.sh wordpress_test root 'password' localhost latest
```

## Step 6: Verify Installation

```bash
# Run basic tests
npm run test:unit

# Check framework status
./setup.sh --verify

# Test WP-CLI integration
wp eval 'echo "WP-CLI is working!";'

# Run PHPUnit
./vendor/bin/phpunit --version

# Check Playwright
npx playwright --version
```

## Step 7: Setup Plugin Testing

### For ANY WordPress Plugin:

```bash
# Create plugin directory structure
PLUGIN_NAME="your-plugin-name"
mkdir -p plugins/$PLUGIN_NAME/{data,tests,scanners,models,analysis}

# Scan the plugin
wp plugin scan $PLUGIN_NAME --output=plugins/$PLUGIN_NAME/analysis/

# Generate tests
npm run generate:tests -- --plugin=$PLUGIN_NAME

# Add to package.json
npm run universal:$PLUGIN_NAME
```

## Complete Installation Script

Create `fresh-install.sh`:

```bash
#!/bin/bash

# WP Testing Framework - Fresh Installation Script
set -e

echo "🚀 WP Testing Framework - Fresh Installation"
echo "============================================"

# Check prerequisites
check_requirements() {
    echo "📋 Checking requirements..."
    
    command -v php >/dev/null 2>&1 || { echo "❌ PHP is required"; exit 1; }
    command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required"; exit 1; }
    command -v composer >/dev/null 2>&1 || { echo "❌ Composer is required"; exit 1; }
    command -v wp >/dev/null 2>&1 || { echo "❌ WP-CLI is required"; exit 1; }
    
    echo "✅ All requirements met!"
}

# Clone framework
install_framework() {
    echo "📦 Installing framework..."
    
    if [ ! -d "wp-testing-framework" ]; then
        git clone https://github.com/your-org/wp-testing-framework.git
    fi
    
    cd wp-testing-framework
}

# Install dependencies
install_dependencies() {
    echo "📚 Installing dependencies..."
    
    composer install --no-interaction
    npm ci
    npx playwright install
}

# Setup environment
setup_environment() {
    echo "⚙️ Setting up environment..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo "Please edit .env file with your configuration"
    fi
}

# Create test database
setup_database() {
    echo "🗄️ Setting up test database..."
    
    read -p "MySQL root password: " -s MYSQL_PASS
    echo
    
    mysql -u root -p$MYSQL_PASS -e "CREATE DATABASE IF NOT EXISTS wordpress_test;"
    mysql -u root -p$MYSQL_PASS -e "GRANT ALL ON wordpress_test.* TO 'wp_test'@'localhost' IDENTIFIED BY 'wp_test';"
}

# Run setup
run_setup() {
    echo "🔧 Running setup..."
    
    chmod +x setup.sh
    ./setup.sh
}

# Verify installation
verify_installation() {
    echo "✨ Verifying installation..."
    
    ./vendor/bin/phpunit --version
    wp eval 'echo "WP-CLI: OK\n";'
    node -e 'console.log("Node.js: OK")'
    
    echo "✅ Installation complete!"
}

# Main execution
main() {
    check_requirements
    install_framework
    install_dependencies
    setup_environment
    setup_database
    run_setup
    verify_installation
    
    echo ""
    echo "🎉 WP Testing Framework is ready!"
    echo "📖 Next steps:"
    echo "   1. Edit .env file with your configuration"
    echo "   2. Run: npm run universal:your-plugin-name"
    echo "   3. View results in workspace/reports/"
}

main "$@"
```

## Quick Commands Reference

```bash
# Test any plugin
npm run universal:plugin-name

# Run specific test types
npm run test:unit plugin-name
npm run test:integration plugin-name
npm run test:security plugin-name

# Generate reports
npm run report:plugin-name

# Clean workspace
npm run clean:all

# Update framework
git pull origin main
npm install
composer update
```

## Troubleshooting

### Common Issues:

1. **Permission errors:**
   ```bash
   chmod -R 755 wp-testing-framework
   chmod +x setup.sh
   ```

2. **Database connection failed:**
   ```bash
   # Check MySQL is running
   sudo service mysql status
   
   # Test connection
   mysql -u root -p -e "SELECT 1;"
   ```

3. **WP-CLI not found:**
   ```bash
   # Install WP-CLI
   curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
   chmod +x wp-cli.phar
   sudo mv wp-cli.phar /usr/local/bin/wp
   ```

4. **Composer memory limit:**
   ```bash
   COMPOSER_MEMORY_LIMIT=-1 composer install
   ```

## Directory Structure After Installation

```
wordpress/
├── wp-admin/
├── wp-content/
├── wp-includes/
├── wp-testing-framework/
│   ├── src/              # Framework core
│   ├── plugins/          # Plugin tests
│   ├── workspace/        # Reports & logs
│   ├── vendor/           # PHP packages
│   ├── node_modules/     # Node packages
│   ├── .env              # Configuration
│   └── setup.sh          # Setup script
└── wp-config.php
```

## Support & Documentation

- **Documentation:** `/docs/` directory
- **Examples:** `/examples/` directory
- **Issues:** GitHub Issues
- **Logs:** `/workspace/logs/`