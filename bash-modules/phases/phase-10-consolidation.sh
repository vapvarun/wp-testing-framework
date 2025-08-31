#!/bin/bash

# Phase 10: Report Consolidation
# Consolidates all analysis results into comprehensive reports

# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_10() {
    local plugin_name=$1
    
    print_phase 10 "Consolidating All Reports"
    
    print_info "Gathering results from all phases..."
    
    # Collect phase results
    PHASE_RESULTS=""
    TOTAL_SCORE=0
    PHASES_RUN=0
    
    for i in {1..12}; do
        phase_num=$(printf "%02d" $i)
        phase_result_file="$SCAN_DIR/.phase-${phase_num}-result"
        
        if [ -f "$phase_result_file" ]; then
            PHASES_RUN=$((PHASES_RUN + 1))
            
            # Read phase status (macOS compatible)
            status=$(cat "$phase_result_file" | sed -n 's/.*"status":[[:space:]]*"\([^"]*\).*/\1/p')
            [ -z "$status" ] && status="unknown"
            
            # Determine phase name
            case $i in
                1) phase_name="Setup" ;;
                2) phase_name="Detection" ;;
                3) phase_name="AI-Analysis" ;;
                4) phase_name="Security" ;;
                5) phase_name="Performance" ;;
                6) phase_name="Test-Generation" ;;
                7) phase_name="Visual-Testing" ;;
                8) phase_name="Integration" ;;
                9) phase_name="Documentation" ;;
                10) phase_name="Consolidation" ;;
                11) phase_name="Live-Testing" ;;
                12) phase_name="Safekeeping" ;;
            esac
            
            PHASE_RESULTS="${PHASE_RESULTS}### Phase $i: $phase_name\n"
            PHASE_RESULTS="${PHASE_RESULTS}- Status: $status\n"
            
            # Check for phase-specific reports (macOS compatible lowercase)
            phase_name_lower=$(echo "$phase_name" | tr '[:upper:]' '[:lower:]')
            report_file="$SCAN_DIR/reports/${phase_name_lower}-report.md"
            report_file="${report_file// /-}"
            
            if [ -f "$report_file" ]; then
                PHASE_RESULTS="${PHASE_RESULTS}- Report: [View Report](reports/$(basename "$report_file"))\n"
                
                # Extract scores if available (macOS compatible)
                score=$(sed -n 's/.*Score:[[:space:]]*\([0-9]*\)\/100.*/\1/p' "$report_file" | head -1)
                if [ -n "$score" ]; then
                    TOTAL_SCORE=$((TOTAL_SCORE + score))
                    PHASE_RESULTS="${PHASE_RESULTS}- Score: $score/100\n"
                fi
                
            fi
            PHASE_RESULTS="${PHASE_RESULTS}\n"
        fi
    done
    
    # Calculate average score
    if [ $PHASES_RUN -gt 0 ]; then
        AVG_SCORE=$((TOTAL_SCORE / PHASES_RUN))
    else
        AVG_SCORE=0
    fi
    
    # Extract plugin metadata (macOS compatible)
    PLUGIN_VERSION=""
    PLUGIN_AUTHOR=""
    if [ -f "$SCAN_DIR/scan-info.json" ]; then
        if command_exists jq; then
            PLUGIN_VERSION=$(jq -r '.version // ""' "$SCAN_DIR/scan-info.json")
            PLUGIN_AUTHOR=$(jq -r '.author // ""' "$SCAN_DIR/scan-info.json")
        else
            # Fallback to sed for JSON parsing
            PLUGIN_VERSION=$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\).*/\1/p' "$SCAN_DIR/scan-info.json")
            PLUGIN_AUTHOR=$(sed -n 's/.*"author":[[:space:]]*"\([^"]*\).*/\1/p' "$SCAN_DIR/scan-info.json")
        fi
    fi
    
    # Create master report
    MASTER_REPORT="$SCAN_DIR/MASTER-REPORT.md"
    
    cat > "$MASTER_REPORT" << EOF
# WordPress Plugin Testing Framework - Master Report

**Plugin**: $plugin_name  
**Version**: ${PLUGIN_VERSION:-Unknown}  
**Author**: ${PLUGIN_AUTHOR:-Unknown}  
**Date**: $(date)  
**Framework Version**: 12.0

---

## Executive Summary

- **Total Phases Run**: $PHASES_RUN/12
- **Average Score**: $AVG_SCORE/100
- **Status**: $([ $AVG_SCORE -ge 80 ] && echo "✅ Production Ready" || echo "⚠️ Needs Attention")

## Phase Results

$(echo -e "$PHASE_RESULTS")

## Key Findings

