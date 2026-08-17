import AppKit
import AVFoundation
import Foundation

guard CommandLine.arguments.count >= 4 else {
    fputs("usage: swift scripts/extract-ui-video-frames.swift <video> <output-directory> <second> [second ...]\n", stderr)
    exit(64)
}

let videoURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let sampleSeconds = CommandLine.arguments.dropFirst(3).compactMap(Double.init)
guard !sampleSeconds.isEmpty else { fatalError("At least one valid sample second is required.") }
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

for (index, seconds) in sampleSeconds.enumerated() {
    let image = try generator.copyCGImage(
        at: CMTime(seconds: seconds, preferredTimescale: 600),
        actualTime: nil
    )
    let bitmap = NSBitmapImageRep(cgImage: image)
    let data = bitmap.representation(using: .png, properties: [:])!
    let destination = outputURL.appendingPathComponent("frame-\(index + 1).png")
    try data.write(to: destination)
    print(destination.path)
}
