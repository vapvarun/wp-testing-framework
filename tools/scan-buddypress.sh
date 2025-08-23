#!/usr/bin/env bash
# BuddyPress Comprehensive Scanner
# Uses direct WP-CLI evaluation to scan BuddyPress

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 BuddyPress Comprehensive Scanner${NC}"
echo "===================================="

cd "$(dirname "$0")/.."
OUT="wp-content/uploads/wbcom-scan"
mkdir -p "$OUT"

# Check if BuddyPress is active
if ! wp plugin is-active buddypress; then
    echo -e "${YELLOW}⚠️  BuddyPress is not active. Activating...${NC}"
    wp plugin activate buddypress
fi

echo -e "${GREEN}✓ BuddyPress is active${NC}"
echo ""

# Create PHP scanner script
cat > /tmp/bp-scanner.php << 'EOF'
<?php
// Ensure BuddyPress is loaded
if (!function_exists('buddypress')) {
    echo json_encode(['error' => 'BuddyPress is not active']);
    exit(1);
}

$bp = buddypress();

// Collect all BuddyPress data
$scan_data = [
    'plugin_info' => [
        'version' => bp_get_version(),
        'db_version' => bp_get_db_version(),
        'active' => true
    ],
    'components' => [],
    'pages' => [],
    'navigation' => [],
    'activity_types' => [],
    'xprofile' => [],
    'groups' => [],
    'rest_routes' => [],
    'emails' => [],
    'settings' => []
];

// Scan components
foreach (bp_core_get_components() as $component => $details) {
    $scan_data['components'][] = [
        'id' => $component,
        'title' => $details['title'] ?? '',
        'description' => $details['description'] ?? '',
        'active' => bp_is_active($component)
    ];
}

// Scan pages
if (function_exists('bp_core_get_directory_page_ids')) {
    $page_ids = bp_core_get_directory_page_ids();
    foreach ($page_ids as $component => $page_id) {
        if ($page_id) {
            $page = get_post($page_id);
            if ($page) {
                $scan_data['pages'][] = [
                    'component' => $component,
                    'title' => $page->post_title,
                    'slug' => $page->post_name,
                    'id' => $page_id,
                    'url' => get_permalink($page_id)
                ];
            }
        }
    }
}

// Scan navigation
if (function_exists('bp_get_nav_menu_items')) {
    $nav_items = bp_get_nav_menu_items();
    foreach ($nav_items as $item) {
        $scan_data['navigation'][] = [
            'name' => $item->name ?? '',
            'slug' => $item->slug ?? '',
            'position' => $item->position ?? 0,
            'component' => $item->component_id ?? ''
        ];
    }
}

// Scan activity types
if (bp_is_active('activity') && function_exists('bp_activity_get_types')) {
    $activity_types = bp_activity_get_types();
    foreach ($activity_types as $type => $label) {
        $scan_data['activity_types'][] = [
            'type' => $type,
            'label' => $label
        ];
    }
}

// Scan xProfile fields
if (bp_is_active('xprofile') && function_exists('bp_xprofile_get_groups')) {
    $field_groups = bp_xprofile_get_groups(['fetch_fields' => true]);
    foreach ($field_groups as $group) {
        $group_data = [
            'id' => $group->id,
            'name' => $group->name,
            'description' => $group->description,
            'fields' => []
        ];
        
        if (!empty($group->fields)) {
            foreach ($group->fields as $field) {
                $group_data['fields'][] = [
                    'id' => $field->id,
                    'name' => $field->name,
                    'type' => $field->type,
                    'required' => $field->is_required
                ];
            }
        }
        
        $scan_data['xprofile'][] = $group_data;
    }
}

// Scan REST routes
$rest_server = rest_get_server();
$routes = $rest_server->get_routes();
foreach ($routes as $route => $handlers) {
    if (strpos($route, '/buddypress/') !== false) {
        $methods = [];
        foreach ($handlers as $handler) {
            if (isset($handler['methods'])) {
                $methods = array_merge($methods, array_keys($handler['methods']));
            }
        }
        $scan_data['rest_routes'][] = [
            'route' => $route,
            'methods' => array_unique($methods)
        ];
    }
}

