import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    fputs("usage: make-icon-png-opaque.swift <input.png> <output.png>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL

guard
    let source = CGImageSourceCreateWithURL(inputURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
else {
    fputs("Unable to decode icon input.\n", stderr)
    exit(1)
}

context.setFillColor(CGColor(red: 28 / 255, green: 43 / 255, blue: 33 / 255, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

guard
    let opaqueImage = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(outputURL, UTType.png.identifier as CFString, 1, nil)
else {
    fputs("Unable to create opaque icon output.\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, opaqueImage, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Unable to write opaque icon output.\n", stderr)
    exit(1)
}
