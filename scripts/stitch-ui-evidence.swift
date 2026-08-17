import AppKit
import AVFoundation
import CoreMedia
import Foundation
import QuartzCore

struct EvidenceClip {
    let title: String
    let path: String
    let retainedTailSeconds: Double
}

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: swift scripts/stitch-ui-evidence.swift <clips.tsv> <output.mov> [speed] [default-tail-seconds]\n", stderr)
    exit(64)
}

let manifestURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let speed = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3]) ?? 4 : 4
let defaultTail = CommandLine.arguments.count > 4 ? Double(CommandLine.arguments[4]) ?? 18 : 18
guard speed > 0, defaultTail > 0 else {
    fatalError("Speed and retained tail must be positive.")
}

let clips = try String(contentsOf: manifestURL, encoding: .utf8)
    .split(whereSeparator: \.isNewline)
    .compactMap { rawLine -> EvidenceClip? in
        let line = String(rawLine)
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty,
              !line.trimmingCharacters(in: .whitespaces).hasPrefix("#") else {
            return nil
        }
        let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 2 else {
            fatalError("Expected tab-separated title and video path: \(line)")
        }
        let tail = fields.count >= 3 ? Double(fields[2]) ?? defaultTail : defaultTail
        return EvidenceClip(title: fields[0], path: fields[1], retainedTailSeconds: tail)
    }

guard !clips.isEmpty else { fatalError("No clips found in \(manifestURL.path)") }

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try? FileManager.default.removeItem(at: outputURL)

let composition = AVMutableComposition()
guard let compositionVideoTrack = composition.addMutableTrack(
    withMediaType: .video,
    preferredTrackID: kCMPersistentTrackID_Invalid
) else { fatalError("Unable to create video track") }

var outputCursor = CMTime.zero
var segmentRanges: [(title: String, range: CMTimeRange)] = []
var renderSize = CGSize.zero
var sourceTransform = CGAffineTransform.identity

for clip in clips {
    let url = URL(fileURLWithPath: clip.path)
    guard FileManager.default.fileExists(atPath: url.path) else {
        fatalError("Missing clip: \(url.path)")
    }
    let asset = AVURLAsset(url: url)
    guard let sourceTrack = asset.tracks(withMediaType: .video).first else {
        fatalError("No video track: \(url.path)")
    }
    if renderSize == .zero {
        sourceTransform = sourceTrack.preferredTransform
        let transformed = sourceTrack.naturalSize.applying(sourceTransform)
        renderSize = CGSize(width: abs(transformed.width), height: abs(transformed.height))
    }

    let retained = min(CMTimeGetSeconds(asset.duration), clip.retainedTailSeconds)
    let sourceRange = CMTimeRange(
        start: CMTime(seconds: max(CMTimeGetSeconds(asset.duration) - retained, 0), preferredTimescale: 600),
        duration: CMTime(seconds: retained, preferredTimescale: 600)
    )
    try compositionVideoTrack.insertTimeRange(sourceRange, of: sourceTrack, at: outputCursor)
    let accelerated = CMTimeMultiplyByFloat64(sourceRange.duration, multiplier: 1 / speed)
    compositionVideoTrack.scaleTimeRange(
        CMTimeRange(start: outputCursor, duration: sourceRange.duration),
        toDuration: accelerated
    )
    segmentRanges.append((clip.title, CMTimeRange(start: outputCursor, duration: accelerated)))
    outputCursor = CMTimeAdd(outputCursor, accelerated)
}

let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: outputCursor)
let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
layerInstruction.setTransform(sourceTransform, at: .zero)
instruction.layerInstructions = [layerInstruction]

let videoComposition = AVMutableVideoComposition()
videoComposition.instructions = [instruction]
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
videoComposition.renderSize = renderSize

let parentLayer = CALayer()
parentLayer.frame = CGRect(origin: .zero, size: renderSize)
let videoLayer = CALayer()
videoLayer.frame = parentLayer.frame
parentLayer.addSublayer(videoLayer)
let totalSeconds = max(CMTimeGetSeconds(outputCursor), 0.001)

func bannerImage(title: String, size: CGSize) -> CGImage {
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor(calibratedWhite: 0.03, alpha: 0.90).setFill()
    NSBezierPath(roundedRect: CGRect(origin: .zero, size: size), xRadius: 26, yRadius: 26).fill()
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 46, weight: .semibold),
        .foregroundColor: NSColor.white,
    ]
    let measured = (title as NSString).size(withAttributes: attributes)
    (title as NSString).draw(
        at: CGPoint(x: max((size.width - measured.width) / 2, 18), y: (size.height - measured.height) / 2),
        withAttributes: attributes
    )
    image.unlockFocus()
    var rect = CGRect(origin: .zero, size: size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
}

for segment in segmentRanges {
    let start = CMTimeGetSeconds(segment.range.start)
    let end = CMTimeGetSeconds(CMTimeRangeGetEnd(segment.range))
    let visibleEnd = min(start + 1.25, end)
    let banner = CALayer()
    banner.frame = CGRect(x: 54, y: renderSize.height - 205, width: renderSize.width - 108, height: 105)
    banner.contents = bannerImage(title: segment.title, size: banner.bounds.size)
    banner.contentsGravity = .resizeAspect
    banner.opacity = 0

    let fade = min(0.18, max((visibleEnd - start) * 0.2, 0.05))
    let animation = CAKeyframeAnimation(keyPath: "opacity")
    animation.keyTimes = [0, start, start + fade, visibleEnd - fade, visibleEnd, totalSeconds]
        .map { NSNumber(value: min(max($0 / totalSeconds, 0), 1)) }
    animation.values = [0, 0, 1, 1, 0, 0]
    animation.duration = totalSeconds
    animation.beginTime = AVCoreAnimationBeginTimeAtZero
    animation.isRemovedOnCompletion = false
    animation.fillMode = .both
    banner.add(animation, forKey: "heading")
    parentLayer.addSublayer(banner)
}

videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: parentLayer
)

guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
    fatalError("Unable to create exporter")
}
exporter.outputURL = outputURL
exporter.outputFileType = .mov
exporter.shouldOptimizeForNetworkUse = true
exporter.videoComposition = videoComposition
let semaphore = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { semaphore.signal() }
semaphore.wait()
guard exporter.status == .completed else {
    fatalError("Export failed: \(exporter.error.map(String.init(reflecting:)) ?? "unknown")")
}

print("output=\(outputURL.path)")
print("clips=\(clips.count)")
print(String(format: "duration_seconds=%.3f", totalSeconds))
print(String(format: "render_size=%.0fx%.0f", renderSize.width, renderSize.height))
