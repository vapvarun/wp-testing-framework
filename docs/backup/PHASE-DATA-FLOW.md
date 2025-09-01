# Phase Data Flow Analysis

## Current State - What Each Phase Produces & Consumes

### Phase 1: Setup ✅
**Produces:**
- `scan-info.json` - Basic scan metadata
- Directory structure

**Consumes:** Nothing (first phase)

**Missing:** Should extract plugin header info (version, author, plugin URI)

---

### Phase 2: Feature Extraction ✅ ENHANCED
**Produces:**
- `extracted-features.json` with:
  - 500 functions (signatures)
  - 61 classes 
  - 100 hooks
  - 3 custom post types
  - 4 AJAX handlers
  - 1 shortcode

**Consumes:** Nothing

**Missing:**
- Admin menu pages/URLs not being extracted
- Settings pages not being extracted
- Widget classes not being extracted
- Gutenberg blocks not being extracted

---

### Phase 3: AST Analysis ✅
**Produces:**
- `wordpress-ast-analysis.json` (2MB+ of rich data)
- Contains detailed function analysis, complexity, etc.

**Consumes:**
- `detection-results.json` (if exists) for file counts

**Missing:** Not parsing/using the AST data in later phases

---

### Phase 4: Security ⚠️
**Produces:**
- `security-report.md`

**Consumes:** Nothing from previous phases!

**PROBLEM:** Should use AST data to find specific vulnerable functions

---

### Phase 5: Performance ⚠️
**Produces:**
- `performance-report.md`

**Consumes:** Nothing from previous phases!

**PROBLEM:** Should use AST complexity data

---

### Phase 6: Test Generation ✅
**Produces:**
- Test files in `generated-tests/`

**Consumes:**
- `wordpress-ast-analysis.json` for hooks/shortcodes count

**Missing:** Should use actual function names from Phase 2 to generate specific tests

---

### Phase 7: Visual Testing ⚠️
**Produces:**
- Screenshots in `screenshots/`

**Consumes:** 
- `test-pages.txt` (if exists)

**PROBLEMS:**
1. Hardcoded URLs: `wp-admin/admin.php?page=$plugin_name`
2. Not using extracted admin pages from Phase 2
3. Not using shortcodes list from Phase 2

---

### Phase 8: Integration ⚠️
**Produces:**
- `integration-report.md`

**Consumes:** Nothing from previous phases!

**PROBLEM:** Should use CPTs, taxonomies, hooks from Phase 2

---

### Phase 9: Documentation ✅
**Produces:**
- AI documentation prompt (50K+)

**Consumes:**
- `wordpress-ast-analysis.json`
- `security-report.md`
- `performance-report.md`
- `functionality-report.md`

**Good:** This phase properly aggregates data!

---

### Phase 10: Consolidation ✅ ENHANCED
**Produces:**
- `MASTER-REPORT.md`
- `aggregated-analysis.json`

**Consumes:**
- `extracted-features.json`
- `wordpress-ast-analysis.json`
- All report files

**Good:** Properly aggregates!

---

### Phase 11: Live Testing ⚠️
**Produces:**
- `live-testing-report.md`

**Consumes:**
- `detection-results.json` for CPT count

**PROBLEM:** Should use actual CPT names from Phase 2 to create test content

---

### Phase 12: Safekeeping ✅
**Produces:**
- Archives in `wbcom-scan/[plugin]/archives/`

**Consumes:**
- `summary.json`

---

## Critical Missing Data Flows

### 1. Admin Pages/URLs Not Extracted
Phase 2 should extract:
```php
add_menu_page('Title', 'Menu', 'capability', 'slug', 'callback');
add_submenu_page('parent', 'Title', 'Menu', 'capability', 'slug', 'callback');
```
And provide URLs like: `admin.php?page=slug`

### 2. AST Data Not Used
Phase 3 generates rich AST with:
- Function complexity scores
- Security patterns
- Code smells

But Phases 4, 5, 8 don't use it!

### 3. Extracted Features Not Used
Phase 2 extracts actual names but:
- Phase 6 doesn't generate tests for specific functions
- Phase 7 doesn't screenshot specific admin pages
- Phase 11 doesn't create content for specific CPTs

### 4. No URL Discovery
Missing extraction of:
- Admin page URLs
- Frontend page URLs
- REST API endpoints
- AJAX endpoints

## Recommended Fixes

### Fix 1: Enhance Phase 2 to Extract Admin Pages
```bash
# Extract admin menu pages
grep -h "add_menu_page\|add_submenu_page" | extract slugs
# Generate URLs: admin.php?page=[slug]
```

### Fix 2: Make Phase 4 Use AST Data
```bash
# Read AST analysis
if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ]; then
    # Check specific vulnerable functions from AST
fi
```

### Fix 3: Make Phase 7 Use Extracted URLs
```bash
# Read admin pages from Phase 2
if [ -f "$SCAN_DIR/extracted-features.json" ]; then
    ADMIN_PAGES=$(jq '.admin_pages[]' "$SCAN_DIR/extracted-features.json")
    # Screenshot each admin page
fi
```

### Fix 4: Make Phase 11 Use Extracted CPTs
```bash
# Read CPT names from Phase 2
if [ -f "$SCAN_DIR/extracted-features.json" ]; then
    CPTS=$(jq '.custom_post_types[].name' "$SCAN_DIR/extracted-features.json")
    # Create test posts for each CPT
fi
```

## Data Flow Should Be:

```
Phase 1 → Plugin metadata
    ↓
Phase 2 → Feature extraction (names, URLs)
    ↓
Phase 3 → Deep AST analysis
    ↓
Phase 4 → Security (uses AST + features)
    ↓
Phase 5 → Performance (uses AST + features)
    ↓
Phase 6 → Tests (uses all above)
    ↓
Phase 7 → Visual (uses URLs from Phase 2)
    ↓
Phase 8 → Integration (uses features)
    ↓
Phase 9 → Documentation (aggregates all)
    ↓
Phase 10 → Master report (final aggregation)
    ↓
Phase 11 → Live testing (uses features)
    ↓
Phase 12 → Archive everything
```