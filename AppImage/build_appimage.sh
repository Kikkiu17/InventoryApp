#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_APP_DIR="$PROJECT_ROOT/Flutter App"
PUBSPEC_FILE="$FLUTTER_APP_DIR/pubspec.yaml"

echo "=== Building AppImage for Inventario ==="

# 1. Read version from pubspec.yaml
if [ ! -f "$PUBSPEC_FILE" ]; then
  echo "Error: pubspec.yaml not found at $PUBSPEC_FILE"
  exit 1
fi

VERSION=$(grep -E '^version:' "$PUBSPEC_FILE" | awk '{print $2}' | cut -d'+' -f1 | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from $PUBSPEC_FILE"
  exit 1
fi

echo "Extracted Version: $VERSION"

# 2. Ensure Flutter Linux release build exists
BUNDLE_DIR="$FLUTTER_APP_DIR/build/linux/x64/release/bundle"

FLUTTER_CMD=$(command -v flutter || true)
if [ -z "$FLUTTER_CMD" ]; then
  if [ -f "$HOME/flutter_sdk/flutter/bin/flutter" ]; then
    FLUTTER_CMD="$HOME/flutter_sdk/flutter/bin/flutter"
  elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_CMD="$HOME/flutter/bin/flutter"
  else
    FLUTTER_CMD="flutter"
  fi
fi

echo "Building Flutter Linux app (release)..."
(cd "$FLUTTER_APP_DIR" && "$FLUTTER_CMD" build linux --release)

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Flutter Linux build bundle not found at $BUNDLE_DIR"
  exit 1
fi

# 3. Prepare AppDir directory structure
APP_DIR="$SCRIPT_DIR/AppDir"
echo "Preparing AppDir at $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# Copy Flutter release bundle contents
cp -r "$BUNDLE_DIR"/* "$APP_DIR/"

# Copy Application Icon
ICON_SRC="$FLUTTER_APP_DIR/assets/icon.png"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$APP_DIR/inventario.png"
  cp "$ICON_SRC" "$APP_DIR/.DirIcon"
else
  echo "Warning: Icon not found at $ICON_SRC"
fi

# Copy Desktop file & update X-AppImage-Version and X-AppImage-UpdateInformation
DESKTOP_SRC="$SCRIPT_DIR/inventario.desktop"
DESKTOP_DST="$APP_DIR/inventario.desktop"
cp "$DESKTOP_SRC" "$DESKTOP_DST"

if grep -q "^X-AppImage-Version=" "$DESKTOP_DST"; then
  sed -i "s/^X-AppImage-Version=.*/X-AppImage-Version=$VERSION/" "$DESKTOP_DST"
else
  echo "X-AppImage-Version=$VERSION" >> "$DESKTOP_DST"
fi

UPDATE_INFO="gh-releases-zsync|Kikkiu17|InventoryApp|latest|Inventario-*-x86_64.AppImage.zsync"
if grep -q "^X-AppImage-UpdateInformation=" "$DESKTOP_DST"; then
  grep -v "^X-AppImage-UpdateInformation=" "$DESKTOP_DST" > "${DESKTOP_DST}.tmp" && mv "${DESKTOP_DST}.tmp" "$DESKTOP_DST"
fi
echo "X-AppImage-UpdateInformation=$UPDATE_INFO" >> "$DESKTOP_DST"

# Copy AppRun entrypoint
cp "$SCRIPT_DIR/AppRun" "$APP_DIR/AppRun"
chmod +x "$APP_DIR/AppRun"

# 4. Check or download appimagetool
APPIMAGETOOL="$SCRIPT_DIR/appimagetool"
if ! command -v appimagetool &> /dev/null; then
  if [ ! -f "$APPIMAGETOOL" ]; then
    echo "Downloading appimagetool..."
    curl -sL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
  fi
  APPIMAGETOOL_CMD="$APPIMAGETOOL"
else
  APPIMAGETOOL_CMD="appimagetool"
fi

# 5. Package into AppImage
OUTPUT_APPIMAGE="$SCRIPT_DIR/Inventario-${VERSION}-x86_64.AppImage"
echo "Packaging into AppImage: $OUTPUT_APPIMAGE..."
echo "Embedding update information: $UPDATE_INFO"

if [ "$APPIMAGETOOL_CMD" = "$APPIMAGETOOL" ]; then
  ARCH=x86_64 "$APPIMAGETOOL_CMD" -u "$UPDATE_INFO" --appimage-extract-and-run "$APP_DIR" "$OUTPUT_APPIMAGE"
else
  ARCH=x86_64 "$APPIMAGETOOL_CMD" -u "$UPDATE_INFO" "$APP_DIR" "$OUTPUT_APPIMAGE"
fi

# Ensure generated .zsync file is placed in SCRIPT_DIR alongside the AppImage
ZSYNC_BASENAME="Inventario-${VERSION}-x86_64.AppImage.zsync"
if [ -f "$PWD/$ZSYNC_BASENAME" ] && [ "$PWD" != "$SCRIPT_DIR" ]; then
  mv "$PWD/$ZSYNC_BASENAME" "$SCRIPT_DIR/"
fi

echo "=== AppImage build completed successfully! ==="
echo "Output: $OUTPUT_APPIMAGE"
if [ -f "$SCRIPT_DIR/$ZSYNC_BASENAME" ]; then
  echo "Zsync:  $SCRIPT_DIR/$ZSYNC_BASENAME"
fi
