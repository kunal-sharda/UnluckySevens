import AppKit
import WebKit

final class SVGRenderer: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let outputURL: URL
    private let outputWidth: CGFloat

    init(inputURL: URL, outputURL: URL, width: CGFloat, height: CGFloat) {
        self.outputURL = outputURL
        self.outputWidth = width

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: width, height: height),
            configuration: configuration
        )

        super.init()
        webView.navigationDelegate = self
        webView.loadFileURL(inputURL, allowingReadAccessTo: inputURL.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let snapshot = WKSnapshotConfiguration()
        snapshot.rect = webView.bounds
        snapshot.snapshotWidth = NSNumber(value: Double(outputWidth))

        webView.takeSnapshot(with: snapshot) { [outputURL] image, error in
            guard error == nil,
                  let image,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                fail("Unable to rasterize SVG: \(error?.localizedDescription ?? "unknown error")")
            }

            do {
                try png.write(to: outputURL)
                CFRunLoopStop(CFRunLoopGetMain())
            } catch {
                fail("Unable to write rasterized icon: \(error.localizedDescription)")
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail("Unable to load SVG: \(error.localizedDescription)")
    }
}

func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 5,
      let width = Double(CommandLine.arguments[3]), width > 0,
      let height = Double(CommandLine.arguments[4]), height > 0 else {
    fail("usage: render-icon-svg.swift <input.svg> <output.png> <width> <height>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
_ = NSApplication.shared
let renderer = SVGRenderer(
    inputURL: inputURL,
    outputURL: outputURL,
    width: width,
    height: height
)

DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
    fail("Timed out while rasterizing SVG")
}

withExtendedLifetime(renderer) {
    CFRunLoopRun()
}
