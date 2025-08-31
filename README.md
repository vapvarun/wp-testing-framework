# WP Testing Framework

**🤖 AI-Driven WordPress Plugin Testing Framework**

Complete plugin analysis with integrated security scanning, performance profiling, and AI-ready reports for test generation!

## ✨ What's New: AI-Enhanced Testing & Complete Integration!

One command now runs **ALL testing tools** in 12 comprehensive phases:
1. **Setup** - Auto-creates all directories
2. **Detection** - Finds and activates plugins
3. **AI Analysis** - AST parsing + dynamic test data generation
4. **Security** - Vulnerability scanning (XSS, SQL injection, nonces)
5. **Performance** - Memory/load profiling with metrics
6. **Test Generation** - AI-enhanced, executable, and basic tests
7. **Visual Testing** - Automated screenshots and UI validation
8. **Integration Tests** - WordPress hooks, shortcodes, AJAX
9. **Reporting** - HTML, Markdown, and AI-ready reports
10. **Consolidation** - Organized final reports with INDEX
11. **Live Testing** - Test data creation and execution
12. **Safekeeping** - Framework preservation and templates

### 🚀 New Features:
- **AI-Enhanced Test Generation** - Intelligent test cases based on code analysis
- **Three-Tier Testing** - Smart, Executable, and Basic tests
- **Dynamic Test Data** - Pattern-based data generation
- **Real Code Coverage** - Executable tests with assertions (not stubs)
- **Automatic Fallbacks** - Works without AI API keys

## ✨ Quick Start (Local WP)

### Mac/Linux Users
```bash
# 1. Navigate to your Local WP site
cd ~/Local\ Sites/your-site/app/public

# 2. Clone and setup (one command!)
git clone https://github.com/vapvarun/wp-testing-framework.git && cd wp-testing-framework && ./local-wp-setup.sh

# 3. Run complete AI-driven analysis
./test-plugin.sh bbpress

# Watch as it analyzes:
# ✅ 2,431 functions
# ✅ 63 classes
# ✅ 2,059 hooks
# ✅ Security vulnerabilities
# ✅ Performance metrics
# ✅ Test coverage
```

### Windows Users
```powershell
# Use Git Bash (recommended) or PowerShell
cd "C:\Users\[YourName]\Local Sites\[site]\app\public"
git clone https://github.com/vapvarun/wp-testing-framework.git
cd wp-testing-framework

# Git Bash
./local-wp-setup.sh
./test-plugin.sh bbpress

# PowerShell
.\local-wp-setup.ps1
.\test-plugin.ps1 bbpress
```

📘 **Full Guides:** 
- [Mac/Linux Setup](docs/setup/LOCAL-WP-QUICK-START.md)
- [Windows Setup](docs/setup/WINDOWS-SETUP-GUIDE.md)

## 🎯 How It Works

The framework automatically:
1. **Detects Local WP** environment
2. **Configures database** (uses root/root)
3. **Sets up site URL** (.local domain)
4. **Creates folders** when testing
5. **Generates reports** instantly

## 📦 Testing Any Plugin - Now with AI Analysis!

### Complete Analysis (All Tools Integrated)
```bash
# Mac/Linux
./test-plugin.sh woocommerce           # Full 8-phase analysis
./test-plugin.sh elementor quick       # Quick essential tests
./test-plugin.sh wordfence security    # Security focus
./test-plugin.sh wp-rocket performance # Performance focus
./test-plugin.sh yoast-seo ai         # AI analysis mode

# Windows (Git Bash or PowerShell)
.\test-plugin.ps1 woocommerce
.\test-plugin.ps1 elementor quick
```

### What Gets Analyzed
- **Functions** - Every PHP function documented with AST parsing
- **Classes** - All class structures mapped with methods
- **Hooks** - WordPress actions/filters identified (4000+ for complex plugins)
- **Security** - Vulnerabilities scanned (XSS, SQL injection, nonces, capabilities)
- **Performance** - Memory usage, load time, file sizes, query optimization
- **Database** - SQL queries analyzed, custom tables detected
- **AJAX/REST** - API endpoints documented with handlers
- **Shortcodes** - All shortcodes detected with callbacks
- **Forms** - Form submissions and validation patterns
- **Test Generation** - AI-enhanced, executable, and basic tests created
- **Coverage** - Real code coverage with executable assertions

