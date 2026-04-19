#!/bin/bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════╗
# ║  AI Terminal — Create macOS .dmg Installer                   ║
# ║  Produces a drag-to-install DMG with an Applications link    ║
# ╚══════════════════════════════════════════════════════════════╝

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AI Terminal"
VERSION="3.1.0"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_TEMP="$BUILD_DIR/${APP_NAME}-temp.dmg"
DMG_FINAL="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

echo "💿 Building ${APP_NAME} ${VERSION}.dmg..."
echo ""

# ── Cleanup any previous partial builds ──
rm -f "$DMG_TEMP" "$DMG_FINAL"
rm -rf "$DMG_STAGING"

# ── Step 1: Build .app bundle if needed ──
if [ ! -d "$APP_BUNDLE" ]; then
    echo "  [1/5] Building .app bundle first..."
    bash "$PROJECT_DIR/Scripts/build-app.sh"
else
    echo "  [1/5] Using existing .app bundle ✓"
fi

# ── Step 2: Create staging area ──
echo "  [2/5] Creating DMG staging area..."
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy the app
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Create symlink to /Applications (the drag-to-install target)
ln -s /Applications "$DMG_STAGING/Applications"

# ── Step 3: Write .DS_Store for window/icon layout ──
echo "  [3/5] Configuring window layout..."
# Use osascript to set the DMG window appearance
STAGING_SIZE=$(du -sk "$DMG_STAGING" | cut -f1)
DMG_SIZE=$(( STAGING_SIZE + 5120 ))  # add 5MB padding

# ── Step 4: Create temporary writable DMG ──
echo "  [4/5] Creating temporary DMG..."
hdiutil create \
    -srcfolder "$DMG_STAGING" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,b=16" \
    -format UDRW \
    -size ${DMG_SIZE}k \
    "$DMG_TEMP" \
    > /dev/null

# Mount it and capture the mount point
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP")
MOUNT_DIR=$(echo "$ATTACH_OUTPUT" | grep -E '\s/Volumes/' | sed 's|.*\(/Volumes/.*\)|\1|')
DEV_NODE=$(echo "$ATTACH_OUTPUT" | grep -E '^/dev/' | head -1 | awk '{print $1}')

# Use AppleScript to set window size and icon positions
osascript << APPLESCRIPT 2>/dev/null || true
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 940, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set position of item "${APP_NAME}.app" of container window to {150, 170}
        set position of item "Applications" of container window to {390, 170}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Sync and unmount
sync
hdiutil detach "$DEV_NODE" > /dev/null

# ── Step 5: Convert to final compressed read-only DMG ──
echo "  [5/5] Compressing to final DMG..."
rm -f "$DMG_FINAL"
hdiutil convert \
    "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL" \
    > /dev/null

# Cleanup
rm -f "$DMG_TEMP"
rm -rf "$DMG_STAGING"

# ── Done ──
DMG_MB=$(( $(stat -f%z "$DMG_FINAL") / 1048576 ))
echo ""
echo "  ✅ ${APP_NAME}-${VERSION}.dmg created:"
echo "     $DMG_FINAL"
echo "     Size: ${DMG_MB} MB"
echo ""
echo "  To distribute:"
echo "     Share the .dmg file — users open it and drag AI Terminal.app"
echo "     to their Applications folder."
echo ""
