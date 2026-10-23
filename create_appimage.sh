#!/bin/bash
# ==============================================================================
# MastiCare Pro - Linux AppImage Packaging Script
# ==============================================================================
set -e

echo "=== 1. Building Flutter Linux Release Bundle ==="
flutter build linux --release

APP_DIR="MastiCare.AppDir"
BUNDLE_DIR="build/linux/x64/release/bundle"

echo "=== 2. Creating AppImage Directory Structure ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# Copy full Flutter bundle (executable, lib, data, assets, TFLite blobs)
cp -r "$BUNDLE_DIR"/* "$APP_DIR"/

echo "=== 3. Creating AppRun Executable Launcher ==="
cat << 'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${HERE}:${LD_LIBRARY_PATH}"
exec "${HERE}/masticare" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

echo "=== 4. Creating Desktop Integration File ==="
cat << 'EOF' > "$APP_DIR/masticare.desktop"
[Desktop Entry]
Name=MastiCare Pro
Comment=Smart Cattle Health Dashboard & Mastitis Screening
Exec=masticare
Icon=masticare
Type=Application
Categories=Medical;Utility;
Terminal=false
EOF

echo "=== 5. Adding Application Icon ==="
if [ -f "assets/icon.png" ]; then
  cp "assets/icon.png" "$APP_DIR/masticare.png"
else
  # Default placeholder icon if custom icon not set
  touch "$APP_DIR/masticare.png"
fi

echo "=== 6. Downloading AppImage Builder Tool ==="
if ! command -v appimagetool &> /dev/null; then
  wget -q https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
  /tmp/appimagetool --appimage-extract > /dev/null
  APPIMAGETOOL="./squashfs-root/AppRun"
else
  APPIMAGETOOL="appimagetool"
fi

echo "=== 7. Packaging MastiCare_Pro-x86_64.AppImage ==="
ARCH=x86_64 $APPIMAGETOOL "$APP_DIR" MastiCare_Pro-x86_64.AppImage

echo ""
echo "=========================================================================="
echo "SUCCESS! Standalone Linux single-click AppImage created:"
echo " -> Output File: MastiCare_Pro-x86_64.AppImage"
echo "=========================================================================="
