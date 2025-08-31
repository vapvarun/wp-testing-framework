#!/bin/bash

# Process Claude AI Responses
# Integrates Claude's analysis back into the framework reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_PATH="$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_usage() {
    cat << EOF
${BLUE}Process AI Responses Tool${NC}
==========================

Processes Claude responses and integrates them into framework reports.

USAGE:
    $0 <plugin-name> [response-file]
    $0 <plugin-name> auto

OPTIONS:
    plugin-name    Name of the plugin
    response-file  Path to Claude response file
    auto          Auto-detect and process all responses

EXAMPLES:
    # Process specific response
    $0 woocommerce /path/to/claude-response.md

    # Auto-process all responses
    $0 woocommerce auto

WORKFLOW:
    1. Run test-plugin.sh to generate AI prompts
    2. Copy prompts to claude.ai
    3. Save Claude responses
    4. Run this script to process responses

EOF
}

process_response() {
    local response_file=$1
    local output_dir=$2
    local phase_num=$3
    
    echo -e "${CYAN}Processing: $(basename $response_file)${NC}"
    
    # Extract security findings
    if grep -q "CRITICAL\|HIGH\|MEDIUM\|Security" "$response_file" 2>/dev/null; then
        echo "  Extracting security findings..."
        grep -B2 -A5 "CRITICAL\|HIGH" "$response_file" > "$output_dir/security-findings.txt" 2>/dev/null || true
    fi
    
    # Extract performance optimizations
    if grep -q "Performance\|Optimization\|Cache" "$response_file" 2>/dev/null; then
        echo "  Extracting performance optimizations..."
        sed -n '/Performance Analysis/,/## [A-Z]/p' "$response_file" > "$output_dir/performance-optimizations.txt" 2>/dev/null || true
    fi
    
    # Extract code blocks
    echo "  Extracting code fixes..."
    sed -n '/```/,/```/p' "$response_file" | grep -v '```' > "$output_dir/code-fixes.txt" 2>/dev/null || true
    
    # Extract scores and ratings
    echo "  Extracting scores..."
    grep -E "Score:.*[0-9]+|Rating:.*[A-Z]|[0-9]+/100" "$response_file" > "$output_dir/scores.txt" 2>/dev/null || true
    
    # Extract recommendations
    echo "  Extracting recommendations..."
    sed -n '/Recommendations\|Improvements/,/^##/p' "$response_file" > "$output_dir/recommendations.txt" 2>/dev/null || true
    
    # Create summary
    cat > "$output_dir/PROCESSED_SUMMARY.md" << EOF
# Processed AI Response Summary

## Source
- File: $(basename $response_file)
- Processed: $(date)
- Phase: $phase_num

## Extracted Components
$([ -s "$output_dir/security-findings.txt" ] && echo "- ✅ Security findings extracted")
$([ -s "$output_dir/performance-optimizations.txt" ] && echo "- ✅ Performance optimizations extracted")
$([ -s "$output_dir/code-fixes.txt" ] && echo "- ✅ Code fixes extracted")
$([ -s "$output_dir/scores.txt" ] && echo "- ✅ Scores extracted")
$([ -s "$output_dir/recommendations.txt" ] && echo "- ✅ Recommendations extracted")

## Key Findings
$(head -5 "$output_dir/security-findings.txt" 2>/dev/null | sed 's/^/- /')

## Scores
$(cat "$output_dir/scores.txt" 2>/dev/null | sed 's/^/- /')

## Integration Status
- [ ] Review security findings
- [ ] Apply code fixes
- [ ] Implement optimizations
- [ ] Update documentation
EOF
    
    echo -e "  ${GREEN}✅ Processing complete${NC}"
}

# Main execution
main() {
    PLUGIN_NAME=$1
    RESPONSE_ARG=$2
    
    if [ -z "$PLUGIN_NAME" ] || [ "$PLUGIN_NAME" == "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Setup paths
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    if [ ! -d "$SCAN_DIR" ]; then
        echo -e "${RED}Error: No scan directory found for $PLUGIN_NAME${NC}"
        echo "Run test-plugin.sh first to create scan directory"
        exit 1
    fi
    
    AI_PROMPTS_DIR="$SCAN_DIR/ai-prompts"
    AI_PROCESSED_DIR="$SCAN_DIR/ai-processed"
    
    # Ensure directories
    mkdir -p "$AI_PROCESSED_DIR"
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Processing Claude AI Responses          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Plugin: $PLUGIN_NAME"
    echo "Scan Directory: $SCAN_DIR"
    echo ""
    
    if [ "$RESPONSE_ARG" == "auto" ]; then
        # Auto-detect and process all responses
        echo -e "${CYAN}Auto-detecting response files...${NC}"
        
        response_count=0
        for response_file in "$AI_PROMPTS_DIR"/*-response.md; do
            if [ -f "$response_file" ]; then
                response_count=$((response_count + 1))
                
                # Extract phase number from filename
                phase_num=$(echo "$(basename $response_file)" | grep -oE 'phase-[0-9]+' | grep -oE '[0-9]+')
                
                # Create output directory for this response
                response_name=$(basename "$response_file" .md)
                output_dir="$AI_PROCESSED_DIR/$response_name"
                mkdir -p "$output_dir"
                
                # Process the response
                process_response "$response_file" "$output_dir" "$phase_num"
            fi
        done
        
        if [ $response_count -eq 0 ]; then
            echo -e "${YELLOW}No response files found in $AI_PROMPTS_DIR${NC}"
            echo "Save Claude responses as *-response.md files"
        else
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✅ Processed $response_count response files${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
        fi
        
    elif [ -f "$RESPONSE_ARG" ]; then
        # Process specific file
        response_name=$(basename "$RESPONSE_ARG" .md)
        output_dir="$AI_PROCESSED_DIR/$response_name"
        mkdir -p "$output_dir"
        
        # Try to extract phase number
        phase_num=$(echo "$response_name" | grep -oE 'phase-[0-9]+' | grep -oE '[0-9]+' || echo "unknown")
        
        process_response "$RESPONSE_ARG" "$output_dir" "$phase_num"
        
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ Response processed successfully${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
        
    else
        echo -e "${RED}Error: Response file not found: $RESPONSE_ARG${NC}"
        exit 1
    fi
    
    # Update main reports with AI insights
    echo ""
    echo -e "${CYAN}Updating framework reports with AI insights...${NC}"
    
    # Update FINAL-REPORT if it exists
    if [ -f "$SCAN_DIR/FINAL-REPORT.md" ]; then
        if [ ! -grep -q "## AI Analysis Results" "$SCAN_DIR/FINAL-REPORT.md" ]; then
            echo "" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "## AI Analysis Results" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "Claude AI analysis has been processed. Results available in:" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "- Security findings: ai-processed/*/security-findings.txt" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "- Performance optimizations: ai-processed/*/performance-optimizations.txt" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "- Code fixes: ai-processed/*/code-fixes.txt" >> "$SCAN_DIR/FINAL-REPORT.md"
            echo "- Recommendations: ai-processed/*/recommendations.txt" >> "$SCAN_DIR/FINAL-REPORT.md"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📁 Processed files saved to:${NC}"
    echo "$AI_PROCESSED_DIR"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Review extracted findings in ai-processed/"
    echo "2. Apply code fixes from code-fixes.txt"
    echo "3. Implement recommendations"
    echo "4. Re-run affected phases to verify fixes"
    echo ""
}

main "$@"