#!/bin/bash

# Phase 5: Performance Analysis
# Analyzes plugin performance metrics and identifies bottlenecks

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_05() {
    local plugin_name=$1
    
    print_phase 5 "Performance Analysis"
    
    print_info "Analyzing plugin performance metrics..."
    
    # Performance metrics
    PERFORMANCE_REPORT="$SCAN_DIR/reports/performance-report.md"
    
    # Check file sizes
    print_info "Checking file sizes..."
    LARGE_FILES=$(find "$PLUGIN_PATH" -type f -size +100k -name "*.php" 2>/dev/null | wc -l)
    VERY_LARGE_FILES=$(find "$PLUGIN_PATH" -type f -size +500k -name "*.php" 2>/dev/null | wc -l)
    
    # Database query analysis
    print_info "Analyzing database operations..."
    DB_QUERIES=$(grep -r '\$wpdb->' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    DIRECT_QUERIES=$(grep -r '\$wpdb->query' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    PREPARED_QUERIES=$(grep -r '\$wpdb->prepare' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Hook density
    print_info "Analyzing hook density..."
    TOTAL_HOOKS=$(grep -r 'add_action\|add_filter' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    PHP_FILES=$(find "$PLUGIN_PATH" -name "*.php" -type f 2>/dev/null | wc -l)
    HOOKS_PER_FILE=$((PHP_FILES > 0 ? TOTAL_HOOKS / PHP_FILES : 0))
    
    # Caching analysis
    print_info "Checking caching implementation..."
    TRANSIENTS=$(grep -r 'set_transient\|get_transient' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    OBJECT_CACHE=$(grep -r 'wp_cache_' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Calculate performance score
    SCORE=100
    SCORE=$((SCORE - (VERY_LARGE_FILES * 10)))
    SCORE=$((SCORE - (LARGE_FILES * 2)))
    SCORE=$((SCORE - (DIRECT_QUERIES > 50 ? 20 : DIRECT_QUERIES / 5)))
    SCORE=$((TRANSIENTS > 0 || OBJECT_CACHE > 0 ? SCORE + 10 : SCORE))
    SCORE=$((SCORE < 0 ? 0 : SCORE > 100 ? 100 : SCORE))
    
    # Generate report
    cat > "$PERFORMANCE_REPORT" << EOF
# Performance Analysis Report
**Plugin**: $plugin_name  
**Date**: $(date)  
**Score**: $SCORE/100

## File Analysis
- Large files (>100KB): $LARGE_FILES
- Very large files (>500KB): $VERY_LARGE_FILES

## Database Performance
- Total DB operations: $DB_QUERIES
- Direct queries: $DIRECT_QUERIES
- Prepared statements: $PREPARED_QUERIES

## Hook Analysis
- Total hooks: $TOTAL_HOOKS
- Average per file: $HOOKS_PER_FILE

## Caching
- Transients used: $TRANSIENTS
- Object cache calls: $OBJECT_CACHE

## Recommendations
$(if [ $VERY_LARGE_FILES -gt 0 ]; then
    echo "- Split very large files for better performance"
fi)
$(if [ $DIRECT_QUERIES -gt 50 ]; then
    echo "- Optimize database queries, use prepared statements"
fi)
$(if [ $TRANSIENTS -eq 0 ] && [ $OBJECT_CACHE -eq 0 ]; then
    echo "- Implement caching for expensive operations"
fi)
EOF
    
    # AI-Enhanced Performance Analysis
    if [ -f "$MODULES_PATH/shared/ai-integration.sh" ]; then
        source "$MODULES_PATH/shared/ai-integration.sh"
        
        # Save metrics for AI analysis
        METRICS_FILE="$SCAN_DIR/performance-metrics.txt"
        cat > "$METRICS_FILE" << METRICS
Database Queries: $DB_QUERY_COUNT
Direct Queries: $DIRECT_QUERIES
Hook Density: $HOOK_DENSITY
Large Files: $LARGE_FILES
Very Large Files: $VERY_LARGE_FILES
Cache Usage - Transients: $TRANSIENTS
Cache Usage - Object Cache: $OBJECT_CACHE
Memory Estimate: $MEMORY_ESTIMATE MB
Performance Score: $SCORE/100
METRICS
        
        # Generate AI performance analysis prompt for Claude
        handle_deep_analysis 5 "$plugin_name" "performance" "$PLUGIN_PATH" "$SCAN_DIR"
        
        # Process any existing AI responses
        process_existing_analysis_reports "$SCAN_DIR" 5
        
        # Add note about optimization analysis to report
        echo "" >> "$PERFORMANCE_REPORT"
        echo "## Optimization Analysis" >> "$PERFORMANCE_REPORT"
        echo "- Detailed analysis request available in: analysis-requests/phase-5-performance.md" >> "$PERFORMANCE_REPORT"
        echo "- Review for comprehensive optimization strategies" >> "$PERFORMANCE_REPORT"
        echo "- Process results for implementation guidance" >> "$PERFORMANCE_REPORT"
    fi
    
    print_success "Performance analysis complete - Score: $SCORE/100"
    
    # Save phase results
    save_phase_results "05" "completed"
    
    # Interactive checkpoint
    checkpoint 5 "Performance analysis complete. Ready for test generation."
    
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
    
    run_phase_05 "$PLUGIN_NAME"
fi