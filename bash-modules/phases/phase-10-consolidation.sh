#!/bin/bash

# Phase 10: Report Consolidation
# Consolidates all phase results into a comprehensive final report

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_10() {
    local plugin_name=$1
    
    print_phase 10 "Consolidating All Reports"
    
    print_info "Gathering results from all phases..."
    
    # Final report path
    FINAL_REPORT="$SCAN_DIR/FINAL-REPORT.md"
    SUMMARY_JSON="$SCAN_DIR/summary.json"
    
    # Initialize scores and metrics
    TOTAL_SCORE=0
    PHASE_COUNT=0
    CRITICAL_ISSUES=0
    WARNINGS=0
    
    # Collect phase results
    PHASE_RESULTS=""
    
    for i in {1..9}; do
        phase_num=$(printf "%02d" $i)
        phase_result_file="$SCAN_DIR/phase-results/phase-${phase_num}.json"
        
        if [ -f "$phase_result_file" ]; then
            PHASE_COUNT=$((PHASE_COUNT + 1))
            status=$(grep -oP '"status":\s*"[^"]+' "$phase_result_file" | cut -d'"' -f4)
            
            case $i in
                1) phase_name="Setup" ;;
                2) phase_name="Detection" ;;
                3) phase_name="AI Analysis" ;;
                4) phase_name="Security" ;;
                5) phase_name="Performance" ;;
                6) phase_name="Test Generation" ;;
                7) phase_name="Visual Testing" ;;
                8) phase_name="Integration" ;;
                9) phase_name="Documentation" ;;
            esac
            
            PHASE_RESULTS="${PHASE_RESULTS}### Phase $i: $phase_name\n"
            PHASE_RESULTS="${PHASE_RESULTS}- Status: $status\n"
            
            # Check for phase-specific reports
            report_file="$SCAN_DIR/reports/${phase_name,,}-report.md"
            report_file="${report_file// /-}"
            
            if [ -f "$report_file" ]; then
                PHASE_RESULTS="${PHASE_RESULTS}- Report: [View Report](reports/$(basename "$report_file"))\n"
                
                # Extract scores if available
                score=$(grep -oP 'Score:\s*\d+/100' "$report_file" | head -1 | grep -oP '\d+' | head -1)
                if [ -n "$score" ]; then
                    TOTAL_SCORE=$((TOTAL_SCORE + score))
                    PHASE_RESULTS="${PHASE_RESULTS}- Score: $score/100\n"
                fi
                
                # Count issues
                critical=$(grep -c "CRITICAL\|Critical" "$report_file" 2>/dev/null || echo 0)
                warning=$(grep -c "WARNING\|Warning\|HIGH\|High" "$report_file" 2>/dev/null || echo 0)
                
                CRITICAL_ISSUES=$((CRITICAL_ISSUES + critical))
                WARNINGS=$((WARNINGS + warning))
            fi
            
            PHASE_RESULTS="${PHASE_RESULTS}\n"
        fi
    done
    
    # Calculate average score
    if [ $PHASE_COUNT -gt 0 ]; then
        AVG_SCORE=$((TOTAL_SCORE / PHASE_COUNT))
    else
        AVG_SCORE=0
    fi
    
    # Get plugin metadata
    PLUGIN_VERSION="Unknown"
    PLUGIN_AUTHOR="Unknown"
    
    if [ -f "$SCAN_DIR/scan-info.json" ]; then
        PLUGIN_VERSION=$(grep -oP '"version":\s*"[^"]+' "$SCAN_DIR/scan-info.json" | cut -d'"' -f4)
        PLUGIN_AUTHOR=$(grep -oP '"author":\s*"[^"]+' "$SCAN_DIR/scan-info.json" | cut -d'"' -f4)
    fi
    
    # Generate consolidated report
    print_info "Generating final consolidated report..."
    
    cat > "$FINAL_REPORT" << EOF
# WordPress Plugin Testing Framework - Final Report
# $plugin_name

Generated: $(date)  
Framework Version: 12.0

## Executive Summary
- **Plugin**: $plugin_name
- **Version**: $PLUGIN_VERSION
- **Author**: $PLUGIN_AUTHOR
- **Overall Score**: $AVG_SCORE/100
- **Critical Issues**: $CRITICAL_ISSUES
- **Warnings**: $WARNINGS
- **Phases Completed**: $PHASE_COUNT/9

## Phase Results Summary

$(echo -e "$PHASE_RESULTS")

## Key Findings

### Strengths
$(if [ $AVG_SCORE -ge 80 ]; then
    echo "-  Excellent overall code quality"
fi)
$(if [ $CRITICAL_ISSUES -eq 0 ]; then
    echo "-  No critical security issues found"
fi)
$(if [ -f "$SCAN_DIR/reports/performance-report.md" ] && grep -q "Score: [8-9][0-9]\|Score: 100" "$SCAN_DIR/reports/performance-report.md"; then
    echo "-  Good performance optimization"
fi)
$(if [ -f "$SCAN_DIR/reports/documentation-report.md" ] && grep -q "Score: [8-9][0-9]\|Score: 100" "$SCAN_DIR/reports/documentation-report.md"; then
    echo "-  Well documented"
fi)

