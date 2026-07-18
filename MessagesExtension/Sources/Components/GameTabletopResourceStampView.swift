import SwiftUI
import ULS_CoreGame

struct GameTabletopResourceStampView: View {
    let resource: ResourceV1
    let size: CGSize
    let usesMiniatureAsset: Bool

    var body: some View {
        Image(assetName)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private var assetName: String {
        usesMiniatureAsset
            ? resource.tabletopMiniStampAssetName
            : resource.tabletopStampAssetName
    }

}
