import AVFoundation
import CoreVideo
import Foundation
import PDFKit

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: swift scripts/pdf-to-ui-video.swift <catalog.pdf> <output.mov> [seconds-per-page]\n", stderr)
    exit(64)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let secondsPerPage = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3]) ?? 1.15 : 1.15
guard secondsPerPage > 0, let document = PDFDocument(url: inputURL), document.pageCount > 0 else {
    fatalError("Unable to load a non-empty PDF catalog.")
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: outputURL)

let width = 1188
let height = 1684
let framesPerSecond: Int32 = 30
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
let input = AVAssetWriterInput(
    mediaType: .video,
    outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: 8_000_000,
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
let regularFrames = max(Int((secondsPerPage * Double(framesPerSecond)).rounded()), 1)
var frameIndex: Int64 = 0

func makeFrame(page: PDFPage) -> CVPixelBuffer {
    var optionalBuffer: CVPixelBuffer?
    guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
          let buffer = optionalBuffer else {
        fatalError("Unable to allocate video frame.")
    }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else { fatalError("Unable to create frame context.") }

    context.setFillColor(CGColor(gray: 0.95, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let pageBounds = page.bounds(for: .mediaBox)
    let scale = min(CGFloat(width) / pageBounds.width, CGFloat(height) / pageBounds.height)
    let drawWidth = pageBounds.width * scale
    let drawHeight = pageBounds.height * scale
    context.saveGState()
    context.translateBy(x: (CGFloat(width) - drawWidth) / 2, y: (CGFloat(height) - drawHeight) / 2)
    context.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: context)
    context.restoreGState()
    return buffer
}

for pageIndex in 0..<document.pageCount {
    guard let page = document.page(at: pageIndex) else { continue }
    let buffer = makeFrame(page: page)
    let repetitions = pageIndex == 0 ? regularFrames * 2 : regularFrames
    for _ in 0..<repetitions {
        while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
        let presentationTime = CMTime(value: frameIndex, timescale: framesPerSecond)
        guard adaptor.append(buffer, withPresentationTime: presentationTime) else {
            fatalError("Unable to append page \(pageIndex + 1): \(writer.error?.localizedDescription ?? "unknown")")
        }
        frameIndex += 1
    }
}

input.markAsFinished()
let semaphore = DispatchSemaphore(value: 0)
writer.finishWriting { semaphore.signal() }
semaphore.wait()
guard writer.status == .completed else {
    fatalError("Video export failed: \(writer.error?.localizedDescription ?? "unknown")")
}

print("output=\(outputURL.path)")
print("pages=\(document.pageCount)")
print(String(format: "duration_seconds=%.3f", Double(frameIndex) / Double(framesPerSecond)))
print("render_size=\(width)x\(height)")
