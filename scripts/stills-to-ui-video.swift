import AppKit
import AVFoundation
import CoreVideo
import Foundation

struct ReviewStill {
    let title: String
    let url: URL
}

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: swift scripts/stills-to-ui-video.swift <stills.tsv> <output.mov> [seconds-per-still]\n", stderr)
    exit(64)
}

let manifestURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let secondsPerStill = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3]) ?? 1.35 : 1.35
let stills = try String(contentsOf: manifestURL, encoding: .utf8)
    .split(whereSeparator: \.isNewline)
    .compactMap { rawLine -> ReviewStill? in
        let line = String(rawLine)
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty,
              !line.trimmingCharacters(in: .whitespaces).hasPrefix("#") else { return nil }
        let fields = line.split(separator: "\t", maxSplits: 1).map(String.init)
        guard fields.count == 2 else { fatalError("Expected title and image path: \(line)") }
        return ReviewStill(title: fields[0], url: URL(fileURLWithPath: fields[1]))
    }
guard secondsPerStill > 0, !stills.isEmpty else { fatalError("No review stills found.") }

let width = 1206
let height = 2622
let framesPerSecond: Int32 = 30
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: outputURL)

let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
let input = AVAssetWriterInput(
    mediaType: .video,
    outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: 9_000_000,
            AVVideoExpectedSourceFrameRateKey: framesPerSecond,
        ],
    ]
)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
    ]
)
guard writer.canAdd(input) else { fatalError("Unable to add video input.") }
writer.add(input)
guard writer.startWriting() else { fatalError("Unable to start writer: \(writer.error?.localizedDescription ?? "unknown")") }
writer.startSession(atSourceTime: .zero)
guard let pool = adaptor.pixelBufferPool else { fatalError("Unable to create pixel buffer pool.") }

let colorSpace = CGColorSpaceCreateDeviceRGB()
let framesPerStill = max(Int((secondsPerStill * Double(framesPerSecond)).rounded()), 1)
var frameIndex: Int64 = 0

func makeFrame(still: ReviewStill) -> CVPixelBuffer {
    guard let image = NSImage(contentsOf: still.url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Unable to load image: \(still.url.path)")
    }
    var optionalBuffer: CVPixelBuffer?
    guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
          let buffer = optionalBuffer else { fatalError("Unable to allocate video frame.") }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else { fatalError("Unable to create frame context.") }

    context.setFillColor(CGColor(gray: 0.92, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let scale = min(CGFloat(width) / CGFloat(cgImage.width), CGFloat(height) / CGFloat(cgImage.height))
    let imageSize = CGSize(width: CGFloat(cgImage.width) * scale, height: CGFloat(cgImage.height) * scale)
    context.draw(cgImage, in: CGRect(
        x: (CGFloat(width) - imageSize.width) / 2,
        y: (CGFloat(height) - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height
    ))

    let bannerRect = CGRect(x: 54, y: CGFloat(height) - 205, width: CGFloat(width) - 108, height: 105)
    context.setFillColor(CGColor(gray: 0.03, alpha: 0.90))
    context.addPath(CGPath(roundedRect: bannerRect, cornerWidth: 26, cornerHeight: 26, transform: nil))
    context.fillPath()
    let title = NSAttributedString(string: still.title, attributes: [
        .font: NSFont.systemFont(ofSize: 46, weight: .semibold),
        .foregroundColor: NSColor.white,
    ])
    let titleSize = title.size()
    let titlePoint = CGPoint(x: (CGFloat(width) - titleSize.width) / 2, y: bannerRect.midY - titleSize.height / 2)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    title.draw(at: titlePoint)
    NSGraphicsContext.restoreGraphicsState()
    return buffer
}

for still in stills {
    let buffer = makeFrame(still: still)
    for _ in 0..<framesPerStill {
        while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
        guard adaptor.append(buffer, withPresentationTime: CMTime(value: frameIndex, timescale: framesPerSecond)) else {
            fatalError("Unable to append \(still.title): \(writer.error?.localizedDescription ?? "unknown")")
        }
        frameIndex += 1
    }
}

input.markAsFinished()
let semaphore = DispatchSemaphore(value: 0)
writer.finishWriting { semaphore.signal() }
semaphore.wait()
guard writer.status == .completed else { fatalError("Video export failed: \(writer.error?.localizedDescription ?? "unknown")") }
print("output=\(outputURL.path)")
print("stills=\(stills.count)")
print(String(format: "duration_seconds=%.3f", Double(frameIndex) / Double(framesPerSecond)))
print("render_size=\(width)x\(height)")
