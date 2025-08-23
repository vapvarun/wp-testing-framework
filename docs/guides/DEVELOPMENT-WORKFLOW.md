# Development Workflow Configuration

## 🏗️ Environment Setup

### Primary Development Environment
- **Location:** `/Users/varundubey/Local Sites/buddynext/app/public/`
- **URL:** http://buddynext.local/
- **WordPress:** Latest
- **BuddyPress:** 15.0.0-alpha
- **Testing Framework:** `/wp-testing-framework/`

### GitHub Repository
- **Location:** `/Users/varundubey/wp-testing-framework/`
- **Purpose:** Version control and collaboration
- **Sync:** Use `sync-to-github.sh` script

## 📁 Directory Structure

```
/Users/varundubey/Local Sites/buddynext/app/public/
├── wp-content/
│   ├── plugins/
│   │   ├── buddypress/              # BuddyPress plugin
│   │   └── wbcom-universal-scanner/ # Our scanner plugin
│   └── uploads/
│       ├── wbcom-scan/              # Scan results
│       └── wbcom-plan/              # Test plans
└── wp-testing-framework/            # Testing framework
    ├── tools/                       # Testing tools
    ├── tests/                       # Test suites
    ├── reports/                     # Generated reports
    └── docs/                        # Documentation
```

## 🔄 Development Workflow

### 1. Always Work in BuddyNext
```bash
cd "/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework"
```

### 2. Run Tests Against Live Site
```bash
# Scan BuddyPress
wp scan buddypress --path="../"

# Generate tests
npm run universal:buddypress

# Run functionality tests
npm run functionality:test -- --plugin buddypress

# Generate AI reports
npm run ai:report -- --plugin buddypress
```

### 3. Test Results Location
- **Scan Data:** `../wp-content/uploads/wbcom-scan/`
- **Test Plans:** `../wp-content/uploads/wbcom-plan/`
- **Reports:** `reports/`
- **Generated Tests:** `tests/generated/`

### 4. Sync to GitHub
```bash
# Run sync script
./sync-to-github.sh

# Then commit in GitHub repo
cd /Users/varundubey/wp-testing-framework
git add .
git commit -m "Update from buddynext development"
git push
```

## 🎯 Testing Commands

### From BuddyNext Testing Framework
```bash
# Always run from: /Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework

# Full test workflow
npm run universal:buddypress

# Component tests
npm run test:bp:members
npm run test:bp:groups
npm run test:bp:activity

# Functionality analysis
npm run functionality:analyze -- --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json

# Customer value analysis  
npm run customer:analyze -- --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json

# AI-optimized reports
npm run ai:report -- --plugin buddypress --scan ../wp-content/uploads/wbcom-scan/buddypress-complete.json
```

## 📊 Report Locations

### In BuddyNext Environment
- `wp-testing-framework/tests/generated/buddypress/` - Generated test files
- `wp-testing-framework/tests/functionality/` - Functionality tests
- `wp-testing-framework/reports/customer-analysis/` - Business analysis
- `wp-testing-framework/reports/ai-analysis/` - AI-ready reports

### After Sync to GitHub
Same structure maintained in `/Users/varundubey/wp-testing-framework/`

## ⚙️ Configuration Files

### package.json Scripts
All npm scripts are configured to work within the buddynext environment:
- Paths use relative references (`../wp-content/uploads/`)
- WP-CLI commands use `--path="../"` to target WordPress root

### PHPUnit Configuration
- Bootstrap files point to WordPress test environment
- Test paths relative to buddynext structure

## 🚨 Important Notes

1. **ALWAYS develop in buddynext.local** - This is the live testing environment
2. **Use relative paths** - Scripts reference `../wp-content/` for WordPress files
3. **Scan data lives in WordPress** - Check `wp-content/uploads/wbcom-scan/`
4. **Sync before committing** - Run `sync-to-github.sh` before Git operations
5. **Test against live site** - BuddyPress is active at http://buddynext.local/

## 🔧 Troubleshooting

### WP-CLI Commands
Always include `--path="../"` when running from testing framework:
```bash
wp plugin list --path="../"
wp scan buddypress --path="../"
```

### File Paths
- Development: `/Users/varundubey/Local Sites/buddynext/app/public/`
- GitHub Repo: `/Users/varundubey/wp-testing-framework/`
- Never mix paths between environments

### Permissions
Ensure proper permissions:
```bash
chmod +x sync-to-github.sh
chmod +x tools/*.sh
```

## 📝 Git Workflow

1. **Develop** in buddynext.local
2. **Test** against live BuddyPress
3. **Sync** using `./sync-to-github.sh`
4. **Commit** in GitHub repository:
   ```bash
   cd /Users/varundubey/wp-testing-framework
   git status
   git add .
   git commit -m "feat: Add BuddyPress testing improvements"
   git push
   ```

---

**Remember:** buddynext.local is your development environment. GitHub repo is for version control only!