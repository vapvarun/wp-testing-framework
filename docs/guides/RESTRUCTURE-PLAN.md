# Framework Restructuring Plan

## Current Issues to Fix

1. **Mixed Universal & Plugin-Specific**: BuddyPress-specific files mixed with framework files
2. **Reports in Git**: Ephemeral reports shouldn't be in version control
3. **No Clear Separation**: Universal tools mixed with plugin tools
4. **Not Scalable**: Current structure won't work for 100+ plugins
5. **Redundant Files**: Multiple similar files doing same thing

## New Structure Implementation

### Step 1: Create New Directory Structure

```bash
wp-testing-framework/
├── src/                 # Universal framework code
├── plugins/             # Plugin-specific (permanent)
│   └── buddypress/     # All BuddyPress permanent data
├── workspace/           # Ephemeral (not synced)
└── templates/           # Plugin templates
```

### Step 2: File Movement Plan

#### Move to `/src/` (Universal Framework)
```
FROM                                    TO
/tools/generators/                  →  /src/Generators/
/tools/analyzers/                   →  /src/Analyzers/
/tools/utilities/report-organizer  →  /src/Utilities/
/tools/templates/scanner-template  →  /src/Templates/
/bin/                              →  /src/Bin/
```

#### Move to `/plugins/buddypress/` (Plugin-Specific)
```
FROM                                    TO
/tests/plugins/buddypress/         →  /plugins/buddypress/tests/
/tools/scanners/*buddypress*       →  /plugins/buddypress/scanners/
/tools/scanners/bp-*               →  /plugins/buddypress/scanners/
/wp-cli-commands/                  →  /plugins/buddypress/commands/
/reports/buddypress/analysis/      →  /plugins/buddypress/analysis/
```

#### Move to `/workspace/` (Ephemeral - Not Synced)
```
FROM                                    TO
/reports/buddypress/execution/     →  /workspace/reports/buddypress/execution/
/reports/buddypress/coverage/      →  /workspace/reports/buddypress/coverage/
/screenshots/                      →  /workspace/screenshots/
/logs/                             →  /workspace/logs/
*.log                              →  /workspace/logs/
```

#### Delete (Redundant/Outdated)
```
- BUDDYPRESS-*.md (Old documentation)
- Multiple phpunit.xml files (consolidate)
- Duplicate test files
- Old cleanup scripts
```

### Step 3: Create Plugin Structure for BuddyPress

```
/plugins/buddypress/
├── data/
│   ├── fixtures/        # Test data
│   ├── mocks/          # Mock objects
│   └── seeds/          # DB seeds
├── tests/
│   ├── unit/           # From current location
│   ├── integration/    # From current location
│   └── functional/     # From current location
├── scanners/
│   ├── component-scanner.php
│   ├── api-scanner.php
│   └── security-scanner.php
├── models/
│   ├── patterns.json   # Code patterns
│   ├── best-practices.json
│   └── vulnerabilities.json
├── analysis/
│   ├── components.json # Component analysis
│   ├── hooks.json      # Hooks mapping
│   └── api.json        # API endpoints
├── commands/           # WP-CLI commands
└── docs/
    ├── README.md
    └── TESTING-GUIDE.md
```

### Step 4: Update Configuration Files

#### New `.gitignore`
```gitignore
# Ephemeral data - NOT synced
/workspace/
*.log
*.cache
.phpunit.result.cache

# Dependencies
/vendor/
/node_modules/

# IDE
.idea/
.vscode/

# OS
.DS_Store
Thumbs.db
```

#### New `composer.json`
```json
{
  "name": "wp-testing-framework/core",
  "autoload": {
    "psr-4": {
      "WPTestingFramework\\": "src/"
    }
  }
}
```

### Step 5: Create Plugin Template

```
/templates/plugin-skeleton/
├── data/
│   ├── fixtures/.gitkeep
│   ├── mocks/.gitkeep
│   └── seeds/.gitkeep
├── tests/
│   ├── unit/.gitkeep
│   ├── integration/.gitkeep
│   ├── functional/.gitkeep
│   └── phpunit.xml
├── scanners/
│   └── .gitkeep
├── models/
│   ├── patterns.json
│   └── best-practices.json
├── analysis/
│   └── .gitkeep
├── commands/
│   └── .gitkeep
├── docs/
│   ├── README.md
│   └── TESTING-GUIDE.md
└── plugin-config.json
```

## Implementation Commands

```bash
# 1. Create new structure
mkdir -p src/{Framework,Generators,Analyzers,Utilities,Templates,Bin}
mkdir -p plugins/buddypress/{data,tests,scanners,models,analysis,commands,docs}
mkdir -p workspace/{reports,screenshots,videos,logs,cache,output}
mkdir -p templates/plugin-skeleton

# 2. Move files (see movement plan above)

# 3. Update namespace and autoloading

# 4. Create .gitignore for workspace
echo "/workspace/" >> .gitignore

# 5. Test the new structure
```

## Benefits of New Structure

1. **Clear Separation**: Universal vs Plugin-specific
2. **Scalable**: Easy to add 100+ plugins
3. **Git-Friendly**: Only permanent data synced
4. **AI-Optimized**: Predictable paths
5. **Maintainable**: Clear ownership
6. **Reusable**: Templates for new plugins
7. **Professional**: Industry-standard structure

## Migration Timeline

1. **Hour 1**: Create directories, move files
2. **Hour 2**: Update configurations, test
3. **Hour 3**: Create templates, documentation
4. **Hour 4**: Verify, commit to GitHub

## Validation Checklist

- [ ] All BuddyPress tests still run
- [ ] Reports generate in workspace/
- [ ] GitHub only syncs permanent data
- [ ] Template creates new plugin structure
- [ ] Documentation updated
- [ ] No broken references
- [ ] Clean separation achieved