#!/usr/bin/env bash
set -euo pipefail

# Project branding is applied after the upstream Cromite patches so the
# Chromium/Cromite source tree remains disposable and easy to rebase.

SRC="${1:?Chromium source directory is required}"
APP_NAME="Nexa Browser"
PACKAGE_NAME="com.nexa.browser"

CHANNEL_CONSTANTS="$SRC/chrome/android/java/res_chromium_base/values/channel_constants.xml"
if [[ ! -f "$CHANNEL_CONSTANTS" ]]; then
  echo "Missing Chromium branding resource: $CHANNEL_CONSTANTS" >&2
  exit 1
fi

python3 - "$CHANNEL_CONSTANTS" "$APP_NAME" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
app_name = sys.argv[2]
text = path.read_text(encoding="utf-8")
pattern = r'(<string\s+name="app_name"[^>]*>)(.*?)(</string>)'
updated, count = re.subn(pattern, rf'\1{app_name}\3', text, count=1, flags=re.DOTALL)
if count != 1:
    raise SystemExit("Could not locate app_name in channel_constants.xml")
path.write_text(updated, encoding="utf-8")
PY

# Modern Android launcher icon: a dark adaptive icon with a cyan/blue
# Chromium-inspired ring. This is vector XML, so no binary assets are needed
# in the bootstrap repository.
ICON_DIR="$SRC/chrome/android/java/res_chromium_base"
mkdir -p "$ICON_DIR/mipmap-anydpi-v26" "$ICON_DIR/drawable"

cat > "$ICON_DIR/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/nexa_icon_background" />
    <foreground android:drawable="@drawable/nexa_icon_foreground" />
</adaptive-icon>
EOF

cat > "$ICON_DIR/drawable/nexa_icon_foreground.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#10151C"
        android:pathData="M54,12A42,42 0,1 0,54 96A42,42 0,1 0,54 12" />
    <path
        android:fillColor="#39B8FF"
        android:pathData="M54,22A32,32 0,1 0,54 86A32,32 0,1 0,54 22M54,30A24,24 0,1 1,54 78A24,24 0,1 1,54 30" />
    <path
        android:fillColor="#0B0F14"
        android:pathData="M54,38A16,16 0,1 0,54 70A16,16 0,1 0,54 38" />
</vector>
EOF

mkdir -p "$ICON_DIR/values"
if ! grep -q 'name="nexa_icon_background"' "$ICON_DIR/values/colors.xml" 2>/dev/null; then
  cat >> "$ICON_DIR/values/colors.xml" <<'EOF'

    <!-- Nexa Browser launcher background -->
    <color name="nexa_icon_background">#05070A</color>
EOF
fi

echo "Branding applied: $APP_NAME ($PACKAGE_NAME)"
