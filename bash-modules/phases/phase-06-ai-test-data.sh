#!/bin/bash

# Phase 6: AI-Driven Intelligent Test Data Generation
# Analyzes plugin's database patterns and generates contextual test data

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_06() {
    local plugin_name=$1
    
    print_phase 6 "AI-Driven Test Data Generation"
    
    print_info "Analyzing plugin database patterns for intelligent test data generation..."
    
    # Initialize paths
    TEST_DATA_DIR="$SCAN_DIR/test-data"
    ensure_directory "$TEST_DATA_DIR"
    
    # Collect all available data for AI analysis
    print_info "Gathering plugin intelligence..."
    
    # 1. Analyze Database Tables
    print_info "Analyzing database structure..."
    DB_ANALYSIS_FILE="$TEST_DATA_DIR/database-analysis.txt"
    
    # Check for custom tables
    if command_exists wp && [ -n "$WP_PATH" ]; then
        wp db query "SHOW TABLES;" --path="$WP_PATH" 2>/dev/null > "$DB_ANALYSIS_FILE"
        
        # Look for plugin-specific tables
        CUSTOM_TABLES=$(grep -i "$plugin_name\|${plugin_name//-/_}" "$DB_ANALYSIS_FILE" 2>/dev/null || echo "")
        
        # Analyze table structures
        if [ -n "$CUSTOM_TABLES" ]; then
            echo "=== CUSTOM TABLES FOUND ===" >> "$DB_ANALYSIS_FILE"
            for table in $CUSTOM_TABLES; do
                echo "Table: $table" >> "$DB_ANALYSIS_FILE"
                wp db query "DESCRIBE $table;" --path="$WP_PATH" 2>/dev/null >> "$DB_ANALYSIS_FILE"
                wp db query "SELECT COUNT(*) as count FROM $table;" --path="$WP_PATH" 2>/dev/null >> "$DB_ANALYSIS_FILE"
            done
        fi
    fi
    
    # 2. Analyze Database Queries in Code
    print_info "Analyzing database query patterns..."
    DB_QUERIES_FILE="$TEST_DATA_DIR/db-queries.txt"
    
    # Extract all database queries from plugin code
    {
        echo "=== WPDB QUERIES ==="
        grep -r "\$wpdb->" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | head -50
        
        echo -e "\n=== INSERT QUERIES ==="
        grep -r "INSERT INTO\|insert(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | head -20
        
        echo -e "\n=== UPDATE QUERIES ==="
        grep -r "UPDATE \|update(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | head -20
        
        echo -e "\n=== CREATE TABLE QUERIES ==="
        grep -r "CREATE TABLE\|dbDelta" "$PLUGIN_PATH" --include="*.php" 2>/dev/null
        
        echo -e "\n=== CUSTOM QUERIES ==="
        grep -r "prepare(\|query(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | head -30
    } > "$DB_QUERIES_FILE"
    
    # 3. Analyze Meta Operations
    print_info "Analyzing meta data patterns..."
    META_PATTERNS_FILE="$TEST_DATA_DIR/meta-patterns.txt"
    
    {
        echo "=== POST META ==="
        grep -r "add_post_meta\|update_post_meta\|get_post_meta" "$PLUGIN_PATH" --include="*.php" | head -20
        
        echo -e "\n=== USER META ==="
        grep -r "add_user_meta\|update_user_meta\|get_user_meta" "$PLUGIN_PATH" --include="*.php" | head -20
        
        echo -e "\n=== TERM META ==="
        grep -r "add_term_meta\|update_term_meta\|get_term_meta" "$PLUGIN_PATH" --include="*.php" | head -20
        
        echo -e "\n=== OPTIONS ==="
        grep -r "add_option\|update_option\|get_option" "$PLUGIN_PATH" --include="*.php" | head -20
        
        echo -e "\n=== TRANSIENTS ==="
        grep -r "set_transient\|get_transient" "$PLUGIN_PATH" --include="*.php" | head -20
    } > "$META_PATTERNS_FILE"
    
    # 4. Analyze Form Fields and Input Types
    print_info "Analyzing form fields and data types..."
    FORM_FIELDS_FILE="$TEST_DATA_DIR/form-fields.txt"
    
    {
        echo "=== INPUT FIELDS ==="
        grep -r "<input\|<textarea\|<select" "$PLUGIN_PATH" --include="*.php" | grep -E "name=|id=" | head -30
        
        echo -e "\n=== NONCE FIELDS ==="
        grep -r "wp_nonce_field\|wp_create_nonce" "$PLUGIN_PATH" --include="*.php" | head -20
        
        echo -e "\n=== AJAX DATA ==="
        grep -r "data:\|FormData\|serialize(" "$PLUGIN_PATH" --include="*.js" --include="*.php" | head -20
    } > "$FORM_FIELDS_FILE"
    
    # 5. Load existing analysis data
    FEATURES_DATA=""
    AST_DATA=""
    
    if [ -f "$SCAN_DIR/extracted-features.json" ] && command_exists jq; then
        FEATURES_DATA=$(cat "$SCAN_DIR/extracted-features.json")
        CPTS=$(echo "$FEATURES_DATA" | jq -r '.custom_post_types[].name // empty' 2>/dev/null)
        SHORTCODES=$(echo "$FEATURES_DATA" | jq -r '.shortcodes[].tag // empty' 2>/dev/null)
        AJAX_HANDLERS=$(echo "$FEATURES_DATA" | jq -r '.ajax_handlers[].handler // empty' 2>/dev/null)
    fi
    
    if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && command_exists jq; then
        AST_DATA=$(jq '.total' "$SCAN_DIR/wordpress-ast-analysis.json" 2>/dev/null)
    fi
    
    # 6. Detect Plugin Type and Patterns
    print_info "Detecting plugin type and patterns..."
    PLUGIN_TYPE="generic"
    PLUGIN_PATTERNS=()
    
    # E-commerce detection
    if grep -q "add_to_cart\|checkout\|payment\|order\|product\|price\|shipping" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="ecommerce"
        PLUGIN_PATTERNS+=("products" "orders" "customers" "payments")
    fi
    
    # Forum/Community detection
    if grep -q "forum\|topic\|reply\|thread\|bbpress\|buddypress" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="forum"
        PLUGIN_PATTERNS+=("forums" "topics" "replies" "users")
    fi
    
    # Form/Contact detection
    if grep -q "contact_form\|form_submit\|form_field\|mail\|smtp" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="forms"
        PLUGIN_PATTERNS+=("form_submissions" "form_fields" "email_logs")
    fi
    
    # Membership/Subscription detection
    if grep -q "membership\|subscription\|member\|restrict\|access" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="membership"
        PLUGIN_PATTERNS+=("members" "subscriptions" "access_levels")
    fi
    
    # LMS/Education detection
    if grep -q "course\|lesson\|quiz\|student\|enrollment" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="lms"
        PLUGIN_PATTERNS+=("courses" "lessons" "enrollments" "grades")
    fi
    
    # Events/Calendar detection
    if grep -q "event\|calendar\|booking\|appointment\|schedule" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="events"
        PLUGIN_PATTERNS+=("events" "bookings" "attendees")
    fi
    
    # Gallery/Media detection
    if grep -q "gallery\|album\|image\|media\|slideshow" "$PLUGIN_PATH"/*.php 2>/dev/null; then
        PLUGIN_TYPE="media"
        PLUGIN_PATTERNS+=("galleries" "albums" "media_items")
    fi
    
    print_success "Detected plugin type: $PLUGIN_TYPE"
    
    # 7. Generate AI Prompt for Test Data
    print_info "Creating AI prompt for intelligent test data generation..."
    
    AI_TEST_DATA_PROMPT="$SCAN_DIR/analysis-requests/phase-6-ai-test-data.md"
    ensure_directory "$(dirname "$AI_TEST_DATA_PROMPT")"
    
    cat > "$AI_TEST_DATA_PROMPT" << 'EOF'
# AI Test Data Generation Request

You are analyzing a WordPress plugin to generate appropriate test data. Based on the plugin's database patterns, code analysis, and functionality, generate SQL queries and WP-CLI commands to create realistic test data.

## Plugin Information
EOF
    
    cat >> "$AI_TEST_DATA_PROMPT" << EOF
- **Plugin Name**: $plugin_name
- **Detected Type**: $PLUGIN_TYPE
- **Patterns Found**: ${PLUGIN_PATTERNS[@]}

## Database Analysis

### Custom Tables Found
\`\`\`
$(cat "$DB_ANALYSIS_FILE" 2>/dev/null | head -100)
\`\`\`

### Database Query Patterns
\`\`\`php
$(cat "$DB_QUERIES_FILE" 2>/dev/null | head -100)
\`\`\`

### Meta Data Patterns
\`\`\`php
$(cat "$META_PATTERNS_FILE" 2>/dev/null | head -100)
\`\`\`

### Form Fields and Input Types
\`\`\`html
$(cat "$FORM_FIELDS_FILE" 2>/dev/null | head -50)
\`\`\`

## Extracted Features

### Custom Post Types
$(if [ -n "$CPTS" ]; then echo "$CPTS"; else echo "None detected"; fi)

### Shortcodes
$(if [ -n "$SHORTCODES" ]; then echo "$SHORTCODES"; else echo "None detected"; fi)

### AJAX Handlers
$(if [ -n "$AJAX_HANDLERS" ]; then echo "$AJAX_HANDLERS"; else echo "None detected"; fi)

## WordPress Patterns (from AST)
\`\`\`json
$AST_DATA
\`\`\`

## Test Data Generation Requirements

Based on the above analysis, generate:

1. **SQL Queries** for:
   - Inserting test data into custom tables (if any)
   - Creating test posts/pages with appropriate meta data
   - Setting up test options and transients
   - Creating relationships between data

2. **WP-CLI Commands** for:
   - Creating test users with appropriate roles and capabilities
   - Creating test posts for each custom post type
   - Creating test pages with shortcodes
   - Setting up test taxonomies and terms
   - Configuring plugin settings

3. **Test Scenarios** based on plugin type:
EOF
    
    # Add type-specific test scenarios
    case "$PLUGIN_TYPE" in
        "ecommerce")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create test products with variations
   - Create test orders in different statuses
   - Create test customers with order history
   - Set up payment methods and shipping zones
   - Create coupons and discounts
EOF
            ;;
        "forum")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create forum categories and forums
   - Create topics with various statuses (open, closed, sticky)
   - Create replies and nested discussions
   - Set up user roles and permissions
   - Create private and hidden forums
EOF
            ;;
        "forms")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create different form types
   - Submit test form entries
   - Set up email notifications
   - Create conditional logic scenarios
   - Test file uploads and validations
EOF
            ;;
        "membership")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create membership levels
   - Create test members with different subscriptions
   - Set up restricted content
   - Create payment history
   - Test access controls
EOF
            ;;
        "lms")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create courses with modules and lessons
   - Enroll students in courses
   - Create quizzes and assignments
   - Generate progress data
   - Set up certificates and badges
EOF
            ;;
        "events")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create events with different dates and venues
   - Create bookings and registrations
   - Set up recurring events
   - Create event categories
   - Generate attendee lists
EOF
            ;;
        "media")
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create galleries and albums
   - Upload test images with metadata
   - Create slideshows
   - Set up image categories
   - Test media permissions
EOF
            ;;
        *)
            cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'
   - Create test content for all custom post types
   - Test all shortcodes with various parameters
   - Create test data for all database tables
   - Set up user roles and capabilities
   - Test all AJAX endpoints
EOF
            ;;
    esac
    
    cat >> "$AI_TEST_DATA_PROMPT" << 'EOF'

4. **Data Relationships**:
   - Identify foreign key relationships
   - Create parent-child hierarchies
   - Set up many-to-many relationships
   - Ensure referential integrity

5. **Edge Cases**:
   - Maximum field lengths
   - Special characters in text fields
   - Boundary values for numeric fields
   - Empty/null values where allowed
   - Large datasets for performance testing

## Expected Output Format

Provide the test data generation in this format:

### 1. SQL Queries
```sql
-- Custom table inserts
INSERT INTO wp_plugin_table (column1, column2) VALUES ('test1', 'value1');

-- Meta data
INSERT INTO wp_postmeta (post_id, meta_key, meta_value) VALUES (1, '_plugin_key', 'test_value');
```

### 2. WP-CLI Commands
```bash
# Create test users
wp user create test_admin admin@test.local --role=administrator --user_pass=Test@2024

# Create custom post type content
wp post create --post_type=custom_type --post_title="Test Title" --post_status=publish
```

### 3. PHP Code for Complex Data
```php
// For complex data structures
$test_data = array(
    'field1' => 'value1',
    'nested' => array(...)
);
update_option('plugin_settings', $test_data);
```

### 4. Test Data Manifest
Provide a JSON structure describing all created test data with IDs and relationships.

## Important Considerations

1. **Data Safety**: Ensure all test data is clearly marked and easily removable
2. **Realistic Values**: Use realistic data that would actually test the plugin
3. **Performance**: Create enough data to test performance but not overwhelm
4. **Relationships**: Maintain proper relationships between entities
5. **Plugin State**: Set up the plugin in various states (active, configured, edge cases)

Generate comprehensive test data that will thoroughly exercise all aspects of this plugin.
EOF
    
    print_success "AI test data prompt generated: $AI_TEST_DATA_PROMPT"
    
    # 8. Generate basic test data while waiting for AI
    print_info "Generating basic test data structure..."
    
    BASIC_TEST_SQL="$TEST_DATA_DIR/basic-test.sql"
    cat > "$BASIC_TEST_SQL" << EOF
-- Basic Test Data for $plugin_name
-- Generated: $(date)

-- Test Users
INSERT INTO wp_users (user_login, user_email, user_pass, display_name) VALUES
('test_admin_$plugin_name', 'admin@test.local', MD5('Test@2024'), 'Test Admin'),
('test_user_$plugin_name', 'user@test.local', MD5('Test@2024'), 'Test User');

-- Plugin Options (if needed)
INSERT INTO wp_options (option_name, option_value, autoload) VALUES
('${plugin_name}_test_mode', '1', 'yes'),
('${plugin_name}_test_data', 'a:1:{s:4:"test";b:1;}', 'yes');
EOF
    
    # Add CPT-specific test data if detected
    if [ -n "$CPTS" ]; then
        echo -e "\n-- Custom Post Type Test Data" >> "$BASIC_TEST_SQL"
        for cpt in $CPTS; do
            cat >> "$BASIC_TEST_SQL" << EOF
INSERT INTO wp_posts (post_type, post_title, post_content, post_status, post_author) VALUES
('$cpt', 'Test $cpt 1', 'Test content for $cpt post type', 'publish', 1),
('$cpt', 'Test $cpt 2', 'Another test for $cpt post type', 'publish', 1);
EOF
        done
    fi
    
    # 9. Create test data execution script
    TEST_EXEC_SCRIPT="$TEST_DATA_DIR/execute-test-data.sh"
    cat > "$TEST_EXEC_SCRIPT" << 'EOF'
#!/bin/bash
# Execute test data for plugin

PLUGIN_NAME="$1"
WP_PATH="$2"

echo "Executing test data for $PLUGIN_NAME..."

# Check if WP-CLI is available
if command -v wp &> /dev/null && [ -n "$WP_PATH" ]; then
    # Execute SQL if exists
    if [ -f "test-data.sql" ]; then
        wp db query < test-data.sql --path="$WP_PATH"
    fi
    
    # Execute WP-CLI commands if exists
    if [ -f "wp-cli-commands.txt" ]; then
        while IFS= read -r cmd; do
            eval "$cmd --path=$WP_PATH"
        done < wp-cli-commands.txt
    fi
else
    echo "WP-CLI not available, using direct SQL..."
    mysql -u root wordpress < test-data.sql
fi

echo "Test data execution complete!"
EOF
    chmod +x "$TEST_EXEC_SCRIPT"
    
    # 10. Generate test data report
    TEST_DATA_REPORT="$SCAN_DIR/reports/test-data-generation-report.md"
    cat > "$TEST_DATA_REPORT" << EOF
# Test Data Generation Report
**Plugin**: $plugin_name  
**Date**: $(date)  
**Plugin Type**: $PLUGIN_TYPE

## Analysis Summary
- Custom Tables: $(echo "$CUSTOM_TABLES" | wc -w)
- Database Queries Found: $(grep -c "\$wpdb->" "$DB_QUERIES_FILE" 2>/dev/null || echo 0)
- Meta Operations: $(grep -c "_meta" "$META_PATTERNS_FILE" 2>/dev/null || echo 0)
- Form Fields: $(grep -c "<input" "$FORM_FIELDS_FILE" 2>/dev/null || echo 0)

## Detected Patterns
$(for pattern in "${PLUGIN_PATTERNS[@]}"; do echo "- $pattern"; done)

## Custom Post Types
$(if [ -n "$CPTS" ]; then echo "$CPTS" | sed 's/^/- /'; else echo "None detected"; fi)

## Shortcodes
$(if [ -n "$SHORTCODES" ]; then echo "$SHORTCODES" | sed 's/^/- /'; else echo "None detected"; fi)

## AI Test Data Generation
- Prompt Location: $AI_TEST_DATA_PROMPT
- Basic SQL: $BASIC_TEST_SQL
- Execution Script: $TEST_EXEC_SCRIPT

## Recommendations
1. Review the AI prompt and provide to Claude/GPT for comprehensive test data
2. Execute the generated SQL queries in a test environment
3. Verify all plugin features work with the test data
4. Use the test data for visual and integration testing

## Files Generated
- Database Analysis: $DB_ANALYSIS_FILE
- Query Patterns: $DB_QUERIES_FILE
- Meta Patterns: $META_PATTERNS_FILE
- Form Fields: $FORM_FIELDS_FILE
- AI Prompt: $AI_TEST_DATA_PROMPT
- Basic Test SQL: $BASIC_TEST_SQL
- Execution Script: $TEST_EXEC_SCRIPT
EOF
    
    print_success "Test data generation analysis complete"
    print_info "AI prompt ready at: $AI_TEST_DATA_PROMPT"
    
    # Show prompt for AI analysis
    echo ""
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "📋 AI Test Data Generation Prompt Ready"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Type: Intelligent Test Data Generation"
    echo "Plugin Type: $PLUGIN_TYPE"
    echo "File: $AI_TEST_DATA_PROMPT"
    echo ""
    echo "To generate comprehensive test data:"
    echo "1. Open: $AI_TEST_DATA_PROMPT"
    echo "2. Copy entire content"
    echo "3. Paste into Claude/ChatGPT"
    echo "4. Save generated SQL and commands to: $TEST_DATA_DIR/"
    echo "5. Execute using: $TEST_EXEC_SCRIPT"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return 0
}