#!/bin/bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════╗
# ║  AI Terminal — Premium .dmg Installer Builder                ║
# ║  Custom dark background · 160px icons · Retina-ready         ║
# ╚══════════════════════════════════════════════════════════════╝

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AI Terminal"
VERSION="3.1.0"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_TEMP="$BUILD_DIR/${APP_NAME}-temp.dmg"
DMG_FINAL="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

# Terminal colors
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
DIM='\033[2m'
RESET='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║  AI Terminal ${VERSION} — DMG Builder      ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${RESET}"
echo ""

# ── Cleanup any previous partial builds ──
rm -f "$DMG_TEMP" "$DMG_FINAL"
rm -rf "$DMG_STAGING"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1: Build .app bundle
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "  ${BOLD}[1/6]${RESET} Building .app bundle..."
    bash "$PROJECT_DIR/Scripts/build-app.sh"
else
    echo -e "  ${BOLD}[1/6]${RESET} Using existing .app bundle ${GREEN}✓${RESET}"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Generate premium background image via Swift
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "  ${BOLD}[2/6]${RESET} Generating premium background..."

BG_SCRIPT="$BUILD_DIR/gen-dmg-bg.swift"
BG_OUT_DIR="$BUILD_DIR/dmg-bg.xcassets"
mkdir -p "$BG_OUT_DIR"

cat > "$BG_SCRIPT" << 'SWIFT_EOF'
import Cocoa
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: gen-dmg-bg.swift <out1x.png> <out2x.png>")
    exit(1)
}

func renderBackground(pixels: Int) -> NSBitmapImageRep {
    let w = CGFloat(pixels)
    let h = CGFloat(pixels * 360 / 660)  // 660×360 aspect
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // ── Dark gradient base ──
    let bgGrad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.035, green: 0.042, blue: 0.055, alpha: 1),   // #090B0E top-left
            CGColor(red: 0.055, green: 0.067, blue: 0.090, alpha: 1),   // #0E1117 center
            CGColor(red: 0.020, green: 0.025, blue: 0.035, alpha: 1),   // #050609 bottom-right
        ] as CFArray,
        locations: [0, 0.5, 1])!

    ctx.drawLinearGradient(bgGrad,
        start: CGPoint(x: 0, y: h),
        end:   CGPoint(x: w, y: 0),
        options: [])

    // ── Fine grid dots (subtle) ──
    let dotSpacing = w * 0.045
    ctx.setFillColor(CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.055))
    var gx: CGFloat = 0
    while gx < w {
        var gy: CGFloat = 0
        while gy < h {
            let r = w * 0.003
            ctx.fillEllipse(in: CGRect(x: gx - r, y: gy - r, width: r*2, height: r*2))
            gy += dotSpacing
        }
        gx += dotSpacing
    }

    // ── Glowing accent orbs ──
    func drawOrb(cx: CGFloat, cy: CGFloat, radius: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) {
        let orb = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: r, green: g, blue: b, alpha: 0.22),
                CGColor(red: r, green: g, blue: b, alpha: 0.07),
                CGColor(red: r, green: g, blue: b, alpha: 0),
            ] as CFArray,
            locations: [0, 0.5, 1])!
        ctx.drawRadialGradient(orb,
            startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
            endCenter:   CGPoint(x: cx, y: cy), endRadius: radius,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    drawOrb(cx: w * 0.18, cy: h * 0.72, radius: w * 0.28, r: 0.34, g: 0.65, b: 1.0)   // blue left
    drawOrb(cx: w * 0.82, cy: h * 0.25, radius: w * 0.22, r: 0.74, g: 0.55, b: 1.0)   // purple right
    drawOrb(cx: w * 0.50, cy: h * 0.50, radius: w * 0.18, r: 0.24, g: 0.85, b: 0.75)  // cyan center

    // ── Thin horizontal scan line accent ──
    let lineY = h * 0.5
    let lineGrad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0),
            CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.18),
            CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0),
        ] as CFArray,
        locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(lineGrad,
        start: CGPoint(x: 0, y: lineY),
        end:   CGPoint(x: w, y: lineY),
        options: [])
    ctx.setFillColor(CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.12))
    ctx.fill(CGRect(x: 0, y: lineY - w*0.001, width: w, height: w*0.002))

    // ── Top border glow ──
    let topGrad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.35),
            CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0),
        ] as CFArray,
        locations: [0, 1])!
    ctx.drawLinearGradient(topGrad,
        start: CGPoint(x: 0, y: h),
        end:   CGPoint(x: 0, y: h - h*0.06),
        options: [])

    // ── Bottom drag-arrow hint text ──
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: w * 0.022, weight: .medium),
        .foregroundColor: NSColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.55),
        .paragraphStyle: paraStyle,
    ]
    let dragText = "Drag  AI Terminal  to  Applications"
    let textRect = CGRect(x: w * 0.15, y: h * 0.055, width: w * 0.7, height: h * 0.07)
    dragText.draw(in: textRect, withAttributes: attrs)

    // ── Arrow between icons (drawn in the middle at icon row) ──
    let arrowAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: w * 0.055, weight: .ultraLight),
        .foregroundColor: NSColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.35),
        .paragraphStyle: paraStyle,
    ]
    let arrowRect = CGRect(x: w * 0.35, y: h * 0.35, width: w * 0.30, height: h * 0.25)
    "→".draw(in: arrowRect, withAttributes: arrowAttrs)

    // ── Version badge ──
    let verAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: w * 0.016, weight: .regular),
        .foregroundColor: NSColor(red: 0.55, green: 0.72, blue: 0.90, alpha: 0.40),
        .paragraphStyle: paraStyle,
    ]
    let verText = "v\(CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "3.1.0")"
    let verRect = CGRect(x: w * 0.35, y: h * 0.075, width: w * 0.30, height: h * 0.07)
    verText.draw(in: verRect, withAttributes: verAttrs)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// 1x — 660×360
