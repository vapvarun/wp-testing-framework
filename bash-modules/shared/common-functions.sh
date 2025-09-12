#!/bin/bash

# WordPress Plugin Testing Framework - Common Functions
# Shared utilities used by all phase modules

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Configuration defaults
export TIMEOUT_LONG=300  # 5 minutes for long operations
export TIMEOUT_SHORT=60  # 1 minute for quick operations
export BATCH_SIZE=100    # Process files in batches for large plugins

# Function to display phase header
print_phase() {
    local phase_num=$1
    local phase_name=$2
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}PHASE $phase_num: $phase_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to show success message
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to show info message
print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to show warning message
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to show error message
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Print subsection header
print_subsection() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
}

# Function for interactive checkpoint
checkpoint() {
    local phase=$1
    local description=$2
    
    if [ "$INTERACTIVE_MODE" = "true" ] && [ "$SKIP_INTERACTIVE" != "true" ]; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}🔄 Checkpoint: Phase $phase${NC}"
        echo -e "${CYAN}Description: $description${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        echo ""
        echo "Options:"
        echo "  [Enter] - Continue to next phase"
        echo "  [s]     - Skip remaining phases"
        echo "  [r]     - Review current results"
        echo "  [q]     - Quit"
        
        read -p "Your choice: " choice
        
        case "$choice" in
            s|S)
                echo "Skipping remaining phases..."
                exit 0
                ;;
            r|R)
                echo "Current results location: $SCAN_DIR"
                if [ -d "$SCAN_DIR/reports" ]; then
                    ls -la "$SCAN_DIR/reports/"
                fi
                read -p "Press Enter to continue..." 
                ;;
            q|Q)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Continuing..."
                ;;
        esac
    fi
}

# Function to show progress spinner
show_progress() {
    local pid=$1
    local task=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}⏳ %s... %c${NC}" "$task" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${GREEN}✅ %s complete    ${NC}\n" "$task"
}

# Function to ensure directory exists
ensure_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run command with timeout
run_with_timeout() {
    local timeout=$1
    shift
    timeout "$timeout" "$@"
}

# Function to save phase results
save_phase_results() {
    local phase=$1
    local status=$2
    local results_file="$SCAN_DIR/phase-results/phase-${phase}.json"
    
    ensure_directory "$SCAN_DIR/phase-results"
    
    cat > "$results_file" << EOF
{
    "phase": "$phase",
    "status": "$status",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "plugin": "$PLUGIN_NAME"
}
EOF
}

# Function to load phase results
load_phase_results() {
    local phase=$1
    local results_file="$SCAN_DIR/phase-results/phase-${phase}.json"
    
    if [ -f "$results_file" ]; then
        cat "$results_file"
    else
        echo "{}"
    fi
}

# Function to check WordPress CLI
check_wp_cli() {
    if command_exists wp; then
        export WP_CLI_AVAILABLE=true
        print_success "WP-CLI detected"
    else
        export WP_CLI_AVAILABLE=false
        print_warning "WP-CLI not found - some features will be limited"
    fi
}

# Function to check Node.js
check_nodejs() {
    if command_exists node; then
        export NODE_AVAILABLE=true
        NODE_VERSION=$(node -v)
        print_success "Node.js detected: $NODE_VERSION"
    else
        export NODE_AVAILABLE=false
        print_warning "Node.js not found - AI and AST features will be limited"
    fi
}

# Function to check PHP
check_php() {
    if command_exists php; then
        export PHP_AVAILABLE=true
        PHP_VERSION=$(php -v | head -n 1)
        print_success "PHP detected: $PHP_VERSION"
    else
        export PHP_AVAILABLE=false
        print_error "PHP not found - cannot continue"
        exit 1
    fi
}

# Function to validate plugin exists
validate_plugin() {
    if [ ! -d "$PLUGIN_PATH" ]; then
        print_error "Plugin directory not found: $PLUGIN_PATH"
        exit 1
    fi
    
    # Check for main plugin file
    if ! ls "$PLUGIN_PATH"/*.php >/dev/null 2>&1; then
        print_error "No PHP files found in plugin directory"
        exit 1
    fi
    
    print_success "Plugin validated: $PLUGIN_NAME"
}

# Function to get plugin metadata
get_plugin_metadata() {
    local main_file=$(find "$PLUGIN_PATH" -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:" {} \; | head -1)
    
    if [ -n "$main_file" ]; then
        PLUGIN_VERSION=$(grep -oP 'Version:\s*\K[^\s]+' "$main_file" 2>/dev/null || echo "Unknown")
        PLUGIN_AUTHOR=$(grep -oP 'Author:\s*\K[^\n]+' "$main_file" 2>/dev/null || echo "Unknown")
        PLUGIN_DESCRIPTION=$(grep -oP 'Description:\s*\K[^\n]+' "$main_file" 2>/dev/null || echo "")
    fi
}

# Function to count files by type
count_files() {
    local path=$1
    local extension=$2
    find "$path" -name "*.$extension" -type f 2>/dev/null | wc -l
}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -gt 1048576 ]; then
        echo "$(( size / 1048576 ))MB"
    elif [ $size -gt 1024 ]; then
        echo "$(( size / 1024 ))KB"
    else
        echo "${size}B"
    fi
}

# Export all functions
export -f print_phase
export -f print_success
export -f print_info
export -f print_warning
export -f print_error
export -f checkpoint
export -f show_progress
export -f ensure_directory
export -f command_exists
export -f run_with_timeout
export -f save_phase_results
export -f load_phase_results
export -f check_wp_cli
export -f check_nodejs
export -f check_php
export -f validate_plugin
export -f get_plugin_metadata
export -f count_files
export -f format_size