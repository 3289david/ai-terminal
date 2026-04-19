#!/bin/bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════╗
# ║  AI Terminal — Build macOS .app Bundle                       ║
# ║  Creates a proper AI Terminal.app from the SPM executable    ║
# ╚══════════════════════════════════════════════════════════════╝

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AI Terminal"
BUNDLE_ID="com.aiterminal.app"
VERSION="3.0.0"
BUILD_DIR="$PROJECT_DIR/.build"
RELEASE_DIR="$BUILD_DIR/release"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"

echo "⚡ Building AI Terminal.app..."
echo ""

# ── Step 1: Build release binary ──
echo "  [1/5] Compiling release build..."
cd "$PROJECT_DIR"
swift build -c release 2>&1 | tail -1

if [ ! -f "$RELEASE_DIR/ai-terminal" ]; then
    # Fallback: SPM might name it AITerminal
    if [ -f "$RELEASE_DIR/AITerminal" ]; then
        EXECUTABLE="AITerminal"
    else
        echo "  ✕ Build failed. No executable found."
        exit 1
    fi
else
    EXECUTABLE="ai-terminal"
fi
echo "  ✓ Build complete"

# ── Step 2: Create .app bundle structure ──
echo "  [2/5] Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# ── Step 3: Copy executables (GUI + CLI) ──
echo "  [3/5] Copying executables..."
cp "$RELEASE_DIR/$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/AITerminal"
chmod +x "$APP_BUNDLE/Contents/MacOS/AITerminal"

# Bundle the CLI binary inside the .app so it auto-installs on first launch
if [ -f "$RELEASE_DIR/ait" ]; then
    cp "$RELEASE_DIR/ait" "$APP_BUNDLE/Contents/MacOS/ait"
    chmod +x "$APP_BUNDLE/Contents/MacOS/ait"
    echo "  ✓ CLI binary (ait) bundled"
else
    echo "  ⚠ CLI binary not found — building it..."
    swift build -c release --product ait 2>&1 | tail -1
    if [ -f "$RELEASE_DIR/ait" ]; then
        cp "$RELEASE_DIR/ait" "$APP_BUNDLE/Contents/MacOS/ait"
        chmod +x "$APP_BUNDLE/Contents/MacOS/ait"
        echo "  ✓ CLI binary (ait) bundled"
    fi
fi

# ── Step 4: Generate Info.plist ──
echo "  [4/5] Writing Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>AITerminal</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 AI Terminal. MIT License.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMainNibFile</key>
    <string></string>
</dict>
</plist>
PLIST

# ── Step 5: Generate app icon ──
echo "  [5/5] Generating app icon..."
ICON_SCRIPT="$PROJECT_DIR/Scripts/generate-icon.swift"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# Generate icon PNGs using Swift/CoreGraphics
swift "$ICON_SCRIPT" "$ICONSET_DIR" 2>/dev/null || {
    echo "  ⚠ Icon generation skipped (needs display). Using placeholder."
    # Create a simple placeholder using sips if available
    for size in 16 32 64 128 256 512 1024; do
        # Create a 1x1 dark pixel PNG and scale it
        printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\x18\x05\x00\x00\x00\x02\x00\x01\xe2!\xbc3\x00\x00\x00\x00IEND\xaeB`\x82' > "$ICONSET_DIR/temp_${size}.png"
    done
}

# Convert iconset to icns if iconutil is available
if command -v iconutil &>/dev/null && ls "$ICONSET_DIR"/*.png &>/dev/null 2>&1; then
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

# ── Step 6: Write PkgInfo ──
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# ── Done ──
echo ""
echo "  ✅ ${APP_NAME}.app created at:"
echo "     $APP_BUNDLE"
echo ""
echo "  To install:"
echo "     cp -R \"$APP_BUNDLE\" /Applications/"
echo ""
echo "  To run:"
echo "     open \"$APP_BUNDLE\""
echo ""
