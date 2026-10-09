#!/usr/bin/env swift
import AppKit
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard !arguments.isEmpty else {
    FileHandle.standardError.write(Data("Usage: inspect_png_alpha.swift <image.png> [...]\n".utf8))
    exit(2)
}

let alphaThreshold: UInt8 = 8

for path in arguments {
    guard let source = NSImage(contentsOfFile: path) else {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        print("ERROR\t\(path)\tunreadable image")
        continue
    }

    var proposedRect = NSRect(origin: .zero, size: source.size)
    guard let image = source.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
        print("ERROR\t\(path)\tunable to decode")
        continue
    }

    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    let drewImage = pixels.withUnsafeMutableBytes { buffer -> Bool in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return false }
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        return true
    }

    guard drewImage else {
        print("ERROR\t\(path)\tunable to create bitmap context")
        continue
    }

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1
    var visiblePixels = 0

    for y in 0..<height {
        for x in 0..<width {
            let alpha = pixels[y * bytesPerRow + x * 4 + 3]
            guard alpha >= alphaThreshold else { continue }
            visiblePixels += 1
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }

    guard maxX >= minX, maxY >= minY else {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        print("EMPTY\t\(path)\tcanvas=\(width)x\(height)")
        continue
    }
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    let visibleWidth = maxX - minX + 1
    let visibleHeight = maxY - minY + 1
    let right = width - maxX - 1
    let top = height - maxY - 1
    let coverage = Double(visiblePixels) / Double(width * height) * 100

    print(
        "OK\t\(path)\tcanvas=\(width)x\(height)" +
        "\tvisible=\(minX),\(minY),\(visibleWidth),\(visibleHeight)" +
        "\tinsets=left:\(minX),right:\(right),bottom:\(minY),top:\(top)" +
        String(format: "\tcoverage=%.2f%%", coverage)
    )
}
