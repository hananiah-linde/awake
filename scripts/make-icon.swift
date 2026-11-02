// Draws the app icon into Resources/Assets.xcassets/AppIcon.appiconset.
// build-app.sh compiles the catalog with actool; a bare .icns gets framed at small sizes on newer macOS.
//
//   swift scripts/make-icon.swift            # regenerates the appiconset PNGs
//   swift scripts/make-icon.swift out.png    # writes just the 1024px PNG (for previewing)
//
// Hand-drawn rather than an SF Symbol: the SF Symbols license doesn't allow them in app icons.
import AppKit

let canvas: CGFloat = 1024

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func drawIcon() {
    // macOS icon grid: an 824pt rounded square centered on the 1024pt canvas.
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

    // No drop shadow on the tile: macOS adds its own, and pixels outside the tile shape make it
    // treat small sizes as a legacy icon and frame them.
    NSGradient(starting: color(0xF6B85E), ending: color(0xC4602A))!.draw(in: tilePath, angle: -90)

    NSGraphicsContext.saveGraphicsState()
    tilePath.addClip()

    let cream = color(0xFFF7EC)
    let creamShade = color(0xEADCC8)

    // Soft drop shadow under the whole cup and saucer.
    let shadow = NSShadow()
    shadow.shadowColor = color(0x5A2A0E, alpha: 0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.shadowBlurRadius = 28

    // Saucer
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    cream.setFill()
    NSBezierPath(ovalIn: NSRect(x: 222, y: 262, width: 580, height: 132)).fill()
    NSGraphicsContext.restoreGraphicsState()
    creamShade.setFill()
    NSBezierPath(ovalIn: NSRect(x: 352, y: 300, width: 320, height: 62)).fill()

    // Handle (drawn before the cup so the cup covers its inner edge)
    let handle = NSBezierPath(ovalIn: NSRect(x: 640, y: 450, width: 170, height: 170))
    handle.lineWidth = 40
    cream.setStroke()
    handle.stroke()

    // Cup body: straight rim, sides curving into a rounded base.
    let rimY: CGFloat = 660
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 302, y: rimY))
    body.line(to: NSPoint(x: 722, y: rimY))
    body.curve(
        to: NSPoint(x: 512, y: 330),
        controlPoint1: NSPoint(x: 722, y: 470),
        controlPoint2: NSPoint(x: 660, y: 330)
    )
    body.curve(
        to: NSPoint(x: 302, y: rimY),
        controlPoint1: NSPoint(x: 364, y: 330),
        controlPoint2: NSPoint(x: 302, y: 470)
    )
    body.close()
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    cream.setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Subtle shading on the cup's right side.
    NSGraphicsContext.saveGraphicsState()
    body.addClip()
    NSGradient(colors: [cream.withAlphaComponent(0), creamShade], atLocations: [0.3, 1], colorSpace: .sRGB)!
        .draw(in: body.bounds, angle: 0)
    NSGraphicsContext.restoreGraphicsState()

    // Rim and coffee
    cream.setFill()
    NSBezierPath(ovalIn: NSRect(x: 302, y: rimY - 38, width: 420, height: 76)).fill()
    color(0x5B3216).setFill()
    NSBezierPath(ovalIn: NSRect(x: 326, y: rimY - 26, width: 372, height: 52)).fill()
    color(0x7A4520).setFill()
    NSBezierPath(ovalIn: NSRect(x: 380, y: rimY - 14, width: 200, height: 24)).fill()

    // Steam
    color(0xFFFFFF, alpha: 0.85).setStroke()
    for x in [430, 512, 594] as [CGFloat] {
        let steam = NSBezierPath()
        steam.lineWidth = 30
        steam.lineCapStyle = .round
        let base: CGFloat = x == 512 ? 718 : 730
        let top: CGFloat = x == 512 ? 852 : 822
        steam.move(to: NSPoint(x: x, y: base))
        steam.curve(
            to: NSPoint(x: x, y: top),
            controlPoint1: NSPoint(x: x + 46, y: base + (top - base) * 0.35),
            controlPoint2: NSPoint(x: x - 46, y: base + (top - base) * 0.65)
        )
        steam.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()
}

func png(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let args = CommandLine.arguments
if args.count > 1 {
    try png(size: 1024).write(to: URL(fileURLWithPath: args[1]))
    exit(0)
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let appiconset = root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: appiconset, withIntermediateDirectories: true)

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let filename = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try png(size: points * scale).write(to: appiconset.appendingPathComponent(filename))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": filename])
    }
}

let info = ["author": "xcode", "version": 1] as [String: Any]
func writeJSON(_ object: Any, to url: URL) throws {
    try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]).write(to: url)
}
try writeJSON(["images": images, "info": info], to: appiconset.appendingPathComponent("Contents.json"))
try writeJSON(["info": info], to: appiconset.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print("Wrote \(appiconset.path)")
