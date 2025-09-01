# Phase Reorganization Plan

## Current Order (PROBLEMATIC)
1. Setup
2. Detection 
3. AI Analysis
4. Security
5. Performance
6. Test Generation
7. Visual Testing ← **PROBLEM: No test data yet!**
8. Integration (creates test data)
9. Documentation
10. Consolidation
11. Live Testing
12. Safekeeping

## BETTER ORDER (Progressive Data Flow)

### Phase 1: Setup & Discovery
- Create directories
- Extract plugin metadata
- Check requirements

### Phase 2: Deep Feature Extraction
- Extract all functions, classes, hooks
- Extract admin menu pages & URLs
- Extract shortcodes, CPTs, AJAX handlers
- **Output:** `extracted-features.json`

### Phase 3: AST Code Analysis
- Deep code analysis
- Complexity metrics
- Pattern detection
- **Output:** `wordpress-ast-analysis.json`

### Phase 4: Security Analysis
- **Uses:** AST data + extracted features
- Find specific vulnerabilities
- **Output:** `security-issues.json`

### Phase 5: Performance Analysis
- **Uses:** AST complexity data
- Identify bottlenecks
- **Output:** `performance-issues.json`

### Phase 6: Test Generation
- **Uses:** Extracted features
- Generate PHPUnit tests
- Generate E2E tests
- **Output:** Test files

### Phase 7: Test Data Creation (NEW/MOVED)
- **Uses:** Extracted features (CPTs, shortcodes)
- Create test users
- Create test posts for each CPT
- Create pages with shortcodes
- **Output:** `test-data.json` with IDs and URLs

### Phase 8: Integration Testing
- **Uses:** Test data from Phase 7
- Test WordPress integration
- Test with other plugins
- **Output:** `integration-report.md`

### Phase 9: Visual Testing (MOVED FROM 7)
- **Uses:** Test data & URLs from Phase 7
- Screenshot admin pages from Phase 2
- Screenshot test pages from Phase 7
- **Output:** Screenshots

### Phase 10: Live Testing (MOVED FROM 11)
- **Uses:** Test data from Phase 7
- Execute AJAX calls
- Test shortcode rendering
- Monitor performance
- **Output:** `live-testing-report.md`

### Phase 11: Documentation (MOVED FROM 9)
- **Uses:** ALL previous data
- Generate AI prompt with everything
- **Output:** Documentation prompt

### Phase 12: Consolidation (MOVED FROM 10)
- **Uses:** ALL data
- Generate master report
- Calculate final scores
- **Output:** `MASTER-REPORT.md`

### Phase 13: Safekeeping (EXTENDED FROM 12)
- Archive everything
- Compare with previous scans
- **Output:** Archives

## Implementation Plan

### Option 1: Renumber Everything
- Rename all phase files
- Update test-plugin.sh
- Update run-phase.sh

### Option 2: Keep Numbers, Change Execution Order
- Keep file names
- Just change the order in test-plugin.sh:
```bash
PHASES=(
    "1:Setup:phase-01-setup.sh"
    "2:Detection:phase-02-detection.sh"
    "3:AI Analysis:phase-03-ai-analysis.sh"
    "4:Security:phase-04-security.sh"
    "5:Performance:phase-05-performance.sh"
    "6:Test Generation:phase-06-test-generation.sh"
    "7:Test Data Creation:phase-08-integration.sh"  # Moved
    "8:Visual Testing:phase-07-visual-testing.sh"   # Moved
    "9:Integration:phase-08-integration-actual.sh"  # New
    "10:Live Testing:phase-11-live-testing.sh"      # Moved
    "11:Documentation:phase-09-documentation.sh"    # Moved
    "12:Consolidation:phase-10-consolidation.sh"    # Moved
    "13:Safekeeping:phase-12-safekeeping.sh"       
)
```

### Option 3: Split Phase 8 (RECOMMENDED)
- Extract test data creation from Phase 8 into new file
- Keep visual testing as Phase 7 but run after test data
- Minimal changes needed

## Recommended Solution

**Create new phase: `phase-06b-test-data.sh`**
- Move test data creation from Phase 8
- Run between Phase 6 and 7
- Phase 7 can then use the test data

This way:
1. Phase 6: Generate tests
2. Phase 6b: Create test data (NEW)
3. Phase 7: Visual testing (can now use test data)
4. Phase 8: Integration testing
5. Continue as normal...