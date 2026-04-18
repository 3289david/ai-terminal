import Cocoa

// ╔══════════════════════════════════════════════════════════════╗
// ║  Generate AI Terminal App Icon                               ║
// ║  Creates a modern dark terminal icon with ⚡ lightning bolt  ║
// ╚══════════════════════════════════════════════════════════════╝

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift generate-icon.swift <output-iconset-dir>")
    exit(1)
}

let outputDir = CommandLine.arguments[1]

struct IconSize {
    let size: Int
    let scale: Int
    var filename: String {
        if scale == 1 {
            return "icon_\(size)x\(size).png"
        } else {
            return "icon_\(size)x\(size)@\(scale)x.png"
        }
    }
    var pixels: Int { size * scale }
}

let sizes: [IconSize] = [
    IconSize(size: 16, scale: 1),
    IconSize(size: 16, scale: 2),
    IconSize(size: 32, scale: 1),
    IconSize(size: 32, scale: 2),
    IconSize(size: 128, scale: 1),
    IconSize(size: 128, scale: 2),
    IconSize(size: 256, scale: 1),
    IconSize(size: 256, scale: 2),
    IconSize(size: 512, scale: 1),
    IconSize(size: 512, scale: 2),
]

func drawIcon(pixels: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: pixels, height: pixels))
    img.lockFocus()
    
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    let s = CGFloat(pixels)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    
    // ── Background: rounded rect with dark gradient ──
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.02, dy: s * 0.02),
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    
    // Dark gradient background
    let bgColors = [
        CGColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0),
        CGColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1.0),
        CGColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1.0),
    ]
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: bgColors as CFArray,
                                  locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }
    
    // ── Subtle grid pattern ──
    ctx.setStrokeColor(CGColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.06))
    ctx.setLineWidth(s * 0.002)
    let gridSpacing = s * 0.08
    var x = gridSpacing
    while x < s {
        ctx.move(to: CGPoint(x: x, y: 0))
        ctx.addLine(to: CGPoint(x: x, y: s))
        x += gridSpacing
    }
    var y = gridSpacing
    while y < s {
        ctx.move(to: CGPoint(x: 0, y: y))
        ctx.addLine(to: CGPoint(x: s, y: y))
        y += gridSpacing
    }
    ctx.strokePath()
    
    // ── Glow behind lightning bolt ──
    let glowCenter = CGPoint(x: s * 0.50, y: s * 0.50)
    let glowColors = [
        CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.25),
        CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.08),
        CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.0),
    ]
    if let glowGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: glowColors as CFArray,
                                  locations: [0.0, 0.4, 1.0]) {
        ctx.drawRadialGradient(glowGrad,
                               startCenter: glowCenter, startRadius: 0,
                               endCenter: glowCenter, endRadius: s * 0.45,
                               options: [])
    }
    
    // ── Terminal prompt: "> _" ──
    let promptFont = NSFont.monospacedSystemFont(ofSize: s * 0.12, weight: .bold)
    let promptAttrs: [NSAttributedString.Key: Any] = [
        .font: promptFont,
        .foregroundColor: NSColor(red: 0.25, green: 0.73, blue: 0.32, alpha: 0.7),
    ]
    let promptStr = NSAttributedString(string: ">_", attributes: promptAttrs)
    let promptSize = promptStr.size()
    promptStr.draw(at: NSPoint(x: s * 0.12, y: s * 0.12))
    
    // ── Lightning bolt ⚡ ──
    let boltPath = CGMutablePath()
    // Draw a stylized lightning bolt centered in the icon
    let cx = s * 0.50
    let cy = s * 0.52
    let boltH = s * 0.50
    let boltW = s * 0.28
    
    boltPath.move(to: CGPoint(x: cx - boltW * 0.05, y: cy + boltH * 0.50))    // top
    boltPath.addLine(to: CGPoint(x: cx - boltW * 0.30, y: cy + boltH * 0.05))  // mid-left
    boltPath.addLine(to: CGPoint(x: cx - boltW * 0.05, y: cy + boltH * 0.10))  // mid-inner-left
    boltPath.addLine(to: CGPoint(x: cx + boltW * 0.05, y: cy - boltH * 0.50))  // bottom
    boltPath.addLine(to: CGPoint(x: cx + boltW * 0.30, y: cy - boltH * 0.05))  // mid-right
    boltPath.addLine(to: CGPoint(x: cx + boltW * 0.05, y: cy - boltH * 0.10))  // mid-inner-right
    boltPath.closeSubpath()
    
    // Bolt gradient fill
    ctx.saveGState()
    ctx.addPath(boltPath)
    ctx.clip()
    let boltColors = [
        CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 1.0),  // #58A6FF
        CGColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.74, green: 0.55, blue: 1.0, alpha: 1.0),  // #BC8CFF purple tip
    ]
    if let boltGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: boltColors as CFArray,
                                  locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(boltGrad,
                               start: CGPoint(x: cx, y: cy + boltH * 0.5),
                               end: CGPoint(x: cx, y: cy - boltH * 0.5),
                               options: [])
    }
    ctx.restoreGState()
    
    // Bolt outline glow
    ctx.setStrokeColor(CGColor(red: 0.34, green: 0.65, blue: 1.0, alpha: 0.5))
    ctx.setLineWidth(s * 0.008)
    ctx.addPath(boltPath)
    ctx.strokePath()
    
    // ── Border ring ──
    ctx.restoreGState()
    let borderPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.025, dy: s * 0.025),
                            cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.setStrokeColor(CGColor(red: 0.19, green: 0.21, blue: 0.24, alpha: 0.8))
    ctx.setLineWidth(s * 0.006)
    ctx.addPath(borderPath)
    ctx.strokePath()
    
    img.unlockFocus()
    return img
}

// Generate all sizes
for iconSize in sizes {
    let img = drawIcon(pixels: iconSize.pixels)
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(iconSize.filename)")
        continue
    }
    let path = (outputDir as NSString).appendingPathComponent(iconSize.filename)
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("  ✓ \(iconSize.filename) (\(iconSize.pixels)x\(iconSize.pixels))")
    } catch {
        print("  ✕ \(iconSize.filename): \(error)")
    }
}

print("  Icon generation complete.")
