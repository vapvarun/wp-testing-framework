#!/bin/bash

# Claude Subscription Analysis Tool
# Optimized for claude.ai subscription usage with maximum context utilization

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FRAMEWORK_PATH="$SCRIPT_DIR"
export MODULES_PATH="$FRAMEWORK_PATH/bash-modules"

# Source modules
source "$MODULES_PATH/shared/common-functions.sh"
source "$MODULES_PATH/shared/ai-claude-subscription.sh"

# Configuration
PLUGIN_NAME=${1:-""}
ANALYSIS_MODE=${2:-"interactive"}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show usage
show_usage() {
    cat << EOF
${BLUE}Claude Subscription Analysis Tool${NC}
====================================

Optimized for Claude.ai subscription (not API) with maximum token usage.

USAGE:
    $0 <plugin-name> [mode]

MODES:
    interactive  - Interactive session with command menu (default)
    security     - Generate security analysis prompt
    performance  - Generate performance analysis prompt
    comprehensive - Generate full analysis prompt (recommended)
    test        - Generate test creation prompt
    doc         - Generate documentation prompt
    batch       - Analyze multiple plugins at once
    project     - Setup Claude Project structure

EXAMPLES:
    # Interactive session
    $0 woocommerce

    # Generate comprehensive analysis
    $0 elementor comprehensive

    # Batch analyze all plugins
    $0 all batch

    # Setup Claude Project
    $0 wpforms project

WORKFLOW:
    1. Run this script to generate optimized prompts
    2. Copy the generated prompt from the output file
    3. Paste into claude.ai for analysis
    4. Save Claude's response for processing
    5. Run process-response command to extract insights

FEATURES:
    - Batches multiple files into single prompt
    - Maximizes context window usage
    - Generates structured analysis requests
    - Creates reusable prompt templates
    - Supports Claude Projects workflow

OUTPUT:
    Prompts saved to: ./analysis-templates/
    Sessions saved to: ./analysis-sessions/
    Projects saved to: ./analysis-projects/

EOF
}

# Main execution
main() {
    if [ -z "$PLUGIN_NAME" ] || [ "$PLUGIN_NAME" == "--help" ] || [ "$PLUGIN_NAME" == "-h" ]; then
        show_usage
        exit 0
    fi
    
    # Setup paths
    export WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    
    if [ "$PLUGIN_NAME" != "all" ]; then
        export PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
        
        if [ ! -d "$PLUGIN_PATH" ]; then
            print_error "Plugin not found: $PLUGIN_PATH"
            exit 1
        fi
    fi
    
    export UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    DATE_MONTH=$(date +"%Y-%m")
    export SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Ensure output directories
    ensure_directory "$FRAMEWORK_PATH/analysis-templates"
    ensure_directory "$FRAMEWORK_PATH/analysis-sessions"
    ensure_directory "$FRAMEWORK_PATH/analysis-projects"
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Subscription Analysis Tool        ║${NC}"
    echo -e "${BLUE}║   Optimized for Maximum Token Usage       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    case $ANALYSIS_MODE in
        interactive)
            print_info "Starting interactive Claude session for $PLUGIN_NAME..."
            start_claude_session "$PLUGIN_NAME"
            ;;
            
        security|performance|comprehensive)
            print_info "Generating $ANALYSIS_MODE analysis prompt for $PLUGIN_NAME..."
            OUTPUT_FILE="$FRAMEWORK_PATH/analysis-templates/${PLUGIN_NAME}-${ANALYSIS_MODE}-$(date +%Y%m%d-%H%M%S).md"
            generate_claude_analysis_prompt "$PLUGIN_PATH" "$PLUGIN_NAME" "$ANALYSIS_MODE" "$OUTPUT_FILE"
            
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✅ Prompt Generated Successfully!${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${CYAN}📋 Next Steps:${NC}"
            echo "1. Open the prompt file: $OUTPUT_FILE"
            echo "2. Copy the entire content (it's optimized for Claude's context)"
            echo "3. Go to claude.ai and start a new conversation"
            echo "4. Paste the prompt and wait for analysis"
            echo "5. Save Claude's response to: ${OUTPUT_FILE%.md}-response.md"
            echo ""
            echo -e "${YELLOW}💡 Tip: This prompt uses maximum context for comprehensive analysis${NC}"
            ;;
            
        test)
            print_info "Generating test creation prompt for $PLUGIN_NAME..."
            OUTPUT_FILE="$FRAMEWORK_PATH/analysis-templates/${PLUGIN_NAME}-tests-$(date +%Y%m%d-%H%M%S).md"
            generate_test_prompt "$PLUGIN_PATH" "$OUTPUT_FILE"
            
            echo ""
            echo -e "${GREEN}✅ Test generation prompt created!${NC}"
            echo "📁 File: $OUTPUT_FILE"
            ;;
            
        doc)
            print_info "Generating documentation prompt for $PLUGIN_NAME..."
            OUTPUT_FILE="$FRAMEWORK_PATH/analysis-templates/${PLUGIN_NAME}-docs-$(date +%Y%m%d-%H%M%S).md"
            generate_doc_prompt "$PLUGIN_PATH" "$PLUGIN_NAME" "$OUTPUT_FILE"
            
            echo ""
            echo -e "${GREEN}✅ Documentation prompt created!${NC}"
            echo "📁 File: $OUTPUT_FILE"
            ;;
            
        batch)
            print_info "Generating batch analysis for multiple plugins..."
            generate_batch_analysis
            ;;
            
        project)
            print_info "Setting up Claude Project for $PLUGIN_NAME..."
            setup_claude_project "$PLUGIN_NAME"
            
            echo ""
            echo -e "${GREEN}✅ Claude Project created!${NC}"
            echo ""
            echo -e "${CYAN}📋 To use with Claude Projects:${NC}"
            echo "1. Create a new Project in claude.ai"
            echo "2. Upload the PROJECT_KNOWLEDGE.md file as project knowledge"
            echo "3. Use the prompts in the prompts/ directory"
            echo "4. Save responses in the responses/ directory"
            ;;
            
        process-response)
            if [ -z "$3" ]; then
                echo "Usage: $0 <plugin-name> process-response <response-file>"
                exit 1
            fi
            
            RESPONSE_FILE="$3"
            OUTPUT_DIR="$FRAMEWORK_PATH/claude-analysis/$PLUGIN_NAME-$(date +%Y%m%d-%H%M%S)"
            
            print_info "Processing Claude response..."
            process_claude_response "$RESPONSE_FILE" "$OUTPUT_DIR"
            ;;
            
        *)
            print_error "Unknown mode: $ANALYSIS_MODE"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}💡 Using Claude Subscription Advantages:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo "• No API costs - use subscription"
    echo "• Maximum context window (200K tokens)"
    echo "• Claude Projects for persistent knowledge"
    echo "• Artifacts for code generation"
    echo "• Interactive refinement capability"
    echo ""
}

# Run main
main "$@"