let rep1x = renderBackground(pixels: 660)
if let data = rep1x.representation(using: .png, properties: [:]) {
    try! data.write(to: URL(fileURLWithPath: args[1]))
}

// 2x — 1320×720
let rep2x = renderBackground(pixels: 1320)
if let data = rep2x.representation(using: .png, properties: [:]) {
    try! data.write(to: URL(fileURLWithPath: args[2]))
}

print("done")
SWIFT_EOF

swift "$BG_SCRIPT" \
    "$BG_OUT_DIR/background.png" \
    "$BG_OUT_DIR/background@2x.png" \
    "$VERSION" 2>/dev/null
echo -e "     Background generated ${GREEN}✓${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Create staging area
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "  ${BOLD}[3/6]${RESET} Assembling DMG contents..."
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING/.background"

# Copy app
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Applications symlink
ln -s /Applications "$DMG_STAGING/Applications"

# Copy retina background into hidden .background folder
cp "$BG_OUT_DIR/background.png"    "$DMG_STAGING/.background/background.png"
cp "$BG_OUT_DIR/background@2x.png" "$DMG_STAGING/.background/background@2x.png"
echo -e "     Contents assembled ${GREEN}✓${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Create writable DMG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "  ${BOLD}[4/6]${RESET} Creating writable DMG..."
STAGING_SIZE=$(du -sk "$DMG_STAGING" | cut -f1)
DMG_SIZE=$(( STAGING_SIZE + 8192 ))  # 8MB padding for background + layout

hdiutil create \
    -srcfolder "$DMG_STAGING" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,b=16" \
    -format UDRW \
    -size ${DMG_SIZE}k \
    "$DMG_TEMP" > /dev/null

ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" 2>&1)
MOUNT_DIR=$(echo "$ATTACH_OUTPUT" | grep -E '\s/Volumes/' | sed 's|.*\(/Volumes/.*\)|\1|' | head -1)
DEV_NODE=$(echo "$ATTACH_OUTPUT"  | grep -E '^/dev/'     | head -1 | awk '{print $1}')

echo -e "     Mounted at ${DIM}$MOUNT_DIR${RESET} ${GREEN}✓${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 5: AppleScript — premium window layout
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "  ${BOLD}[5/6]${RESET} Applying premium Finder layout..."

osascript << APPLESCRIPT 2>/dev/null || true
tell application "Finder"
    tell disk "${APP_NAME}"
        open

        -- Window chrome
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {320, 80, 980, 440}

        -- Icon view options
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 160
        set text size of viewOptions to 13
        set shows item info of viewOptions to false
        set shows icon preview of viewOptions to true
        set label position of viewOptions to bottom

        -- Background image
        set background picture of viewOptions to file ".background:background.png"

        -- Icon positions  (window is 660 wide × 360 tall)
        -- App icon at ~160px from left, Applications at ~500px
        set position of item "${APP_NAME}.app" of container window to {162, 185}
        set position of item "Applications"    of container window to {498, 185}

        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

# Bless the volume (sets the window position DS_Store)
bless --folder "$MOUNT_DIR" --openfolder "$MOUNT_DIR" 2>/dev/null || true

# ── Set volume icon on writable DMG now (before converting) ──
if [ -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
    cp "$APP_BUNDLE/Contents/Resources/AppIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
fi

sync
hdiutil detach "$DEV_NODE" > /dev/null
echo -e "     Layout applied ${GREEN}✓${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 6: Convert to final compressed read-only DMG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "  ${BOLD}[6/6]${RESET} Compressing final DMG..."
hdiutil convert \
    "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL" > /dev/null

# ── Cleanup ──
rm -f "$DMG_TEMP"
rm -rf "$DMG_STAGING" "$BG_OUT_DIR" "$BG_SCRIPT"

# ── Print summary ──
DMG_MB=$(echo "scale=1; $(stat -f%z "$DMG_FINAL") / 1048576" | bc)
echo ""
echo -e "${BOLD}${GREEN}  ✅  ${APP_NAME} ${VERSION} installer ready!${RESET}"
echo -e "     ${DIM}$DMG_FINAL${RESET}"
echo -e "     ${DIM}Size: ${DMG_MB} MB${RESET}"
echo ""
echo -e "  ${BOLD}What's inside:${RESET}"
echo -e "     • Dark gradient background with glowing accent orbs"
echo -e "     • Retina-ready background (1x + 2x PNG)"
echo -e "     • 160px icons · drag-arrow hint · version badge"
echo -e "     • Custom volume icon (app icon)"
echo ""
echo -e "  ${BOLD}Distribute:${RESET}"
echo -e "     Share ${BOLD}${APP_NAME}-${VERSION}.dmg${RESET} — users open it and"
echo -e "     drag ${BOLD}AI Terminal.app${RESET} to the Applications folder."
echo ""
