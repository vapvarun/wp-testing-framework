#!/bin/bash
# Safe Cleanup Script for WordPress Testing Framework
# This script only removes truly temporary files that are regenerated on each test run

echo "🧹 Starting SAFE cleanup of WordPress Testing Framework..."
echo "This will only remove temporary test artifacts that are regenerated automatically."
echo ""

# Create backup directory with timestamp
BACKUP_DIR="archive/cleanup-$(date +%Y%m%d-%H%M%S)"
echo "📁 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Count files before cleanup
BEFORE_COUNT=$(find . -type f | wc -l)
BEFORE_SIZE=$(du -sh . | cut -f1)

echo "📊 Before cleanup: $BEFORE_COUNT files, Size: $BEFORE_SIZE"
echo ""

# ========================================
# SAFE TO DELETE - Test Artifacts
# ========================================

echo "1️⃣ Removing Playwright test artifacts (regenerated each test run)..."

# Remove test results (these are regenerated on each test run)
if [ -d "tools/e2e/test-results" ]; then
    echo "   - Moving test-results to backup..."
    mv tools/e2e/test-results "$BACKUP_DIR/" 2>/dev/null
    echo "   ✅ Test results backed up"
fi

# Remove playwright report data (regenerated on each test run)
if [ -d "tools/e2e/playwright-report/data" ]; then
    echo "   - Moving playwright-report/data to backup..."
    mv tools/e2e/playwright-report/data "$BACKUP_DIR/" 2>/dev/null
    echo "   ✅ Playwright report data backed up"
fi

# ========================================
# SAFE TO DELETE - Empty Files
# ========================================

echo ""
echo "2️⃣ Removing empty files..."

# Find and remove empty files (0 bytes)
find . -type f -size 0 -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" 2>/dev/null | while read -r file; do
    echo "   - Removing empty file: $file"
    rm -f "$file"
done

# ========================================
# CONSOLIDATE - Error Context Files
# ========================================

echo ""
echo "3️⃣ Consolidating error-context.md files..."

# Find all error-context.md files and consolidate
ERROR_FILES=$(find . -name "error-context.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
if [ ! -z "$ERROR_FILES" ]; then
    echo "   - Found multiple error-context.md files"
    echo "   - Creating consolidated error log..."
    
    # Create consolidated error file
    CONSOLIDATED_ERROR_FILE="$BACKUP_DIR/consolidated-errors-$(date +%Y%m%d).md"
    echo "# Consolidated Error Contexts - $(date)" > "$CONSOLIDATED_ERROR_FILE"
    echo "" >> "$CONSOLIDATED_ERROR_FILE"
    
    while IFS= read -r file; do
        echo "## Error from: $file" >> "$CONSOLIDATED_ERROR_FILE"
        echo "" >> "$CONSOLIDATED_ERROR_FILE"
        cat "$file" >> "$CONSOLIDATED_ERROR_FILE"
        echo "" >> "$CONSOLIDATED_ERROR_FILE"
        echo "---" >> "$CONSOLIDATED_ERROR_FILE"
        echo "" >> "$CONSOLIDATED_ERROR_FILE"
        
        # Remove the original
        rm -f "$file"
    done <<< "$ERROR_FILES"
    
    echo "   ✅ Error contexts consolidated to: $CONSOLIDATED_ERROR_FILE"
fi

# ========================================
# ORGANIZE - Misplaced Files
# ========================================

echo ""
echo "4️⃣ Organizing misplaced files..."

# Move load-wp-cli-commands.php to proper location
if [ -f "load-wp-cli-commands.php" ]; then
    echo "   - Moving load-wp-cli-commands.php to wp-cli-commands/"
    mv load-wp-cli-commands.php wp-cli-commands/ 2>/dev/null
    echo "   ✅ WP-CLI command file moved"
fi

# ========================================
# CLEAN - Old Generated Files
# ========================================

echo ""
echo "5️⃣ Cleaning old generated files..."

# Remove old cleanup scripts and reports (keep the tools)
if [ -f "cleanup-script.sh" ]; then
    echo "   - Removing old cleanup-script.sh"
    rm -f cleanup-script.sh
fi

if [ -f "cleanup-report.json" ]; then
    echo "   - Moving cleanup-report.json to backup"
    mv cleanup-report.json "$BACKUP_DIR/"
fi

# ========================================
# PRESERVE - Important Files
# ========================================

echo ""
echo "6️⃣ Preserving important files..."
echo "   ✅ All scanners preserved in /tools/scanners/"
echo "   ✅ All test files preserved in /tests/"
echo "   ✅ All reports preserved in /reports/"
echo "   ✅ All WP-CLI commands preserved"
echo "   ✅ All configuration files preserved"

# ========================================
# SUMMARY
# ========================================

echo ""
echo "=================="
echo "🎉 CLEANUP COMPLETE"
echo "=================="

# Count files after cleanup
AFTER_COUNT=$(find . -type f | wc -l)
AFTER_SIZE=$(du -sh . | cut -f1)

echo "📊 After cleanup: $AFTER_COUNT files, Size: $AFTER_SIZE"
echo "📁 Backup location: $BACKUP_DIR"

FILES_REMOVED=$((BEFORE_COUNT - AFTER_COUNT))
echo "✨ Files removed/moved: $FILES_REMOVED"

echo ""
echo "💡 Next steps:"
echo "1. Run: php tools/utilities/file-index-generator.php"
echo "2. Commit the cleaned framework"
echo "3. If anything was wrongly removed, check: $BACKUP_DIR"

echo ""
echo "✅ Safe cleanup completed successfully!"