// Scan email templates
if (function_exists('bp_email_get_schema')) {
    $email_schema = bp_email_get_schema();
    foreach ($email_schema as $situation => $details) {
        $scan_data['emails'][] = [
            'situation' => $situation,
            'description' => $details['description'] ?? ''
        ];
    }
}

// Scan settings
$settings_fields = [
    'bp-active-components',
    'bp-pages',
    'bp-disable-account-deletion',
    'bp-disable-avatar-uploads',
    'bp-disable-cover-image-uploads',
    'bp-disable-group-avatar-uploads',
    'bp-disable-group-cover-image-uploads',
    'bp-disable-profile-sync',
    'bp-enable-members-invitations',
    'bp-enable-membership-requests'
];

foreach ($settings_fields as $option) {
    $value = bp_get_option($option);
    if ($value !== false) {
        $scan_data['settings'][] = [
            'option' => $option,
            'value' => is_array($value) ? json_encode($value) : $value
        ];
    }
}

// Output as JSON
echo json_encode($scan_data, JSON_PRETTY_PRINT);
EOF

# Run the scanner
echo -e "${BLUE}→ Running comprehensive BuddyPress scan...${NC}"
wp eval-file /tmp/bp-scanner.php > "$OUT/buddypress-complete.json" 2>/dev/null

# Also save legacy format files for backwards compatibility
echo -e "${BLUE}→ Generating legacy format files...${NC}"
wp eval "
    \$data = json_decode(file_get_contents('$OUT/buddypress-complete.json'), true);
    file_put_contents('$OUT/components.json', json_encode(\$data['components'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/pages.json', json_encode(\$data['pages'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/nav.json', json_encode(\$data['navigation'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/activity-types.json', json_encode(\$data['activity_types'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/xprofile.json', json_encode(\$data['xprofile'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/rest.json', json_encode(\$data['rest_routes'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/emails.json', json_encode(\$data['emails'] ?? [], JSON_PRETTY_PRINT));
    file_put_contents('$OUT/settings.json', json_encode(\$data['settings'] ?? [], JSON_PRETTY_PRINT));
" 2>/dev/null

# Generate scan summary
echo ""
echo -e "${BLUE}📊 Scan Summary:${NC}"
echo "=================="

if [ -f "$OUT/buddypress-complete.json" ]; then
    # Extract summary from the complete scan
    wp eval "
    \$data = json_decode(file_get_contents('$OUT/buddypress-complete.json'), true);
    echo 'Plugin Version: ' . (\$data['plugin_info']['version'] ?? 'Unknown') . PHP_EOL;
    echo 'Active Components: ' . count(array_filter(\$data['components'] ?? [], function(\$c) { return \$c['active']; })) . PHP_EOL;
    echo 'Pages: ' . count(\$data['pages'] ?? []) . PHP_EOL;
    echo 'Navigation Items: ' . count(\$data['navigation'] ?? []) . PHP_EOL;
    echo 'Activity Types: ' . count(\$data['activity_types'] ?? []) . PHP_EOL;
    echo 'XProfile Groups: ' . count(\$data['xprofile'] ?? []) . PHP_EOL;
    echo 'REST Endpoints: ' . count(\$data['rest_routes'] ?? []) . PHP_EOL;
    echo 'Email Templates: ' . count(\$data['emails'] ?? []) . PHP_EOL;
    echo 'Settings: ' . count(\$data['settings'] ?? []) . PHP_EOL;
    " 2>/dev/null || echo "Could not parse scan results"
fi

# Clean up temp file
rm -f /tmp/bp-scanner.php

echo ""
echo -e "${GREEN}✅ Scan complete!${NC}"
echo "Results saved to: $OUT"
echo ""
echo "Next steps:"
echo "1. Generate test plan: npm run bp:claude"
echo "2. Run tests: npm test"