# Deprecated Documentation

## Why These Files Were Moved

These documentation files were moved to backup as they are either:
1. Plugin-specific guides (redundant with the main test-plugin.sh that works for any plugin)
2. Internal standards documents (integrated into the main scripts)
3. Platform-specific guides (replaced by setup scripts)

### Files in This Folder

#### BBPRESS-TESTING.md & BUDDYPRESS-TESTING.md
- **Reason:** Plugin-specific testing guides
- **Replacement:** Use `./test-plugin.sh bbpress` or `./test-plugin.sh buddypress`
- These guides were for specific plugins, but the framework now handles any plugin automatically

#### DOCUMENTATION-QUALITY-STANDARDS.md
- **Reason:** Internal quality standards document
- **Replacement:** Quality validation is now built into test-plugin.sh Phase 7
- The quality checking logic from this document is now automated in the scripts

#### WINDOWS-SETUP.md
- **Reason:** Platform-specific setup guide
- **Replacement:** Use `setup.ps1` or `local-wp-setup.ps1` for Windows
- The PowerShell scripts now handle Windows setup automatically

## Current Documentation Structure

The simplified documentation now consists of:
- **README.md** - Main documentation with all essential information
- **INSTALL.md** - Quick installation guide for all platforms

All setup is handled by scripts:
- `setup.sh` / `setup.ps1` - General WordPress installations
- `local-wp-setup.sh` / `local-wp-setup.ps1` - Local WP specific setup

---

*These files are kept for reference but are no longer maintained.*