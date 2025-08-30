# 🚀 WordPress Testing Framework - Complete Workflow

## 📋 Overview
A fully AI-driven, plugin-agnostic testing framework that adapts to ANY WordPress plugin based on actual code analysis, not assumptions.

---

## 🔄 Complete Testing Flow

### 🎯 **START: Command Execution**
```bash
./test-plugin.sh [plugin-name]
```
Example: `./test-plugin.sh health-check`

---

## 📊 **12-Phase Testing Pipeline**

### **PHASE 1: Environment Setup & Validation**
```
📁 Directory Structure Created:
├── wp-content/uploads/
│   ├── wbcom-scan/           # Temporary scanning workspace
│   │   └── plugin-name/
│   │       └── 2025-01/       # Date-based organization
│   │           ├── raw-outputs/
│   │           ├── ai-analysis/
│   │           └── reports/
│   └── wbcom-plan/           # AI-processed results
│       └── plugin-name/
│           └── 2025-01/
│               ├── documentation/
│               └── test-results/
└── plugins/
    └── plugin-name/          # Safekeeping copy
```

**What Happens:**
- ✅ Validates plugin exists and is active
- ✅ Creates organized directory structure
- ✅ Sets up timestamped folders for this scan
- ✅ Prepares raw output directories

---

### **PHASE 2: Basic Plugin Analysis**
```
Collecting: Version, Files, Structure
```

**What Happens:**
- 📊 Counts PHP, JS, CSS files
- 📁 Maps directory structure
- 📝 Extracts plugin metadata
- 🔍 Identifies main plugin file

**Output:**
- File count statistics
- Directory tree structure
- Plugin header information

---

### **PHASE 3: AI-Driven Code Analysis** ⭐
```
Running: Grep → PHPStan → PHPCS → Psalm → AST Parser → Test Data Generator
```

**3.1 Grep Baseline Analysis:**
- Searches for WordPress patterns
- Finds hooks, filters, shortcodes
- Detects AJAX handlers
- Identifies security functions

**3.2 Professional PHP Tools:**
```bash
PHPStan: Static analysis for type safety
PHPCS:   WordPress coding standards
Psalm:   Advanced type inference
PHPMD:   Mess detection
PHPCPD:  Copy-paste detection
```

**3.3 AST (Abstract Syntax Tree) Analysis:**
```javascript
node tools/php-ast-analyzer.js
```
- Parses PHP into syntax tree
- Accurately detects:
  - Custom Post Types
  - Taxonomies
  - REST endpoints
  - Database operations
  - Class structures
  - Function relationships

**3.4 AI Test Data Generation:** 🤖
```javascript
node tools/ai/test-data-generator.mjs
```
**Intelligent Analysis:**
- Reads AST analysis results
- Identifies plugin features
- NO hardcoded assumptions
- Creates customized test plan

**Generated Files:**
- `test-data-plan.json` - Structured test data requirements
- `generate-test-data.php` - Executable PHP script

**Example Test Data Plan:**
```json
{
  "plugin": "my-plugin",
  "test_data": [
    {
      "type": "custom_post_type",
      "name": "detected_cpt_name",
      "count": 5,
      "fields": { ... }
    },
    {
      "type": "shortcode",
      "name": "detected_shortcode",
      "action": "create_page"
    }
  ]
}
```

---

### **PHASE 4: Security Analysis**
```
Scanning for: XSS, SQL Injection, Nonce checks, Capabilities
```

**What Happens:**
- 🔒 Detects direct SQL queries
- 🛡️ Finds missing nonce verifications
- ⚠️ Identifies XSS vulnerabilities
- 🔑 Checks capability validations
- 📋 Counts sanitization functions

**Security Scanner Output:**
- Critical vulnerabilities count
- Security score (0-100)
- Specific file:line references
- Fix recommendations

---

### **PHASE 5: Performance Analysis**
```
Profiling: Memory usage, Load time, Database queries
```

**What Happens:**
- ⚡ Measures plugin load time
- 💾 Checks memory footprint
- 📊 Counts database operations
- 📦 Identifies large files
- 🔄 Analyzes hook density

---

### **PHASE 6: Test Generation & Coverage**
```
Creating: Unit tests, Integration tests, Coverage reports
```

**What Happens:**
- 🧪 Generates PHPUnit test templates
- 📊 Calculates potential coverage
- 🎯 Prioritizes critical functions
- 📝 Creates test configuration

---

### **PHASE 7: Documentation Generation & Validation**
```
Generating: User Guide, Issues Report, Development Plan
```

**7.1 Documentation Generation:**
- Uses ACTUAL scan data (not templates)
- Includes real code examples
- Adds discovered features
- Creates actionable recommendations

**7.2 Professional Enhancement:**
```bash
tools/documentation/enhance-documentation.sh
```
- Extracts real function implementations
- Adds configuration examples
- Includes actual shortcodes found

**7.3 Quality Validation:**
```bash
tools/documentation/validate-documentation.sh
```
- Scores documentation quality
- Checks line count, code blocks
- Verifies specific references
- Ensures actionable content

**Generated Documents:**
1. `USER-GUIDE.md` - How to use the plugin
2. `ISSUES-AND-FIXES.md` - Problems with solutions
3. `DEVELOPMENT-PLAN.md` - Roadmap with timelines

---

### **PHASE 8: Professional Reporting**
```
Generating: HTML Dashboard, CSV exports, JSON data
```

**What Happens:**
- 📊 Creates visual HTML dashboard
- 📈 Generates charts and graphs
- 📋 Exports data in multiple formats
- 🎨 Includes screenshots if available

---

### **PHASE 9: User-Friendly Analysis**
```
Creating: Plain English guides, Enhancement recommendations
```

