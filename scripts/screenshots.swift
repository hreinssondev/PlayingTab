// Renders the Mac App Store screenshots (2880x1800).
//
//   swiftc -O scripts/screenshots.swift -o /tmp/screenshots
//   /tmp/screenshots <icon-1024.png> <out-dir>

import AppKit

let W: CGFloat = 2880, H: CGFloat = 1800

let ink = NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 1)
let gray = NSColor(srgbRed: 0.43, green: 0.43, blue: 0.45, alpha: 1)
let coral = NSColor(srgbRed: 1.00, green: 0.42, blue: 0.36, alpha: 1)
let magenta = NSColor(srgbRed: 0.85, green: 0.13, blue: 0.47, alpha: 1)
let accent = NSColor(srgbRed: 0.90, green: 0.22, blue: 0.43, alpha: 1)

// Draws with a top-left origin into a W x H bitmap. No alpha channel:
// App Store Connect rejects screenshots that have one.
func canvas(_ path: String, _ draw: () -> Void) {
    let cg = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    cg.translateBy(x: 0, y: H)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, cg.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
}

var cg: CGContext { NSGraphicsContext.current!.cgContext }

func background() {
    let top = NSColor(srgbRed: 1.00, green: 0.96, blue: 0.95, alpha: 1)
    let bottom = NSColor(srgbRed: 0.99, green: 0.89, blue: 0.93, alpha: 1)
    NSGradient(starting: top, ending: bottom)!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: 90)
}

func text(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, y: CGFloat) {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight),
                                                .foregroundColor: color, .paragraphStyle: para,
                                                .kern: size * -0.01]
    NSAttributedString(string: s, attributes: attrs).draw(in: NSRect(x: 0, y: y, width: W, height: size * 1.4))
}

func label(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, in r: NSRect, center: Bool = false) {
    let para = NSMutableParagraphStyle()
    para.alignment = center ? .center : .left
    para.lineBreakMode = .byTruncatingTail
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
    let h = font.ascender - font.descender
    NSAttributedString(string: s, attributes: attrs).draw(in: NSRect(x: r.minX, y: r.midY - h / 2, width: r.width, height: h))
}

func symbol(_ name: String, _ size: CGFloat, _ color: NSColor, at p: NSPoint) {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(config)!
    img.draw(in: NSRect(x: p.x - img.size.width / 2, y: p.y - img.size.height / 2, width: img.size.width, height: img.size.height),
             from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}

func shadowed(_ blur: CGFloat, _ alpha: CGFloat, _ body: () -> Void) {
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: blur / 3), blur: blur, color: NSColor.black.withAlphaComponent(alpha).cgColor)
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
    body()
    cg.endTransparencyLayer()
    cg.restoreGState()
}

struct Tab { let title: String; let playing: Bool }