EOF
    
    # Add key findings from various reports
    if [ -f "$SCAN_DIR/reports/security-report.md" ]; then
        echo "### Security" >> "$MASTER_REPORT"
        # Extract vulnerabilities count (macOS compatible)
        vulns=$(grep -c "potential.*vulnerabilit" "$SCAN_DIR/reports/security-report.md" 2>/dev/null || echo "0")
        echo "- Potential vulnerabilities found: $vulns" >> "$MASTER_REPORT"
        echo "" >> "$MASTER_REPORT"
    fi
    
    if [ -f "$SCAN_DIR/reports/performance-report.md" ]; then
        echo "### Performance" >> "$MASTER_REPORT"
        # Extract performance metrics
        db_queries=$(grep -c "Database quer" "$SCAN_DIR/reports/performance-report.md" 2>/dev/null || echo "0")
        echo "- Database operations analyzed: $db_queries" >> "$MASTER_REPORT"
        echo "" >> "$MASTER_REPORT"
    fi
    
    if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && command_exists jq; then
        echo "### Code Analysis" >> "$MASTER_REPORT"
        functions=$(jq '.total.functions // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null)
        classes=$(jq '.total.classes // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null)
        hooks=$(jq '.total.hooks // 0' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null)
        echo "- Functions: $functions" >> "$MASTER_REPORT"
        echo "- Classes: $classes" >> "$MASTER_REPORT"
        echo "- Hooks: $hooks" >> "$MASTER_REPORT"
        echo "" >> "$MASTER_REPORT"
    fi
    
    # Add recommendations
    cat >> "$MASTER_REPORT" << EOF

## Recommendations

1. **Security**: $([ -f "$SCAN_DIR/reports/security-report.md" ] && grep -c "HIGH" "$SCAN_DIR/reports/security-report.md" 2>/dev/null | xargs -I {} test {} -gt 0 && echo "Address HIGH priority security issues immediately" || echo "Continue regular security audits")
2. **Performance**: $([ $AVG_SCORE -lt 70 ] && echo "Optimize database queries and caching" || echo "Performance is acceptable")
3. **Testing**: $([ -f "$SCAN_DIR/generated-tests" ] && echo "Execute generated test suite" || echo "Generate comprehensive test coverage")
4. **Documentation**: $([ -f "$SCAN_DIR/reports/documentation-report.md" ] && echo "Review and enhance documentation" || echo "Create missing documentation")

## Files Generated

- Reports: $(ls -1 "$SCAN_DIR/reports" 2>/dev/null | wc -l | tr -d ' ') files
- Tests: $(ls -1 "$SCAN_DIR/generated-tests" 2>/dev/null | wc -l | tr -d ' ') files
- Screenshots: $(ls -1 "$SCAN_DIR/screenshots" 2>/dev/null | wc -l | tr -d ' ') files
- Analysis Prompts: $(ls -1 "$SCAN_DIR/analysis-requests" 2>/dev/null | wc -l | tr -d ' ') files

## Next Steps

1. Review the detailed reports in the \`reports/\` directory
2. Address any security vulnerabilities identified
3. Implement recommended performance optimizations
4. Execute the generated test suite
5. Review and implement the development plan

---

*Report generated by WordPress Plugin Testing Framework v12.0*  
*For support, visit: https://github.com/wp-testing-framework*
EOF
    
    print_success "Master report generated: $MASTER_REPORT"
    
    # Create JSON summary for programmatic access
    JSON_SUMMARY="$SCAN_DIR/summary.json"
    
    cat > "$JSON_SUMMARY" << EOF
{
    "plugin": "$plugin_name",
    "version": "${PLUGIN_VERSION:-Unknown}",
    "date": "$(date -Iseconds)",
    "framework_version": "12.0",
    "phases_run": $PHASES_RUN,
    "average_score": $AVG_SCORE,
    "reports": {
        "master": "MASTER-REPORT.md",
        "security": "reports/security-report.md",
        "performance": "reports/performance-report.md",
        "documentation": "reports/documentation-report.md"
    },
    "metrics": {
        "functions": ${functions:-0},
        "classes": ${classes:-0},
        "hooks": ${hooks:-0},
        "vulnerabilities": ${vulns:-0}
    },
    "status": "$([ $AVG_SCORE -ge 80 ] && echo "production_ready" || echo "needs_attention")"
}
EOF
    
    print_success "JSON summary created: $JSON_SUMMARY"
    
    # Save phase results
    save_phase_results "10" "completed"
    
    # Generate final score
    print_success "Consolidation complete - Overall Score: $AVG_SCORE/100"
    
    # Display summary
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 Analysis Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Plugin: $plugin_name"
    echo "Phases Completed: $PHASES_RUN/12"
    echo "Overall Score: $AVG_SCORE/100"
    echo ""
    echo "Master Report: $MASTER_REPORT"
    echo "All Reports: $SCAN_DIR/reports/"
    echo ""
    
    return 0
}

# Execute if running standalone
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Check if plugin name provided
    if [ -z "$1" ]; then
        echo "Usage: $0 <plugin-name>"
        exit 1
    fi
    
    # Set required variables
    PLUGIN_NAME=$1
    FRAMEWORK_PATH="$(cd "$(dirname "$0")/../../" && pwd)"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    
    # Load scan directory
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Run the phase
    run_phase_10 "$PLUGIN_NAME"
fi