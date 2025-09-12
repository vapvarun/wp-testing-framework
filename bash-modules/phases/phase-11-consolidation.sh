#!/bin/bash

# Phase 10: Master Consolidation & Aggregation
# This phase combines ALL data from previous phases into comprehensive reports

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Main phase function
run_phase_11() {
    local plugin_name="${1:-}"
    if [ -z "$plugin_name" ]; then
        print_error "Plugin name required"
        return 1
    fi

    print_phase 11 "Master Data Consolidation & Aggregation"

# Initialize paths
WP_CONTENT_PATH="${WP_CONTENT_PATH:-/Users/varundubey/Local Sites/wptesting/app/public/wp-content}"
SCAN_DIR="$WP_CONTENT_PATH/uploads/wbcom-scan/$plugin_name/$(date +%Y-%m)"
MASTER_REPORT="$SCAN_DIR/MASTER-REPORT.md"
AGGREGATED_JSON="$SCAN_DIR/aggregated-analysis.json"

print_info "Aggregating all analysis data..."

# Initialize scoring
TOTAL_SCORE=0
PHASE_COUNT=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

# Check and aggregate data from each phase
declare -A PHASE_DATA

# Phase 1: Setup (check if directories exist)
if [ -d "$SCAN_DIR" ]; then
    PHASE_DATA["setup"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=10))
fi

