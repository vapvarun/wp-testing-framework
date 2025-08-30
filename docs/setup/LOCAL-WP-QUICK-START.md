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

## 🎯 Testing Any Plugin - Complete AI-Driven Analysis!

```bash
# NEW: Complete integrated testing with AI analysis
./test-plugin.sh bbpress

# Or specify test type:
./test-plugin.sh woocommerce full       # Complete analysis (default)
./test-plugin.sh elementor quick        # Quick tests only
./test-plugin.sh wordfence security     # Security focus
./test-plugin.sh wp-rocket performance  # Performance focus
./test-plugin.sh yoast-seo ai          # AI analysis mode
```

### 🤖 What the Integrated Script Does (8 Phases):
1. **Setup** - Creates all directories automatically
2. **Detection** - Finds and activates the plugin
3. **AI Analysis** - Scans all functions, classes, hooks (2,431+ for bbPress!)
4. **Security** - Runs security scanner, checks for vulnerabilities
5. **Performance** - Profiles memory, load time, file sizes
6. **Testing** - Generates and runs tests, coverage reports
7. **AI Reports** - Creates Claude-ready analysis files
8. **Dashboard** - Generates beautiful HTML reports

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

### Testing Popular Plugins with AI Analysis

```bash
# E-commerce (Analyzes payment flows, cart logic, checkout security)
./test-plugin.sh woocommerce
./test-plugin.sh easy-digital-downloads

# Page Builders (Scans widgets, elements, rendering performance)
./test-plugin.sh elementor
./test-plugin.sh beaver-builder
./test-plugin.sh divi-builder

# SEO (Reviews meta handling, schema, performance impact)
./test-plugin.sh wordpress-seo      # Yoast
./test-plugin.sh all-in-one-seo-pack

# Forms (Checks validation, sanitization, AJAX handlers)
./test-plugin.sh contact-form-7
./test-plugin.sh wpforms-lite
./test-plugin.sh ninja-forms

# Community/Forum (2,431 functions, 2,059 hooks for bbPress!)
./test-plugin.sh buddypress
./test-plugin.sh bbpress

# Security (Deep vulnerability scanning)
./test-plugin.sh wordfence security
./test-plugin.sh sucuri-scanner security

# Performance (Memory profiling, cache analysis)
./test-plugin.sh w3-total-cache performance
./test-plugin.sh wp-rocket performance
```

## 🏃 Quick Commands

```bash
# Complete AI-driven analysis (all 8 phases)
./test-plugin.sh {plugin}

# Specific test types
./test-plugin.sh {plugin} full         # Everything (default)
./test-plugin.sh {plugin} quick        # Essential checks only
./test-plugin.sh {plugin} security     # Security scanning focus
./test-plugin.sh {plugin} performance  # Performance profiling
./test-plugin.sh {plugin} ai          # AI analysis mode

# View results
open workspace/reports/{plugin}/report-*.html

# Feed to Claude for test generation
cat workspace/ai-reports/{plugin}/ai-analysis-report.md
```

## 📊 Output Locations & What's Generated

After testing, find comprehensive results:

### AI Analysis Files (`workspace/ai-reports/{plugin}/`)
- `ai-analysis-report.md` - Complete report for Claude
- `functions-list.txt` - All PHP functions (e.g., 2,431 for bbPress)
- `classes-list.txt` - All PHP classes
- `hooks-list.txt` - WordPress hooks
- `database-operations.txt` - SQL queries
- `ajax-handlers.txt` - AJAX endpoints
- `security-analysis.txt` - Security findings
- `summary.json` - Machine-readable metrics

### Test Reports (`workspace/reports/{plugin}/`)
- `report-*.html` - Beautiful visual dashboard
- `security-*.txt` - Security scanner results
- `performance-*.txt` - Performance profiler data
- `coverage-*.txt` - Test coverage analysis

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

## 📝 Example Complete Workflow

```bash
# 1. Clone fresh site in Local WP
# 2. Install plugin you want to test (e.g., bbPress)
# 3. Navigate to public directory
cd ~/Local\ Sites/mysite/app/public

# 4. Install framework
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# 5. Run automatic setup for Local WP
./local-wp-setup.sh

# 6. Run complete AI-driven analysis (all tools integrated!)
./test-plugin.sh bbpress

# 7. Watch the magic happen:
#    ✅ 2,431 functions analyzed
#    ✅ 63 classes documented
#    ✅ 2,059 hooks identified
#    ✅ Security vulnerabilities checked
#    ✅ Performance profiled
#    ✅ Test coverage calculated
#    ✅ AI reports generated

# 8. View beautiful HTML dashboard
open workspace/reports/bbpress/report-*.html

# 9. Feed to Claude for test generation
cat workspace/ai-reports/bbpress/ai-analysis-report.md
# Copy and paste to Claude: "Generate PHPUnit tests for these functions"
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