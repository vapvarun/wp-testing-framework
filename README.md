# WP Testing Framework

**🤖 AI-Driven WordPress Plugin Testing Framework**

Complete plugin analysis with integrated security scanning, performance profiling, and AI-ready reports for test generation!

## ✨ What's New: Modular Testing Framework with AI Integration!

### 📦 Modular Architecture - Run Any Phase Independently!

The framework now uses a **fully modular approach** where each phase can be run independently:

```bash
# Run complete analysis (all 12 phases)
./test-plugin.sh bbpress

# Run individual phases
./bash-modules/phases/phase-02-detection-enhanced.sh bbpress
./bash-modules/phases/phase-03-ai-analysis.sh bbpress
./bash-modules/phases/phase-06-ai-test-data.sh bbpress

# Skip specific phases
SKIP_PHASES="7,11" ./test-plugin.sh bbpress
```

### 🔄 Progressive Data Flow - Each Phase Builds on Previous!

12 comprehensive phases with **progressive data building**:
1. **Setup** - Directory structure + scan-info.json
2. **Detection (Enhanced)** - Extracts 500+ functions, classes, hooks with ACTUAL data
3. **AI Analysis (AST)** - 2MB+ rich AST data with complexity metrics
4. **Security** - Uses AST data for vulnerability scanning
5. **Performance** - Uses complexity metrics from AST
6. **Test Generation + AI Data** - Creates tests AND contextual test data
7. **Visual Testing** - Uses test data created in Phase 6
8. **Integration Tests** - Tests with realistic data relationships
9. **AI Documentation** - 50K+ prompt using ALL previous data
10. **Consolidation (Enhanced)** - Aggregates everything, calculates score
11. **Live Testing** - Uses real test data from Phase 6
12. **Safekeeping** - Archives to wbcom-scan, not framework

### 🚀 New Features:
- **Modular Phase System** - Run any phase independently
- **AI-Driven Test Data** - Analyzes database patterns for contextual data
- **Progressive Enhancement** - No repeated work, each phase adds value
- **Clean Framework** - All data in wbcom-scan, framework contains only tools
- **Real Data Extraction** - Actual names/values, not just counts

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

## 🤖 AI-Enhanced Testing & Modular Phases

### Running Individual Phases

Each phase can be run independently for targeted analysis:

```bash
# Phase 2: Enhanced Detection (extracts actual data)
./bash-modules/phases/phase-02-detection-enhanced.sh plugin-name

# Phase 3: AI/AST Analysis (generates 2MB+ AST data)
./bash-modules/phases/phase-03-ai-analysis.sh plugin-name

# Phase 6: AI Test Data Generation (analyzes database patterns)
./bash-modules/phases/phase-06-ai-test-data.sh plugin-name

# Phase 9: AI Documentation (uses all collected data)
./bash-modules/phases/phase-09-documentation.sh plugin-name

# Phase 10: Enhanced Consolidation (aggregates everything)
./bash-modules/phases/phase-10-consolidation-enhanced.sh plugin-name
```

### AI-Driven Test Data Generation

The framework analyzes database patterns to generate contextual test data:

```bash
# Run AI test data generation
./bash-modules/phases/phase-06-ai-test-data.sh your-plugin

# Creates comprehensive AI prompt at:
# wbcom-scan/your-plugin/2025-09/analysis-requests/phase-6-ai-test-data.md

# AI analyzes:
# - Database queries (INSERT, UPDATE, SELECT)
# - Custom tables and schema
# - Meta operations and relationships
# - Plugin type detection (ecommerce, forum, LMS, etc.)
```

**AI generates contextual test data based on plugin type:**
- **E-commerce**: Products, orders, payment methods
- **Forum**: Topics, replies, user discussions
- **LMS**: Courses, lessons, enrollments
- **Membership**: Subscription levels, access rules
- **Forms**: Submissions with validation

### Test Generation Tiers

#### 1. Executable Tests (Always Generated)
- Real assertions that execute code
- Function existence and callability
- Shortcode output validation
- Hook callback verification
- Provides actual code coverage (20-30%)

#### 2. AI-Enhanced Test Data
- Contextual data based on plugin patterns
- SQL queries for custom tables
- WP-CLI commands for content creation
- Realistic relationships and foreign keys

#### 3. Basic Test Structure
- PHPUnit test class framework
- Placeholder methods for manual development
- Setup and teardown methods

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

## 📁 Output Structure - Clean Separation

All analysis data is stored in `wbcom-scan/` keeping the framework clean:

```
wp-content/uploads/wbcom-scan/plugin-name/2025-09/
├── extracted-features.json       # 500+ functions, classes, hooks with names
├── wordpress-ast-analysis.json   # 2MB+ AST data with complexity
├── test-data-manifest.json      # Created test data IDs and URLs
├── analysis-requests/
│   ├── phase-6-ai-test-data.md  # AI prompt for test data generation
│   └── phase-9-ai-documentation.md # 50K+ comprehensive prompt
├── reports/
│   ├── security-report.md       # Vulnerability analysis
│   ├── performance-report.md    # Performance metrics
│   ├── test-data-report.md      # Test data creation summary
│   └── MASTER-REPORT.md         # Aggregated analysis with score
├── generated-tests/
│   ├── *ExecutableTest.php      # Real executable tests
│   └── *BasicTest.php           # Test structure
├── documentation/
│   ├── USER-GUIDE.md            # AI-generated user guide
│   └── ISSUES-AND-FIXES.md     # AI-generated issues report
└── raw-outputs/
    ├── detected-functions.txt   # Function signatures
    ├── detected-classes.txt     # Class definitions
    ├── detected-hooks.txt       # Hook implementations
    └── test-pages.txt          # Created test page URLs
```

**Framework directory stays clean - contains only tools!**

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