import SwiftUI
import ULS_CoreGame

struct GameTabletopResourceStampView: View {
    let resource: ResourceV1
    let size: CGSize
    let usesMiniatureAsset: Bool

    var body: some View {
        ZStack {
            ForEach(Array(strokeOffsets.enumerated()), id: \.offset) { _, offset in
                Image(assetName)
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .offset(offset)
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private var assetName: String {
        usesMiniatureAsset
            ? resource.tabletopMiniStampAssetName
            : resource.tabletopStampAssetName
    }

    private var strokeOffsets: [CGSize] {
        guard resource == .sheep else { return [.zero] }

        // The sheep drawing has finer authored strokes than the other resource
        // marks. One device-pixel expansion preserves its shape while matching
        // their optical weight on small tabletop cards and cost pips.
        return [
            .zero,
            CGSize(width: -0.34, height: 0),
            CGSize(width: 0.34, height: 0),
            CGSize(width: 0, height: -0.34),
            CGSize(width: 0, height: 0.34),
        ]
    }
}
