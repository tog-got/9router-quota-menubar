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
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // 1. Apple macOS Standard Icon Grid (824x824 inside 1024x1024)
    let margin = 100.0 * scale
    let iconRect = rect.insetBy(dx: margin, dy: margin)
    let cornerRadius = 185.0 * scale
    let squirclePath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Multi-stage Soft Drop Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -22.0 * scale),
        blur: 40.0 * scale,
        color: NSColor.black.withAlphaComponent(0.45).cgColor
    )
    NSColor.black.withAlphaComponent(0.02).setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -6.0 * scale),
        blur: 16.0 * scale,
        color: NSColor.black.withAlphaComponent(0.3).cgColor
    )
    NSColor.black.withAlphaComponent(0.02).setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // 2. Main Icon Canvas & Cosmic Obsidian Background
    ctx.saveGState()
    squirclePath.addClip()
    
    // Base Gradient: Deep Space Blue / Obsidian Violet
    let bgColors = [
        NSColor(red: 0.08, green: 0.10, blue: 0.20, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.05, blue: 0.12, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.6, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: iconRect.midX, y: iconRect.maxY),
            end: CGPoint(x: iconRect.midX, y: iconRect.minY),
            options: []
        )
    }
    
    // Aurora Neon Mesh Lights in Background
    // Top-Left Cyan Glow
    let cyanGlowColors = [
        NSColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.35).cgColor,
        NSColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    if let cyanGrad = CGGradient(colorsSpace: colorSpace, colors: cyanGlowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            cyanGrad,
            startCenter: CGPoint(x: iconRect.minX + 150 * scale, y: iconRect.maxY - 120 * scale),
            startRadius: 0,
            endCenter: CGPoint(x: iconRect.minX + 150 * scale, y: iconRect.maxY - 120 * scale),
            endRadius: 360 * scale,
            options: []
        )
    }
    
    // Bottom-Right Violet Glow
    let violetGlowColors = [
        NSColor(red: 0.65, green: 0.15, blue: 0.95, alpha: 0.3).cgColor,
        NSColor(red: 0.65, green: 0.15, blue: 0.95, alpha: 0.0).cgColor
    ] as CFArray
    if let violetGrad = CGGradient(colorsSpace: colorSpace, colors: violetGlowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            violetGrad,
            startCenter: CGPoint(x: iconRect.maxX - 140 * scale, y: iconRect.minY + 140 * scale),
            startRadius: 0,
            endCenter: CGPoint(x: iconRect.maxX - 140 * scale, y: iconRect.minY + 140 * scale),
            endRadius: 380 * scale,
            options: []
        )
    }
    
    let center = CGPoint(x: iconRect.midX, y: iconRect.midY + 12.0 * scale)
    
    // 3. Glowing AI Speedometer / Quota Track Arc
    let gaugeRadius = 250.0 * scale
    
    // Background Dark Track
    let trackPath = NSBezierPath()
    trackPath.appendArc(withCenter: center, radius: gaugeRadius, startAngle: 220, endAngle: -40, clockwise: true)
    trackPath.lineWidth = 32.0 * scale
    trackPath.lineCapStyle = .round
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    trackPath.stroke()
    
    // Active Multi-Color Neon Gauge Arc (Electric Cyan -> Emerald Green)
    let activeArc = NSBezierPath()
    activeArc.appendArc(withCenter: center, radius: gaugeRadius, startAngle: 220, endAngle: 30, clockwise: true)
    activeArc.lineWidth = 30.0 * scale
    activeArc.lineCapStyle = .round
    
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: 24.0 * scale,
        color: NSColor(red: 0.0, green: 0.9, blue: 0.95, alpha: 0.8).cgColor
    )
    NSColor(red: 0.0, green: 0.88, blue: 0.95, alpha: 1.0).setStroke()
    activeArc.stroke()
    ctx.restoreGState()
    
    // Inner Accent Arc (Magenta / Purple)
    let accentArc = NSBezierPath()
    accentArc.appendArc(withCenter: center, radius: gaugeRadius, startAngle: 220, endAngle: 150, clockwise: true)
    accentArc.lineWidth = 30.0 * scale
    accentArc.lineCapStyle = .round
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: 16.0 * scale,
        color: NSColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 0.9).cgColor
    )
    NSColor(red: 0.85, green: 0.25, blue: 1.0, alpha: 1.0).setStroke()
    accentArc.stroke()
    ctx.restoreGState()
    
    // Gauge Precision Tick Dots & Radians
    let totalTicks = 11
    for i in 0..<totalTicks {
        let angleDeg = 220.0 - (Double(i) * (260.0 / Double(totalTicks - 1)))
        let angleRad = angleDeg * .pi / 180.0
        let tickRadius = (i % 2 == 0) ? 5.5 * scale : 3.5 * scale
        let dotCenter = CGPoint(
            x: center.x + (gaugeRadius + 36.0 * scale) * CGFloat(cos(angleRad)),
            y: center.y + (gaugeRadius + 36.0 * scale) * CGFloat(sin(angleRad))
        )
        let dotPath = NSBezierPath(ovalIn: CGRect(x: dotCenter.x - tickRadius, y: dotCenter.y - tickRadius, width: tickRadius * 2, height: tickRadius * 2))
        
        if i <= 7 {
            NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.95).setFill()
        } else {
            NSColor(white: 1.0, alpha: 0.2).setFill()
        }
        dotPath.fill()
    }
    
    // 4. Central 3D Frosted Glass Dial Plate
    let innerDiscRadius = 175.0 * scale
    let innerDiscRect = CGRect(x: center.x - innerDiscRadius, y: center.y - innerDiscRadius, width: innerDiscRadius * 2, height: innerDiscRadius * 2)
    let discPath = NSBezierPath(ovalIn: innerDiscRect)
    
    // Disc Drop Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -8.0 * scale),
        blur: 24.0 * scale,
        color: NSColor.black.withAlphaComponent(0.6).cgColor
    )
    NSColor(red: 0.1, green: 0.12, blue: 0.25, alpha: 0.85).setFill()
    discPath.fill()
    ctx.restoreGState()
    
    // Disc Bevel Gradient
    let discColors = [
        NSColor(white: 0.22, alpha: 0.9).cgColor,
        NSColor(white: 0.08, alpha: 0.95).cgColor
    ] as CFArray
    if let discGrad = CGGradient(colorsSpace: colorSpace, colors: discColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        discPath.addClip()
        ctx.drawLinearGradient(
            discGrad,
            start: CGPoint(x: innerDiscRect.midX, y: innerDiscRect.maxY),
            end: CGPoint(x: innerDiscRect.midX, y: innerDiscRect.minY),
            options: []
        )
        ctx.restoreGState()
    }
    
    // Disc Specular Rim
    discPath.lineWidth = 2.5 * scale
    NSColor(white: 1.0, alpha: 0.25).setStroke()
    discPath.stroke()
    
    // 5. Stylized Modern 3D Monogram "9R" in Center
    let logoText = "9R"
    let fontSize = 155.0 * scale
    let font = NSFont.systemFont(ofSize: fontSize, weight: .black)
    
    let textShadow = NSShadow()
    textShadow.shadowOffset = NSSize(width: 0, height: -6.0 * scale)
    textShadow.shadowBlurRadius = 16.0 * scale
    textShadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
    
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: textShadow
    ]
    
    let attrString = NSAttributedString(string: logoText, attributes: textAttrs)
    let textSize = attrString.size()
    let textRect = CGRect(
        x: center.x - (textSize.width / 2.0),
        y: center.y - (textSize.height / 2.0) - (6.0 * scale),
        width: textSize.width,
        height: textSize.height
    )
    attrString.draw(in: textRect)
    
    // 6. Glowing Golden AI Sparkle (Top-Right)
    let sparkleRadius = 22.0 * scale
    let sparkleCenter = CGPoint(x: center.x + 95.0 * scale, y: center.y + 75.0 * scale)
    
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: 16.0 * scale,
        color: NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9).cgColor
    )
    let sparklePath = NSBezierPath()
    sparklePath.move(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + sparkleRadius))
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x + sparkleRadius, y: sparkleCenter.y), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - sparkleRadius), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x - sparkleRadius, y: sparkleCenter.y), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    sparklePath.curve(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + sparkleRadius), controlPoint1: sparkleCenter, controlPoint2: sparkleCenter)
    NSColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0).setFill()
    sparklePath.fill()
    ctx.restoreGState()
    
    // 7. Outer Glass Specular Rim Highlight
    let outerRimPath = NSBezierPath(roundedRect: iconRect.insetBy(dx: 1.5 * scale, dy: 1.5 * scale), xRadius: cornerRadius - 1.5 * scale, yRadius: cornerRadius - 1.5 * scale)
    outerRimPath.lineWidth = 2.0 * scale
    NSColor(white: 1.0, alpha: 0.35).setStroke()
    outerRimPath.stroke()
    
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

print("Iconset generated successfully at \(iconsetPath)")
