# Shell Scripts Cleanup - Complete

## ✅ Actions Completed

### 1. Archived Redundant Scripts
Moved to `archive/scripts/`:
- ❌ `run-buddypress-tests.sh` - Use `npm run universal:buddypress` instead
- ❌ `cleanup-wordpress-root.sh` - One-time cleanup, no longer needed
- ❌ `safe-cleanup.sh` - Replaced with npm commands

### 2. Added Clean Commands to package.json
```json
"clean": "rm -rf workspace/* reports/*/execution/* coverage/* .phpunit.cache test-results playwright-report",
"clean:all": "npm run clean && rm -rf node_modules vendor",
"clean:workspace": "rm -rf workspace/*",
"clean:reports": "rm -rf reports/*/execution/* reports/*/api/* reports/*/security/* reports/*/performance/*",
"clean:coverage": "rm -rf coverage/*"
```

### 3. Updated sync-to-github.sh
- ✅ Removed hardcoded paths
- ✅ Uses current directory as source
- ✅ Uses environment variable or `$HOME/wp-testing-framework` as destination
- ✅ Updated to sync new framework structure (src, plugins, templates)
- ✅ Excludes ephemeral data (workspace, reports)

### 4. Verified setup.sh
- ✅ No hardcoded paths found
- ✅ Uses relative paths throughout

## 📊 Results

### Before
- 5 shell scripts in root
- Hardcoded paths in sync script
- No clean commands in package.json

### After
- 2 essential scripts remain (`setup.sh`, `sync-to-github.sh`)
- All paths are relative or configurable
- 5 clean commands added to package.json
- 60% reduction in root shell scripts

## 🎯 Benefits

1. **Cleaner root directory** - Only essential scripts remain
2. **Portable scripts** - No hardcoded paths
3. **npm-based workflows** - Use `npm run` commands instead of shell scripts
4. **Organized archives** - Old scripts preserved in `archive/scripts/`
5. **Flexible deployment** - sync-to-github.sh works from any location

## 📝 Usage

### Setup Framework
```bash
./setup.sh
```

### Clean Commands
```bash
npm run clean           # Clean temporary files
npm run clean:all       # Clean everything including dependencies
npm run clean:workspace # Clean workspace only
npm run clean:reports   # Clean report execution folders
npm run clean:coverage  # Clean coverage reports
```

### Sync to GitHub
```bash
# Default location ($HOME/wp-testing-framework)
./sync-to-github.sh

# Custom location
export WP_TESTING_GITHUB_PATH=/path/to/repo
./sync-to-github.sh
```

### Run Tests (using npm instead of shell scripts)
```bash
npm run universal:buddypress  # Complete BuddyPress testing
npm run test:bp:all          # All BuddyPress tests
npm run test:e2e             # E2E tests
```

## 🗂️ Archived Scripts Location
```
archive/scripts/
├── run-buddypress-tests.sh
├── cleanup-wordpress-root.sh
└── safe-cleanup.sh
```

---

**Shell scripts cleanup complete! Framework is now cleaner and more maintainable.**