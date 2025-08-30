# WP Testing Framework - System Requirements

## Minimum Requirements

### PHP
- **Version:** 8.0 or higher
- **Required Extensions:**
  - `mbstring` - Multi-byte string support
  - `xml` - XML parsing
  - `curl` - HTTP requests
  - `zip` - Archive handling
  - `dom` - DOM manipulation
  - `json` - JSON support
  - `tokenizer` - PHP tokenization
  - `pdo_mysql` - Database connection

### Node.js
- **Version:** 16.0 or higher
- **NPM:** 8.0 or higher
- **Purpose:** E2E testing, build tools, automation

### Database
- **MySQL:** 5.7+ or MariaDB 10.3+
- **Separate test database recommended**
- **User with CREATE/DROP privileges**

### WordPress
- **Version:** 5.9 or higher
- **Multisite:** Optional, supported
- **REST API:** Must be enabled

### Server
- **Apache/Nginx** with mod_rewrite
- **Memory:** 256MB minimum (512MB recommended)
- **Disk Space:** 500MB for framework + tests
- **Write permissions** for workspace directory

## Required Tools

### Composer (Required)
```bash
# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

### WP-CLI (Required)
```bash
# Install WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --version
```

### Git (Recommended)
```bash
# Check Git
git --version
# Install: apt-get install git (Ubuntu) or brew install git (Mac)
```

### Playwright (Auto-installed)
```bash
# Installed automatically via npm
# Requires system dependencies for browsers
npx playwright install-deps
```

## Recommended Requirements

### PHP
- **Version:** 8.2 or higher
- **Memory Limit:** 512MB
- **Max Execution Time:** 300 seconds
- **OPcache:** Enabled

### Development Tools
- **PHPUnit:** 9.5+ (installed via Composer)
- **PHP CodeSniffer:** For code standards
- **PHPStan:** For static analysis
- **Psalm:** For type checking

### Optional Tools
- **Docker:** For containerized testing
- **Redis/Memcached:** For cache testing
- **Xdebug:** For debugging and coverage

## Environment Check Script

Create `check-requirements.php`:

```php
<?php
/**
 * WP Testing Framework - Requirements Checker
 */

$requirements = [
    'php_version' => '8.0',
    'extensions' => [
        'mbstring', 'xml', 'curl', 'zip', 
        'dom', 'json', 'tokenizer', 'pdo_mysql'
    ],
    'commands' => [
        'composer' => 'composer --version',
        'wp-cli' => 'wp --version',
        'node' => 'node --version',
        'npm' => 'npm --version'
    ]
];

$passed = true;

// Check PHP version
if (version_compare(PHP_VERSION, $requirements['php_version'], '<')) {
    echo "❌ PHP {$requirements['php_version']}+ required. Current: " . PHP_VERSION . "\n";
    $passed = false;
} else {
    echo "✅ PHP version: " . PHP_VERSION . "\n";
}

// Check extensions
foreach ($requirements['extensions'] as $ext) {
    if (!extension_loaded($ext)) {
        echo "❌ Missing PHP extension: {$ext}\n";
        $passed = false;
    } else {
        echo "✅ PHP extension: {$ext}\n";
    }
}

// Check commands
foreach ($requirements['commands'] as $name => $command) {
    exec($command . ' 2>&1', $output, $return);
    if ($return !== 0) {
        echo "❌ {$name} not found\n";
        $passed = false;
    } else {
        echo "✅ {$name}: " . $output[0] . "\n";
    }
    unset($output);
}

// Check WordPress
if (defined('ABSPATH')) {
    echo "✅ WordPress detected\n";
} else {
    echo "⚠️  WordPress not loaded (run from WP root)\n";
}

echo "\n" . ($passed ? "✅ All requirements met!" : "❌ Some requirements missing") . "\n";
```

## OS-Specific Installation

### Ubuntu/Debian
```bash
# Update system
sudo apt update && sudo apt upgrade

# Install PHP and extensions
sudo apt install php8.2 php8.2-{mbstring,xml,curl,zip,mysql,dom,tokenizer}

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs

# Install MySQL
sudo apt install mysql-server
```

### macOS
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install PHP
brew install php@8.2

# Install Node.js
brew install node

# Install MySQL
brew install mysql
```

### Windows (WSL2)
```bash
# Enable WSL2
wsl --install

# Follow Ubuntu instructions above
```

## Docker Setup (Optional)

```yaml
# docker-compose.yml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./wp-testing-framework:/var/www/html/wp-testing-framework
      
  db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: root
      
  test-db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: wordpress_test
      MYSQL_USER: wp_test
      MYSQL_PASSWORD: wp_test
      MYSQL_ROOT_PASSWORD: root
```

## Performance Recommendations

### PHP Configuration (`php.ini`)
```ini
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M
max_file_uploads = 20
```

### MySQL Configuration (`my.cnf`)
```ini
[mysqld]
innodb_buffer_pool_size = 256M
max_connections = 100
query_cache_size = 16M
query_cache_type = 1
```

## Verification Commands

```bash
# Check all requirements
php check-requirements.php

# System info
php -i | grep -E "PHP Version|System"
mysql --version
node --version
npm --version

# WordPress info
wp core version
wp plugin list
wp theme list

# Framework verification
cd wp-testing-framework
./setup.sh --verify
```