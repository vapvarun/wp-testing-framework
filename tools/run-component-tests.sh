#!/bin/bash

# BuddyPress Component Test Runner
# Run tests for specific BuddyPress components

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
COMPONENT=""
TEST_TYPE="all"
COVERAGE=false
VERBOSE=false

# Show help
show_help() {
    echo "BuddyPress Component Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --component COMPONENT    Test specific component (core, members, xprofile, activity, groups, friends, messages, notifications, settings, blogs)"
    echo "  -t, --type TYPE             Test type (unit, integration, functional, e2e, all)"
    echo "  -g, --group GROUP           Test component group (critical, social, management)"
    echo "  --coverage                  Generate code coverage report"
    echo "  -v, --verbose              Show detailed output"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c members              # Run all tests for Members component"
    echo "  $0 -c activity -t unit     # Run only unit tests for Activity component"
    echo "  $0 -g critical             # Run tests for critical components (Core + Members)"
    echo "  $0 -c groups --coverage    # Run Groups tests with coverage report"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--component)
            COMPONENT="$2"
            shift 2
            ;;
        -t|--type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -g|--group)
            GROUP="$2"
            shift 2
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to run tests
run_tests() {
    local suite=$1
    local name=$2
    
    echo -e "${BLUE}🧪 Running $name tests...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    CMD="vendor/bin/phpunit -c phpunit-components.xml --testsuite $suite"
    
    if [ "$VERBOSE" = true ]; then
        CMD="$CMD --verbose"
    fi
    
    if [ "$COVERAGE" = true ]; then
        CMD="$CMD --coverage-html coverage/$suite --coverage-text"
    fi
    
    if $CMD; then
        echo -e "${GREEN}✅ $name tests passed!${NC}"
    else
        echo -e "${RED}❌ $name tests failed!${NC}"
        exit 1
    fi
    echo ""
}

# Function to run E2E tests
run_e2e_tests() {
    local component=$1
    
    echo -e "${BLUE}🌐 Running E2E tests for $component...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if npm run test:e2e -- --grep "$component"; then
        echo -e "${GREEN}✅ E2E tests passed!${NC}"
    else
        echo -e "${RED}❌ E2E tests failed!${NC}"
        exit 1
    fi
    echo ""
}

# Main execution
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   BuddyPress Component Testing Suite     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Run group tests
if [ ! -z "$GROUP" ]; then
    case $GROUP in
        critical)
            echo -e "${YELLOW}Testing Critical Components (Core + Members)${NC}"
            run_tests "critical-components" "Critical Components"
            ;;
        social)
            echo -e "${YELLOW}Testing Social Components (Friends + Messages + Activity)${NC}"
            run_tests "social-components" "Social Components"
            ;;
        management)
            echo -e "${YELLOW}Testing Management Components (Groups + Notifications + Settings)${NC}"
            run_tests "management-components" "Management Components"
            ;;
        *)
            echo -e "${RED}Unknown group: $GROUP${NC}"
            exit 1
            ;;
    esac
    exit 0
fi

# Run component-specific tests
if [ ! -z "$COMPONENT" ]; then
    # Validate component
    case $COMPONENT in
        core|members|xprofile|activity|groups|friends|messages|notifications|settings|blogs)
            ;;
        *)
            echo -e "${RED}Unknown component: $COMPONENT${NC}"
            echo "Valid components: core, members, xprofile, activity, groups, friends, messages, notifications, settings, blogs"
            exit 1
            ;;
    esac
    
    # Component display names
    declare -A COMPONENT_NAMES=(
        ["core"]="Core"
        ["members"]="Members"
        ["xprofile"]="Extended Profiles"
        ["activity"]="Activity Streams"
        ["groups"]="Groups"
        ["friends"]="Friends"
        ["messages"]="Messages"
        ["notifications"]="Notifications"
        ["settings"]="Settings"
        ["blogs"]="Site Tracking"
    )
    
    DISPLAY_NAME=${COMPONENT_NAMES[$COMPONENT]}
    echo -e "${YELLOW}Testing $DISPLAY_NAME Component${NC}"
    echo ""
    
    case $TEST_TYPE in
        unit)
            echo -e "${BLUE}Running Unit Tests Only${NC}"
            vendor/bin/phpunit tests/phpunit/Components/${COMPONENT^}/Unit/
            ;;
        integration)
            echo -e "${BLUE}Running Integration Tests Only${NC}"
            vendor/bin/phpunit tests/phpunit/Components/${COMPONENT^}/Integration/
            ;;
        functional)
            echo -e "${BLUE}Running Functional Tests Only${NC}"
            vendor/bin/phpunit tests/phpunit/Components/${COMPONENT^}/Functional/
            ;;
        e2e)
            run_e2e_tests "$DISPLAY_NAME"
            ;;
        all)
            run_tests "${COMPONENT}-component" "$DISPLAY_NAME"
            if [ "$COMPONENT" != "core" ] && [ "$COMPONENT" != "blogs" ]; then
                run_e2e_tests "$DISPLAY_NAME"
            fi
            ;;
        *)
            echo -e "${RED}Unknown test type: $TEST_TYPE${NC}"
            exit 1
            ;;
    esac
else
    # Run all component tests
    echo -e "${YELLOW}Running ALL Component Tests${NC}"
    echo ""
    run_tests "all-components" "All Components"
fi

# Show coverage report location
if [ "$COVERAGE" = true ]; then
    echo -e "${GREEN}📊 Coverage report generated in coverage/ directory${NC}"
    echo -e "${BLUE}Open coverage/index.html in your browser to view the report${NC}"
fi

echo ""
echo -e "${GREEN}✨ Testing complete!${NC}"