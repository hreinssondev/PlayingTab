// Renders the PlayingTab icon: a browser tab with a play symbol and sound waves.
//
//   swiftc -O scripts/icon.swift -o /tmp/icon
//   /tmp/icon <pixels> <out.png>

import AppKit

// Draws on a 1024-unit canvas (y up) scaled to `px` pixels.
func render(_ px: Int, to path: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: CGFloat(px) / 1024, y: CGFloat(px) / 1024)

    let top = NSColor(srgbRed: 1.00, green: 0.42, blue: 0.36, alpha: 1)
    let bottom = NSColor(srgbRed: 0.85, green: 0.13, blue: 0.47, alpha: 1)
    let accent = NSColor(srgbRed: 0.90, green: 0.22, blue: 0.43, alpha: 1)

    // Squircle background on Apple's macOS icon grid (824pt body, 100pt margin).
    let body = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    body.fill()
    ctx.restoreGState()
    NSGradient(starting: top, ending: bottom)!.draw(in: body, angle: -90)

    // Browser tabs: rounded top corners, flared feet that run into the tab bar.
    func tab(_ l: CGFloat, _ r: CGFloat, _ t: CGFloat) -> NSBezierPath {
        let b: CGFloat = 300, rad: CGFloat = 64, foot: CGFloat = 40
        let p = NSBezierPath()
        p.move(to: NSPoint(x: l - foot, y: b))
        p.appendArc(withCenter: NSPoint(x: l - foot, y: b + foot), radius: foot, startAngle: 270, endAngle: 360)
        p.line(to: NSPoint(x: l, y: t - rad))
        p.appendArc(withCenter: NSPoint(x: l + rad, y: t - rad), radius: rad, startAngle: 180, endAngle: 90, clockwise: true)
        p.line(to: NSPoint(x: r - rad, y: t))
        p.appendArc(withCenter: NSPoint(x: r - rad, y: t - rad), radius: rad, startAngle: 90, endAngle: 0, clockwise: true)
        p.line(to: NSPoint(x: r, y: b + foot))
        p.appendArc(withCenter: NSPoint(x: r + foot, y: b + foot), radius: foot, startAngle: 180, endAngle: 270)
        p.close()
        return p
    }
    NSColor.white.withAlphaComponent(0.35).setFill()
    tab(196, 420, 610).fill()
    tab(604, 828, 610).fill()
    NSColor.white.setFill()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 24, color: NSColor.black.withAlphaComponent(0.22).cgColor)
    tab(282, 742, 690).fill()
    ctx.restoreGState()

    // Tab bar baseline.
    NSBezierPath(roundedRect: NSRect(x: 150, y: 272, width: 724, height: 32), xRadius: 16, yRadius: 16).fill()

    // Play triangle with rounded corners.
    accent.setFill()
    accent.setStroke()
    let cx: CGFloat = 452, cy: CGFloat = 495, h: CGFloat = 190
    let tri = NSBezierPath()
    tri.move(to: NSPoint(x: cx - h * 0.42, y: cy + h / 2))
    tri.line(to: NSPoint(x: cx + h * 0.48, y: cy))
    tri.line(to: NSPoint(x: cx - h * 0.42, y: cy - h / 2))
    tri.close()
    tri.lineJoinStyle = .round
    tri.lineWidth = 36
    tri.fill()
    tri.stroke()

    // Sound waves.
    for (i, radius) in [CGFloat(92), 152].enumerated() {
        let arc = NSBezierPath()
        arc.appendArc(withCenter: NSPoint(x: cx + 60, y: cy), radius: radius, startAngle: -38, endAngle: 38)
        arc.lineWidth = 34
        arc.lineCapStyle = .round
        accent.withAlphaComponent(i == 0 ? 1 : 0.75).setStroke()
        arc.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

render(Int(CommandLine.arguments[1])!, to: CommandLine.arguments[2])