// A Safari window: toolbar, tab bar, and a video page for the active tab.
func window(_ f: NSRect, tabs: [Tab], active: Int, url: String, video: String) {
    let r: CGFloat = 26
    shadowed(90, 0.22) {
        NSColor.white.setFill()
        NSBezierPath(roundedRect: f, xRadius: r, yRadius: r).fill()
    }
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: f, xRadius: r, yRadius: r).addClip()

    // Toolbar.
    let toolbar = NSRect(x: f.minX, y: f.minY, width: f.width, height: 104)
    NSColor(white: 0.965, alpha: 1).setFill()
    toolbar.fill()
    for (i, c) in [NSColor(srgbRed: 1, green: 0.37, blue: 0.34, alpha: 1),
                   NSColor(srgbRed: 1, green: 0.74, blue: 0.18, alpha: 1),
                   NSColor(srgbRed: 0.16, green: 0.79, blue: 0.25, alpha: 1)].enumerated() {
        c.setFill()
        NSBezierPath(ovalIn: NSRect(x: f.minX + 40 + CGFloat(i) * 44, y: toolbar.midY - 13, width: 26, height: 26)).fill()
    }
    let field = NSRect(x: f.midX - f.width * 0.22, y: toolbar.midY - 28, width: f.width * 0.44, height: 56)
    NSColor(white: 0.90, alpha: 1).setFill()
    NSBezierPath(roundedRect: field, xRadius: 14, yRadius: 14).fill()
    label(url, 30, .regular, ink, in: field, center: true)

    // Tab bar.
    let bar = NSRect(x: f.minX, y: toolbar.maxY, width: f.width, height: 76)
    NSColor(white: 0.90, alpha: 1).setFill()
    bar.fill()
    let tw = (f.width - 24) / CGFloat(tabs.count)
    for (i, tab) in tabs.enumerated() {
        let t = NSRect(x: f.minX + 12 + CGFloat(i) * tw, y: bar.minY + 10, width: tw - 6, height: bar.height - 20)
        if i == active {
            shadowed(10, 0.12) {
                NSColor.white.setFill()
                NSBezierPath(roundedRect: t, xRadius: 12, yRadius: 12).fill()
            }
        } else if i > 0 && i - 1 != active {
            NSColor(white: 0.78, alpha: 1).setFill()
            NSRect(x: t.minX - 3, y: t.minY + 14, width: 2, height: t.height - 28).fill()
        }
        var textRect = t.insetBy(dx: 26, dy: 0)
        if tab.playing {
            symbol("speaker.wave.2.fill", 26, accent, at: NSPoint(x: t.maxX - 40, y: t.midY))
            textRect.size.width -= 50
        }
        label(tab.title, 28, i == active ? .semibold : .regular, i == active ? ink : gray, in: textRect, center: true)
    }

    // Page: video player with title and placeholder text lines.
    let page = NSRect(x: f.minX, y: bar.maxY, width: f.width, height: f.maxY - bar.maxY)
    NSColor.white.setFill()
    page.fill()
    let pad: CGFloat = 56
    let vw = page.width * 0.64 - pad * 1.5
    let player = NSRect(x: page.minX + pad, y: page.minY + pad, width: vw, height: min(vw * 9 / 16, page.height - pad * 2 - 150))
    let playerPath = NSBezierPath(roundedRect: player, xRadius: 20, yRadius: 20)
    NSGradient(starting: coral, ending: magenta)!.draw(in: playerPath, angle: -60)
    // Equalizer bars to suggest audio.
    let heights: [CGFloat] = [0.30, 0.55, 0.80, 0.45, 0.95, 0.65, 0.35, 0.70, 0.50, 0.25]
    let bw: CGFloat = player.width * 0.028, gap = bw * 0.9
    let total = CGFloat(heights.count) * bw + CGFloat(heights.count - 1) * gap
    NSColor.white.withAlphaComponent(0.92).setFill()
    for (i, h) in heights.enumerated() {
        let bh = player.height * 0.30 * h
        let x = player.midX - total / 2 + CGFloat(i) * (bw + gap)
        NSBezierPath(roundedRect: NSRect(x: x, y: player.midY - 30 - bh, width: bw, height: bh * 2), xRadius: bw / 2, yRadius: bw / 2).fill()
    }
    // Progress bar.
    let track = NSRect(x: player.minX + 40, y: player.maxY - 56, width: player.width - 80, height: 10)
    NSColor.white.withAlphaComponent(0.35).setFill()
    NSBezierPath(roundedRect: track, xRadius: 5, yRadius: 5).fill()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY, width: track.width * 0.38, height: 10), xRadius: 5, yRadius: 5).fill()
    NSBezierPath(ovalIn: NSRect(x: track.minX + track.width * 0.38 - 14, y: track.midY - 14, width: 28, height: 28)).fill()

    label(video, 46, .bold, ink, in: NSRect(x: player.minX, y: player.maxY + 30, width: player.width, height: 64))
    NSColor(white: 0.90, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: player.minX, y: player.maxY + 108, width: player.width * 0.45, height: 22), xRadius: 11, yRadius: 11).fill()

    // Sidebar of up-next items.
    let sx = player.maxX + pad
    var y = player.minY
    while y + 150 < page.maxY - pad {
        NSColor(white: 0.93, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: sx, y: y, width: 240, height: 135), xRadius: 14, yRadius: 14).fill()
        NSColor(white: 0.90, alpha: 1).setFill()
        let lw = page.maxX - pad - (sx + 270)
        NSBezierPath(roundedRect: NSRect(x: sx + 270, y: y + 20, width: lw, height: 22), xRadius: 11, yRadius: 11).fill()
        NSBezierPath(roundedRect: NSRect(x: sx + 270, y: y + 62, width: lw * 0.6, height: 22), xRadius: 11, yRadius: 11).fill()
        y += 165
    }
    NSGraphicsContext.restoreGraphicsState()
}

