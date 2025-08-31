#!/bin/bash

# Phase 10: Report Consolidation
# Consolidates all phase results into a comprehensive final report

# Source common functions
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
