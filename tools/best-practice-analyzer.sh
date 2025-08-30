#!/bin/bash

# Best Practice WordPress Plugin Analyzer
# Uses industry-standard tools for comprehensive analysis

PLUGIN_PATH=$1
PLUGIN_NAME=$(basename "$PLUGIN_PATH")

if [ -z "$PLUGIN_PATH" ]; then
    echo "Usage: ./best-practice-analyzer.sh <plugin-path>"
    exit 1
fi

echo "🔍 Analyzing $PLUGIN_NAME with industry-standard tools..."
echo "================================================"

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "⚠️  $1 not found. Installing..."
        return 1
    fi
    return 0
}

# 1. PHPStan - Static Analysis
echo ""
echo "1️⃣ PHPStan Analysis"
echo "-------------------"
if check_tool phpstan; then
    phpstan analyze "$PLUGIN_PATH" --level=5 --no-progress 2>/dev/null | head -20
else
    composer require --dev phpstan/phpstan 2>/dev/null
    vendor/bin/phpstan analyze "$PLUGIN_PATH" --level=5 --no-progress 2>/dev/null | head -20
fi

# 2. PHP_CodeSniffer with WordPress Standards
echo ""
echo "2️⃣ WordPress Coding Standards (PHPCS)"
echo "-------------------------------------"
if check_tool phpcs; then
    phpcs --standard=WordPress-Core "$PLUGIN_PATH" --report=summary 2>/dev/null
else
    composer require --dev squizlabs/php_codesniffer 2>/dev/null
    composer require --dev wp-coding-standards/wpcs 2>/dev/null
    vendor/bin/phpcs --config-set installed_paths vendor/wp-coding-standards/wpcs
    vendor/bin/phpcs --standard=WordPress-Core "$PLUGIN_PATH" --report=summary 2>/dev/null
fi

# 3. PHP Mess Detector
echo ""
echo "3️⃣ PHP Mess Detector (PHPMD)"
echo "----------------------------"
if check_tool phpmd; then
    phpmd "$PLUGIN_PATH" text cleancode,codesize,controversial,design,naming,unusedcode 2>/dev/null | head -20
else
    composer require --dev phpmd/phpmd 2>/dev/null
    vendor/bin/phpmd "$PLUGIN_PATH" text cleancode,codesize,controversial,design,naming,unusedcode 2>/dev/null | head -20
fi

# 4. PHP Copy/Paste Detector
echo ""
echo "4️⃣ Copy/Paste Detection (PHPCPD)"
echo "--------------------------------"
if check_tool phpcpd; then
    phpcpd "$PLUGIN_PATH" 2>/dev/null | head -10
else
    composer require --dev sebastian/phpcpd 2>/dev/null
    vendor/bin/phpcpd "$PLUGIN_PATH" 2>/dev/null | head -10
fi

# 5. PHP Lines of Code
echo ""
echo "5️⃣ Code Metrics (PHPLOC)"
echo "------------------------"
if check_tool phploc; then
    phploc "$PLUGIN_PATH" 2>/dev/null
else
    composer require --dev phploc/phploc 2>/dev/null
    vendor/bin/phploc "$PLUGIN_PATH" 2>/dev/null
fi

# 6. Security Check with Psalm (if available)
echo ""
echo "6️⃣ Security Analysis (Psalm)"
echo "----------------------------"
if [ -f psalm.xml ]; then
    psalm --taint-analysis "$PLUGIN_PATH" 2>/dev/null | head -20
else
    echo "Psalm config not found. Creating..."
    cat > psalm.xml << 'EOF'
<?xml version="1.0"?>
<psalm
    errorLevel="3"
    resolveFromConfigFile="true"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="https://getpsalm.org/schema/config"
    xsi:schemaLocation="https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd"
>
    <projectFiles>
        <directory name="." />
        <ignoreFiles>
            <directory name="vendor" />
        </ignoreFiles>
    </projectFiles>
    <plugins>
        <pluginClass class="Psalm\WordPressPlugin\Plugin" />
    </plugins>
</psalm>
EOF
    composer require --dev vimeo/psalm 2>/dev/null
    composer require --dev humanmade/psalm-plugin-wordpress 2>/dev/null
    vendor/bin/psalm --init
    vendor/bin/psalm "$PLUGIN_PATH" 2>/dev/null | head -20
fi

# 7. Generate comprehensive report
echo ""
echo "7️⃣ Generating Comprehensive Report"
echo "----------------------------------"
REPORT_FILE="analysis-report-$(date +%Y%m%d-%H%M%S).json"

cat > "$REPORT_FILE" << EOF
{
    "plugin": "$PLUGIN_NAME",
    "analyzed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "tools_used": [
        "PHPStan",
        "PHP_CodeSniffer (WordPress Standards)",
        "PHP Mess Detector",
        "PHP Copy/Paste Detector",
        "PHP Lines of Code",
        "Psalm (Security)"
    ],
    "recommendations": [
        "Run 'composer require --dev phpstan/phpstan-wordpress' for WordPress stubs",
        "Use 'phpstan/extension-installer' for automatic extension loading",
        "Configure .phpcs.xml for custom rules",
        "Add psalm-plugin-wordpress for better WordPress support"
    ]
}
EOF

echo "✅ Analysis complete! Report saved to: $REPORT_FILE"
echo ""
echo "📚 Recommended Next Steps:"
echo "  1. Fix critical issues from PHPStan (type errors)"
echo "  2. Address WordPress coding standard violations"
echo "  3. Refactor code with high complexity (PHPMD)"
echo "  4. Remove duplicate code (PHPCPD)"
echo "  5. Review security issues from Psalm taint analysis"