### Areas for Improvement
$(if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "- L **Critical**: $CRITICAL_ISSUES security vulnerabilities need immediate attention"
fi)
$(if [ $WARNINGS -gt 0 ]; then
    echo "-   $WARNINGS warnings require review"
fi)
$(if [ $AVG_SCORE -lt 60 ]; then
    echo "-   Overall quality needs improvement"
fi)

## Test Artifacts

### Reports Generated
EOF
    
    # List all generated reports
    if [ -d "$SCAN_DIR/reports" ]; then
        for report in "$SCAN_DIR/reports"/*.md; do
            if [ -f "$report" ]; then
                echo "- [$(basename "$report")](reports/$(basename "$report"))" >> "$FINAL_REPORT"
            fi
        done
    fi
    
    # Add recommendations section
    cat >> "$FINAL_REPORT" << EOF

## Priority Recommendations

### High Priority
$(if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "1. Fix all critical security vulnerabilities immediately"
fi)
$(if [ -f "$SCAN_DIR/reports/security-report.md" ] && grep -q "eval()" "$SCAN_DIR/reports/security-report.md"; then
    echo "2. Remove or secure all eval() statements"
fi)
$(if [ -f "$SCAN_DIR/reports/security-report.md" ] && grep -q "SQL injection" "$SCAN_DIR/reports/security-report.md"; then
    echo "3. Fix SQL injection vulnerabilities"
fi)

### Medium Priority
$(if [ -f "$SCAN_DIR/reports/performance-report.md" ] && grep -q "Score: [0-5][0-9]" "$SCAN_DIR/reports/performance-report.md"; then
    echo "4. Optimize performance bottlenecks"
fi)
$(if [ -f "$SCAN_DIR/generated-tests" ] && [ $(find "$SCAN_DIR/generated-tests" -name "*.php" | wc -l) -lt 5 ]; then
    echo "5. Increase test coverage"
fi)

### Low Priority
$(if [ ! -f "$PLUGIN_PATH/CHANGELOG.md" ] && [ ! -f "$PLUGIN_PATH/changelog.txt" ]; then
    echo "6. Add changelog documentation"
fi)
$(if [ -f "$SCAN_DIR/reports/integration-report.md" ] && grep -q "Score: [0-4][0-9]" "$SCAN_DIR/reports/integration-report.md"; then
    echo "7. Enhance WordPress integration"
fi)

## Metadata
- **Framework Version**: 12.0
- **Scan Date**: $(date)
- **Plugin Path**: $PLUGIN_PATH
- **Scan Directory**: $SCAN_DIR
- **Test Type**: ${TEST_TYPE:-full}

---
*Generated by WordPress Plugin Testing Framework v12.0*
EOF
    
    print_success "Final report generated: $FINAL_REPORT"
    
    # Generate JSON summary
    print_info "Generating JSON summary..."
    
    cat > "$SUMMARY_JSON" << EOF
{
    "plugin": "$plugin_name",
    "version": "$PLUGIN_VERSION",
    "author": "$PLUGIN_AUTHOR",
    "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "overall_score": $AVG_SCORE,
    "critical_issues": $CRITICAL_ISSUES,
    "warnings": $WARNINGS,
    "phases_completed": $PHASE_COUNT,
    "total_phases": 9,
    "framework_version": "12.0",
    "scan_directory": "$SCAN_DIR"
}
EOF
    
    print_success "JSON summary generated: $SUMMARY_JSON"
    
    # Display summary
    echo ""
    echo -e "${BLUE}PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP${NC}"
    echo -e "${BLUE}              FINAL ANALYSIS COMPLETE              ${NC}"
    echo -e "${BLUE}PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP${NC}"
    echo ""
    echo "Plugin: $plugin_name"
    echo "Overall Score: $AVG_SCORE/100"
    echo ""
    echo "Critical Issues: $CRITICAL_ISSUES"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Reports saved to: $SCAN_DIR/reports/"
    echo "Final report: $FINAL_REPORT"
    
    # Save phase results
    save_phase_results "10" "completed"
    
    # Interactive checkpoint
    checkpoint 10 "Consolidation complete. Ready for live testing."
    
    return 0
}

# Execute if running standalone
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if [ -z "$1" ]; then
        echo "Usage: $0 <plugin-name>"
        exit 1
    fi
    
    PLUGIN_NAME=$1
    FRAMEWORK_PATH="$(cd "$(dirname "$0")/../../" && pwd)"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    TEST_TYPE=${TEST_TYPE:-full}
    
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    run_phase_10 "$PLUGIN_NAME"
fi