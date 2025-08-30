# Backup Scripts

This folder contains older/alternative versions of scripts that have been replaced by simplified versions.

## Archived Scripts

- **setup.sh (old)** - Original complex setup script
- **fresh-install.sh** - Detailed installation script (replaced by simplified setup.sh)
- **sync-to-github.sh** - GitHub sync script (use git commands directly)

## Current Active Scripts

The main folder now contains only essential scripts:

1. **setup.sh** - Smart universal setup (auto-detects Local WP)
2. **local-wp-setup.sh** - Local WP specific quick setup
3. **test-plugin.sh** - Universal plugin tester with auto-folder creation

## Why Simplified?

- **setup.sh** now auto-detects environment and runs appropriate setup
- **test-plugin.sh** handles all plugin testing with automatic folder creation
- **local-wp-setup.sh** provides zero-config setup for Local WP users

These three scripts cover all use cases without confusion.