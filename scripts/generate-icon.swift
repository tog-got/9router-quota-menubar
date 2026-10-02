#!/usr/bin/env swift
import Cocoa

func createIconImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let scale = size / 1024.0
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    
    // 1. Apple macOS Squircle Path (Rounded Rect with continuous corners)
    let margin = 80.0 * scale
    let iconRect = rect.insetBy(dx: margin, dy: margin)
    let cornerRadius = 185.0 * scale
    let squirclePath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -12.0 * scale),
        blur: 32.0 * scale,
        color: NSColor.black.withAlphaComponent(0.35).cgColor
    )
    NSColor.black.withAlphaComponent(0.01).setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // 2. Background Gradient (Deep Vibrant Indigo / Royal Blue / Violet)
    ctx.saveGState()
    squirclePath.addClip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.16, blue: 0.35, alpha: 1.0).cgColor,
        NSColor(red: 0.25, green: 0.12, blue: 0.45, alpha: 1.0).cgColor,
        NSColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: iconRect.minX, y: iconRect.maxY),
            end: CGPoint(x: iconRect.maxX, y: iconRect.minY),
            options: []
        )
    }
    
    // Inner Glow & Ambient Highlights
    let glowColors = [
        NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 0.4).cgColor,
        NSColor(red: 0.6, green: 0.2, blue: 0.9, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            radialGlow,
            startCenter: CGPoint(x: iconRect.midX, y: iconRect.maxY * 0.85),
            startRadius: 10 * scale,
            endCenter: CGPoint(x: iconRect.midX, y: iconRect.maxY * 0.85),
            endRadius: 400 * scale,
            options: []
        )
    }
    
    // 3. Glowing Meter Gauge / Arc
    let center = CGPoint(x: iconRect.midX, y: iconRect.midY + 15.0 * scale)
    let gaugeRadius = 240.0 * scale
    
    // Background Gauge Track (Dashed / Dim)
    let trackPath = NSBezierPath()
    trackPath.appendArc(withCenter: center, radius: gaugeRadius, startAngle: 215, endAngle: -35, clockwise: true)
    trackPath.lineWidth = 26.0 * scale
    trackPath.lineCapStyle = .round
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    trackPath.stroke()
    
    // Active Gauge Fill (Vibrant Gradient Cyan -> Emerald)
    let activeGaugePath = NSBezierPath()
    activeGaugePath.appendArc(withCenter: center, radius: gaugeRadius, startAngle: 215, endAngle: 45, clockwise: true)
    activeGaugePath.lineWidth = 26.0 * scale
    activeGaugePath.lineCapStyle = .round
    
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: 16.0 * scale,
        color: NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.7).cgColor
    )
    NSColor(red: 0.0, green: 0.82, blue: 0.95, alpha: 0.95).setStroke()
    activeGaugePath.stroke()
    ctx.restoreGState()
    
    // Gauge Ticks / Dots
    for i in 0..<9 {
        let angleDeg = 215.0 - (Double(i) * (250.0 / 8.0))
        let angleRad = angleDeg * .pi / 180.0
        let dotRadius = 4.5 * scale
        let dotCenter = CGPoint(
            x: center.x + (gaugeRadius + 32.0 * scale) * CGFloat(cos(angleRad)),
            y: center.y + (gaugeRadius + 32.0 * scale) * CGFloat(sin(angleRad))
        )
        let dotPath = NSBezierPath(ovalIn: CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        if i <= 5 {
            NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.9).setFill()
        } else {
            NSColor(white: 1.0, alpha: 0.25).setFill()
        }
        dotPath.fill()
    }
    
    // 4. Center Logo / Typography "9R"
    let logoText = "9R"
    let fontSize = 160.0 * scale
    let font = NSFont.systemFont(ofSize: fontSize, weight: .black)
    
    let textShadow = NSShadow()
    textShadow.shadowOffset = NSSize(width: 0, height: -4.0 * scale)
    textShadow.shadowBlurRadius = 12.0 * scale
    textShadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: textShadow
    ]
    
    let attrString = NSAttributedString(string: logoText, attributes: textAttrs)
    let textSize = attrString.size()
    let textRect = CGRect(
        x: center.x - (textSize.width / 2.0),
        y: center.y - (textSize.height / 2.0) - (8.0 * scale),
        width: textSize.width,
        height: textSize.height
    )
    attrString.draw(in: textRect)
    
    // AI Sparkle Badge on Top-Right of Center
    let sparkleRadius = 18.0 * scale
    let sparkleCenter = CGPoint(x: center.x + 85.0 * scale, y: center.y + 65.0 * scale)
    
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: 10.0 * scale,
        color: NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.8).cgColor
    )
    let sparklePath = NSBezierPath()
    sparklePath.move(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + sparkleRadius))
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x + sparkleRadius, y: sparkleCenter.y), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - sparkleRadius), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x - sparkleRadius, y: sparkleCenter.y), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + sparkleRadius), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0).setFill()
    sparklePath.fill()
    ctx.restoreGState()
    
    // Subtle Glass Top Rim Reflection
    let rimPath = NSBezierPath(roundedRect: iconRect.insetBy(dx: 1.5 * scale, dy: 1.5 * scale), xRadius: cornerRadius - 1.5 * scale, yRadius: cornerRadius - 1.5 * scale)
    rimPath.lineWidth = 2.0 * scale
    NSColor(white: 1.0, alpha: 0.25).setStroke()
    rimPath.stroke()
    
    ctx.restoreGState()
    image.unlockFocus()
    return image
}

let iconsetPath = "Resources/AppIcon.iconset"
let fileManager = FileManager.default
try? fileManager.removeItem(atPath: iconsetPath)
try? fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true, attributes: nil)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = createIconImage(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(iconsetPath)/\(name)")
        try? png.write(to: url)
    }
}

print("Iconset generated at \(iconsetPath)")
