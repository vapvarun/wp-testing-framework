#!/bin/bash

# Generate auto-login URL for WordPress admin
# Uses wp-cli to create a magic login link

SITE_PATH="${1:-/Users/varundubey/Local Sites/wptesting/app/public}"
USERNAME="${2:-admin}"

cd "$SITE_PATH"

# Check if user exists, if not create it
if ! wp user get "$USERNAME" --field=ID 2>/dev/null; then
    echo "Creating admin user..."
    wp user create "$USERNAME" "${USERNAME}@example.com" --role=administrator --user_pass=temp123
fi

# Install and activate magic login plugin if needed
if ! wp plugin is-installed magic-login 2>/dev/null; then
    # Use wp-cli to generate a one-time login URL
    # This works without any plugin using wp-cli's built-in functionality
    LOGIN_URL=$(wp eval "
        \$user = get_user_by('login', '$USERNAME');
        if (\$user) {
            \$key = get_password_reset_key(\$user);
            if (!is_wp_error(\$key)) {
                echo network_site_url(\"wp-login.php?action=rp&key=\$key&login=\" . rawurlencode(\$user->user_login), 'login');
            }
        }
    " 2>/dev/null)
    
    if [ -z "$LOGIN_URL" ]; then
        # Alternative method: Create a custom auto-login URL
        LOGIN_URL=$(wp eval "
            \$user = get_user_by('login', '$USERNAME');
            if (\$user) {
                // Set auth cookie directly
                wp_set_current_user(\$user->ID);
                wp_set_auth_cookie(\$user->ID);
                echo add_query_arg('logged_in', 'true', admin_url());
            }
        " 2>/dev/null)
    fi
else
    # Use magic login plugin if available
    LOGIN_URL=$(wp magic-login create "$USERNAME" --url-only 2>/dev/null)
fi

echo "$LOGIN_URL"