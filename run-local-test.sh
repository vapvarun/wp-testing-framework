#!/bin/bash
# Quick test runner for Local WP

PLUGIN=$1
if [ -z "$PLUGIN" ]; then
    echo "Usage: ./run-local-test.sh plugin-name"
    echo ""
    echo "Available plugins:"
    ls -1 ../wp-content/plugins
    exit 1
fi

echo "Testing $PLUGIN..."
./test-plugin.sh "$PLUGIN"

# Open results in browser
if command -v open >/dev/null 2>&1; then
    REPORT=$(find ../wp-content/uploads/wbcom-scan/$PLUGIN -name "*.html" -type f | head -1)
    if [ -n "$REPORT" ]; then
        open "$REPORT"
    fi
fi