## 📊 Generated Reports & AI Files

### Visual Dashboard
```bash
# Open beautiful HTML report
open workspace/reports/plugin-name/report-*.html
```

### AI Analysis Files (Feed to Claude!)
```bash
# Complete AI report
cat workspace/ai-reports/plugin-name/ai-analysis-report.md

# Detailed lists
cat workspace/ai-reports/plugin-name/functions-list.txt    # All functions
cat workspace/ai-reports/plugin-name/classes-list.txt      # All classes
cat workspace/ai-reports/plugin-name/hooks-list.txt        # All hooks
cat workspace/ai-reports/plugin-name/security-analysis.txt # Security findings
```

### How to Use with Claude
1. Run analysis: `./test-plugin.sh your-plugin`
2. Copy AI report: `cat workspace/ai-reports/your-plugin/ai-analysis-report.md`
3. Paste to Claude: "Generate comprehensive PHPUnit tests for these functions"
4. Claude generates complete test suites based on your analysis!

## 🤖 AI-Enhanced Testing (NEW!)

### Automatic Test Generation
The framework now generates three tiers of tests automatically:

#### 1. AI-Enhanced Smart Tests (Requires API Key)
```bash
# Set your Anthropic API key
export ANTHROPIC_API_KEY="your-api-key"

# Run with AI enhancement
./test-plugin.sh your-plugin

# Tests generated in:
# wp-content/uploads/wbcom-scan/your-plugin/*/generated-tests/*SmartExecutableTest.php
```

**AI generates tests for:**
- Security vulnerabilities (XSS, SQL injection)
- Edge cases and error handling
- Form validation and sanitization
- Database operations with isolation
- User roles and capabilities
- AJAX handlers with mock requests

#### 2. Executable Tests (Always Generated)
- Real assertions that execute code
- Function existence and callability
- Shortcode output validation
- Hook callback verification
- Provides actual code coverage (20-30%)

#### 3. Basic Test Structure
- PHPUnit test class framework
- Placeholder methods for manual development
- Setup and teardown methods

### Coverage Reporting
```bash
# Run tests with coverage
XDEBUG_MODE=coverage ./test-plugin.sh your-plugin

# Coverage appears in reports:
# - Test Summary shows coverage percentage
# - Executable tests provide real coverage (not 0%)
# - AI tests can achieve 40-60% coverage
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

## 🛠️ Integrated Testing Tools

All PHP testing tools now run automatically in sequence:

1. **Built-in AI Scanner** - Extracts functions, classes, hooks
2. **security-scanner.php** - Vulnerability detection
3. **performance-profiler.php** - Memory and load analysis
4. **test-coverage-report.php** - Coverage metrics
5. **component-test-dashboard.php** - Visual test status

## 📁 What Gets Created Automatically

When you run `./test-plugin.sh plugin-name`:

```
workspace/
├── ai-reports/plugin-name/
│   ├── ai-analysis-report.md    # Complete AI report
│   ├── functions-list.txt       # All functions (e.g., 2,431 for bbPress)
│   ├── classes-list.txt         # All classes (e.g., 63 for bbPress)
│   ├── hooks-list.txt           # All hooks (e.g., 2,059 for bbPress)
│   ├── database-operations.txt  # SQL queries
│   ├── ajax-handlers.txt        # AJAX endpoints
│   ├── security-analysis.txt    # Security findings
│   └── summary.json             # Machine-readable data
├── reports/plugin-name/
│   ├── report-*.html            # Beautiful dashboard
│   ├── security-*.txt           # Security scan results
│   ├── performance-*.txt        # Performance metrics
│   └── coverage-*.txt           # Test coverage
└── plugins/plugin-name/
    ├── test-config.json          # Auto-generated config
    └── tests/                    # Generated test suites
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

### Documentation
- **[Setup Guides](docs/setup/)** - Detailed installation
- **[Plugin Guides](docs/plugin-guides/)** - Plugin-specific docs
- **[Technical Docs](docs/technical/)** - Framework internals, methodology
- **[Feature Docs](docs/features/)** - Feature implementations
- **[Reports](docs/reports/)** - Status reports and improvements

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