// Keycaps for the shortcut, centered on `center`.
func keycaps(_ keys: [String], center: NSPoint) {
    let size: CGFloat = 150, gap: CGFloat = 28
    let total = CGFloat(keys.count) * size + CGFloat(keys.count - 1) * gap
    for (i, k) in keys.enumerated() {
        let r = NSRect(x: center.x - total / 2 + CGFloat(i) * (size + gap), y: center.y - size / 2, width: size, height: size)
        shadowed(30, 0.25) {
            NSColor.white.setFill()
            NSBezierPath(roundedRect: r, xRadius: 30, yRadius: 30).fill()
        }
        NSColor(white: 0.88, alpha: 1).setStroke()
        let edge = NSBezierPath(roundedRect: r.insetBy(dx: 1.5, dy: 1.5), xRadius: 29, yRadius: 29)
        edge.lineWidth = 3
        edge.stroke()
        label(k, 72, .medium, ink, in: r, center: true)
    }
}

func pill(_ s: String, _ sym: String, center: NSPoint) {
    let font = NSFont.systemFont(ofSize: 48, weight: .semibold)
    let w = (s as NSString).size(withAttributes: [.font: font]).width + 190
    let r = NSRect(x: center.x - w / 2, y: center.y - 60, width: w, height: 120)
    shadowed(30, 0.12) {
        NSColor.white.setFill()
        NSBezierPath(roundedRect: r, xRadius: 60, yRadius: 60).fill()
    }
    symbol(sym, 44, accent, at: NSPoint(x: r.minX + 80, y: r.midY))
    label(s, 48, .semibold, ink, in: NSRect(x: r.minX + 130, y: r.minY, width: w - 150, height: r.height))
}

let args = CommandLine.arguments
let icon = NSImage(contentsOfFile: args[1])!
let out = args[2]

canvas("\(out)/1-jump.png") {
    background()
    text("Jump to the tab that’s playing.", 128, .bold, ink, y: 150)
    text("Press ⌥⌘P anywhere in Safari.", 60, .regular, gray, y: 340)
    window(NSRect(x: 360, y: 520, width: 2160, height: 1180),
           tabs: [Tab(title: "Inbox", playing: false), Tab(title: "Quarterly Report", playing: false),
                  Tab(title: "Lo-fi Beats to Study To", playing: true), Tab(title: "Weeknight Recipes", playing: false),
                  Tab(title: "Flight Status", playing: false)],
           active: 2, url: "music.example.com", video: "Lo-fi Beats to Study To")
    keycaps(["⌥", "⌘", "P"], center: NSPoint(x: W / 2, y: 1690))
}

canvas("\(out)/2-cycle.png") {
    background()
    text("Every window. Every tab.", 128, .bold, ink, y: 150)
    text("Press again to cycle through everything that’s playing.", 60, .regular, gray, y: 340)
    window(NSRect(x: 200, y: 540, width: 1640, height: 1000),
           tabs: [Tab(title: "Docs", playing: false), Tab(title: "Morning Podcast", playing: true), Tab(title: "Calendar", playing: false)],
           active: 1, url: "podcasts.example.com", video: "Morning Podcast, Episode 42")
    window(NSRect(x: 1040, y: 720, width: 1640, height: 1000),
           tabs: [Tab(title: "News", playing: false), Tab(title: "Shopping", playing: false), Tab(title: "Live Concert", playing: true)],
           active: 2, url: "video.example.com", video: "Live Concert in the Park")
}

canvas("\(out)/3-private.png") {
    background()
    text("Private by design.", 128, .bold, ink, y: 150)
    text("No data collected. Nothing leaves your Mac.", 60, .regular, gray, y: 340)
    shadowed(0, 0) { icon.draw(in: NSRect(x: W / 2 - 400, y: 520, width: 800, height: 800)) }
    pill("No tracking", "hand.raised.fill", center: NSPoint(x: W / 2 - 720, y: 1520))
    pill("No network access", "wifi.slash", center: NSPoint(x: W / 2, y: 1520))
    pill("One shortcut", "command", center: NSPoint(x: W / 2 + 720, y: 1520))
}
