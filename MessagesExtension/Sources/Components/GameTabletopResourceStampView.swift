import SwiftUI
import ULS_CoreGame

struct GameTabletopResourceStampView: View {
    let resource: ResourceV1
    let size: CGSize
    let usesMiniatureAsset: Bool
    let assetBundle: Bundle

    init(
        resource: ResourceV1,
        size: CGSize,
        usesMiniatureAsset: Bool,
        assetBundle: Bundle = .main
    ) {
        self.resource = resource
        self.size = size
        self.usesMiniatureAsset = usesMiniatureAsset
        self.assetBundle = assetBundle
    }

    var body: some View {
        Image(assetName, bundle: assetBundle)
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
