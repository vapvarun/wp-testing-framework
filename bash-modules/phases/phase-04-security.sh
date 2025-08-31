#!/bin/bash

# Phase 4: Security Vulnerability Scanning
# Scans for common WordPress security vulnerabilities

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_04() {
    local plugin_name=$1
    
    print_phase 4 "Security Vulnerability Scanning"
    
    print_info "Scanning for security vulnerabilities..."
    
    # Initialize vulnerability counts
    CRITICAL_COUNT=0
    HIGH_COUNT=0
    MEDIUM_COUNT=0
    LOW_COUNT=0
    
    # Security checks
    SECURITY_REPORT="$SCAN_DIR/reports/security-report.md"
    
    cat > "$SECURITY_REPORT" << EOF
# Security Vulnerability Report
**Plugin**: $plugin_name  
**Date**: $(date)

## Vulnerability Scan Results
EOF
    
    # Check for eval() usage
    print_info "Checking for eval() usage..."
    EVAL_COUNT=$(grep -r "eval(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    if [ $EVAL_COUNT -gt 0 ]; then
        print_warning "Found $EVAL_COUNT eval() usage - potential code execution vulnerability"
        CRITICAL_COUNT=$((CRITICAL_COUNT + EVAL_COUNT))
        echo "- **CRITICAL**: $EVAL_COUNT instances of eval() found" >> "$SECURITY_REPORT"
    fi
    
    # Check for SQL injection vulnerabilities
    print_info "Checking for SQL injection vulnerabilities..."
    SQL_INJECT=$(grep -r '\$wpdb.*\$_\(GET\|POST\|REQUEST\)' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    if [ $SQL_INJECT -gt 0 ]; then
        print_warning "Found $SQL_INJECT potential SQL injection points"
        HIGH_COUNT=$((HIGH_COUNT + SQL_INJECT))
        echo "- **HIGH**: $SQL_INJECT potential SQL injection vulnerabilities" >> "$SECURITY_REPORT"
    fi
    
    # Check for XSS vulnerabilities
    print_info "Checking for XSS vulnerabilities..."
    XSS_COUNT=$(grep -r 'echo.*\$_\(GET\|POST\|REQUEST\)' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    if [ $XSS_COUNT -gt 0 ]; then
        print_warning "Found $XSS_COUNT potential XSS vulnerabilities"
        HIGH_COUNT=$((HIGH_COUNT + XSS_COUNT))
        echo "- **HIGH**: $XSS_COUNT potential XSS vulnerabilities" >> "$SECURITY_REPORT"
    fi
    
    # Check for nonce verification
    print_info "Checking for nonce verification..."
    FORM_COUNT=$(grep -r '\$_POST\[\|$_GET\[' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    NONCE_COUNT=$(grep -r 'wp_verify_nonce\|check_admin_referer' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    if [ $FORM_COUNT -gt 0 ] && [ $NONCE_COUNT -eq 0 ]; then
        print_warning "Forms without nonce verification detected"
        MEDIUM_COUNT=$((MEDIUM_COUNT + 1))
        echo "- **MEDIUM**: Forms without nonce verification" >> "$SECURITY_REPORT"
    fi
    
    # Check for capability checks
    print_info "Checking for capability checks..."
    ADMIN_PAGE=$(grep -r 'add_menu_page\|add_submenu_page' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    CAPABILITY=$(grep -r 'current_user_can\|user_can' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    if [ $ADMIN_PAGE -gt 0 ] && [ $CAPABILITY -eq 0 ]; then
        print_warning "Admin pages without capability checks"
        MEDIUM_COUNT=$((MEDIUM_COUNT + 1))
        echo "- **MEDIUM**: Admin pages without capability checks" >> "$SECURITY_REPORT"
    fi
    
    # Check for file operations
    print_info "Checking for unsafe file operations..."
    FILE_OPS=$(grep -r 'file_get_contents\|fopen\|include\|require' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | grep '\$_' | wc -l)
    if [ $FILE_OPS -gt 0 ]; then
        print_warning "Found $FILE_OPS unsafe file operations"
        CRITICAL_COUNT=$((CRITICAL_COUNT + FILE_OPS))
        echo "- **CRITICAL**: $FILE_OPS unsafe file operations with user input" >> "$SECURITY_REPORT"
    fi
    
    # Deep Security Analysis
    if [ -f "$MODULES_PATH/shared/advanced-analysis.sh" ]; then
        source "$MODULES_PATH/shared/advanced-analysis.sh"
        
        # Generate comprehensive security analysis request
        handle_deep_analysis 4 "$plugin_name" "security" "$PLUGIN_PATH" "$SCAN_DIR"
        
        # Process any existing security reports
        process_existing_analysis_reports "$SCAN_DIR" 4
        
        # Check if vulnerability assessment results exist
        if [ -f "$SCAN_DIR/deep-analysis/phase-4-security-critical-findings.txt" ]; then
            DEEP_CRITICAL=$(grep -c "CRITICAL" "$SCAN_DIR/deep-analysis/phase-4-security-critical-findings.txt" 2>/dev/null || echo 0)
            DEEP_HIGH=$(grep -c "HIGH" "$SCAN_DIR/deep-analysis/phase-4-security-critical-findings.txt" 2>/dev/null || echo 0)
            
            if [ $DEEP_CRITICAL -gt 0 ] || [ $DEEP_HIGH -gt 0 ]; then
                echo "" >> "$SECURITY_REPORT"
                echo "## Advanced Security Assessment" >> "$SECURITY_REPORT"
                echo "- Critical vulnerabilities found: $DEEP_CRITICAL" >> "$SECURITY_REPORT"
                echo "- High priority issues: $DEEP_HIGH" >> "$SECURITY_REPORT"
                echo "- Full report available in analysis-requests/ directory" >> "$SECURITY_REPORT"
            fi
        fi
    fi
    
    # Calculate security score
    TOTAL_ISSUES=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))
    SECURITY_SCORE=$((100 - (CRITICAL_COUNT * 20) - (HIGH_COUNT * 10) - (MEDIUM_COUNT * 5) - (LOW_COUNT * 2)))
    SECURITY_SCORE=$((SECURITY_SCORE < 0 ? 0 : SECURITY_SCORE))
    
    # Add summary to report
    cat >> "$SECURITY_REPORT" << EOF

## Summary
- Critical Issues: $CRITICAL_COUNT
- High Priority: $HIGH_COUNT
- Medium Priority: $MEDIUM_COUNT
- Low Priority: $LOW_COUNT
- **Total Issues**: $TOTAL_ISSUES
- **Security Score**: $SECURITY_SCORE/100

## Recommendations
$(if [ $CRITICAL_COUNT -gt 0 ]; then
    echo "1. **URGENT**: Address all critical vulnerabilities immediately"
    echo "2. Remove or secure all eval() statements"
    echo "3. Validate and sanitize all file operations"
fi)
$(if [ $HIGH_COUNT -gt 0 ]; then
    echo "4. Escape all user output with appropriate WordPress functions"
    echo "5. Use prepared statements for all database queries"
fi)
$(if [ $MEDIUM_COUNT -gt 0 ]; then
    echo "6. Implement nonce verification for all forms"
    echo "7. Add capability checks for all admin functions"
fi)
EOF
    
    print_success "Security scan complete - Score: $SECURITY_SCORE/100"
    
    # Save phase results
    save_phase_results "04" "completed"
    
    # Interactive checkpoint
    checkpoint 4 "Security scan complete. Ready for performance analysis."
    
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
    
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    run_phase_04 "$PLUGIN_NAME"
fi