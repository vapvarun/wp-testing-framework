# WordPress Testing Framework - Maintenance Guidelines

## 🎯 Purpose
Keep the framework organized, efficient, and AI-ready for Claude Code integration.

## 📋 File Organization Index

### Master Index Files (Keep Updated)
- **`FILE-INDEX.md`** - Human-readable complete file listing
- **`FILE-INDEX.json`** - AI-consumable file metadata
- **`FOLDER-ORGANIZATION.md`** - Folder structure documentation

### Automated Tools
1. **File Index Generator** - `tools/utilities/file-index-generator.php`
   ```bash
   php tools/utilities/file-index-generator.php
   ```
   - Scans all framework files
   - Generates markdown and JSON indexes
   - Identifies file purposes and status

2. **Cleanup Organizer** - `tools/utilities/cleanup-organizer.php`
   ```bash
   php tools/utilities/cleanup-organizer.php
   ```
   - Identifies duplicate files
   - Finds temporary/backup files
   - Suggests file reorganization
   - Generates cleanup script

## 🗂️ Folder Structure

### Core Framework (`/wp-testing-framework/`)
```
├── /tools/              # Testing tools (scanners, generators, etc.)
├── /tests/              # Test files (PHPUnit, E2E)
├── /reports/            # Generated reports
├── /wp-cli-commands/    # Custom WP-CLI commands
├── /bin/                # Shell scripts
├── /examples/           # Example files
└── /docs/               # Documentation
```

### Data Folders (`/wp-content/uploads/`)
```
├── /wbcom-scan/         # Environment-specific scan data (DON'T COMMIT)
│   ├── /current-scans/  # Latest analysis results
│   ├── /initial-scans/  # Original scans
│   └── /archive/        # Old/deprecated scans
│
└── /wbcom-plan/         # Reusable models (CAN COMMIT)
    ├── /docs/           # Test plans and documentation
    ├── /models/         # Learning patterns
    ├── /templates/      # Test templates
    └── /knowledge-base/ # Accumulated knowledge
```

## 🔄 Regular Maintenance Tasks

### Daily
- [ ] Check for new files in root directory
- [ ] Move misplaced files to correct folders
- [ ] Clear test result artifacts if > 100MB

### Weekly
- [ ] Run file index generator
- [ ] Run cleanup organizer
- [ ] Archive old scan results
- [ ] Review and execute cleanup script
- [ ] Update documentation for new features

### Monthly
- [ ] Full framework audit
- [ ] Remove deprecated files
- [ ] Consolidate duplicate functionality
- [ ] Update all indexes and documentation
- [ ] Optimize file structure

## 🧹 Cleanup Procedures

### 1. Identify Issues
```bash
php tools/utilities/cleanup-organizer.php
```

### 2. Review Cleanup Script
```bash
cat cleanup-script.sh
```

### 3. Execute Cleanup (Carefully)
```bash
./cleanup-script.sh
```

### 4. Update Indexes
```bash
php tools/utilities/file-index-generator.php
```

### 5. Commit Changes
```bash
git add -A
git commit -m "Framework maintenance and cleanup"
git push
```

## 📊 Current Statistics (2025-08-23)

- **Total Files**: 143 core files (excluding dependencies)
- **AI-Ready**: 134 files (93.7%)
- **Issues Found**: 360 (mostly test artifacts)
- **Space to Recover**: ~11MB

### File Distribution
- Markdown: 55 files (38.5%)
- PHP: 41 files (28.7%)
- JSON: 17 files (11.9%)
- JavaScript/MJS: 17 files (11.9%)
- Shell Scripts: 9 files (6.3%)
- XML: 4 files (2.8%)

## 🚫 Files/Folders to Clean

### Can Delete
- `/tools/e2e/test-results/` - Test artifacts (regenerated each run)
- `/tools/e2e/playwright-report/` - Old reports
- `*.tmp`, `*.bak`, `*.backup` - Temporary files
- Hash-named files (e.g., `fd9a99d6a75629b9599aaae4a8c3c39551090f7a.md`)

### Should Archive
- Old scan results in `wbcom-scan`
- Duplicate test reports
- Previous version backups

### Never Delete
- Any file in `/tools/scanners/`
- Any file in `/wp-cli-commands/`
- Configuration files (*.json, *.xml, *.yml)
- Documentation files (*.md)

## 🤖 AI Optimization (For Claude Code)

### Keep Files AI-Ready
1. **Use Clear Names**: Descriptive, purpose-driven filenames
2. **Add Headers**: Include purpose comment at file start
3. **Format JSON**: Always use pretty-print for readability
4. **Document Changes**: Update FILE-INDEX.md when adding files

### Optimal Structure for AI
```
- JSON files for data (AI can parse easily)
- Markdown for reports (structured, readable)
- Clear folder hierarchy (logical organization)
- Consistent naming conventions
- Purpose-driven file organization
```

## ✅ Best Practices

### DO
- ✅ Run cleanup tools regularly
- ✅ Keep indexes updated
- ✅ Archive before deleting
- ✅ Document all changes
- ✅ Use automated tools
- ✅ Maintain clear folder structure
- ✅ Keep AI-readability in mind

### DON'T
- ❌ Delete files without archiving
- ❌ Leave files in root directory
- ❌ Ignore cleanup warnings
- ❌ Mix environment data with code
- ❌ Create deep nested folders
- ❌ Use unclear file names
- ❌ Commit environment-specific data

## 📝 Quick Commands

### Full Maintenance Cycle
```bash
# 1. Generate current index
php tools/utilities/file-index-generator.php

# 2. Run cleanup analysis
php tools/utilities/cleanup-organizer.php

# 3. Review and execute cleanup
./cleanup-script.sh

# 4. Update indexes again
php tools/utilities/file-index-generator.php

# 5. Commit changes
git add -A
git commit -m "Regular maintenance: cleanup and reorganization"
git push
```

### Check Framework Health
```bash
# Count files
find . -type f -name "*.php" -o -name "*.js" -o -name "*.json" | wc -l

# Check folder sizes
du -sh */

# Find large files
find . -type f -size +1M

# Find empty files
find . -type f -size 0
```

## 🎯 Goals

1. **Organization**: Every file in its proper place
2. **Efficiency**: No duplicate or unnecessary files
3. **AI-Ready**: Structured for Claude Code analysis
4. **Documentation**: Everything indexed and documented
5. **Maintainability**: Easy to update and extend

## 📅 Next Maintenance Due

- Daily Check: Every day at project start
- Weekly Cleanup: Every Friday
- Monthly Audit: First Monday of month
- Index Update: After any significant changes

---

**Remember**: A well-organized framework is easier to maintain, extend, and use with AI tools like Claude Code.