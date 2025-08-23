#!/usr/bin/env bash
set -euo pipefail

# Change this to your absolute site path if you run from elsewhere:
SITE_ROOT="/Users/varundubey/Local Sites/buddynext/app/public"
cd "$SITE_ROOT"

OUT="wp-content/uploads/wbcom-scan"
REQ_BP="$SITE_ROOT/wp-content/plugins/buddypress/bp-loader.php"
REQ_CMD="$SITE_ROOT/wp-content/plugins/wbcom-dev-tools/cli/class-wbcom-bp-cli.php"

mkdir -p "$OUT"

scan() {
  local name="$1"
  echo "→ scanning $name"
  if wp --skip-themes --skip-plugins \
       --require="$REQ_BP" \
       --require="$REQ_CMD" \
       wbcom:bp "$name" > "$OUT/$name.json"; then
    true
  else
    echo "WARN: $name failed; writing []"
    echo "[]" > "$OUT/$name.json"
  fi
}

for name in components pages nav activity-types xprofile rest emails settings; do
  scan "$name"
done

echo "Done. See $OUT"
