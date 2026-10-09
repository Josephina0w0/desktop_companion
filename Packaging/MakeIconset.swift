import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 || arguments.count == 4 else {
    fatalError("Usage: MakeIconset.swift <source-png> <output-iconset> [output-icns]")
}

let sourcePath = arguments[1]
let iconsetURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
let icnsURL = arguments.count == 4 ? URL(fileURLWithPath: arguments[3]) : nil
let fileManager = FileManager.default

if fileManager.fileExists(atPath: iconsetURL.path) {
    try fileManager.removeItem(at: iconsetURL)
}
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

guard let source = NSImage(contentsOfFile: sourcePath) else {
    fatalError("Cannot load source icon: \(sourcePath)")
}
let sourceSize = source.size

let entries: [(name: String, pixels: Int)] = [
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

var renderedPNGData = [String: Data]()

for entry in entries {
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    guard let canvas = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: entry.pixels,
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        pixelsHigh: entry.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Cannot create icon canvas")
    }

    canvas.size = NSSize(width: entry.pixels, height: entry.pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: entry.pixels, height: entry.pixels).fill()

    let scale = min(
        CGFloat(entry.pixels) / sourceSize.width,
        CGFloat(entry.pixels) / sourceSize.height
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    )
    let drawWidth = sourceSize.width * scale
    let drawHeight = sourceSize.height * scale
    let drawRect = NSRect(
        x: (CGFloat(entry.pixels) - drawWidth) / 2,
        y: (CGFloat(entry.pixels) - drawHeight) / 2,
        width: drawWidth,
        height: drawHeight
    )
    source.draw(in: drawRect, from: NSRect(origin: .zero, size: sourceSize), operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = canvas.representation(using: .png, properties: [:]) else {
        fatalError("Cannot render icon PNG")
    }
    try data.write(to: iconsetURL.appendingPathComponent(entry.name))
    renderedPNGData[entry.name] = data
}

if let icnsURL {
    // Modern macOS can reject an otherwise complete .iconset. ICNS supports
    // PNG payloads directly, so assemble the standard representations here.
    let representations: [(type: String, filename: String)] = [
        ("icp4", "icon_16x16.png"),
        ("icp5", "icon_32x32.png"),
        ("icp6", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic08", "icon_256x256.png"),
        ("ic09", "icon_512x512.png"),
        ("ic10", "icon_512x512@2x.png"),
        ("ic11", "icon_16x16@2x.png"),
        ("ic12", "icon_32x32@2x.png"),
        ("ic13", "icon_128x128@2x.png"),
        ("ic14", "icon_256x256@2x.png")
    ]

    func bigEndianUInt32(_ value: Int) -> Data {
        var encoded = UInt32(value).bigEndian
        return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
    }

    var body = Data()
    for representation in representations {
        guard let type = representation.type.data(using: .ascii),
              let png = renderedPNGData[representation.filename] else {
            fatalError("Cannot assemble ICNS representation \(representation.type)")
        }
        body.append(type)
        body.append(bigEndianUInt32(png.count + 8))
        body.append(png)
    }

    var icns = Data("icns".utf8)
    icns.append(bigEndianUInt32(body.count + 8))
    icns.append(body)
    try icns.write(to: icnsURL)
}
