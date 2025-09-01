# Testing Framework Phases

## Overview
The framework consists of 12 progressive analysis phases that build upon each other.

## Phase Scripts

### Phase 1: Setup & Directory Structure
**File**: `phase-01-setup.sh`
- Creates directory structure in `wbcom-scan/[plugin]/[YYYY-MM]/`
- Validates plugin existence
- Checks system requirements
- **Output**: Directory structure, scan-info.json

### Phase 2: Plugin Detection & Feature Extraction
**Files**: 
- `phase-02-detection.sh` (original - counts features)
- `phase-02-detection-enhanced.sh` ✨ (RECOMMENDED - extracts actual data)

**Enhanced version extracts**:
- Actual function signatures (not just count)
- Class definitions with names
- Hooks with context
- Shortcodes with tags
- AJAX handlers with names
- Custom post types
- REST API routes
- **Output**: extracted-features.json with REAL DATA

### Phase 3: AI-Driven Code Analysis (AST)
**File**: `phase-03-ai-analysis.sh`
- Runs AST analysis using Node.js
- Analyzes both PHP and JavaScript files
- Extracts code complexity metrics
- Identifies WordPress patterns
- **Output**: wordpress-ast-analysis.json (2MB+ of rich data)

### Phase 4: Security Vulnerability Scanning
**File**: `phase-04-security.sh`
- Scans for XSS vulnerabilities
- Checks SQL injection risks
- Validates nonce usage
- Checks capability verification
- **Output**: security-report.md, security issues in JSON

### Phase 5: Performance Analysis
**File**: `phase-05-performance-analysis.sh`
- Analyzes file sizes
- Counts database operations
- Checks caching implementation
- Measures hook density
- **Output**: performance-report.md

### Phase 6: Test Generation & Coverage
**File**: `phase-06-test-generation.sh`
- Generates PHPUnit test files
- Creates test bootstrap
- Attempts code coverage analysis
- **Output**: generated-tests/*.php

### Phase 7: Visual Testing & Screenshots
**File**: `phase-07-visual-testing.sh`
- Captures admin interface screenshots
- Tests plugin settings pages
- Validates frontend display
- **Output**: screenshots/*.png

### Phase 8: WordPress Integration Tests
**File**: `phase-08-integration.sh`
- Tests WordPress hook integration
- Validates database operations
- Checks user capabilities
- Tests with sample data
- **Output**: integration-report.md

### Phase 9: AI-Driven Documentation Generation
**File**: `phase-09-documentation.sh` ✨ (Enhanced)
- Collects ALL data from previous phases
- Extracts function/class/hook signatures
- Creates comprehensive AI prompt (50K+)
- **Output**: AI documentation prompt for generating 5 documents

### Phase 10: Consolidation & Master Report
**Files**:
- `phase-10-consolidation.sh` (original)
- `phase-10-consolidation-enhanced.sh` ✨ (RECOMMENDED)

**Enhanced version**:
- Aggregates data from ALL phases
- Calculates overall score (0-100)
- Identifies critical issues
- Creates actionable recommendations
- **Output**: MASTER-REPORT.md, aggregated-analysis.json

### Phase 11: Live Testing with Test Data
**File**: `phase-11-live-testing.sh`
- Creates test posts for CPTs
- Tests AJAX endpoints
- Validates shortcode output
- Monitors performance
- **Output**: live-testing-report.md

### Phase 12: Framework Safekeeping
**File**: `phase-12-safekeeping.sh` ✨ (Updated)
- Archives scan results to `wbcom-scan/[plugin]/archives/`
- Maintains scan history
- Cleans old archives
- **Output**: Archives in plugin's directory (not framework)

## Enhanced Versions

### Currently Enhanced:
- ✨ Phase 2: `phase-02-detection-enhanced.sh` - Extracts actual data
- ✨ Phase 9: Already enhanced to collect all data
- ✨ Phase 10: `phase-10-consolidation-enhanced.sh` - Proper aggregation
- ✨ Phase 12: Updated to store in wbcom-scan

### Recommended Usage:
```bash
# Use enhanced versions where available
./test-plugin.sh [plugin-name]

# Or run individual enhanced phases
./bash-modules/phases/phase-02-detection-enhanced.sh [plugin-name]
./bash-modules/phases/phase-10-consolidation-enhanced.sh [plugin-name]
```

## Data Flow

```
Phase 1 → Directory Structure
Phase 2 → extracted-features.json (REAL DATA)
Phase 3 → wordpress-ast-analysis.json (2MB+ AST)
Phase 4 → Security issues
Phase 5 → Performance metrics
Phase 6 → Generated tests
Phase 7 → Screenshots
Phase 8 → Integration results
Phase 9 → Combines ALL → AI Documentation Prompt (50K+)
Phase 10 → Aggregates ALL → MASTER-REPORT.md
Phase 11 → Live validation
Phase 12 → Archives to wbcom-scan/[plugin]/archives/
```

## Output Location
All outputs are stored in:
```
/wp-content/uploads/wbcom-scan/[plugin-name]/[YYYY-MM]/
```

NOT in the framework directory!