**What Happens:**
- 👤 Translates technical findings
- 💡 Suggests improvements
- 📚 Creates how-to guides
- 🚀 Provides upgrade paths

**Based on AI Analysis:**
- If few AJAX handlers → Suggests real-time features
- If no REST API → Recommends mobile connectivity
- If missing shortcodes → Proposes content shortcuts

---

### **PHASE 10: Report Consolidation**
```
Organizing: All reports into final structure
```

**What Happens:**
- 📦 Copies all reports to safekeeping
- 🗂️ Creates master index
- 📁 Organizes by category
- 🔗 Links all related files

---

### **PHASE 11: Live Testing with AI Test Data** 🧪
```
Executing: AI-generated test scenarios
```

**11.1 Test Data Execution:**
```php
php generate-test-data.php  // AI-generated script
```

**What Actually Happens:**
- Creates content based on discovered CPTs
- Generates pages with found shortcodes
- Sets up taxonomies detected
- No hardcoded assumptions!

**11.2 Visual Testing:**
- Takes screenshots of generated content
- Tests AJAX endpoints found
- Verifies REST API routes
- Checks admin pages

**11.3 Functional Testing:**
- Tests each discovered feature
- Validates shortcode output
- Checks AJAX responses
- Verifies data persistence

---

### **PHASE 12: Final Summary & Archive**
```
Creating: Executive summary, Success metrics, Archive
```

**Final Outputs:**
```
plugins/[plugin-name]/
├── final-reports-[timestamp]/
│   ├── EXECUTIVE-SUMMARY.md
│   ├── test-results.json
│   ├── security-report.txt
│   ├── performance-metrics.txt
│   └── screenshots/
└── test-data-created.json
```

---

## 🔬 **How AI-Driven Analysis Works**

### **Traditional Approach (OLD):**
```bash
if plugin_name contains "forum" → assume forum features
if plugin_name contains "shop" → assume ecommerce
```
❌ **Problems:** Wrong assumptions, missed features, generic tests

### **AI-Driven Approach (NEW):**
```javascript
1. Parse actual PHP code → AST
2. Detect real features:
   - Found register_post_type() → Create matching test posts
   - Found add_shortcode() → Generate test pages with shortcodes
   - Found wp_ajax_* → Test those specific AJAX calls
3. Generate targeted test data
```
✅ **Benefits:** Accurate, specific, comprehensive

---

## 📊 **Example: Complete Flow for Any Plugin**

### **Input:** 
```bash
./test-plugin.sh my-custom-plugin
```

### **AI Discovers:**
- 3 Custom Post Types: `event`, `speaker`, `sponsor`
- 2 Shortcodes: `[event_list]`, `[speaker_grid]`
- 5 AJAX handlers for live filtering
- 1 REST endpoint for mobile app

### **AI Generates Test Data:**
```php
// Automatically created by AI
- 5 test events with dates and venues
- 3 test speakers with bios
- 3 test sponsors with logos
- Test pages with [event_list] shortcode
- Test pages with [speaker_grid] shortcode
```

### **AI Recommends:**
- "Add caching for event queries (detected 50+ DB calls)"
- "Implement lazy loading for speaker images"
- "Add REST endpoints for remaining CPTs"
- "Consider adding [event_calendar] shortcode"

---

## 🎯 **Key Advantages**

### **1. Truly Plugin-Agnostic**
- No hardcoded plugin names
- No assumption-based testing
- Adapts to ANY WordPress plugin

### **2. Intelligent Test Data**
- Based on actual code analysis
- Creates relevant test scenarios
- No generic "Test Post 1, 2, 3"

### **3. Actionable Insights**
- Specific line numbers for issues
- Exact functions that need fixes
- Real code examples from plugin

### **4. Professional Documentation**
- Generated from actual findings
- Includes real metrics
- Provides specific solutions

---

## 🚦 **Quick Start Guide**

### **1. First-Time Setup:**
```bash
# Clone framework
git clone [repo] wp-testing-framework
cd wp-testing-framework

# Run setup for your environment
./setup.sh           # General WordPress
# OR
./local-wp-setup.sh  # Local WP by Flywheel

# Install dependencies
npm install
```

### **2. Test Any Plugin:**
```bash
# Full analysis (all 12 phases)
./test-plugin.sh plugin-name

# Quick security check only
./test-plugin.sh plugin-name security

# AI analysis only
./test-plugin.sh plugin-name ai
```

### **3. View Results:**
```bash
# Open HTML dashboard
open wp-content/uploads/wbcom-plan/plugin-name/*/reports/report-*.html

# Read documentation
cat plugins/plugin-name/final-reports-*/USER-GUIDE.md

# Check test data created
cat wp-content/uploads/wbcom-scan/plugin-name/*/ai-analysis/test-data-plan.json
```

---

## 📁 **Output Locations**

### **During Testing:**
```
wp-content/uploads/wbcom-scan/[plugin]/[date]/
```

### **AI Processed:**
```
wp-content/uploads/wbcom-plan/[plugin]/[date]/
```

### **Final Archive:**
```
plugins/[plugin]/final-reports-[timestamp]/
```

---

## 🔧 **Customization**

### **Skip Phases:**
Interactive prompts let you skip any phase:
- "Continue with Phase X? (y/n)"

### **Timeout Settings:**
Large plugins have automatic timeouts:
- AST analysis: 5 minutes max
- Test data generation: 3 minutes max

### **Parallel Processing:**
Multiple tools run simultaneously for speed

---

## 🎉 **Result**
A complete, AI-driven analysis of ANY WordPress plugin with:
- ✅ Accurate feature detection
- ✅ Relevant test data
- ✅ Specific recommendations
- ✅ Professional documentation
- ✅ Zero assumptions