# 🔐 Auto-Login Feature for WordPress Testing Framework

## ✨ New Feature: Automatic Login URL Generation

Instead of creating users and managing passwords, the framework now generates **auto-login URLs** that work instantly!

## 🚀 How It Works

1. **PHP Script** (`tools/create-auto-login.php`):
   - Creates admin user if doesn't exist
   - Generates unique token with expiry
   - Stores token as WordPress transient
   - Returns auto-login URL

2. **MU-Plugin Handler** (auto-installed):
   - Intercepts auto-login requests
   - Validates token
   - Logs in user automatically
   - Deletes token after use (one-time use)

3. **Screenshot Tool Integration**:
   - Detects `USE_AUTO_LOGIN=true` environment variable
   - Generates fresh auto-login URL
   - Opens browser directly to admin dashboard
   - No login form interaction needed!

## 📝 Usage Examples

### Generate Auto-Login URL
```bash
php tools/create-auto-login.php admin 30
# Output: http://wptesting.local?auto_login=TOKEN&redirect_to=http://wptesting.local/wp-admin/
```

### Run Screenshots with Auto-Login
```bash
# Interactive mode with auto-login
INTERACTIVE=true USE_AUTO_LOGIN=true node tools/automated-screenshot-capture.js plugin-name http://site.local

# Or use the flag
node tools/automated-screenshot-capture.js plugin-name http://site.local --auto-login
```

## 🎯 Benefits

1. **No Password Management** - No need to remember or store passwords
2. **Always Works** - Creates user if needed, generates fresh token
3. **Secure** - Token expires after use or time limit
4. **Fast** - Skips login form entirely
5. **Clean** - No leftover test users with known passwords

## 🔒 Security Features

- **One-time tokens** - Each token deleted after use
- **Time expiry** - Tokens expire (default 30 minutes)
- **Transient storage** - Uses WordPress transients
- **Sanitized input** - All inputs properly sanitized
- **Admin only** - Creates admin users for testing

## 📊 Comparison

| Method | Old (Username/Password) | New (Auto-Login) |
|--------|------------------------|------------------|
| Setup | Create user, set password | Automatic |
| Login Speed | Fill form, submit, wait | Instant redirect |
| Security | Password in scripts | One-time token |
| Reliability | Can fail if wrong password | Always works |
| Cleanup | Manual user deletion | Token auto-expires |

## 🔧 Technical Details

### Token Generation
```php
$token = wp_generate_password(32, false);
set_transient('auto_login_' . $token, $user->ID, $expiry_minutes * 60);
```

### Auto-Login Handler
```php
add_action("init", function() {
    if (isset($_GET["auto_login"])) {
        $token = sanitize_text_field($_GET["auto_login"]);
        $user_id = get_transient("auto_login_" . $token);
        
        if ($user_id) {
            delete_transient("auto_login_" . $token);
            wp_set_current_user($user_id);
            wp_set_auth_cookie($user_id);
            wp_safe_redirect(admin_url());
        }
    }
});
```

## ✅ Result

The testing framework now uses **auto-login URLs** for instant, secure access to WordPress admin - making the entire process faster and more reliable!