#!/bin/bash

# Phase 7b: Test Data Creation
# Creates test content that will be used by visual testing and live testing phases

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_07b() {
    local plugin_name=$1
    
    print_phase "7b" "Test Data Creation"
    
    print_info "Creating test data for comprehensive testing..."
    
    # Test data manifest file
    TEST_DATA_FILE="$SCAN_DIR/test-data-manifest.json"
    
    # Initialize test data JSON
    cat > "$TEST_DATA_FILE" << EOF
{
    "plugin": "$plugin_name",
    "created_at": "$(date -Iseconds)",
    "users": [],
    "posts": [],
    "pages": [],
    "custom_posts": [],
    "shortcode_pages": [],
    "admin_pages": [],
    "test_urls": []
}
EOF
    
    # Check if we have extracted features to work with
    FEATURES_FILE="$SCAN_DIR/extracted-features.json"
    HAS_FEATURES=false
    if [ -f "$FEATURES_FILE" ] && command_exists jq; then
        HAS_FEATURES=true
    fi
    
    # Check WP-CLI availability
    WP_CLI_AVAILABLE=false
    if command_exists wp && [ -n "$WP_PATH" ]; then
        if wp core is-installed --path="$WP_PATH" 2>/dev/null; then
            WP_CLI_AVAILABLE=true
        fi
    fi
    
    if [ "$WP_CLI_AVAILABLE" = "true" ]; then
        print_info "Using WP-CLI to create test data..."
        
        # Create test users
        print_info "Creating test users..."
        USERS_CREATED=()
        
        for role in administrator editor author subscriber; do
            username="test_${role}_${plugin_name}"
            email="${username}@test.local"
            
            # Check if user exists
            if ! wp user get "$username" --path="$WP_PATH" &>/dev/null; then
                USER_ID=$(wp user create "$username" "$email" \
                    --role="$role" \
                    --user_pass="Test@2024!" \
                    --path="$WP_PATH" \
                    --porcelain 2>/dev/null || echo "0")
                
                if [ "$USER_ID" != "0" ]; then
                    USERS_CREATED+=("{\"id\":$USER_ID,\"username\":\"$username\",\"role\":\"$role\"}")
                    print_success "Created test user: $username (ID: $USER_ID)"
                fi
            else
                USER_ID=$(wp user get "$username" --field=ID --path="$WP_PATH" 2>/dev/null)
                USERS_CREATED+=("{\"id\":$USER_ID,\"username\":\"$username\",\"role\":\"$role\"}")
                print_info "User exists: $username (ID: $USER_ID)"
            fi
        done
        
        # Extract shortcodes from features
        SHORTCODES=()
        if [ "$HAS_FEATURES" = "true" ]; then
            SHORTCODES=($(jq -r '.shortcodes[].tag // empty' "$FEATURES_FILE" 2>/dev/null))
        fi
        
        # Also check for shortcodes in detection results
        if [ ${#SHORTCODES[@]} -eq 0 ]; then
            SHORTCODES_FILE="$SCAN_DIR/raw-outputs/detected-shortcodes.txt"
            if [ -f "$SHORTCODES_FILE" ] && [ -s "$SHORTCODES_FILE" ]; then
                mapfile -t SHORTCODES < "$SHORTCODES_FILE"
            fi
        fi
        
        # Add plugin-specific shortcodes if known
        case "$plugin_name" in
            "bbpress")
                # bbPress specific shortcodes
                BBPRESS_SHORTCODES=("bbp-forum-index" "bbp-forum-form" "bbp-single-forum" 
                                   "bbp-topic-index" "bbp-topic-form" "bbp-single-topic"
                                   "bbp-reply-form" "bbp-single-reply" "bbp-login" "bbp-register"
                                   "bbp-lost-pass" "bbp-stats")
                for sc in "${BBPRESS_SHORTCODES[@]}"; do
                    if [[ ! " ${SHORTCODES[@]} " =~ " ${sc} " ]]; then
                        SHORTCODES+=("$sc")
                    fi
                done
                ;;
            "woocommerce")
                # WooCommerce shortcodes
                WOO_SHORTCODES=("products" "product" "add_to_cart" "product_page"
                               "product_category" "sale_products" "best_selling_products"
                               "recent_products" "featured_products" "woocommerce_cart"
                               "woocommerce_checkout" "woocommerce_my_account")
                for sc in "${WOO_SHORTCODES[@]}"; do
                    if [[ ! " ${SHORTCODES[@]} " =~ " ${sc} " ]]; then
                        SHORTCODES+=("$sc")
                    fi
                done
                ;;
        esac
        
        # Create test pages for shortcodes
        SHORTCODE_PAGES=()
        if [ ${#SHORTCODES[@]} -gt 0 ]; then
            print_info "Creating test pages for ${#SHORTCODES[@]} shortcodes..."
            
            for shortcode in "${SHORTCODES[@]}"; do
                if [ -n "$shortcode" ]; then
                    PAGE_TITLE="Test: [$shortcode] Shortcode"
                    PAGE_CONTENT="<h2>Testing [$shortcode]</h2>
<h3>Basic Usage:</h3>
[$shortcode]

<h3>With Common Parameters:</h3>
[$shortcode id=\"1\" title=\"Test Title\" count=\"5\"]

<h3>Nested/Multiple:</h3>
[$shortcode]
<p>Content between shortcodes</p>
[$shortcode id=\"2\"]"
                    
                    PAGE_ID=$(wp post create \
                        --post_type=page \
                        --post_status=publish \
                        --post_title="$PAGE_TITLE" \
                        --post_content="$PAGE_CONTENT" \
                        --path="$WP_PATH" \
                        --porcelain 2>/dev/null || echo "0")
                    
                    if [ "$PAGE_ID" != "0" ]; then
                        PAGE_URL=$(wp post get "$PAGE_ID" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                        SHORTCODE_PAGES+=("{\"id\":$PAGE_ID,\"shortcode\":\"$shortcode\",\"url\":\"$PAGE_URL\"}")
                        print_success "Created test page for [$shortcode] - ID: $PAGE_ID"
                        
                        # Save for Phase 7 visual testing
                        ensure_directory "$SCAN_DIR/raw-outputs"
                        echo "$PAGE_ID:$shortcode:$PAGE_URL" >> "$SCAN_DIR/raw-outputs/test-pages.txt"
                    fi
                fi
            done
        fi
        
        # Extract Custom Post Types
        CPTS=()
        if [ "$HAS_FEATURES" = "true" ]; then
            CPTS=($(jq -r '.custom_post_types[].name // empty' "$FEATURES_FILE" 2>/dev/null))
        fi
        
        # Create test content for Custom Post Types
        CUSTOM_POSTS=()
        
        # Special handling for bbPress to create proper relationships
        if [ "$plugin_name" = "bbpress" ]; then
            print_info "Creating bbPress test content with proper relationships..."
            
            # Create test forums first
            FORUM_IDS=()
            for i in 1 2 3; do
                FORUM_ID=$(wp post create \
                    --post_type="forum" \
                    --post_status=publish \
                    --post_title="Test Forum #$i" \
                    --post_content="<p>This is test forum #$i for bbPress testing.</p><p>This forum contains various topics and discussions.</p>" \
                    --path="$WP_PATH" \
                    --porcelain 2>/dev/null || echo "0")
                
                if [ "$FORUM_ID" != "0" ]; then
                    FORUM_IDS+=($FORUM_ID)
                    FORUM_URL=$(wp post get "$FORUM_ID" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                    CUSTOM_POSTS+=("{\"id\":$FORUM_ID,\"type\":\"forum\",\"url\":\"$FORUM_URL\"}")
                    print_success "Created forum - ID: $FORUM_ID"
                    ensure_directory "$SCAN_DIR/raw-outputs"
                    echo "$FORUM_ID:forum:$FORUM_URL" >> "$SCAN_DIR/raw-outputs/test-content-urls.txt"
                    
                    # Create topics for this forum
                    for j in 1 2; do
                        TOPIC_ID=$(wp post create \
                            --post_type="topic" \
                            --post_status=publish \
                            --post_title="Topic $j in Forum $i" \
                            --post_content="<p>This is a test topic discussing important matters.</p><p>Please share your thoughts below.</p>" \
                            --post_parent=$FORUM_ID \
                            --path="$WP_PATH" \
                            --porcelain 2>/dev/null || echo "0")
                        
                        if [ "$TOPIC_ID" != "0" ]; then
                            TOPIC_URL=$(wp post get "$TOPIC_ID" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                            CUSTOM_POSTS+=("{\"id\":$TOPIC_ID,\"type\":\"topic\",\"url\":\"$TOPIC_URL\"}")
                            print_success "Created topic - ID: $TOPIC_ID"
                            echo "$TOPIC_ID:topic:$TOPIC_URL" >> "$SCAN_DIR/raw-outputs/test-content-urls.txt"
                            
                            # Create replies for this topic
                            for k in 1 2; do
                                REPLY_ID=$(wp post create \
                                    --post_type="reply" \
                                    --post_status=publish \
                                    --post_title="Re: Topic $j in Forum $i" \
                                    --post_content="<p>This is reply #$k to the topic.</p><p>Great discussion!</p>" \
                                    --post_parent=$TOPIC_ID \
                                    --path="$WP_PATH" \
                                    --porcelain 2>/dev/null || echo "0")
                                
                                if [ "$REPLY_ID" != "0" ]; then
                                    REPLY_URL=$(wp post get "$REPLY_ID" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                                    CUSTOM_POSTS+=("{\"id\":$REPLY_ID,\"type\":\"reply\",\"url\":\"$REPLY_URL\"}")
                                    print_success "Created reply - ID: $REPLY_ID"
                                    echo "$REPLY_ID:reply:$REPLY_URL" >> "$SCAN_DIR/raw-outputs/test-content-urls.txt"
                                fi
                            done
                        fi
                    done
                fi
            done
        elif [ ${#CPTS[@]} -gt 0 ]; then
            # Generic CPT handling for other plugins
            print_info "Creating test content for ${#CPTS[@]} custom post types..."
            
            for cpt in "${CPTS[@]}"; do
                if [ -n "$cpt" ] && [ "$cpt" != "post" ] && [ "$cpt" != "page" ]; then
                    # Create 3 test posts for each CPT
                    for i in 1 2 3; do
                        POST_ID=$(wp post create \
                            --post_type="$cpt" \
                            --post_status=publish \
                            --post_title="Test $cpt #$i" \
                            --post_content="<p>This is test content for the <strong>$cpt</strong> custom post type.</p>
<p>Testing various content elements:</p>
<ul>
<li>List item 1</li>
<li>List item 2</li>
</ul>
<blockquote>This is a quote for testing.</blockquote>
<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>" \
                            --path="$WP_PATH" \
                            --porcelain 2>/dev/null || echo "0")
                        
                        if [ "$POST_ID" != "0" ]; then
                            POST_URL=$(wp post get "$POST_ID" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                            CUSTOM_POSTS+=("{\"id\":$POST_ID,\"type\":\"$cpt\",\"url\":\"$POST_URL\"}")
                            print_success "Created $cpt post - ID: $POST_ID"
                            
                            # Save CPT URLs for Phase 7 visual testing
                            ensure_directory "$SCAN_DIR/raw-outputs"
                            echo "$POST_ID:$cpt:$POST_URL" >> "$SCAN_DIR/raw-outputs/test-content-urls.txt"
                        fi
                    done
                fi
            done
        fi
        
        # Extract Admin Pages
        ADMIN_PAGES=()
        if [ "$HAS_FEATURES" = "true" ]; then
            # Try to extract admin page slugs
            ADMIN_SLUGS=($(jq -r '.admin_pages[].slug // empty' "$FEATURES_FILE" 2>/dev/null))
        fi
        
        # Also try to find admin pages directly
        if [ ${#ADMIN_SLUGS[@]} -eq 0 ]; then
            # Look for add_menu_page and add_submenu_page calls
            ADMIN_SLUGS=($(grep -h "add_menu_page\|add_submenu_page" "$PLUGIN_PATH"/*.php "$PLUGIN_PATH"/*/*.php 2>/dev/null | \
                sed -E "s/.*add_(sub)?menu_page\([^,]+,[^,]+,[^,]+,[^,]+,\s*['\"]([^'\"]+).*/\2/" | \
                sort -u | head -10))
        fi
        
        # Generate admin page URLs
        SITE_URL=$(wp option get siteurl --path="$WP_PATH" 2>/dev/null || echo "http://localhost")
        for slug in "${ADMIN_SLUGS[@]}"; do
            if [ -n "$slug" ]; then
                ADMIN_URL="${SITE_URL}/wp-admin/admin.php?page=${slug}"
                ADMIN_PAGES+=("{\"slug\":\"$slug\",\"url\":\"$ADMIN_URL\"}")
                print_info "Found admin page: $slug"
            fi
        done
        
        # Create standard test posts
        print_info "Creating standard test posts..."
        STANDARD_POSTS=()
        for i in 1 2 3 4 5; do
            POST_ID=$(wp post create \
                --post_type=post \
                --post_status=publish \
                --post_title="Plugin Test Post $i" \
                --post_content="Test content for $plugin_name plugin. This post tests standard WordPress functionality." \
                --path="$WP_PATH" \
                --porcelain 2>/dev/null || echo "0")
            
            if [ "$POST_ID" != "0" ]; then
                STANDARD_POSTS+=("{\"id\":$POST_ID}")
            fi
        done
        print_success "Created ${#STANDARD_POSTS[@]} standard test posts"
        
        # Update test data manifest with all created data
        if command_exists jq; then
            # Build JSON arrays
            USERS_JSON=$(IFS=,; echo "[${USERS_CREATED[*]}]")
            PAGES_JSON=$(IFS=,; echo "[${SHORTCODE_PAGES[*]}]")
            CUSTOM_JSON=$(IFS=,; echo "[${CUSTOM_POSTS[*]}]")
            ADMIN_JSON=$(IFS=,; echo "[${ADMIN_PAGES[*]}]")
            POSTS_JSON=$(IFS=,; echo "[${STANDARD_POSTS[*]}]")
            
            cat > "$TEST_DATA_FILE" << EOF
{
    "plugin": "$plugin_name",
    "created_at": "$(date -Iseconds)",
    "site_url": "$SITE_URL",
    "users": $USERS_JSON,
    "posts": $POSTS_JSON,
    "shortcode_pages": $PAGES_JSON,
    "custom_posts": $CUSTOM_JSON,
    "admin_pages": $ADMIN_JSON,
    "statistics": {
        "users_created": ${#USERS_CREATED[@]},
        "shortcode_pages": ${#SHORTCODE_PAGES[@]},
        "custom_posts": ${#CUSTOM_POSTS[@]},
        "admin_pages": ${#ADMIN_PAGES[@]},
        "standard_posts": ${#STANDARD_POSTS[@]}
    }
}
EOF
        fi
        
    else
        print_warning "WP-CLI not available - creating URL list only"
        
        # At minimum, create a list of URLs to test
        SITE_URL="http://localhost"
        if [ -f "$WP_PATH/wp-config.php" ]; then
            SITE_URL=$(grep -oP "define\s*\(\s*'WP_HOME'\s*,\s*'[^']+'" "$WP_PATH/wp-config.php" | cut -d"'" -f4)
            SITE_URL=${SITE_URL:-"http://localhost"}
        fi
        
        # Create basic URL list for visual testing
        cat > "$SCAN_DIR/raw-outputs/test-urls.txt" << EOF
$SITE_URL/
$SITE_URL/wp-admin/
$SITE_URL/wp-admin/plugins.php
$SITE_URL/wp-admin/admin.php?page=$plugin_name
EOF
        
        print_info "Created basic URL list for testing"
    fi
    
    # Generate test data report
    TEST_REPORT="$SCAN_DIR/reports/test-data-report.md"
    cat > "$TEST_REPORT" << EOF
# Test Data Creation Report
**Plugin**: $plugin_name  
**Date**: $(date)

## Summary
- Test Users: ${#USERS_CREATED[@]}
- Shortcode Test Pages: ${#SHORTCODE_PAGES[@]}
- Custom Post Type Content: ${#CUSTOM_POSTS[@]}
- Admin Pages Found: ${#ADMIN_PAGES[@]}
- Standard Test Posts: ${#STANDARD_POSTS[@]}

## Test Data Manifest
Location: $TEST_DATA_FILE

## URLs for Visual Testing
EOF
    
    # Add URLs to report
    if [ ${#SHORTCODE_PAGES[@]} -gt 0 ]; then
        echo "### Shortcode Pages" >> "$TEST_REPORT"
        for page in "${SHORTCODE_PAGES[@]}"; do
            echo "- $page" >> "$TEST_REPORT"
        done
    fi
    
    if [ ${#ADMIN_PAGES[@]} -gt 0 ]; then
        echo "### Admin Pages" >> "$TEST_REPORT"
        for page in "${ADMIN_PAGES[@]}"; do
            echo "- $page" >> "$TEST_REPORT"
        done
    fi
    
    print_success "Test data creation complete"
    print_success "Test data manifest: $TEST_DATA_FILE"
    
    return 0
}