# Phase 2: Feature Extraction
if [ -f "$SCAN_DIR/extracted-features.json" ] || [ -f "$SCAN_DIR/detection-results.json" ]; then
    PHASE_DATA["extraction"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=10))
    
    # Extract statistics (with fallbacks for empty files)
    if [ -f "$SCAN_DIR/extracted-features.json" ] && [ -s "$SCAN_DIR/extracted-features.json" ]; then
        if command -v jq &> /dev/null; then
            FUNC_COUNT=$(jq '.statistics.functions // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
            CLASS_COUNT=$(jq '.statistics.classes // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
            HOOK_COUNT=$(jq '.statistics.hooks // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
        fi
    else
        # Try to get from AST if extracted-features is empty
        if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && [ -s "$SCAN_DIR/wordpress-ast-analysis.json" ]; then
            if command -v jq &> /dev/null; then
                FUNC_COUNT=$(jq '.functions // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null || echo "0")
                CLASS_COUNT=$(jq '.classes // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null || echo "0")
                HOOK_COUNT=$(jq '.wordpress_features.hooks // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null || echo "0")
            fi
        fi
    fi
fi

# Phase 3: AST Analysis
if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ]; then
    PHASE_DATA["ast_analysis"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=15))
    
    # Extract AST metrics
    if command -v jq &> /dev/null; then
        AST_FUNCTIONS=$(jq '.total.functions // 0' "$SCAN_DIR/wordpress-ast-analysis.json")
        AST_CLASSES=$(jq '.total.classes // 0' "$SCAN_DIR/wordpress-ast-analysis.json")
        AST_SECURITY=$(jq '.total.security_issues // 0' "$SCAN_DIR/wordpress-ast-analysis.json")
        AST_COMPLEXITY=$(jq '.total.complexity // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null)
        
        if [ "$AST_SECURITY" -gt 0 ]; then
            ((CRITICAL_ISSUES+=AST_SECURITY))
        fi
    fi
fi

# Phase 4: Security Analysis
if [ -f "$SCAN_DIR/reports/security-report.md" ]; then
    PHASE_DATA["security"]="✅ Complete"
    ((PHASE_COUNT++))
    
    # Extract security score
    SECURITY_SCORE=$(grep "Security Score:" "$SCAN_DIR/reports/security-report.md" | sed -E 's/.*:\s*([0-9]+).*/\1/' | head -1)
    if [ ! -z "$SECURITY_SCORE" ]; then
        ((TOTAL_SCORE+=SECURITY_SCORE/10))
    fi
    
    # Count security issues
    XSS_COUNT=$(grep -c "XSS" "$SCAN_DIR/reports/security-report.md" 2>/dev/null || echo 0)
    SQL_COUNT=$(grep -c "SQL" "$SCAN_DIR/reports/security-report.md" 2>/dev/null || echo 0)
    ((HIGH_ISSUES+=XSS_COUNT+SQL_COUNT))
fi

# Phase 5: Performance Analysis
if [ -f "$SCAN_DIR/reports/performance-report.md" ]; then
    PHASE_DATA["performance"]="✅ Complete"
    ((PHASE_COUNT++))
    
    PERF_SCORE=$(grep "Score:" "$SCAN_DIR/reports/performance-report.md" | sed -E 's/.*:\s*([0-9]+).*/\1/' | head -1)
    if [ ! -z "$PERF_SCORE" ]; then
        ((TOTAL_SCORE+=PERF_SCORE/10))
    fi
fi

# Phase 6: Test Generation
if [ -d "$SCAN_DIR/generated-tests" ]; then
    PHASE_DATA["tests"]="✅ Complete"
    ((PHASE_COUNT++))
    TEST_COUNT=$(find "$SCAN_DIR/generated-tests" -name "*.php" | wc -l)
    if [ "$TEST_COUNT" -gt 0 ]; then
        ((TOTAL_SCORE+=10))
    fi
fi

# Phase 7: Visual Testing
if [ -d "$SCAN_DIR/screenshots" ]; then
    PHASE_DATA["visual"]="✅ Complete"
    ((PHASE_COUNT++))
    SCREENSHOT_COUNT=$(find "$SCAN_DIR/screenshots" -name "*.png" 2>/dev/null | wc -l)
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        ((TOTAL_SCORE+=5))
    fi
fi

# Phase 8: Integration Testing
if [ -f "$SCAN_DIR/reports/integration-report.md" ]; then
    PHASE_DATA["integration"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=10))
fi

# Phase 9: Documentation
if [ -f "$SCAN_DIR/analysis-requests/phase-9-ai-documentation.md" ]; then
    PHASE_DATA["documentation"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=10))
fi

# Phase 11: Live Testing
if [ -f "$SCAN_DIR/reports/live-testing-report.md" ]; then
    PHASE_DATA["live_testing"]="✅ Complete"
    ((PHASE_COUNT++))
    ((TOTAL_SCORE+=5))
fi

# Calculate final score
if [ $PHASE_COUNT -gt 0 ]; then
    FINAL_SCORE=$((TOTAL_SCORE * 100 / (PHASE_COUNT * 10)))
else
    FINAL_SCORE=0
fi

# Generate aggregated JSON
print_info "Creating aggregated analysis JSON..."

cat > "$AGGREGATED_JSON" << EOF
{
  "plugin": "$plugin_name",
  "analysis_date": "$(date -Iseconds)",
  "overall_score": $FINAL_SCORE,
  "phases_completed": $PHASE_COUNT,
  "issues": {
    "critical": $CRITICAL_ISSUES,
    "high": $HIGH_ISSUES,
    "medium": $MEDIUM_ISSUES,
    "low": $LOW_ISSUES
  },
  "metrics": {
    "functions": ${AST_FUNCTIONS:-0},
    "classes": ${AST_CLASSES:-0},
    "hooks": ${HOOK_COUNT:-0},
    "security_score": ${SECURITY_SCORE:-0},
    "performance_score": ${PERF_SCORE:-0},
    "test_coverage": 0
  },
  "phases": {
    "setup": "${PHASE_DATA[setup]:-❌ Missing}",
    "extraction": "${PHASE_DATA[extraction]:-❌ Missing}",
    "ast_analysis": "${PHASE_DATA[ast_analysis]:-❌ Missing}",
    "security": "${PHASE_DATA[security]:-❌ Missing}",
    "performance": "${PHASE_DATA[performance]:-❌ Missing}",
    "tests": "${PHASE_DATA[tests]:-❌ Missing}",
    "visual": "${PHASE_DATA[visual]:-❌ Missing}",
    "integration": "${PHASE_DATA[integration]:-❌ Missing}",
    "documentation": "${PHASE_DATA[documentation]:-❌ Missing}",
    "live_testing": "${PHASE_DATA[live_testing]:-❌ Missing}"
  }
}
EOF

# Generate Master Report
print_info "Generating master report..."

cat > "$MASTER_REPORT" << EOF
# MASTER ANALYSIS REPORT
**Plugin**: $plugin_name  
**Date**: $(date)  
**Overall Score**: $FINAL_SCORE/100

## Executive Summary
This comprehensive analysis evaluated the $plugin_name WordPress plugin across $PHASE_COUNT analysis phases, identifying ${CRITICAL_ISSUES} critical issues, ${HIGH_ISSUES} high-priority issues, ${MEDIUM_ISSUES} medium issues, and ${LOW_ISSUES} low-priority issues.

## Phase Completion Status
| Phase | Status | Details |
|-------|--------|---------|
| Setup & Discovery | ${PHASE_DATA[setup]:-❌ Missing} | Directory structure and plugin metadata |
| Feature Extraction | ${PHASE_DATA[extraction]:-❌ Missing} | ${FUNC_COUNT:-0} functions, ${CLASS_COUNT:-0} classes, ${HOOK_COUNT:-0} hooks |
| AST Code Analysis | ${PHASE_DATA[ast_analysis]:-❌ Missing} | ${AST_FUNCTIONS:-0} functions analyzed |
| Security Scan | ${PHASE_DATA[security]:-❌ Missing} | Score: ${SECURITY_SCORE:-0}/100 |
| Performance Analysis | ${PHASE_DATA[performance]:-❌ Missing} | Score: ${PERF_SCORE:-0}/100 |
| Test Generation | ${PHASE_DATA[tests]:-❌ Missing} | ${TEST_COUNT:-0} test files generated |
| Visual Testing | ${PHASE_DATA[visual]:-❌ Missing} | ${SCREENSHOT_COUNT:-0} screenshots captured |
| Integration Testing | ${PHASE_DATA[integration]:-❌ Missing} | WordPress integration verified |
| Documentation | ${PHASE_DATA[documentation]:-❌ Missing} | AI documentation prompt generated |
| Live Testing | ${PHASE_DATA[live_testing]:-❌ Missing} | Runtime validation completed |

## Key Metrics
- **Total Functions**: ${AST_FUNCTIONS:-0}
- **Total Classes**: ${AST_CLASSES:-0}
- **WordPress Hooks**: ${HOOK_COUNT:-0}
- **Security Issues**: $((CRITICAL_ISSUES + HIGH_ISSUES))
- **Performance Score**: ${PERF_SCORE:-0}/100
- **Test Coverage**: 0%

## Critical Findings

### Security Issues
EOF

# Add security findings if available
if [ -f "$SCAN_DIR/reports/security-report.md" ]; then
    echo "" >> "$MASTER_REPORT"
    grep -A 5 "Vulnerability Scan Results" "$SCAN_DIR/reports/security-report.md" >> "$MASTER_REPORT" 2>/dev/null || echo "No security issues found" >> "$MASTER_REPORT"
fi

cat >> "$MASTER_REPORT" << EOF

### Performance Bottlenecks
EOF

# Add performance findings if available
if [ -f "$SCAN_DIR/reports/performance-report.md" ]; then
    echo "" >> "$MASTER_REPORT"
    grep -A 5 "Recommendations" "$SCAN_DIR/reports/performance-report.md" >> "$MASTER_REPORT" 2>/dev/null || echo "No performance issues found" >> "$MASTER_REPORT"
fi

cat >> "$MASTER_REPORT" << EOF

### Code Quality
EOF

# Add code quality metrics from AST if available
if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && command -v jq &> /dev/null; then
    echo "- Nonce Checks: $(jq '.total.nonces // 0' "$SCAN_DIR/wordpress-ast-analysis.json")" >> "$MASTER_REPORT"
    echo "- Capability Checks: $(jq '.total.capabilities // 0' "$SCAN_DIR/wordpress-ast-analysis.json")" >> "$MASTER_REPORT"
    echo "- Sanitization Calls: $(jq '.total.sanitization // 0' "$SCAN_DIR/wordpress-ast-analysis.json")" >> "$MASTER_REPORT"
    echo "- Escaping Calls: $(jq '.total.escaping // 0' "$SCAN_DIR/wordpress-ast-analysis.json")" >> "$MASTER_REPORT"
fi

cat >> "$MASTER_REPORT" << EOF

## Recommendations

### Immediate Actions (Critical)
EOF

if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "1. Address $CRITICAL_ISSUES critical security vulnerabilities" >> "$MASTER_REPORT"
fi

if [ $HIGH_ISSUES -gt 0 ]; then
    echo "2. Fix $HIGH_ISSUES high-priority issues" >> "$MASTER_REPORT"
fi

cat >> "$MASTER_REPORT" << EOF

### Short-term Improvements (1-2 weeks)
1. Increase test coverage (currently 0%)
2. Implement caching for database-heavy operations
3. Add input validation for all user inputs

### Long-term Enhancements (1-3 months)
1. Refactor high-complexity functions
2. Implement REST API for modern integration
3. Add Gutenberg block support
4. Improve multisite compatibility

## Technical Debt Score
Based on the analysis, the technical debt score is: **${FINAL_SCORE}/100**

### Breakdown:
- Code Quality: ${AST_FUNCTIONS:+Good} ${AST_FUNCTIONS:-Unknown}
- Security Posture: ${SECURITY_SCORE:-0}/100
- Performance: ${PERF_SCORE:-0}/100
- Test Coverage: 0/100
- Documentation: ${PHASE_DATA[documentation]:-Missing}

## Data Files
All analysis data is available in:
- Master JSON: $AGGREGATED_JSON
- Feature Data: $SCAN_DIR/extracted-features.json
- AST Analysis: $SCAN_DIR/wordpress-ast-analysis.json
- Reports Directory: $SCAN_DIR/reports/

## Next Steps
1. Review critical security issues immediately
2. Generate comprehensive documentation using the AI prompt
3. Implement suggested test cases
4. Plan refactoring based on complexity analysis
5. Schedule regular re-scans to track improvements

---
*Generated by WordPress Plugin Testing Framework v12.0*
*Analysis completed in $PHASE_COUNT phases*
EOF

# Create summary JSON for dashboard/API consumption
SUMMARY_JSON="$SCAN_DIR/summary.json"
cat > "$SUMMARY_JSON" << EOF
{
  "plugin": "$plugin_name",
  "score": $FINAL_SCORE,
  "phases": $PHASE_COUNT,
  "issues": {
    "total": $((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES + LOW_ISSUES)),
    "critical": $CRITICAL_ISSUES,
    "high": $HIGH_ISSUES
  },
  "timestamp": "$(date -Iseconds)"
}
EOF

print_success "Master report generated: $MASTER_REPORT"
print_success "Aggregated JSON created: $AGGREGATED_JSON"
print_success "Summary JSON created: $SUMMARY_JSON"

# Display summary
echo ""
print_info "Analysis Summary:"
echo "  - Overall Score: $FINAL_SCORE/100"
echo "  - Phases Completed: $PHASE_COUNT/10"
echo "  - Critical Issues: $CRITICAL_ISSUES"
echo "  - High Priority Issues: $HIGH_ISSUES"
echo ""

if [ $FINAL_SCORE -ge 80 ]; then
    print_success "✨ Plugin is in EXCELLENT condition!"
elif [ $FINAL_SCORE -ge 60 ]; then
    print_warning "⚠️ Plugin needs some improvements"
elif [ $FINAL_SCORE -ge 40 ]; then
    print_warning "⚠️ Plugin has significant issues"
else
    print_error "❌ Plugin requires major work"
fi

    print_success "Phase 11 completed successfully"
    
    # Copy aggregated analysis to wbcom-plans for learning patterns
    PLAN_DIR="$UPLOAD_PATH/wbcom-plan/$plugin_name/$DATE_MONTH"
    ensure_directory "$PLAN_DIR/analysis-results"
    
    if [ -f "$AGGREGATED_FILE" ]; then
        cp "$AGGREGATED_FILE" "$PLAN_DIR/analysis-results/aggregated-analysis.json"
        print_info "Copied aggregated analysis to wbcom-plans"
    fi
    
    if [ -f "$MASTER_REPORT" ]; then
        cp "$MASTER_REPORT" "$PLAN_DIR/analysis-results/master-report.md"
        print_info "Copied master report to wbcom-plans"
    fi
    
    # Save plugin score pattern
    SCORES_DIR="$UPLOAD_PATH/wbcom-plan/models/plugin-scores"
    ensure_directory "$SCORES_DIR"
    
    cat > "$SCORES_DIR/${plugin_name}-score.json" << EOF
{
    "plugin": "$plugin_name",
    "overall_score": ${FINAL_SCORE:-0},
    "critical_issues": ${CRITICAL_ISSUES:-0},
    "high_issues": ${HIGH_ISSUES:-0},
    "analysis_date": "$(date -Iseconds)",
    "phase_scores": {
        "functions": ${FUNC_COUNT:-0},
        "classes": ${CLASS_COUNT:-0},
        "hooks": ${HOOK_COUNT:-0},
        "security_issues": ${SECURITY_ISSUES:-0},
        "performance_issues": ${PERF_ISSUES:-0}
    }
}
EOF
    print_info "Saved plugin score pattern to wbcom-plans"
    
    return 0
}