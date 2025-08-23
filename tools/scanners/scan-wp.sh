#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT="wp-content/uploads/wp-scan"
mkdir -p "$OUT"

TARGET_TYPE="${1:-site}"
TARGET_SLUG="${2:-}"

echo "🔍 Scanning WordPress ${TARGET_TYPE}..."

case "$TARGET_TYPE" in
    plugin)
        echo "→ scanning plugin: ${TARGET_SLUG}"
        wp scan plugins --slug="${TARGET_SLUG}" > "$OUT/plugin-${TARGET_SLUG}.json"
        ;;
    theme)
        echo "→ scanning theme: ${TARGET_SLUG}"
        wp scan themes --slug="${TARGET_SLUG}" > "$OUT/theme-${TARGET_SLUG}.json"
        ;;
    site|*)
        echo "→ scanning full site"
        wp scan site > "$OUT/site.json"
        echo "→ scanning all plugins"
        wp scan plugins > "$OUT/plugins.json"
        echo "→ scanning all themes"
        wp scan themes > "$OUT/themes.json"
        ;;
esac

echo "✅ Scan complete. Results in $OUT"
