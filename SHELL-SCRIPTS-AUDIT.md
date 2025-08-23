# Shell Scripts Audit - WP Testing Framework

## Root Directory Scripts Analysis

### 🟢 ESSENTIAL SCRIPTS (Keep)

#### 1. `setup.sh` (203 lines)
**Purpose**: Main setup script for the framework
**Functions**:
- Checks Node.js, Composer, WP-CLI prerequisites
- Installs npm and composer dependencies
- Installs Playwright browsers
- Creates directory structure
- Sets up local bin tools
- Verifies WordPress and BuddyPress installation

**Status**: ✅ **KEEP** - Core setup functionality

---

#### 2. `sync-to-github.sh` (100 lines)
**Purpose**: Syncs development to GitHub repository
**Functions**:
- Syncs from local development to GitHub folder
- Excludes node_modules, vendor, temp files
- Handles directories: tools, tests, docs, plugins, reports
- Syncs configuration files

**Status**: ✅ **KEEP** - Required for GitHub deployment
**Note**: Has hardcoded paths that may need updating

---

### 🟡 REDUNDANT/OUTDATED SCRIPTS (Consider Removing)

#### 3. `run-buddypress-tests.sh` (177 lines)
**Purpose**: Runs complete BuddyPress testing workflow
**Functions**:
- Scans BuddyPress
- Runs functionality analysis
- Executes scenario tests
- Generates reports

**Status**: ⚠️ **REDUNDANT** - Functionality covered by npm scripts
**Alternative**: Use `npm run universal:buddypress` instead
**Recommendation**: Remove or convert to npm script

---

#### 4. `cleanup-wordpress-root.sh` (147 lines)
**Purpose**: Removes duplicate testing files from WordPress root
**Functions**:
- Removes test files from WordPress root
- Cleans up duplicates after framework move

**Status**: ⚠️ **OUTDATED** - One-time cleanup script
**Recommendation**: Archive or remove - no longer needed after restructuring

---

#### 5. `safe-cleanup.sh` (162 lines)
**Purpose**: Removes temporary test artifacts
**Functions**:
- Removes Playwright test results
- Cleans coverage reports
- Removes cache files
- Creates backup before deletion

**Status**: 🟡 **OPTIONAL** - Useful but could be npm script
**Alternative**: Convert to `npm run clean` command
**Recommendation**: Convert to npm script and remove .sh file

---

## Summary & Recommendations

### Keep These Scripts:
1. ✅ **setup.sh** - Essential for initial setup
2. ✅ **sync-to-github.sh** - Needed for GitHub sync (update paths)

### Remove/Replace These Scripts:
1. ❌ **run-buddypress-tests.sh** → Use `npm run universal:buddypress`
2. ❌ **cleanup-wordpress-root.sh** → Archive and delete
3. ❌ **safe-cleanup.sh** → Convert to `npm run clean`

### Action Items:

#### 1. Update package.json with clean script:
```json
"scripts": {
  "clean": "rm -rf workspace/* reports/*/execution/* coverage/* .phpunit.cache",
  "clean:all": "npm run clean && rm -rf node_modules vendor"
}
```

#### 2. Update sync-to-github.sh:
- Remove hardcoded paths
- Use relative paths or environment variables
- Update to match new framework structure

#### 3. Archive old scripts:
```bash
mkdir -p archive/scripts
mv cleanup-wordpress-root.sh archive/scripts/
mv run-buddypress-tests.sh archive/scripts/
```

#### 4. Create simplified run script (if needed):
Instead of complex shell scripts, use npm scripts:
```json
"universal:buddypress": "npm run scan:bp && npm run analyze:bp && npm run test:bp:all && npm run report:bp"
```

## Scripts in Subdirectories (Not Audited Yet)

Found additional scripts in:
- `tools/run-component-tests.sh`
- `tools/scan-bp.sh`
- `tools/scan-buddypress.sh`
- `tools/scanners/scan-wp.sh`
- `tools/test-coverage-report.sh`
- `src/Bin/setup-data-dirs.sh`
- `plugins/buddypress/tests/run-tests.sh`

These should be audited separately if needed.

## Final Count:
- **Essential**: 2 scripts
- **To Remove**: 3 scripts
- **Total Reduction**: 60% of root scripts